CREATE OR REPLACE VIEW mart.country_risk_summary AS
WITH txn AS (
    SELECT
        t.country_code,
        COUNT(*) AS total_transactions,
        SUM(CASE WHEN t.status = 'approved' THEN 1 ELSE 0 END) AS approved_transactions,
        SUM(CASE WHEN t.status = 'failed' THEN 1 ELSE 0 END) AS failed_transactions,
        ROUND(SUM(t.amount), 2) AS total_transaction_amount,
        ROUND(AVG(t.amount), 2) AS avg_transaction_amount,
        SUM(CASE WHEN t.is_cross_border = TRUE THEN 1 ELSE 0 END) AS cross_border_transactions
    FROM core.transactions t
    GROUP BY t.country_code
),
cb AS (
    SELECT
        t.country_code,
        COUNT(*) AS chargeback_count,
        ROUND(SUM(c.chargeback_amount), 2) AS chargeback_amount
    FROM core.chargebacks c
    JOIN core.transactions t
      ON c.transaction_id = t.transaction_id
    GROUP BY t.country_code
),
al AS (
    SELECT
        t.country_code,
        COUNT(*) AS alert_count
    FROM risk.alerts a
    JOIN core.transactions t
      ON a.transaction_id = t.transaction_id
    GROUP BY t.country_code
)
SELECT
    txn.country_code,
    txn.total_transactions,
    txn.approved_transactions,
    txn.failed_transactions,
    txn.total_transaction_amount,
    txn.avg_transaction_amount,
    txn.cross_border_transactions,

    COALESCE(cb.chargeback_count, 0) AS chargeback_count,
    COALESCE(cb.chargeback_amount, 0.00) AS chargeback_amount,
    COALESCE(al.alert_count, 0) AS alert_count,

    ROUND(
        100.0 * txn.approved_transactions / NULLIF(txn.total_transactions, 0),
        2
    ) AS approval_rate_pct,

    ROUND(
        100.0 * txn.failed_transactions / NULLIF(txn.total_transactions, 0),
        2
    ) AS failure_rate_pct,

    ROUND(
        100.0 * txn.cross_border_transactions / NULLIF(txn.total_transactions, 0),
        2
    ) AS cross_border_rate_pct,

    ROUND(
        100.0 * COALESCE(cb.chargeback_count, 0) / NULLIF(txn.total_transactions, 0),
        2
    ) AS chargeback_rate_pct

FROM txn
LEFT JOIN cb
    ON txn.country_code = cb.country_code
LEFT JOIN al
    ON txn.country_code = al.country_code
ORDER BY txn.total_transactions DESC;

SELECT *
FROM mart.country_risk_summary
ORDER BY total_transactions DESC;

SELECT COUNT(*) AS row_count
FROM mart.country_risk_summary;

SELECT
    SUM(total_transactions) AS total_transactions,
    SUM(chargeback_count) AS total_chargebacks,
    SUM(alert_count) AS total_alerts
FROM mart.country_risk_summary;

SELECT country_code, chargeback_rate_pct
FROM mart.country_risk_summary
ORDER BY chargeback_rate_pct DESC;


