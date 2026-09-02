CREATE TABLE core.devices (
    device_id            BIGSERIAL PRIMARY KEY,
    device_fingerprint   VARCHAR(100) UNIQUE NOT NULL,
    device_type          VARCHAR(30) NOT NULL,
    os_name              VARCHAR(30),
    app_version          VARCHAR(20),
    first_seen_at        TIMESTAMP NOT NULL,
    last_seen_at         TIMESTAMP,
    is_emulator          BOOLEAN DEFAULT FALSE,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_devices_type
        CHECK (device_type IN ('mobile', 'desktop', 'tablet')),

    CONSTRAINT chk_devices_last_seen
        CHECK (last_seen_at IS NULL OR last_seen_at >= first_seen_at)
);

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'core'
  AND table_name = 'devices';