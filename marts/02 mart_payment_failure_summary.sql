CREATE OR REPLACE VIEW mart.payment_failure_summary AS
SELECT
    DATE(t.transaction_ts) AS failure_date,
    t.failure_reason,

    COUNT(*) AS failed_transaction_count,
    ROUND(SUM(t.amount), 2) AS failed_transaction_amount,
    ROUND(AVG(t.amount), 2) AS avg_failed_transaction_amount,

    COUNT(DISTINCT t.customer_id) AS affected_customers,
    COUNT(DISTINCT t.merchant_id) AS affected_merchants,

    SUM(CASE WHEN t.is_cross_border = TRUE THEN 1 ELSE 0 END) AS cross_border_failed_transactions,

    ROUND(
        100.0 * SUM(CASE WHEN t.is_cross_border = TRUE THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS cross_border_failure_rate_pct

FROM core.transactions t
WHERE t.status = 'failed'
  AND t.failure_reason IS NOT NULL
GROUP BY DATE(t.transaction_ts), t.failure_reason
ORDER BY failure_date, failure_reason;

SELECT *
FROM mart.payment_failure_summary
ORDER BY failure_date, failure_reason
LIMIT 10;

SELECT COUNT(*) AS row_count
FROM mart.payment_failure_summary;

SELECT failure_reason, SUM(failed_transaction_count) AS total_failures
FROM mart.payment_failure_summary
GROUP BY failure_reason
ORDER BY total_failures DESC;


SELECT
    SUM(failed_transaction_count) AS total_failed_transactions,
    ROUND(SUM(failed_transaction_amount), 2) AS total_failed_amount
FROM mart.payment_failure_summary;