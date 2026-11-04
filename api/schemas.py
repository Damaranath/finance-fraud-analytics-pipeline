"""Response models: the exact shape of every JSON answer the API sends back."""
from typing import Optional

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = Field(examples=["ok"])
    database: str = Field(examples=["connected"])


class SummaryResponse(BaseModel):
    total_transactions: int = Field(description="All transactions, every status")
    approved_transactions: int
    failed_transactions: int
    pending_transactions: int
    reversed_transactions: int
    total_transaction_amount: Optional[float] = Field(description="Sum of all transaction amounts; null if there are no transactions")


class ChargebackResponse(BaseModel):
    total_chargebacks: int
    chargeback_rate_pct: Optional[float] = Field(description="Chargebacks as % of all transactions; null if there are no transactions")
    chargeback_rate_approved_pct: Optional[float] = Field(description="Chargebacks as % of approved transactions only (a chargeback can only follow a completed payment); null if there are none")


class AlertRuleSummary(BaseModel):
    rule_name: str = Field(examples=["high_value_transaction"])
    alert_count: int
    average_risk_score: Optional[float] = Field(description="Average risk score (0-100); null if no alert for this rule has a score")


class CountryRisk(BaseModel):
    country_code: str = Field(examples=["AU"])
    total_transactions: int
    approval_rate_pct: Optional[float]
    failure_rate_pct: Optional[float]
    cross_border_rate_pct: Optional[float]
    chargeback_rate_pct: Optional[float]


class CustomerRisk(BaseModel):
    customer_id: int
    total_transactions: int
    approved_transactions: int
    failed_transactions: int
    total_transaction_amount: Optional[float]
    avg_transaction_amount: Optional[float]
    cross_border_transactions: int
    chargeback_count: int
    alert_count: int


class ErrorResponse(BaseModel):
    detail: str = Field(examples=["Customer not found"])
