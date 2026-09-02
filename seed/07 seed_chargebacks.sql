INSERT INTO core.chargebacks (
    chargeback_ref,
    transaction_id,
    customer_id,
    merchant_id,
    chargeback_ts,
    chargeback_amount,
    reason_code,
    chargeback_status
)
WITH eligible_tx AS (
    SELECT
        t.transaction_id,
        t.customer_id,
        t.merchant_id,
        t.transaction_ts,
        t.amount,
        t.is_cross_border,
        t.country_code,
        m.risk_level,
        m.merchant_category,
        random() AS r_pick,
        random() AS r_reason,
        random() AS r_status
    FROM core.transactions t
    JOIN core.merchants m
      ON t.merchant_id = m.merchant_id
    WHERE t.status = 'approved'
      AND t.transaction_type = 'purchase'
),
scored_tx AS (
    SELECT
        *,
        CASE
            WHEN risk_level = 'high' THEN 0.040
            WHEN risk_level = 'medium' THEN 0.023
            ELSE 0.012
        END
        + CASE WHEN is_cross_border THEN 0.010 ELSE 0.000 END
        + CASE WHEN amount >= 1000 THEN 0.008 ELSE 0.000 END
        + CASE
            WHEN merchant_category IN ('travel', 'digital_goods', 'gaming', 'marketplace')
                THEN 0.006
            ELSE 0.000
          END AS chargeback_prob
    FROM eligible_tx
),
picked_tx AS (
    SELECT
        *
    FROM scored_tx
    WHERE r_pick < chargeback_prob
)
SELECT
    'CB' || LPAD(ROW_NUMBER() OVER (ORDER BY transaction_id)::text, 8, '0') AS chargeback_ref,
    transaction_id,
    customer_id,
    merchant_id,
    transaction_ts
        + ((7 + random() * 90)::int) * INTERVAL '1 day'
        + ((random() * 86400)::int) * INTERVAL '1 second' AS chargeback_ts,
    amount AS chargeback_amount,
    CASE
        WHEN r_reason < 0.42 THEN 'fraud'
        WHEN r_reason < 0.68 THEN 'service_not_received'
        WHEN r_reason < 0.84 THEN 'duplicate_processing'
        ELSE 'authorization_issue'
    END AS reason_code,
    CASE
        WHEN r_status < 0.24 THEN 'open'
        WHEN r_status < 0.52 THEN 'won'
        WHEN r_status < 0.90 THEN 'lost'
        ELSE 'reversed'
    END AS chargeback_status
FROM picked_tx;


SELECT COUNT(*) AS chargeback_count
FROM core.chargebacks;

SELECT reason_code, COUNT(*) AS cnt
FROM core.chargebacks
GROUP BY reason_code
ORDER BY cnt DESC;

SELECT chargeback_status, COUNT(*) AS cnt
FROM core.chargebacks
GROUP BY chargeback_status
ORDER BY cnt DESC;


SELECT ROUND(AVG(chargeback_amount), 2) AS avg_chargeback_amount,
       MIN(chargeback_amount) AS min_chargeback_amount,
       MAX(chargeback_amount) AS max_chargeback_amount
FROM core.chargebacks;

SELECT m.risk_level, COUNT(*) AS cnt
FROM core.chargebacks c
JOIN core.merchants m
  ON c.merchant_id = m.merchant_id
GROUP BY m.risk_level
ORDER BY cnt DESC;


SELECT COUNT(*) AS distinct_merchants_with_chargebacks
FROM (
    SELECT DISTINCT merchant_id
    FROM core.chargebacks
) x;