SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'core'
  AND table_name = 'customers';

CREATE TABLE core.accounts (
    account_id           BIGSERIAL PRIMARY KEY,
    account_ref          VARCHAR(30) UNIQUE NOT NULL,
    customer_id          BIGINT NOT NULL REFERENCES core.customers(customer_id),
    account_type         VARCHAR(20) NOT NULL,
    currency_code        CHAR(3) NOT NULL,
    account_status       VARCHAR(20) NOT NULL,
    opened_at            TIMESTAMP NOT NULL,
    closed_at            TIMESTAMP,
    is_primary           BOOLEAN DEFAULT FALSE,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_accounts_type
        CHECK (account_type IN ('wallet', 'debit_card', 'credit_card', 'bank_account')),

    CONSTRAINT chk_accounts_status
        CHECK (account_status IN ('active', 'blocked', 'closed')),

    CONSTRAINT chk_accounts_currency_code
        CHECK (char_length(currency_code) = 3),

    CONSTRAINT chk_accounts_closed_at
        CHECK (closed_at IS NULL OR closed_at >= opened_at)
);

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'core'
  AND table_name = 'accounts';