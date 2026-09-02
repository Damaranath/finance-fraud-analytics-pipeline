CREATE TABLE core.customer_devices (
    customer_device_id   BIGSERIAL PRIMARY KEY,
    customer_id          BIGINT NOT NULL REFERENCES core.customers(customer_id),
    device_id            BIGINT NOT NULL REFERENCES core.devices(device_id),
    linked_at            TIMESTAMP NOT NULL,
    last_used_at         TIMESTAMP,
    is_trusted           BOOLEAN DEFAULT FALSE,

    CONSTRAINT uq_customer_devices
        UNIQUE (customer_id, device_id),

    CONSTRAINT chk_customer_devices_last_used
        CHECK (last_used_at IS NULL OR last_used_at >= linked_at)
);

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'core'
  AND table_name = 'customer_devices';