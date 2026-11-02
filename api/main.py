from pathlib import Path

import psycopg2
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
from api.database import get_cursor

app = FastAPI(
    title="Finance Fraud Analytics API",
    version="1.0.0"
)


def to_float(value):
    """Convert a DB number to float, but keep NULL as None instead of crashing."""
    return float(value) if value is not None else None


DASHBOARD_FILE = Path(__file__).parent / "static" / "dashboard.html"


@app.get("/", include_in_schema=False)
def root():
    """Opening the bare address sends you to the dashboard."""
    return RedirectResponse(url="/dashboard")


@app.get("/dashboard", response_class=HTMLResponse, include_in_schema=False)
def dashboard():
    """A web page that calls this API's own endpoints and draws charts."""
    return DASHBOARD_FILE.read_text(encoding="utf-8")


@app.get("/health")
def health_check():
    try:
        with get_cursor() as cursor:
            cursor.execute("SELECT 1;")
            cursor.fetchone()
    except psycopg2.OperationalError:
        return JSONResponse(
            status_code=503,
            content={"status": "error", "database": "unreachable"}
        )

    return {
        "status": "ok",
        "database": "connected"
    }

@app.get("/summary")
def get_summary():
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

        row = cursor.fetchone()

    return {
        "total_transactions": row[0],
        "approved_transactions": row[1],
        "failed_transactions": row[2],
        "pending_transactions": row[3],
        "reversed_transactions": row[4],
        "total_transaction_amount": to_float(row[5])
    }

@app.get("/chargebacks")
def get_chargebacks():
    with get_cursor() as cursor:
        cursor.execute("""
            SELECT
                COUNT(*) AS total_chargebacks,
                ROUND(
                    COUNT(*) * 100.0 /
                    NULLIF((SELECT COUNT(*) FROM core.transactions), 0),
                    2
                ) AS chargeback_rate_pct
            FROM core.chargebacks;
        """)

        row = cursor.fetchone()

    return {
        "total_chargebacks": row[0],
        "chargeback_rate_pct": to_float(row[1])
    }

@app.get("/alerts")
def get_alerts():
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

        rows = cursor.fetchall()

    return [
        {
            "rule_name": row[0],
            "alert_count": row[1],
            "average_risk_score": to_float(row[2])
        }
        for row in rows
    ]

@app.get("/country-risk")
def get_country_risk():
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

        rows = cursor.fetchall()

    return [
        {
            "country_code": row[0],
            "total_transactions": row[1],
            "approval_rate_pct": to_float(row[2]),
            "failure_rate_pct": to_float(row[3]),
            "cross_border_rate_pct": to_float(row[4]),
            "chargeback_rate_pct": to_float(row[5])
        }
        for row in rows
    ]

@app.get("/customers/{customer_id}/risk")
def get_customer_risk(customer_id: int):
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
        raise HTTPException(
            status_code=404,
            detail="Customer not found"
        )

    return {
        "customer_id": row[0],
        "total_transactions": row[1],
        "approved_transactions": row[2],
        "failed_transactions": row[3],
        "total_transaction_amount": to_float(row[4]),
        "avg_transaction_amount": to_float(row[5]),
        "cross_border_transactions": row[6],
        "chargeback_count": row[7],
        "alert_count": row[8]
    }
