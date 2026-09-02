CREATE TABLE core.transactions (
    transaction_id       BIGSERIAL PRIMARY KEY,
    transaction_ref      VARCHAR(40) UNIQUE NOT NULL,
    account_id           BIGINT NOT NULL REFERENCES core.accounts(account_id),
    customer_id          BIGINT NOT NULL REFERENCES core.customers(customer_id),
    merchant_id          BIGINT NOT NULL REFERENCES core.merchants(merchant_id),
    device_id            BIGINT REFERENCES core.devices(device_id),
    transaction_ts       TIMESTAMP NOT NULL,
    amount               NUMERIC(12,2) NOT NULL,
    currency_code        CHAR(3) NOT NULL,
    transaction_type     VARCHAR(20) NOT NULL,
    payment_channel      VARCHAR(20) NOT NULL,
    payment_method       VARCHAR(20) NOT NULL,
    country_code         CHAR(2) NOT NULL,
    status               VARCHAR(20) NOT NULL,
    failure_reason       VARCHAR(50),
    is_cross_border      BOOLEAN DEFAULT FALSE,
    ip_address           VARCHAR(45),
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_transactions_amount
        CHECK (amount > 0),

    CONSTRAINT chk_transactions_currency_code
        CHECK (char_length(currency_code) = 3),

    CONSTRAINT chk_transactions_country_code
        CHECK (char_length(country_code) = 2),

    CONSTRAINT chk_transactions_type
        CHECK (transaction_type IN ('purchase', 'refund', 'withdrawal', 'transfer')),

    CONSTRAINT chk_transactions_channel
        CHECK (payment_channel IN ('app', 'web', 'pos', 'api')),

    CONSTRAINT chk_transactions_method
        CHECK (payment_method IN ('card', 'bank_transfer', 'wallet', 'account_balance')),

    CONSTRAINT chk_transactions_status
        CHECK (status IN ('approved', 'failed', 'pending', 'reversed')),

    CONSTRAINT chk_transactions_failure_reason
        CHECK (
            failure_reason IS NULL OR
            failure_reason IN (
                'insufficient_funds',
                'issuer_declined',
                'suspected_fraud',
                'invalid_cvv',
                'technical_error',
                'velocity_limit'
            )
        ),

    CONSTRAINT chk_transactions_failure_logic
        CHECK (
            (status = 'failed' AND failure_reason IS NOT NULL)
            OR
            (status <> 'failed' AND failure_reason IS NULL)
        )
);

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'core'
  AND table_name = 'transactions';