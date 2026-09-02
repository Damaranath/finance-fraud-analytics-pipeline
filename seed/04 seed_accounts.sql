 INSERT INTO core.accounts (
    account_ref,
    customer_id,
    account_type,
    currency_code,
    account_status,
    opened_at,
    closed_at,
    is_primary
)
SELECT
    'ACC' || LPAD(c.customer_id::text, 7, '0') AS account_ref,
    c.customer_id,
    CASE
        WHEN r_type < 0.40 THEN 'wallet'
        WHEN r_type < 0.68 THEN 'debit_card'
        WHEN r_type < 0.88 THEN 'credit_card'
        ELSE 'bank_account'
    END AS account_type,
    CASE c.country_code
        WHEN 'AU' THEN 'AUD'
        WHEN 'US' THEN 'USD'
        WHEN 'GB' THEN 'GBP'
        WHEN 'SG' THEN 'SGD'
        WHEN 'IN' THEN 'INR'
        ELSE 'USD'
    END AS currency_code,
    CASE
        WHEN c.customer_status = 'closed' THEN 'closed'
        WHEN c.customer_status = 'suspended' AND r_status < 0.55 THEN 'blocked'
        WHEN r_status < 0.94 THEN 'active'
        WHEN r_status < 0.98 THEN 'blocked'
        ELSE 'closed'
    END AS account_status,
    c.signup_date
        + ((random() * 30)::int) * INTERVAL '1 day' AS opened_at,
    CASE
        WHEN c.customer_status = 'closed' THEN
            c.signup_date
            + ((60 + random() * 500)::int) * INTERVAL '1 day'
        ELSE NULL
    END AS closed_at,
    TRUE AS is_primary
FROM (
    SELECT
        customer_id,
        country_code,
        signup_date,
        customer_status,
        random() AS r_type,
        random() AS r_status
    FROM core.customers
) c;

SELECT COUNT(*) AS account_count
FROM core.accounts;

SELECT account_type, COUNT(*) AS cnt
FROM core.accounts
GROUP BY account_type
ORDER BY cnt DESC;

SELECT currency_code, COUNT(*) AS cnt
FROM core.accounts
GROUP BY currency_code
ORDER BY cnt DESC;

SELECT account_status, COUNT(*) AS cnt
FROM core.accounts
GROUP BY account_status
ORDER BY cnt DESC;

SELECT is_primary, COUNT(*) AS cnt
FROM core.accounts
GROUP BY is_primary;