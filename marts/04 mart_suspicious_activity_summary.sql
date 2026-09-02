CREATE OR REPLACE VIEW mart.suspicious_activity_summary AS
SELECT
    DATE(a.alert_ts) AS alert_date,
    a.rule_name,

    COUNT(*) AS alert_count,
    COUNT(DISTINCT a.entity_id) AS distinct_entities,
    COUNT(DISTINCT a.transaction_id) AS distinct_transactions,

    SUM(CASE WHEN a.severity = 'medium' THEN 1 ELSE 0 END) AS medium_alerts,
    SUM(CASE WHEN a.severity = 'high' THEN 1 ELSE 0 END) AS high_alerts,
    SUM(CASE WHEN a.severity = 'critical' THEN 1 ELSE 0 END) AS critical_alerts,

    ROUND(AVG(a.risk_score), 2) AS avg_risk_score,
    MIN(a.risk_score) AS min_risk_score,
    MAX(a.risk_score) AS max_risk_score

FROM risk.alerts a
GROUP BY DATE(a.alert_ts), a.rule_name
ORDER BY alert_date, rule_name;

SELECT *
FROM mart.suspicious_activity_summary
ORDER BY alert_date, rule_name
LIMIT 10;

SELECT COUNT(*) AS row_count
FROM mart.suspicious_activity_summary;

SELECT rule_name, SUM(alert_count) AS total_alerts
FROM mart.suspicious_activity_summary
GROUP BY rule_name
ORDER BY total_alerts DESC;

SELECT
    SUM(alert_count) AS total_alerts,
    SUM(medium_alerts) AS total_medium_alerts,
    SUM(high_alerts) AS total_high_alerts,
    SUM(critical_alerts) AS total_critical_alerts
FROM mart.suspicious_activity_summary;

SELECT
    ROUND(AVG(avg_risk_score), 2) AS avg_alert_risk_score
FROM mart.suspicious_activity_summary;

