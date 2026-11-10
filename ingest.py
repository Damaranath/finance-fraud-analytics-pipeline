"""Config-driven CSV ingestion into PostgreSQL (transactions_clean).

Usage:
    python ingest.py configs/cardsim.yaml            # validate + load
    python ingest.py configs/cardsim.yaml --dry-run  # validate only, no DB
"""
import argparse
import sys
from pathlib import Path

import pandas as pd
import yaml

PROJECT_ROOT = Path(__file__).resolve().parent
STANDARD_COLUMNS = [
    "transaction_id", "customer_id", "amount", "txn_timestamp",
    "merchant", "category", "is_fraud",
]

CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS transactions_clean (
    transaction_id  TEXT          NOT NULL,
    customer_id     TEXT          NOT NULL,
    amount          NUMERIC(12,2) NOT NULL,
    txn_timestamp   TIMESTAMP     NOT NULL,
    merchant        TEXT,
    category        TEXT,
    is_fraud        BOOLEAN       NOT NULL,
    source_dataset  TEXT          NOT NULL,
    ingested_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    PRIMARY KEY (source_dataset, transaction_id)
);
"""

INSERT_SQL = """
INSERT INTO transactions_clean
    (transaction_id, customer_id, amount, txn_timestamp,
     merchant, category, is_fraud, source_dataset)
VALUES %s
ON CONFLICT (source_dataset, transaction_id) DO NOTHING
RETURNING 1
"""


# ---------------------------------------------------------------- config ----
def load_config(path):
    with open(path) as f:
        cfg = yaml.safe_load(f)
    for key in ("source_name", "csv_path", "column_map", "required_columns"):
        if key not in cfg:
            sys.exit(f"Config error: missing key '{key}' in {path}")
    cfg.setdefault("chunksize", 100_000)
    cfg.setdefault("timestamp_format", None)
    return cfg


def check_header(csv_path, column_map):
    header = pd.read_csv(csv_path, nrows=0).columns
    missing = [c for c in column_map if c not in header]
    if missing:
        sys.exit(f"Required source columns missing from {csv_path}: {missing}")


# ------------------------------------------------------------ validation ----
def transform_and_validate(chunk, cfg, seen_ids):
    """Return (clean_df, rejected_df) for one chunk of raw string data."""
    raw = chunk.rename(columns=cfg["column_map"])
    for col in STANDARD_COLUMNS:          # optional columns may be unmapped
        if col not in raw:
            raw[col] = None
    raw = raw[STANDARD_COLUMNS]
    for col in raw.columns:               # treat blank strings as missing
        raw[col] = raw[col].str.strip().replace("", pd.NA)

    reasons = pd.Series("", index=raw.index)

    def flag(mask, reason):
        reasons[mask] = reasons[mask] + reason + ";"

    for col in cfg["required_columns"]:
        flag(raw[col].isna(), f"missing_{col}")

    amount = pd.to_numeric(raw["amount"], errors="coerce")
    flag(raw["amount"].notna() & amount.isna(), "amount_not_numeric")

    ts = pd.to_datetime(raw["txn_timestamp"], format=cfg["timestamp_format"],
                        errors="coerce")
    flag(raw["txn_timestamp"].notna() & ts.isna(), "timestamp_unparseable")

    fraud = raw["is_fraud"].map({"0": False, "1": True})
    flag(raw["is_fraud"].notna() & fraud.isna(), "is_fraud_not_0_or_1")

    # duplicates: within this chunk, or already seen in an earlier chunk
    ids = raw["transaction_id"]
    dup = ids.notna() & (ids.duplicated(keep="first") | ids.isin(seen_ids))
    flag(dup, "duplicate_transaction_id")

    bad = reasons != ""
    rejected = chunk[bad].copy()
    rejected["reject_reason"] = reasons[bad].str.rstrip(";")

    clean = raw[~bad].copy()
    clean["amount"] = amount[~bad].round(2)
    clean["txn_timestamp"] = ts[~bad]
    clean["is_fraud"] = fraud[~bad].astype(bool)
    clean["source_dataset"] = cfg["source_name"]

    seen_ids.update(clean["transaction_id"])
    return clean, rejected


# ------------------------------------------------------------------ load ----
def load_chunk(conn, clean):
    from psycopg2.extras import execute_values

    clean = clean.astype(object).where(clean.notna(), None)  # NaN -> NULL
    rows = [
        (r.transaction_id, r.customer_id, r.amount,
         r.txn_timestamp.to_pydatetime(), r.merchant, r.category,
         bool(r.is_fraud), r.source_dataset)
        for r in clean.itertuples(index=False)
    ]
    with conn.cursor() as cur:
        # rowcount only reflects the last page, so count RETURNING rows instead
        inserted = len(execute_values(cur, INSERT_SQL, rows,
                                      page_size=10_000, fetch=True))
    conn.commit()
    return inserted


# ------------------------------------------------------------------ main ----
def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("config", help="path to source YAML config")
    parser.add_argument("--dry-run", action="store_true",
                        help="validate and write rejects, but skip the database")
    args = parser.parse_args()

    cfg = load_config(args.config)
    csv_path = PROJECT_ROOT / cfg["csv_path"]
    check_header(csv_path, cfg["column_map"])

    log_dir = PROJECT_ROOT / "logs"
    log_dir.mkdir(exist_ok=True)
    reject_path = log_dir / f"rejected_{cfg['source_name']}.csv"

    conn = None
    if not args.dry_run:
        from api.database import get_connection
        conn = get_connection()
        with conn.cursor() as cur:
            cur.execute(CREATE_TABLE_SQL)
        conn.commit()

    seen_ids = set()
    totals = {"read": 0, "clean": 0, "rejected": 0, "inserted": 0}
    first_reject_write = True

    try:
        reader = pd.read_csv(csv_path, usecols=list(cfg["column_map"]),
                             dtype=str, keep_default_na=False,
                             chunksize=cfg["chunksize"])
        for i, chunk in enumerate(reader, start=1):
            clean, rejected = transform_and_validate(chunk, cfg, seen_ids)

            if not rejected.empty:
                rejected.to_csv(reject_path, index=False,
                                mode="w" if first_reject_write else "a",
                                header=first_reject_write)
                first_reject_write = False

            inserted = load_chunk(conn, clean) if conn and not clean.empty else 0

            totals["read"] += len(chunk)
            totals["clean"] += len(clean)
            totals["rejected"] += len(rejected)
            totals["inserted"] += inserted
            print(f"chunk {i}: read={len(chunk)} clean={len(clean)} "
                  f"rejected={len(rejected)} inserted={inserted}")
    except Exception:
        if conn:
            conn.rollback()
        raise
    finally:
        if conn:
            conn.close()

    print(f"\nDone [{cfg['source_name']}]: {totals}")
    if totals["rejected"]:
        print(f"Rejected rows written to {reject_path}")
    if conn is not None and totals["inserted"] < totals["clean"]:
        print(f"{totals['clean'] - totals['inserted']} clean rows already "
              "existed in transactions_clean (skipped).")


if __name__ == "__main__":
    main()
