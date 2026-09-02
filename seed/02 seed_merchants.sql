INSERT INTO core.merchants (
    merchant_ref,
    merchant_name,
    merchant_category,
    country_code,
    merchant_status,
    risk_level,
    onboarded_at
)
SELECT
    'MERCH' || LPAD(gs::text, 5, '0') AS merchant_ref,
    CASE
        WHEN r_cat < 0.18 THEN 'Retail Merchant ' || gs
        WHEN r_cat < 0.33 THEN 'Electronics Store ' || gs
        WHEN r_cat < 0.45 THEN 'Travel Merchant ' || gs
        WHEN r_cat < 0.58 THEN 'Food Delivery ' || gs
        WHEN r_cat < 0.72 THEN 'Digital Goods ' || gs
        WHEN r_cat < 0.84 THEN 'Gaming Merchant ' || gs
        WHEN r_cat < 0.93 THEN 'Marketplace Seller ' || gs
        ELSE 'Subscription Service ' || gs
    END AS merchant_name,
    CASE
        WHEN r_cat < 0.18 THEN 'retail'
        WHEN r_cat < 0.33 THEN 'electronics'
        WHEN r_cat < 0.45 THEN 'travel'
        WHEN r_cat < 0.58 THEN 'food_delivery'
        WHEN r_cat < 0.72 THEN 'digital_goods'
        WHEN r_cat < 0.84 THEN 'gaming'
        WHEN r_cat < 0.93 THEN 'marketplace'
        ELSE 'subscription'
    END AS merchant_category,
    CASE
        WHEN r_country < 0.50 THEN 'AU'
        WHEN r_country < 0.72 THEN 'US'
        WHEN r_country < 0.84 THEN 'GB'
        WHEN r_country < 0.93 THEN 'SG'
        ELSE 'IN'
    END AS country_code,
    CASE
        WHEN r_status < 0.94 THEN 'active'
        WHEN r_status < 0.98 THEN 'suspended'
        ELSE 'closed'
    END AS merchant_status,
    CASE
        WHEN r_risk < 0.62 THEN 'low'
        WHEN r_risk < 0.87 THEN 'medium'
        ELSE 'high'
    END AS risk_level,
    TIMESTAMP '2022-01-01'
        + ((random() * 1180)::int) * INTERVAL '1 day'
        + ((random() * 86400)::int) * INTERVAL '1 second' AS onboarded_at
FROM (
    SELECT
        gs,
        random() AS r_cat,
        random() AS r_country,
        random() AS r_status,
        random() AS r_risk
    FROM generate_series(1, 400) AS gs
) t;


SELECT COUNT(*) AS merchant_count
FROM core.merchants;

SELECT merchant_category, COUNT(*) AS cnt
FROM core.merchants
GROUP BY merchant_category
ORDER BY cnt DESC;


SELECT country_code, COUNT(*) AS cnt
FROM core.merchants
GROUP BY country_code
ORDER BY cnt DESC;

SELECT merchant_status, COUNT(*) AS cnt
FROM core.merchants
GROUP BY merchant_status
ORDER BY cnt DESC;

SELECT risk_level, COUNT(*) AS cnt
FROM core.merchants
GROUP BY risk_level
ORDER BY cnt DESC;