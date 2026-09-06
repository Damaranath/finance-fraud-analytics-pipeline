import os

import pandas as pd

import psycopg2

from dotenv import load_dotenv

load_dotenv()

print("DB_USER:", os.getenv("DB_USER"))

print("DB_NAME:", os.getenv("DB_NAME"))

print("DB_PASSWORD loaded:", bool(os.getenv("DB_PASSWORD")))

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

print("\nRows:", len(df))

print("\nColumns:")

print(df.columns.tolist())

print("\nMissing values:")

print(df.isnull().sum())

print("\nDuplicate rows:")

print(df.duplicated().sum())

print("\nTransaction status counts:")

print(df["status"].value_counts(dropna=False))

print("\nTransaction type counts:")

print(df["transaction_type"].value_counts(dropna=False))

print("\nAmount summary:")

print(df["amount"].describe())

conn.close()

print("\n--- BUSINESS RULE CHECKS ---")

# 1. Failed transactions without a failure reason
failed_without_reason = df[
    (df["status"] == "failed") &
    (df["failure_reason"].isna())
]

print("\nFailed transactions without failure reason:")
print(len(failed_without_reason))


# 2. Non-failed transactions that incorrectly have a failure reason
non_failed_with_reason = df[
    (df["status"] != "failed") &
    (df["failure_reason"].notna())
]

print("\nNon-failed transactions with failure reason:")
print(len(non_failed_with_reason))


# 3. Invalid or zero/negative transaction amounts
invalid_amounts = df[df["amount"] <= 0]

print("\nTransactions with invalid amount:")
print(len(invalid_amounts))


# 4. Cross-border distribution
print("\nCross-border transaction counts:")
print(df["is_cross_border"].value_counts(dropna=False))


# 5. Failure reasons
print("\nFailure reason counts:")
print(df["failure_reason"].value_counts(dropna=False))


# 6. Payment channel distribution
print("\nPayment channel counts:")
print(df["payment_channel"].value_counts(dropna=False))


# 7. Payment method distribution
print("\nPayment method counts:")
print(df["payment_method"].value_counts(dropna=False))

