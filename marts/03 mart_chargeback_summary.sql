CREATE OR REPLACE VIEW mart.chargeback_summary AS
SELECT
    DATE(c.chargeback_ts) AS chargeback_date,
    c.reason_code,

    COUNT(*) AS chargeback_count,
    ROUND(SUM(c.chargeback_amount), 2) AS chargeback_amount,
    ROUND(AVG(c.chargeback_amount), 2) AS avg_chargeback_amount,

    COUNT(DISTINCT c.customer_id) AS affected_customers,
    COUNT(DISTINCT c.merchant_id) AS affected_merchants,

    SUM(CASE WHEN c.chargeback_status = 'open' THEN 1 ELSE 0 END) AS open_chargebacks,
    SUM(CASE WHEN c.chargeback_status = 'won' THEN 1 ELSE 0 END) AS won_chargebacks,
    SUM(CASE WHEN c.chargeback_status = 'lost' THEN 1 ELSE 0 END) AS lost_chargebacks,
    SUM(CASE WHEN c.chargeback_status = 'reversed' THEN 1 ELSE 0 END) AS reversed_chargebacks,

    ROUND(
        100.0 * SUM(CASE WHEN c.chargeback_status = 'lost' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS lost_rate_pct

FROM core.chargebacks c
GROUP BY DATE(c.chargeback_ts), c.reason_code
ORDER BY chargeback_date, reason_code;

SELECT *
FROM mart.chargeback_summary
ORDER BY chargeback_date, reason_code
LIMIT 10;


SELECT COUNT(*) AS row_count
FROM mart.chargeback_summary;

SELECT reason_code, SUM(chargeback_count) AS total_chargebacks
FROM mart.chargeback_summary
GROUP BY reason_code
ORDER BY total_chargebacks DESC;

SELECT
    SUM(chargeback_count) AS total_chargebacks,
    ROUND(SUM(chargeback_amount), 2) AS total_chargeback_amount
FROM mart.chargeback_summary;

SELECT
    SUM(open_chargebacks) AS total_open,
    SUM(won_chargebacks) AS total_won,
    SUM(lost_chargebacks) AS total_lost,
    SUM(reversed_chargebacks) AS total_reversed
FROM mart.chargeback_summary;

