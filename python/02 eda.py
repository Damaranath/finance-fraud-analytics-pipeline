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
SELECT *
FROM core.transactions;
"""

df = pd.read_sql(query, conn)

print("\n--- EDA: TRANSACTION ANALYSIS ---")

print("\n1. Average amount by transaction status:")
print(
    df.groupby("status")["amount"]
    .agg(["count", "mean", "median", "sum"])
    .round(2)
)

print("\n2. Failure rate by payment channel:")
channel_summary = (
    df.groupby("payment_channel")
    .agg(
        total_transactions=("transaction_id", "count"),
        failed_transactions=("status", lambda x: (x == "failed").sum())
    )
)

channel_summary["failure_rate_pct"] = (
    channel_summary["failed_transactions"]
    / channel_summary["total_transactions"]
    * 100
).round(2)

print(channel_summary.sort_values("failure_rate_pct", ascending=False))

print("\n3. Failure rate by payment method:")
method_summary = (
    df.groupby("payment_method")
    .agg(
        total_transactions=("transaction_id", "count"),
        failed_transactions=("status", lambda x: (x == "failed").sum())
    )
)

method_summary["failure_rate_pct"] = (
    method_summary["failed_transactions"]
    / method_summary["total_transactions"]
    * 100
).round(2)

print(method_summary.sort_values("failure_rate_pct", ascending=False))

print("\n4. Cross-border vs domestic:")
cross_border_summary = (
    df.groupby("is_cross_border")
    .agg(
        total_transactions=("transaction_id", "count"),
        failed_transactions=("status", lambda x: (x == "failed").sum()),
        avg_amount=("amount", "mean")
    )
)

cross_border_summary["failure_rate_pct"] = (
    cross_border_summary["failed_transactions"]
    / cross_border_summary["total_transactions"]
    * 100
).round(2)

print(cross_border_summary.round(2))

print("\n5. Average amount by failure reason:")
print(
    df[df["status"] == "failed"]
    .groupby("failure_reason")["amount"]
    .agg(["count", "mean", "sum"])
    .round(2)
    .sort_values("sum", ascending=False)
)

conn.close()
