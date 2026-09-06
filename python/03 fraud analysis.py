import os
from pathlib import Path

import pandas as pd
import psycopg2
from dotenv import load_dotenv

env_path = Path(__file__).resolve().parents[1] / ".env"
load_dotenv(env_path)

conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    database=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD")
)

query = """
WITH alert_summary AS (
    SELECT
        transaction_id,
        COUNT(*) AS alert_count,
        MAX(risk_score) AS max_risk_score,
        STRING_AGG(DISTINCT rule_name, ', ') AS alert_rules
    FROM risk.alerts
    WHERE transaction_id IS NOT NULL
    GROUP BY transaction_id
),

chargeback_summary AS (
    SELECT
        transaction_id,
        COUNT(*) AS chargeback_count,
        MAX(reason_code) AS chargeback_reason
    FROM core.chargebacks
    GROUP BY transaction_id
)

SELECT
    t.transaction_id,
    t.customer_id,
    t.merchant_id,
    t.device_id,
    t.transaction_ts,
    t.amount,
    t.transaction_type,
    t.payment_channel,
    t.payment_method,
    t.country_code,
    t.status,
    t.is_cross_border,

    CASE
        WHEN cb.transaction_id IS NOT NULL THEN 1
        ELSE 0
    END AS has_chargeback,

    cb.chargeback_reason,

    CASE
        WHEN a.transaction_id IS NOT NULL THEN 1
        ELSE 0
    END AS has_alert,

    COALESCE(a.alert_count, 0) AS alert_count,
    a.alert_rules,
    a.max_risk_score

FROM core.transactions t

LEFT JOIN chargeback_summary cb
    ON t.transaction_id = cb.transaction_id

LEFT JOIN alert_summary a
    ON t.transaction_id = a.transaction_id;
"""

df = pd.read_sql(query, conn)

print("\n--- FRAUD ANALYSIS ---")

print("\nRows after joins:")
print(len(df))

print("\n1. Transactions with chargebacks:")
print(df["has_chargeback"].value_counts())

print("\n2. Chargeback rate:")
chargeback_rate = df["has_chargeback"].mean() * 100
print(round(chargeback_rate, 2), "%")

print("\n3. Transactions with alerts:")
print(df["has_alert"].value_counts())

print("\n4. Alert rate:")
alert_rate = df["has_alert"].mean() * 100
print(round(alert_rate, 2), "%")

print("\n5. Chargeback rate by cross-border status:")
cross_border_cb = (
    df.groupby("is_cross_border")
    .agg(
        transactions=("transaction_id", "nunique"),
        chargebacks=("has_chargeback", "sum")
    )
)

cross_border_cb["chargeback_rate_pct"] = (
    cross_border_cb["chargebacks"]
    / cross_border_cb["transactions"]
    * 100
).round(2)

print(cross_border_cb)

print("\n6. Chargeback rate by payment channel:")
channel_cb = (
    df.groupby("payment_channel")
    .agg(
        transactions=("transaction_id", "nunique"),
        chargebacks=("has_chargeback", "sum")
    )
)

channel_cb["chargeback_rate_pct"] = (
    channel_cb["chargebacks"]
    / channel_cb["transactions"]
    * 100
).round(2)

print(channel_cb.sort_values("chargeback_rate_pct", ascending=False))

print("\n7. Alert count distribution:")
print(df["alert_count"].value_counts().sort_index())

print("\n8. Maximum risk score summary:")
print(df["max_risk_score"].describe().round(2))

print("\nTransactions with multiple alerts:")
print((df["alert_count"] > 1).sum())

print("\n9. Chargeback rate for alerted vs non-alerted transactions:")
alert_cb = (
    df.groupby("has_alert")
    .agg(
        transactions=("transaction_id", "nunique"),
        chargebacks=("has_chargeback", "sum")
    )
)

alert_cb["chargeback_rate_pct"] = (
    alert_cb["chargebacks"]
    / alert_cb["transactions"]
    * 100
).round(2)

print(alert_cb)

conn.close()


