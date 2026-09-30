/*
Create analysis views for churn analysis.
This includes cleaning missing values and filtering invalid records.
The original source tables are not changed.
*/

PRAGMA foreign_keys = ON;


-- 1. ACCOUNT CHURN STATUS
-- Event-based churn is the primary analytical definition.

DROP VIEW IF EXISTS vw_account_churn_status;
CREATE VIEW vw_account_churn_status AS
SELECT
    a.account_id,
    a.account_name,
    a.industry,
    a.country,
    a.signup_date,
    a.referral_source,
    a.plan_tier,
    a.seats,
    CASE
        WHEN LOWER(TRIM(CAST(a.is_trial AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1
        ELSE 0
    END AS is_trial,
    CASE
        WHEN LOWER(TRIM(CAST(a.churn_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1
        ELSE 0
    END AS source_churn_flag,
    CASE
        WHEN ce.account_id IS NOT NULL THEN 1
        ELSE 0
    END AS analysis_churn_flag
FROM accounts AS a
LEFT JOIN (
    SELECT DISTINCT account_id
    FROM churn_events
) AS ce
    ON a.account_id = ce.account_id;


-- 2. NORMALIZED SUBSCRIPTIONS
-- Blank end dates are treated as analytical NULLs.
-- Boolean-like fields imported as text are normalized to 0/1.

DROP VIEW IF EXISTS vw_subscriptions_normalized;
CREATE VIEW vw_subscriptions_normalized AS
SELECT
    subscription_id,
    account_id,
    start_date,
    NULLIF(TRIM(end_date), '') AS end_date,
    plan_tier,
    seats,
    mrr_amount,
    arr_amount,
    CASE WHEN LOWER(TRIM(CAST(is_trial AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1 ELSE 0 END AS is_trial,
    CASE WHEN LOWER(TRIM(CAST(upgrade_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1 ELSE 0 END AS upgrade_flag,
    CASE WHEN LOWER(TRIM(CAST(downgrade_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1 ELSE 0 END AS downgrade_flag,
    CASE WHEN LOWER(TRIM(CAST(churn_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1 ELSE 0 END AS source_churn_flag,
    billing_frequency,
    CASE WHEN LOWER(TRIM(CAST(auto_renew_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1 ELSE 0 END AS auto_renew_flag
FROM subscriptions;


-- 3. VALID FEATURE USAGE
-- Keep usage only when it falls inside the associated subscription window.

DROP VIEW IF EXISTS vw_valid_feature_usage;
CREATE VIEW vw_valid_feature_usage AS
SELECT
    fu.usage_event_key,
    fu.usage_id,
    fu.subscription_id,
    fu.usage_date,
    fu.feature_name,
    fu.usage_count,
    fu.usage_duration_secs,
    fu.error_count,
    CASE WHEN LOWER(TRIM(CAST(fu.is_beta_feature AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1 ELSE 0 END AS is_beta_feature
FROM feature_usage AS fu
JOIN vw_subscriptions_normalized AS s
    ON fu.subscription_id = s.subscription_id
WHERE DATE(fu.usage_date) >= DATE(s.start_date)
  AND (
        s.end_date IS NULL
        OR DATE(fu.usage_date) <= DATE(s.end_date)
      );


-- 4. VALID SUPPORT TICKETS
-- Keep tickets submitted on/after account signup.
-- Blank satisfaction scores are normalized to SQL NULL.

DROP VIEW IF EXISTS vw_valid_support_tickets;
CREATE VIEW vw_valid_support_tickets AS
SELECT
    st.ticket_id,
    st.account_id,
    st.submitted_at,
    st.closed_at,
    st.resolution_time_hours,
    st.priority,
    st.first_response_time_minutes,
    CAST(NULLIF(TRIM(CAST(st.satisfaction_score AS TEXT)), '') AS REAL) AS satisfaction_score,
    CASE WHEN LOWER(TRIM(CAST(st.escalation_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1 ELSE 0 END AS escalation_flag
FROM support_tickets AS st
JOIN accounts AS a
    ON st.account_id = a.account_id
WHERE DATE(st.submitted_at) >= DATE(a.signup_date);


-- 5. NORMALIZED CHURN EVENTS
-- Boolean-like event flags are normalized to 0/1.

DROP VIEW IF EXISTS vw_churn_events_normalized;
CREATE VIEW vw_churn_events_normalized AS
SELECT
    churn_event_id,
    account_id,
    churn_date,
    reason_code,
    refund_amount_usd,
    CASE WHEN LOWER(TRIM(CAST(preceding_upgrade_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1 ELSE 0 END AS preceding_upgrade_flag,
    CASE WHEN LOWER(TRIM(CAST(preceding_downgrade_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1 ELSE 0 END AS preceding_downgrade_flag,
    CASE WHEN LOWER(TRIM(CAST(is_reactivation AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1 ELSE 0 END AS is_reactivation,
    NULLIF(TRIM(feedback_text), '') AS feedback_text
FROM churn_events;


-- 6. ANALYSIS-LAYER VALIDATION

SELECT analysis_churn_flag, COUNT(*) AS account_count
FROM vw_account_churn_status
GROUP BY analysis_churn_flag
ORDER BY analysis_churn_flag;

SELECT
    (SELECT COUNT(*) FROM feature_usage) AS raw_feature_usage_rows,
    (SELECT COUNT(*) FROM vw_valid_feature_usage) AS valid_feature_usage_rows,
    (SELECT COUNT(*) FROM feature_usage) -
    (SELECT COUNT(*) FROM vw_valid_feature_usage) AS excluded_feature_usage_rows;

SELECT
    (SELECT COUNT(*) FROM support_tickets) AS raw_support_ticket_rows,
    (SELECT COUNT(*) FROM vw_valid_support_tickets) AS valid_support_ticket_rows,
    (SELECT COUNT(*) FROM support_tickets) -
    (SELECT COUNT(*) FROM vw_valid_support_tickets) AS excluded_support_ticket_rows;
