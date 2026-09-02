CREATE TABLE core.chargebacks (
    chargeback_id        BIGSERIAL PRIMARY KEY,
    chargeback_ref       VARCHAR(30) UNIQUE NOT NULL,
    transaction_id       BIGINT NOT NULL REFERENCES core.transactions(transaction_id),
    customer_id          BIGINT NOT NULL REFERENCES core.customers(customer_id),
    merchant_id          BIGINT NOT NULL REFERENCES core.merchants(merchant_id),
    chargeback_ts        TIMESTAMP NOT NULL,
    chargeback_amount    NUMERIC(12,2) NOT NULL,
    reason_code          VARCHAR(50) NOT NULL,
    chargeback_status    VARCHAR(20) NOT NULL,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_chargebacks_amount
        CHECK (chargeback_amount > 0),

    CONSTRAINT chk_chargebacks_reason
        CHECK (
            reason_code IN (
                'fraud',
                'service_not_received',
                'duplicate_processing',
                'authorization_issue'
            )
        ),

    CONSTRAINT chk_chargebacks_status
        CHECK (
            chargeback_status IN (
                'open',
                'won',
                'lost',
                'reversed'
            )
        )
);

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'core'
  AND table_name = 'chargebacks';