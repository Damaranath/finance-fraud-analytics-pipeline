-- =========================================
-- STEP 1: one primary device link per customer
-- =========================================

SELECT COUNT(*) AS customer_device_links
FROM core.customer_devices;

-- =========================================
-- STEP 2: second device for some customers
-- =========================================
INSERT INTO core.customer_devices (
    customer_id,
    device_id,
    linked_at,
    last_used_at,
    is_trusted
)
SELECT
    x.customer_id,
    x.device_id,
    x.linked_at,
    x.linked_at
        + ((1 + random() * 650)::int) * INTERVAL '1 day'
        + ((random() * 86400)::int) * INTERVAL '1 second' AS last_used_at,
    CASE
        WHEN random() < 0.68 THEN TRUE
        ELSE FALSE
    END AS is_trusted
FROM (
    SELECT
        c.customer_id,
        (((c.customer_id + 1700) - 1) % 6500) + 1 AS device_id,
        c.signup_date + ((20 + random() * 60)::int) * INTERVAL '1 day' AS linked_at
    FROM core.customers c
    WHERE random() < 0.28
      AND (((c.customer_id + 1700) - 1) % 6500) + 1 <> ((c.customer_id - 1) % 6500) + 1
) x;

-- =========================================
-- STEP 3: third device for a smaller group
-- =========================================

INSERT INTO core.customer_devices (
    customer_id,
    device_id,
    linked_at,
    last_used_at,
    is_trusted
)
SELECT
    x.customer_id,
    x.device_id,
    x.linked_at,
    x.linked_at
        + ((1 + random() * 550)::int) * INTERVAL '1 day'
        + ((random() * 86400)::int) * INTERVAL '1 second' AS last_used_at,
    CASE
        WHEN random() < 0.52 THEN TRUE
        ELSE FALSE
    END AS is_trusted
FROM (
    SELECT
        c.customer_id,
        (((c.customer_id + 3300) - 1) % 6500) + 1 AS device_id,
        c.signup_date + ((45 + random() * 120)::int) * INTERVAL '1 day' AS linked_at
    FROM core.customers c
    WHERE random() < 0.10
      AND (((c.customer_id + 3300) - 1) % 6500) + 1 <> ((c.customer_id - 1) % 6500) + 1
      AND (((c.customer_id + 3300) - 1) % 6500) + 1 <> (((c.customer_id + 1700) - 1) % 6500) + 1
) x;


SELECT COUNT(*) AS customer_device_links
FROM core.customer_devices;

SELECT is_trusted, COUNT(*) AS cnt
FROM core.customer_devices
GROUP BY is_trusted
ORDER BY is_trusted;

SELECT device_count, COUNT(*) AS customer_cnt
FROM (
    SELECT customer_id, COUNT(*) AS device_count
    FROM core.customer_devices
    GROUP BY customer_id
) t
GROUP BY device_count
ORDER BY device_count;

SELECT COUNT(*) AS devices_used
FROM (
    SELECT DISTINCT device_id
    FROM core.customer_devices
) d;