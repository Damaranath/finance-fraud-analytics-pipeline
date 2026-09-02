INSERT INTO core.transactions (
    transaction_ref,
    account_id,
    customer_id,
    merchant_id,
    device_id,
    transaction_ts,
    amount,
    currency_code,
    transaction_type,
    payment_channel,
    payment_method,
    country_code,
    status,
    failure_reason,
    is_cross_border,
    ip_address
)
WITH active_merchants AS (
    SELECT
        merchant_id,
        merchant_category,
        country_code,
        risk_level,
        ROW_NUMBER() OVER (ORDER BY merchant_id) AS rn
    FROM core.merchants
    WHERE merchant_status = 'active'
),
merchant_count AS (
    SELECT COUNT(*) AS cnt
    FROM active_merchants
),
base AS (
    SELECT
        gs,
        ((random() * 4999)::int + 1) AS customer_id,
        random() AS r_merchant,
        random() AS r_status,
        random() AS r_type,
        random() AS r_channel,
        random() AS r_method,
        random() AS r_cross,
        random() AS r_amt,
        random() AS r_fail_reason
    FROM generate_series(1, 60000) AS gs
),
chosen_merchants AS (
    SELECT
        b.*,
        ((b.r_merchant * mc.cnt)::int + 1) AS merchant_rn
    FROM base b
    CROSS JOIN merchant_count mc
),
tx_base AS (
    SELECT
        cm.gs,
        c.customer_id,
        c.country_code AS customer_country,
        c.risk_segment,
        c.signup_date,
        a.account_id,
        a.currency_code,
        a.opened_at,
        cd.device_id,
        m.merchant_id,
        m.merchant_category,
        m.country_code AS merchant_country,
        m.risk_level AS merchant_risk_level,
        cm.r_status,
        cm.r_type,
        cm.r_channel,
        cm.r_method,
        cm.r_cross,
        cm.r_amt,
        cm.r_fail_reason
    FROM chosen_merchants cm
    JOIN core.customers c
      ON c.customer_id = cm.customer_id
    JOIN core.accounts a
      ON a.customer_id = c.customer_id
     AND a.is_primary = TRUE
     AND a.account_status IN ('active', 'blocked')
    JOIN LATERAL (
        SELECT cd.device_id
        FROM core.customer_devices cd
        WHERE cd.customer_id = c.customer_id
        ORDER BY random()
        LIMIT 1
    ) cd ON TRUE
    JOIN active_merchants m
      ON m.rn = cm.merchant_rn
),
tx_enriched AS (
    SELECT
        gs,
        customer_id,
        account_id,
        merchant_id,
        device_id,
        currency_code,
        customer_country,
        merchant_country,
        merchant_category,
        merchant_risk_level,
        signup_date,
        opened_at,

        CASE
            WHEN r_cross < 0.88 THEN customer_country
            ELSE merchant_country
        END AS transaction_country,

        CASE
            WHEN r_cross < 0.88 THEN FALSE
            ELSE customer_country <> merchant_country
        END AS is_cross_border,

        CASE
            WHEN merchant_category = 'retail' THEN ROUND((15 + r_amt * 285)::numeric, 2)
            WHEN merchant_category = 'electronics' THEN ROUND((80 + r_amt * 1920)::numeric, 2)
            WHEN merchant_category = 'travel' THEN ROUND((120 + r_amt * 2380)::numeric, 2)
            WHEN merchant_category = 'food_delivery' THEN ROUND((10 + r_amt * 90)::numeric, 2)
            WHEN merchant_category = 'digital_goods' THEN ROUND((5 + r_amt * 145)::numeric, 2)
            WHEN merchant_category = 'gaming' THEN ROUND((5 + r_amt * 220)::numeric, 2)
            WHEN merchant_category = 'marketplace' THEN ROUND((12 + r_amt * 780)::numeric, 2)
            ELSE ROUND((8 + r_amt * 180)::numeric, 2)
        END AS amount,

        CASE
            WHEN r_status < 0.84 THEN 'approved'
            WHEN r_status < 0.95 THEN 'failed'
            WHEN r_status < 0.985 THEN 'pending'
            ELSE 'reversed'
        END AS status,

        CASE
            WHEN r_status < 0.84 THEN NULL
            WHEN r_status < 0.95 THEN
                CASE
                    WHEN r_fail_reason < 0.34 THEN 'insufficient_funds'
                    WHEN r_fail_reason < 0.58 THEN 'issuer_declined'
                    WHEN r_fail_reason < 0.72 THEN 'invalid_cvv'
                    WHEN r_fail_reason < 0.84 THEN 'technical_error'
                    WHEN r_fail_reason < 0.93 THEN 'velocity_limit'
                    ELSE 'suspected_fraud'
                END
            ELSE NULL
        END AS failure_reason,

        CASE
            WHEN r_type < 0.93 THEN 'purchase'
            WHEN r_type < 0.97 THEN 'refund'
            WHEN r_type < 0.99 THEN 'transfer'
            ELSE 'withdrawal'
        END AS transaction_type,

        CASE
            WHEN r_channel < 0.58 THEN 'app'
            WHEN r_channel < 0.86 THEN 'web'
            WHEN r_channel < 0.96 THEN 'pos'
            ELSE 'api'
        END AS payment_channel,

        CASE
            WHEN r_method < 0.52 THEN 'card'
            WHEN r_method < 0.74 THEN 'wallet'
            WHEN r_method < 0.90 THEN 'bank_transfer'
            ELSE 'account_balance'
        END AS payment_method
    FROM tx_base
)
SELECT
    'TXN' || LPAD(gs::text, 9, '0') AS transaction_ref,
    account_id,
    customer_id,
    merchant_id,
    device_id,
    GREATEST(
        opened_at + INTERVAL '1 minute',
        signup_date + INTERVAL '1 minute'
    )
    + ((random() * 700)::int) * INTERVAL '1 day'
    + ((random() * 86400)::int) * INTERVAL '1 second' AS transaction_ts,
    amount,
    currency_code,
    transaction_type,
    payment_channel,
    payment_method,
    transaction_country AS country_code,
    status,
    failure_reason,
    is_cross_border,
    '10.' || ((random() * 255)::int)::text || '.'
          || ((random() * 255)::int)::text || '.'
          || ((random() * 255)::int)::text AS ip_address
FROM tx_enriched;


SELECT COUNT(*) AS transaction_count
FROM core.transactions;

SELECT status, COUNT(*) AS cnt
FROM core.transactions
GROUP BY status
ORDER BY cnt DESC;

SELECT transaction_type, COUNT(*) AS cnt
FROM core.transactions
GROUP BY transaction_type
ORDER BY cnt DESC;

SELECT payment_channel, COUNT(*) AS cnt
FROM core.transactions
GROUP BY payment_channel
ORDER BY cnt DESC;

SELECT payment_channel, COUNT(*) AS cnt
FROM core.transactions
GROUP BY payment_channel
ORDER BY cnt DESC;

SELECT payment_method, COUNT(*) AS cnt
FROM core.transactions
GROUP BY payment_method
ORDER BY cnt DESC;

SELECT is_cross_border, COUNT(*) AS cnt
FROM core.transactions
GROUP BY is_cross_border
ORDER BY is_cross_border;

SELECT merchant_id, COUNT(*) AS txn_cnt
FROM core.transactions
GROUP BY merchant_id
ORDER BY txn_cnt DESC
LIMIT 10;


SELECT MIN(amount) AS min_amount,
       MAX(amount) AS max_amount,
       ROUND(AVG(amount), 2) AS avg_amount
FROM core.transactions;

