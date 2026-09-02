-- =========================================================
-- RULE 1: Repeated failed transactions in 30 minutes
-- customer has 3+ failed transactions in a rolling 30-min window
-- =========================================================
INSERT INTO risk.alerts (
    alert_ref,
    alert_ts,
    entity_type,
    entity_id,
    transaction_id,
    rule_name,
    alert_type,
    severity,
    alert_status,
    risk_score,
    alert_reason
)
WITH failed_tx AS (
    SELECT
        t.transaction_id,
        t.customer_id,
        t.transaction_ts,
        COUNT(*) OVER (
            PARTITION BY t.customer_id
            ORDER BY t.transaction_ts
            RANGE BETWEEN INTERVAL '30 minutes' PRECEDING AND CURRENT ROW
        ) AS fail_count_30m
    FROM core.transactions t
    WHERE t.status = 'failed'
),
rule_hits AS (
    SELECT *
    FROM failed_tx
    WHERE fail_count_30m >= 3
)
SELECT
    'ALT-R1-' || LPAD(ROW_NUMBER() OVER (ORDER BY transaction_id)::text, 8, '0') AS alert_ref,
    transaction_ts AS alert_ts,
    'customer' AS entity_type,
    customer_id AS entity_id,
    transaction_id,
    'repeated_failed_transactions_30m' AS rule_name,
    'velocity_risk' AS alert_type,
    CASE
        WHEN fail_count_30m >= 5 THEN 'high'
        ELSE 'medium'
    END AS severity,
    'open' AS alert_status,
    CASE
        WHEN fail_count_30m >= 5 THEN 82.0
        ELSE 64.0
    END AS risk_score,
    'Customer had ' || fail_count_30m || ' failed transactions within 30 minutes.' AS alert_reason
FROM rule_hits;

-- =========================================================
-- RULE 2: High-value transaction
-- =========================================================
INSERT INTO risk.alerts (
    alert_ref,
    alert_ts,
    entity_type,
    entity_id,
    transaction_id,
    rule_name,
    alert_type,
    severity,
    alert_status,
    risk_score,
    alert_reason
)
SELECT
    'ALT-R2-' || LPAD(ROW_NUMBER() OVER (ORDER BY t.transaction_id)::text, 8, '0') AS alert_ref,
    t.transaction_ts AS alert_ts,
    'transaction' AS entity_type,
    t.transaction_id AS entity_id,
    t.transaction_id,
    'high_value_transaction' AS rule_name,
    'amount_risk' AS alert_type,
    CASE
        WHEN t.amount >= 2200 THEN 'high'
        ELSE 'medium'
    END AS severity,
    'open' AS alert_status,
    CASE
        WHEN t.amount >= 2200 THEN 88.0
        ELSE 67.0
    END AS risk_score,
    'Transaction amount ' || t.amount || ' exceeded high-value threshold.' AS alert_reason
FROM core.transactions t
WHERE t.amount >= 1500;

-- =========================================================
-- RULE 3: Cross-border transaction on high-risk merchant
-- =========================================================
INSERT INTO risk.alerts (
    alert_ref,
    alert_ts,
    entity_type,
    entity_id,
    transaction_id,
    rule_name,
    alert_type,
    severity,
    alert_status,
    risk_score,
    alert_reason
)
SELECT
    'ALT-R3-' || LPAD(ROW_NUMBER() OVER (ORDER BY t.transaction_id)::text, 8, '0') AS alert_ref,
    t.transaction_ts AS alert_ts,
    'transaction' AS entity_type,
    t.transaction_id AS entity_id,
    t.transaction_id,
    'cross_border_high_risk_merchant' AS rule_name,
    'cross_border_risk' AS alert_type,
    'high' AS severity,
    'open' AS alert_status,
    86.0 AS risk_score,
    'Cross-border transaction detected on high-risk merchant ' || m.merchant_ref || '.' AS alert_reason
FROM core.transactions t
JOIN core.merchants m
  ON t.merchant_id = m.merchant_id
WHERE t.is_cross_border = TRUE
  AND m.risk_level = 'high';

-- =========================================================
-- RULE 4: Emulator device usage
-- =========================================================
INSERT INTO risk.alerts (
    alert_ref,
    alert_ts,
    entity_type,
    entity_id,
    transaction_id,
    rule_name,
    alert_type,
    severity,
    alert_status,
    risk_score,
    alert_reason
)
SELECT
    'ALT-R4-' || LPAD(ROW_NUMBER() OVER (ORDER BY t.transaction_id)::text, 8, '0') AS alert_ref,
    t.transaction_ts AS alert_ts,
    'device' AS entity_type,
    d.device_id AS entity_id,
    t.transaction_id,
    'emulator_device_usage' AS rule_name,
    'device_risk' AS alert_type,
    'high' AS severity,
    'open' AS alert_status,
    91.0 AS risk_score,
    'Transaction originated from emulator-flagged device.' AS alert_reason
FROM core.transactions t
JOIN core.devices d
  ON t.device_id = d.device_id
WHERE d.is_emulator = TRUE;

-- =========================================================
-- RULE 5: Customer with multiple chargebacks
-- alert on each chargeback row for customers with 2+ chargebacks
-- =========================================================
INSERT INTO risk.alerts (
    alert_ref,
    alert_ts,
    entity_type,
    entity_id,
    transaction_id,
    rule_name,
    alert_type,
    severity,
    alert_status,
    risk_score,
    alert_reason
)
WITH cb_counts AS (
    SELECT
        customer_id,
        COUNT(*) AS chargeback_count
    FROM core.chargebacks
    GROUP BY customer_id
    HAVING COUNT(*) >= 2
)
SELECT
    'ALT-R5-' || LPAD(ROW_NUMBER() OVER (ORDER BY c.chargeback_id)::text, 8, '0') AS alert_ref,
    c.chargeback_ts AS alert_ts,
    'customer' AS entity_type,
    c.customer_id AS entity_id,
    c.transaction_id,
    'multiple_chargebacks_customer' AS rule_name,
    'chargeback_risk' AS alert_type,
    CASE
        WHEN cc.chargeback_count >= 4 THEN 'high'
        ELSE 'medium'
    END AS severity,
    'open' AS alert_status,
    CASE
        WHEN cc.chargeback_count >= 4 THEN 89.0
        ELSE 71.0
    END AS risk_score,
    'Customer has ' || cc.chargeback_count || ' chargebacks on record.' AS alert_reason
FROM core.chargebacks c
JOIN cb_counts cc
  ON c.customer_id = cc.customer_id;

  SELECT COUNT(*) AS alert_count
FROM risk.alerts;


SELECT rule_name, COUNT(*) AS cnt
FROM risk.alerts
GROUP BY rule_name
ORDER BY cnt DESC;


SELECT severity, COUNT(*) AS cnt
FROM risk.alerts
GROUP BY severity
ORDER BY cnt DESC;


SELECT entity_type, COUNT(*) AS cnt
FROM risk.alerts
GROUP BY entity_type
ORDER BY cnt DESC;


SELECT alert_status, COUNT(*) AS cnt
FROM risk.alerts
GROUP BY alert_status
ORDER BY cnt DESC;

SELECT ROUND(AVG(risk_score), 2) AS avg_risk_score,
       MIN(risk_score) AS min_risk_score,
       MAX(risk_score) AS max_risk_score
FROM risk.alerts;



