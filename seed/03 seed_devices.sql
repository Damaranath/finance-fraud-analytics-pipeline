INSERT INTO core.devices (
    device_fingerprint,
    device_type,
    os_name,
    app_version,
    first_seen_at,
    last_seen_at,
    is_emulator
)
SELECT
    'DEV-' || md5(gs::text || '-' || (gs * 17)::text) AS device_fingerprint,
    device_type,
    os_name,
    app_version,
    first_seen_at,
    first_seen_at
        + ((random() * 180)::int) * INTERVAL '1 day'
        + ((random() * 86400)::int) * INTERVAL '1 second' AS last_seen_at,
    is_emulator
FROM (
    SELECT
        gs,
        CASE
            WHEN r_type < 0.72 THEN 'mobile'
            WHEN r_type < 0.92 THEN 'desktop'
            ELSE 'tablet'
        END AS device_type,
        CASE
            WHEN r_type < 0.40 THEN 'iOS'
            WHEN r_type < 0.72 THEN 'Android'
            WHEN r_type < 0.86 THEN 'Windows'
            WHEN r_type < 0.96 THEN 'macOS'
            ELSE 'iPadOS'
        END AS os_name,
        CASE
            WHEN r_app < 0.20 THEN '1.0.0'
            WHEN r_app < 0.38 THEN '1.1.0'
            WHEN r_app < 0.56 THEN '1.2.0'
            WHEN r_app < 0.74 THEN '1.3.0'
            WHEN r_app < 0.88 THEN '2.0.0'
            ELSE '2.1.0'
        END AS app_version,
        TIMESTAMP '2023-01-01'
            + ((random() * 820)::int) * INTERVAL '1 day'
            + ((random() * 86400)::int) * INTERVAL '1 second' AS first_seen_at,
        CASE
            WHEN r_emulator < 0.035 THEN TRUE
            ELSE FALSE
        END AS is_emulator
    FROM (
        SELECT
            gs,
            random() AS r_type,
            random() AS r_app,
            random() AS r_emulator
        FROM generate_series(1, 6500) AS gs
    ) s
) d;

SELECT COUNT(*) AS device_count
FROM core.devices;

SELECT device_type, COUNT(*) AS cnt
FROM core.devices
GROUP BY device_type
ORDER BY cnt DESC;

SELECT os_name, COUNT(*) AS cnt
FROM core.devices
GROUP BY os_name
ORDER BY cnt DESC;

SELECT is_emulator, COUNT(*) AS cnt
FROM core.devices
GROUP BY is_emulator
ORDER BY is_emulator;

