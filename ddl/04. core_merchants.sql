CREATE TABLE core.merchants (
    merchant_id          BIGSERIAL PRIMARY KEY,
    merchant_ref         VARCHAR(30) UNIQUE NOT NULL,
    merchant_name        VARCHAR(120) NOT NULL,
    merchant_category    VARCHAR(50) NOT NULL,
    country_code         CHAR(2) NOT NULL,
    merchant_status      VARCHAR(20) NOT NULL,
    risk_level           VARCHAR(20) NOT NULL,
    onboarded_at         TIMESTAMP NOT NULL,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_merchants_status
        CHECK (merchant_status IN ('active', 'suspended', 'closed')),

    CONSTRAINT chk_merchants_risk_level
        CHECK (risk_level IN ('low', 'medium', 'high')),

    CONSTRAINT chk_merchants_country_code
        CHECK (char_length(country_code) = 2)
);

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'core'
  AND table_name = 'merchants';