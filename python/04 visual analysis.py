import os
from pathlib import Path

import pandas as pd
import psycopg2
import matplotlib.pyplot as plt
from dotenv import load_dotenv

project_root = Path(__file__).resolve().parents[1]
load_dotenv(project_root / ".env")

output_dir = project_root / "outputs"
output_dir.mkdir(exist_ok=True)

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
        MAX(risk_score) AS max_risk_score
    FROM risk.alerts
    WHERE transaction_id IS NOT NULL
    GROUP BY transaction_id
),
chargeback_summary AS (
    SELECT
        transaction_id,
        1 AS has_chargeback
    FROM core.chargebacks
    GROUP BY transaction_id
)
SELECT
    t.transaction_id,
    t.payment_channel,
    t.is_cross_border,
    COALESCE(a.alert_count, 0) AS alert_count,
    CASE WHEN a.transaction_id IS NOT NULL THEN 1 ELSE 0 END AS has_alert,
    COALESCE(cb.has_chargeback, 0) AS has_chargeback
FROM core.transactions t
LEFT JOIN alert_summary a
    ON t.transaction_id = a.transaction_id
LEFT JOIN chargeback_summary cb
    ON t.transaction_id = cb.transaction_id;
"""

df = pd.read_sql(query, conn)
conn.close()

# 1. Alerted vs non-alerted
alert_rate = (
    df.groupby("has_alert")["has_chargeback"]
    .mean()
    .mul(100)
)

alert_rate.index = ["Non-alerted", "Alerted"]

plt.figure(figsize=(7, 5))
alert_rate.plot(kind="bar")
plt.title("Chargeback Rate: Alerted vs Non-Alerted Transactions")
plt.ylabel("Chargeback Rate (%)")
plt.xlabel("")
plt.xticks(rotation=0)
plt.tight_layout()
plt.savefig(output_dir / "alerted_vs_non_alerted.png", dpi=200)
plt.close()


# 2. Domestic vs cross-border
cross_rate = (
    df.groupby("is_cross_border")["has_chargeback"]
    .mean()
    .mul(100)
)

cross_rate.index = ["Domestic", "Cross-border"]

plt.figure(figsize=(7, 5))
cross_rate.plot(kind="bar")
plt.title("Chargeback Rate: Domestic vs Cross-Border")
plt.ylabel("Chargeback Rate (%)")
plt.xlabel("")
plt.xticks(rotation=0)
plt.tight_layout()
plt.savefig(output_dir / "cross_border_chargeback_rate.png", dpi=200)
plt.close()


# 3. Chargeback rate by payment channel
channel_rate = (
    df.groupby("payment_channel")["has_chargeback"]
    .mean()
    .mul(100)
    .sort_values(ascending=False)
)

plt.figure(figsize=(7, 5))
channel_rate.plot(kind="bar")
plt.title("Chargeback Rate by Payment Channel")
plt.ylabel("Chargeback Rate (%)")
plt.xlabel("Payment Channel")
plt.xticks(rotation=0)
plt.tight_layout()
plt.savefig(output_dir / "payment_channel_chargeback_rate.png", dpi=200)
plt.close()


# 4. Chargeback rate by alert count
alert_count_rate = (
    df.groupby("alert_count")["has_chargeback"]
    .mean()
    .mul(100)
)

plt.figure(figsize=(7, 5))
alert_count_rate.plot(kind="bar")
plt.title("Chargeback Rate by Number of Alerts")
plt.ylabel("Chargeback Rate (%)")
plt.xlabel("Alert Count")
plt.xticks(rotation=0)
plt.tight_layout()
plt.savefig(output_dir / "chargeback_rate_by_alert_count.png", dpi=200)
plt.close()

print("\nVisuals saved to:", output_dir)

print("\nAlerted vs non-alerted:")
print(alert_rate.round(2))

print("\nDomestic vs cross-border:")
print(cross_rate.round(2))

print("\nPayment channel:")
print(channel_rate.round(2))

print("\nAlert count:")
print(alert_count_rate.round(2))


summary = pd.DataFrame({

    "metric": [

        "Overall chargeback rate",

        "Alerted transaction chargeback rate",

        "Non-alerted transaction chargeback rate",

        "Cross-border chargeback rate",

        "Domestic chargeback rate",

        "Web chargeback rate",

        "App chargeback rate",

        "API chargeback rate",

        "POS chargeback rate"

    ],

    "value_pct": [

        df["has_chargeback"].mean() * 100,

        df.loc[df["has_alert"] == 1, "has_chargeback"].mean() * 100,

        df.loc[df["has_alert"] == 0, "has_chargeback"].mean() * 100,

        df.loc[df["is_cross_border"] == True, "has_chargeback"].mean() * 100,

        df.loc[df["is_cross_border"] == False, "has_chargeback"].mean() * 100,

        df.loc[df["payment_channel"] == "web", "has_chargeback"].mean() * 100,

        df.loc[df["payment_channel"] == "app", "has_chargeback"].mean() * 100,

        df.loc[df["payment_channel"] == "api", "has_chargeback"].mean() * 100,

        df.loc[df["payment_channel"] == "pos", "has_chargeback"].mean() * 100

    ]

})

summary["value_pct"] = summary["value_pct"].round(2)

summary.to_csv(

    output_dir / "Analysis summary.csv",

    index=False

)

print("\nSaved analysis summary:")

print(summary)