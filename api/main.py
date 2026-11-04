from pathlib import Path

import psycopg2
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse

from api.database import get_cursor
from api.schemas import (
    AlertRuleSummary,
    ChargebackResponse,
    CountryRisk,
    CustomerRisk,
    ErrorResponse,
    HealthResponse,
    SummaryResponse,
)

app = FastAPI(
    title="Finance Fraud Analytics API",
    description="Fraud, chargeback and risk metrics served from PostgreSQL analytical marts.",
    version="1.1.0"
)

DASHBOARD_FILE = Path(__file__).parent / "static" / "dashboard.html"


@app.get("/", include_in_schema=False)
def root():
    """Opening the bare address sends you to the dashboard."""
    return RedirectResponse(url="/dashboard")


@app.get("/dashboard", response_class=HTMLResponse, include_in_schema=False)
def dashboard():
    """A web page that calls this API's own endpoints and draws charts."""
    return DASHBOARD_FILE.read_text(encoding="utf-8")


@app.get(
    "/health",
    response_model=HealthResponse,
    tags=["System"],
    responses={503: {"model": HealthResponse, "description": "Database unreachable"}},
)
def health_check():
    """Check that the API is running and can reach the database."""
    try:
        with get_cursor() as cursor:
            cursor.execute("SELECT 1;")
            cursor.fetchone()
    except psycopg2.OperationalError:
        return JSONResponse(
            status_code=503,
            content={"status": "error", "database": "unreachable"}
        )

    return {"status": "ok", "database": "connected"}


@app.get("/summary", response_model=SummaryResponse, tags=["Transactions"])
def get_summary():
    """Transaction counts by status and the total transaction amount."""
    with get_cursor() as cursor:
        cursor.execute("""
            SELECT
                COUNT(*) AS total_transactions,
                COUNT(*) FILTER (WHERE status = 'approved') AS approved_transactions,
                COUNT(*) FILTER (WHERE status = 'failed') AS failed_transactions,
                COUNT(*) FILTER (WHERE status = 'pending') AS pending_transactions,
                COUNT(*) FILTER (WHERE status = 'reversed') AS reversed_transactions,
                ROUND(SUM(amount)::numeric, 2) AS total_transaction_amount
            FROM core.transactions;
        """)
        return cursor.fetchone()


@app.get("/chargebacks", response_model=ChargebackResponse, tags=["Chargebacks"])
def get_chargebacks():
    """Total chargebacks, plus the chargeback rate over all transactions and over approved transactions."""
    with get_cursor() as cursor:
        cursor.execute("""
            SELECT
                COUNT(*) AS total_chargebacks,
                ROUND(
                    COUNT(*) * 100.0 /
                    NULLIF((SELECT COUNT(*) FROM core.transactions), 0),
                    2
                ) AS chargeback_rate_pct,
                ROUND(
                    COUNT(*) * 100.0 /
                    NULLIF((SELECT COUNT(*) FROM core.transactions WHERE status = 'approved'), 0),
                    2
                ) AS chargeback_rate_approved_pct
            FROM core.chargebacks;
        """)
        return cursor.fetchone()


@app.get("/alerts", response_model=list[AlertRuleSummary], tags=["Fraud alerts"])
def get_alerts():
    """Alert count and average risk score for each fraud rule."""
    with get_cursor() as cursor:
        cursor.execute("""
            SELECT
                rule_name,
                COUNT(*) AS alert_count,
                ROUND(AVG(risk_score)::numeric, 2) AS average_risk_score
            FROM risk.alerts
            GROUP BY rule_name
            ORDER BY alert_count DESC;
        """)
        return cursor.fetchall()


@app.get("/country-risk", response_model=list[CountryRisk], tags=["Risk"])
def get_country_risk():
    """Approval, failure, cross-border and chargeback rates by country."""
    with get_cursor() as cursor:
        cursor.execute("""
            SELECT
                country_code,
                total_transactions,
                approval_rate_pct,
                failure_rate_pct,
                cross_border_rate_pct,
                chargeback_rate_pct
            FROM mart.country_risk_summary
            ORDER BY total_transactions DESC;
        """)
        return cursor.fetchall()


@app.get(
    "/customers/{customer_id}/risk",
    response_model=CustomerRisk,
    tags=["Risk"],
    responses={404: {"model": ErrorResponse, "description": "Customer not found"}},
)
def get_customer_risk(customer_id: int):
    """Risk profile for one customer: activity, cross-border use, chargebacks and alerts."""
    with get_cursor() as cursor:
        cursor.execute("""
            SELECT
                customer_id,
                total_transactions,
                approved_transactions,
                failed_transactions,
                total_transaction_amount,
                avg_transaction_amount,
                cross_border_transactions,
                chargeback_count,
                alert_count
            FROM mart.customer_risk_profile
            WHERE customer_id = %s;
        """, (customer_id,))
        row = cursor.fetchone()

    if row is None:
        raise HTTPException(status_code=404, detail="Customer not found")

    return row
