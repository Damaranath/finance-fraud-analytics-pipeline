-- =========================
-- CORE TABLE INDEXES
-- =========================

CREATE INDEX idx_accounts_customer_id
    ON core.accounts(customer_id);

CREATE INDEX idx_customer_devices_customer_id
    ON core.customer_devices(customer_id);

CREATE INDEX idx_customer_devices_device_id
    ON core.customer_devices(device_id);

CREATE INDEX idx_transactions_account_id
    ON core.transactions(account_id);

CREATE INDEX idx_transactions_customer_id
    ON core.transactions(customer_id);

CREATE INDEX idx_transactions_merchant_id
    ON core.transactions(merchant_id);

CREATE INDEX idx_transactions_device_id
    ON core.transactions(device_id);

CREATE INDEX idx_transactions_transaction_ts
    ON core.transactions(transaction_ts);

CREATE INDEX idx_transactions_status
    ON core.transactions(status);

CREATE INDEX idx_transactions_country_code
    ON core.transactions(country_code);

CREATE INDEX idx_chargebacks_transaction_id
    ON core.chargebacks(transaction_id);

CREATE INDEX idx_chargebacks_customer_id
    ON core.chargebacks(customer_id);

CREATE INDEX idx_chargebacks_merchant_id
    ON core.chargebacks(merchant_id);

CREATE INDEX idx_chargebacks_chargeback_ts
    ON core.chargebacks(chargeback_ts);

-- =========================
-- RISK TABLE INDEXES
-- =========================

CREATE INDEX idx_alerts_entity_type_entity_id
    ON risk.alerts(entity_type, entity_id);

CREATE INDEX idx_alerts_transaction_id
    ON risk.alerts(transaction_id);

CREATE INDEX idx_alerts_alert_ts
    ON risk.alerts(alert_ts);

CREATE INDEX idx_alerts_alert_status
    ON risk.alerts(alert_status);

CREATE INDEX idx_alerts_severity
    ON risk.alerts(severity);

    