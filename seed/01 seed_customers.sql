INSERT INTO core.customers (
    customer_ref,
    full_name,
    email,
    phone,
    date_of_birth,
    country_code,
    city,
    signup_date,
    kyc_status,
    customer_status,
    risk_segment
)
SELECT
    'CUST' || LPAD(gs::text, 6, '0') AS customer_ref,
    'Customer ' || gs AS full_name,
    'customer' || gs || '@example.com' AS email,
    '+61-4' || LPAD((10000000 + gs)::text, 8, '0') AS phone,
    DATE '1970-01-01' + ((random() * 12000)::int) AS date_of_birth,
    CASE
        WHEN r_country < 0.55 THEN 'AU'
        WHEN r_country < 0.75 THEN 'US'
        WHEN r_country < 0.88 THEN 'GB'
        WHEN r_country < 0.95 THEN 'SG'
        ELSE 'IN'
    END AS country_code,
    CASE
        WHEN r_country < 0.55 THEN
            CASE
                WHEN r_city < 0.35 THEN 'Sydney'
                WHEN r_city < 0.60 THEN 'Melbourne'
                WHEN r_city < 0.80 THEN 'Brisbane'
                ELSE 'Perth'
            END
        WHEN r_country < 0.75 THEN
            CASE
                WHEN r_city < 0.50 THEN 'New York'
                ELSE 'San Francisco'
            END
        WHEN r_country < 0.88 THEN
            CASE
                WHEN r_city < 0.60 THEN 'London'
                ELSE 'Manchester'
            END
        WHEN r_country < 0.95 THEN 'Singapore'
        ELSE
            CASE
                WHEN r_city < 0.50 THEN 'Hyderabad'
                ELSE 'Mumbai'
            END
    END AS city,
    TIMESTAMP '2023-01-01'
        + ((random() * 820)::int) * INTERVAL '1 day'
        + ((random() * 86400)::int) * INTERVAL '1 second' AS signup_date,
    CASE
        WHEN r_kyc < 0.86 THEN 'verified'
        WHEN r_kyc < 0.96 THEN 'pending'
        ELSE 'rejected'
    END AS kyc_status,
    CASE
        WHEN r_status < 0.92 THEN 'active'
        WHEN r_status < 0.97 THEN 'suspended'
        ELSE 'closed'
    END AS customer_status,
    CASE
        WHEN r_risk < 0.70 THEN 'low'
        WHEN r_risk < 0.92 THEN 'medium'
        ELSE 'high'
    END AS risk_segment
FROM (
    SELECT
        gs,
        random() AS r_country,
        random() AS r_city,
        random() AS r_kyc,
        random() AS r_status,
        random() AS r_risk
    FROM generate_series(1, 5000) AS gs
) t;