CREATE TABLE risk.alerts (
    alert_id             BIGSERIAL PRIMARY KEY,
    alert_ref            VARCHAR(30) UNIQUE NOT NULL,
    alert_ts             TIMESTAMP NOT NULL,
    entity_type          VARCHAR(20) NOT NULL,
    entity_id            BIGINT NOT NULL,
    transaction_id       BIGINT REFERENCES core.transactions(transaction_id),
    rule_name            VARCHAR(100) NOT NULL,
    alert_type           VARCHAR(50) NOT NULL,
    severity             VARCHAR(20) NOT NULL,
    alert_status         VARCHAR(20) NOT NULL,
    risk_score           NUMERIC(5,2),
    alert_reason         TEXT,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_alerts_entity_type
        CHECK (entity_type IN ('customer', 'merchant', 'device', 'transaction')),

    CONSTRAINT chk_alerts_severity
        CHECK (severity IN ('low', 'medium', 'high', 'critical')),

    CONSTRAINT chk_alerts_status
        CHECK (alert_status IN ('open', 'under_review', 'closed', 'false_positive')),

    CONSTRAINT chk_alerts_risk_score
        CHECK (risk_score IS NULL OR (risk_score >= 0 AND risk_score <= 100))
);

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'risk'
  AND table_name = 'alerts';