CREATE OR REPLACE VIEW mart.daily_transaction_summary AS
SELECT
    DATE(t.transaction_ts) AS transaction_date,

    COUNT(*) AS total_transactions,

    SUM(CASE WHEN t.status = 'approved' THEN 1 ELSE 0 END) AS approved_transactions,
    SUM(CASE WHEN t.status = 'failed' THEN 1 ELSE 0 END) AS failed_transactions,
    SUM(CASE WHEN t.status = 'pending' THEN 1 ELSE 0 END) AS pending_transactions,
    SUM(CASE WHEN t.status = 'reversed' THEN 1 ELSE 0 END) AS reversed_transactions,

    ROUND(SUM(t.amount), 2) AS total_transaction_amount,
    ROUND(SUM(CASE WHEN t.status = 'approved' THEN t.amount ELSE 0 END), 2) AS approved_transaction_amount,
    ROUND(SUM(CASE WHEN t.status = 'failed' THEN t.amount ELSE 0 END), 2) AS failed_transaction_amount,

    ROUND(AVG(t.amount), 2) AS avg_transaction_amount,

    SUM(CASE WHEN t.is_cross_border = TRUE THEN 1 ELSE 0 END) AS cross_border_transactions,

    ROUND(
        100.0 * SUM(CASE WHEN t.status = 'approved' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS approval_rate_pct,

    ROUND(
        100.0 * SUM(CASE WHEN t.status = 'failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS failure_rate_pct,

    ROUND(
        100.0 * SUM(CASE WHEN t.is_cross_border = TRUE THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS cross_border_rate_pct

FROM core.transactions t
GROUP BY DATE(t.transaction_ts)
ORDER BY transaction_date;


SELECT *
FROM mart.daily_transaction_summary
ORDER BY transaction_date
LIMIT 10;

SELECT COUNT(*) AS day_count
FROM mart.daily_transaction_summary;

SELECT
    MIN(transaction_date) AS min_date,
    MAX(transaction_date) AS max_date
FROM mart.daily_transaction_summary;


SELECT
    ROUND(AVG(total_transactions), 2) AS avg_daily_transactions,
    ROUND(AVG(total_transaction_amount), 2) AS avg_daily_transaction_amount,
    ROUND(AVG(approval_rate_pct), 2) AS avg_daily_approval_rate
FROM mart.daily_transaction_summary;





