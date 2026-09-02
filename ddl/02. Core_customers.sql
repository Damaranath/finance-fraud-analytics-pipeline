CREATE TABLE core.customers (
    customer_id         BIGSERIAL PRIMARY KEY,
    customer_ref        VARCHAR(30) UNIQUE NOT NULL,
    full_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(120) UNIQUE NOT NULL,
    phone               VARCHAR(30),
    date_of_birth       DATE,
    country_code        CHAR(2) NOT NULL,
    city                VARCHAR(80),
    signup_date         TIMESTAMP NOT NULL,
    kyc_status          VARCHAR(20) NOT NULL,
    customer_status     VARCHAR(20) NOT NULL,
    risk_segment        VARCHAR(20),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_customers_kyc_status
        CHECK (kyc_status IN ('verified', 'pending', 'rejected')),

    CONSTRAINT chk_customers_status
        CHECK (customer_status IN ('active', 'suspended', 'closed')),

    CONSTRAINT chk_customers_risk_segment
        CHECK (risk_segment IN ('low', 'medium', 'high') OR risk_segment IS NULL),

    CONSTRAINT chk_customers_country_code
        CHECK (char_length(country_code) = 2)
);

 SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'core'
  AND table_name = 'customers';

