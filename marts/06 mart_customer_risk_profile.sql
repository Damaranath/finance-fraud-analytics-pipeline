CREATE OR REPLACE VIEW mart.customer_risk_profile AS
WITH txn AS (
    SELECT
        t.customer_id,
        COUNT(*) AS total_transactions,
        SUM(CASE WHEN t.status = 'approved' THEN 1 ELSE 0 END) AS approved_transactions,
        SUM(CASE WHEN t.status = 'failed' THEN 1 ELSE 0 END) AS failed_transactions,
        ROUND(SUM(t.amount), 2) AS total_transaction_amount,
        ROUND(AVG(t.amount), 2) AS avg_transaction_amount,
        SUM(CASE WHEN t.is_cross_border = TRUE THEN 1 ELSE 0 END) AS cross_border_transactions
    FROM core.transactions t
    GROUP BY t.customer_id
),
cb AS (
    SELECT
        c.customer_id,
        COUNT(*) AS chargeback_count,
        ROUND(SUM(c.chargeback_amount), 2) AS chargeback_amount
    FROM core.chargebacks c
    GROUP BY c.customer_id
),
al AS (
    SELECT
        a.entity_id AS customer_id,
        COUNT(*) AS alert_count
    FROM risk.alerts a
    WHERE a.entity_type = 'customer'
    GROUP BY a.entity_id
)
SELECT
    c.customer_id,
    c.customer_ref,
    c.full_name,
    c.country_code,
    c.city,
    c.kyc_status,
    c.customer_status,
    c.risk_segment,
    c.signup_date,

    COALESCE(txn.total_transactions, 0) AS total_transactions,
    COALESCE(txn.approved_transactions, 0) AS approved_transactions,
    COALESCE(txn.failed_transactions, 0) AS failed_transactions,
    COALESCE(txn.total_transaction_amount, 0.00) AS total_transaction_amount,
    COALESCE(txn.avg_transaction_amount, 0.00) AS avg_transaction_amount,
    COALESCE(txn.cross_border_transactions, 0) AS cross_border_transactions,

    COALESCE(cb.chargeback_count, 0) AS chargeback_count,
    COALESCE(cb.chargeback_amount, 0.00) AS chargeback_amount,

    COALESCE(al.alert_count, 0) AS alert_count,

    ROUND(
        100.0 * COALESCE(txn.failed_transactions, 0) / NULLIF(COALESCE(txn.total_transactions, 0), 0),
        2
    ) AS failure_rate_pct,

    ROUND(
        100.0 * COALESCE(txn.cross_border_transactions, 0) / NULLIF(COALESCE(txn.total_transactions, 0), 0),
        2
    ) AS cross_border_rate_pct,

    ROUND(
        100.0 * COALESCE(cb.chargeback_count, 0) / NULLIF(COALESCE(txn.total_transactions, 0), 0),
        2
    ) AS chargeback_rate_pct

FROM core.customers c
LEFT JOIN txn
    ON c.customer_id = txn.customer_id
LEFT JOIN cb
    ON c.customer_id = cb.customer_id
LEFT JOIN al
    ON c.customer_id = al.customer_id
ORDER BY total_transaction_amount DESC, total_transactions DESC;

SELECT COUNT(*) AS row_count
FROM mart.customer_risk_profile;

SELECT *
FROM mart.customer_risk_profile
ORDER BY total_transaction_amount DESC
LIMIT 10;

SELECT
    SUM(total_transactions) AS total_transactions,
    SUM(chargeback_count) AS total_chargebacks,
    SUM(alert_count) AS total_alerts
FROM mart.customer_risk_profile;

SELECT risk_segment, COUNT(*) AS customer_count
FROM mart.customer_risk_profile
GROUP BY risk_segment
ORDER BY customer_count DESC;

SELECT
    ROUND(AVG(total_transactions), 2) AS avg_transactions_per_customer,
    ROUND(AVG(total_transaction_amount), 2) AS avg_amount_per_customer,
    ROUND(AVG(chargeback_rate_pct), 2) AS avg_chargeback_rate_pct
FROM mart.customer_risk_profile;

