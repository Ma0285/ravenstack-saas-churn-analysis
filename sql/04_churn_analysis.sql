/*
Use the analytical views to answer the churn analysis questions.
The original source tables are kept unchanged.
*/

PRAGMA foreign_keys = ON;


-- 1. CHURN DEFINITION VALIDATION

-- Source account churn flag distribution.
SELECT
    source_churn_flag,
    COUNT(*) AS account_count
FROM vw_account_churn_status
GROUP BY source_churn_flag
ORDER BY source_churn_flag;

-- Distinct accounts with one or more detailed churn events.
SELECT
    COUNT(DISTINCT account_id) AS accounts_with_churn_event
FROM vw_churn_events_normalized;

-- Reconcile the source churn flag with the event-based analytical definition.
SELECT
    source_churn_flag,
    analysis_churn_flag,
    COUNT(*) AS account_count
FROM vw_account_churn_status
GROUP BY source_churn_flag, analysis_churn_flag
ORDER BY source_churn_flag, analysis_churn_flag;

-- Total churn events versus distinct affected accounts.
SELECT
    COUNT(*) AS total_churn_events,
    COUNT(DISTINCT account_id) AS distinct_churned_accounts
FROM vw_churn_events_normalized;

-- Accounts with repeat churn-event records.
SELECT
    account_id,
    COUNT(*) AS churn_event_count
FROM vw_churn_events_normalized
GROUP BY account_id
HAVING COUNT(*) > 1
ORDER BY churn_event_count DESC, account_id;

-- Number of accounts with more than one churn event.
SELECT
    COUNT(*) AS accounts_with_multiple_churn_events
FROM (
    SELECT account_id
    FROM vw_churn_events_normalized
    GROUP BY account_id
    HAVING COUNT(*) > 1
);


-- 2. OVERALL CUSTOMER & CHURN OVERVIEW

-- Business Question: What is RavenStack's analytical account-level churn rate?
SELECT
    COUNT(*) AS total_accounts,
    SUM(analysis_churn_flag) AS churned_accounts,
    COUNT(*) - SUM(analysis_churn_flag) AS retained_accounts,
    ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS churn_rate_pct
FROM vw_account_churn_status;

-- Customer population context.
SELECT plan_tier, COUNT(*) AS account_count
FROM vw_account_churn_status
GROUP BY plan_tier
ORDER BY account_count DESC;

SELECT industry, COUNT(*) AS account_count
FROM vw_account_churn_status
GROUP BY industry
ORDER BY account_count DESC;

SELECT referral_source, COUNT(*) AS account_count
FROM vw_account_churn_status
GROUP BY referral_source
ORDER BY account_count DESC;

SELECT is_trial, COUNT(*) AS account_count
FROM vw_account_churn_status
GROUP BY is_trial
ORDER BY is_trial;

SELECT country, COUNT(*) AS account_count
FROM vw_account_churn_status
GROUP BY country
ORDER BY account_count DESC;


-- 3. CHURN BY CUSTOMER SEGMENT

-- Business Question: Which plan tiers show the highest observed churn rate?
SELECT
    plan_tier,
    COUNT(*) AS total_accounts,
    SUM(analysis_churn_flag) AS churned_accounts,
    ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS churn_rate_pct
FROM vw_account_churn_status
GROUP BY plan_tier
ORDER BY churn_rate_pct DESC;

-- Churn by industry.
SELECT
    industry,
    COUNT(*) AS total_accounts,
    SUM(analysis_churn_flag) AS churned_accounts,
    ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS churn_rate_pct
FROM vw_account_churn_status
GROUP BY industry
ORDER BY churn_rate_pct DESC;

-- Churn by referral source.
SELECT
    referral_source,
    COUNT(*) AS total_accounts,
    SUM(analysis_churn_flag) AS churned_accounts,
    ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS churn_rate_pct
FROM vw_account_churn_status
GROUP BY referral_source
ORDER BY churn_rate_pct DESC;

-- Churn by trial status.
SELECT
    is_trial,
    COUNT(*) AS total_accounts,
    SUM(analysis_churn_flag) AS churned_accounts,
    ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS churn_rate_pct
FROM vw_account_churn_status
GROUP BY is_trial
ORDER BY churn_rate_pct DESC;

-- Churn by customer-size band.
WITH account_size AS (
    SELECT
        *,
        CASE
            WHEN seats <= 10 THEN 'Small (1-10)'
            WHEN seats <= 50 THEN 'Medium (11-50)'
            ELSE 'Large (51+)'
        END AS customer_size
    FROM vw_account_churn_status
)
SELECT
    customer_size,
    COUNT(*) AS total_accounts,
    SUM(analysis_churn_flag) AS churned_accounts,
    ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS churn_rate_pct
FROM account_size
GROUP BY customer_size
ORDER BY churn_rate_pct DESC;

-- Churn by country. Interpret smaller groups cautiously.
SELECT
    country,
    COUNT(*) AS total_accounts,
    SUM(analysis_churn_flag) AS churned_accounts,
    ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS churn_rate_pct
FROM vw_account_churn_status
GROUP BY country
ORDER BY churn_rate_pct DESC;


-- 4. SUPPORT EXPERIENCE & CHURN

-- Business Question: How does valid support experience differ between churned and retained accounts?
WITH support_summary AS (
    SELECT
        account_id,
        COUNT(*) AS ticket_count,
        AVG(resolution_time_hours) AS avg_resolution_hours,
        AVG(first_response_time_minutes) AS avg_first_response_minutes,
        AVG(satisfaction_score) AS avg_satisfaction_score,
        SUM(escalation_flag) AS escalation_count
    FROM vw_valid_support_tickets
    GROUP BY account_id
)
SELECT
    acs.analysis_churn_flag,
    COUNT(*) AS account_count,
    ROUND(AVG(COALESCE(ss.ticket_count, 0)), 2) AS avg_ticket_count,
    ROUND(AVG(ss.avg_resolution_hours), 2) AS avg_resolution_hours,
    ROUND(AVG(ss.avg_first_response_minutes), 2) AS avg_first_response_minutes,
    ROUND(AVG(ss.avg_satisfaction_score), 2) AS avg_satisfaction_score,
    ROUND(AVG(COALESCE(ss.escalation_count, 0)), 2) AS avg_escalations
FROM vw_account_churn_status AS acs
LEFT JOIN support_summary AS ss
    ON acs.account_id = ss.account_id
GROUP BY acs.analysis_churn_flag
ORDER BY acs.analysis_churn_flag;


-- 5. FEATURE ENGAGEMENT & CHURN

-- Business Question: Is lower valid feature engagement associated with churn?
WITH usage_summary AS (
    SELECT
        s.account_id,
        COUNT(*) AS usage_event_rows,
        SUM(fu.usage_count) AS total_usage_count,
        SUM(fu.usage_duration_secs) AS total_usage_duration_secs,
        SUM(fu.error_count) AS total_error_count,
        SUM(fu.is_beta_feature) AS beta_usage_events,
        COUNT(DISTINCT fu.feature_name) AS distinct_features_used
    FROM vw_valid_feature_usage AS fu
    JOIN vw_subscriptions_normalized AS s
        ON fu.subscription_id = s.subscription_id
    GROUP BY s.account_id
)
SELECT
    acs.analysis_churn_flag,
    COUNT(*) AS account_count,
    ROUND(AVG(COALESCE(us.usage_event_rows, 0)), 2) AS avg_usage_event_rows,
    ROUND(AVG(COALESCE(us.total_usage_count, 0)), 2) AS avg_total_usage_count,
    ROUND(AVG(COALESCE(us.total_usage_duration_secs, 0)), 2) AS avg_total_usage_duration_secs,
    ROUND(AVG(COALESCE(us.total_error_count, 0)), 2) AS avg_total_error_count,
    ROUND(AVG(COALESCE(us.beta_usage_events, 0)), 2) AS avg_beta_usage_events,
    ROUND(AVG(COALESCE(us.distinct_features_used, 0)), 2) AS avg_distinct_features_used
FROM vw_account_churn_status AS acs
LEFT JOIN usage_summary AS us
    ON acs.account_id = us.account_id
GROUP BY acs.analysis_churn_flag
ORDER BY acs.analysis_churn_flag;


-- 6. SUBSCRIPTION & RECURRING-REVENUE EXPOSURE

-- Business Question: What subscription behavior and recurring-revenue exposure are associated with churned accounts?
WITH subscription_summary AS (
    SELECT
        account_id,
        COUNT(*) AS subscription_count,
        SUM(mrr_amount) AS total_subscription_mrr,
        SUM(arr_amount) AS total_subscription_arr,
        SUM(upgrade_flag) AS upgrade_count,
        SUM(downgrade_flag) AS downgrade_count,
        SUM(is_trial) AS trial_subscription_count,
        SUM(auto_renew_flag) AS auto_renew_count,
        SUM(CASE WHEN end_date IS NULL THEN 1 ELSE 0 END) AS active_subscription_count,
        SUM(CASE WHEN end_date IS NULL THEN mrr_amount ELSE 0 END) AS active_mrr_amount,
        SUM(CASE WHEN end_date IS NULL THEN arr_amount ELSE 0 END) AS active_arr_amount
    FROM vw_subscriptions_normalized
    GROUP BY account_id
)
SELECT
    acs.analysis_churn_flag,
    COUNT(*) AS account_count,
    ROUND(AVG(ss.subscription_count), 2) AS avg_subscription_count,
    ROUND(SUM(ss.total_subscription_mrr), 2) AS total_subscription_mrr,
    ROUND(SUM(ss.total_subscription_arr), 2) AS total_subscription_arr,
    SUM(ss.active_subscription_count) AS active_subscription_count,
    ROUND(SUM(ss.active_mrr_amount), 2) AS active_mrr_amount,
    ROUND(SUM(ss.active_arr_amount), 2) AS active_arr_amount,
    ROUND(AVG(ss.upgrade_count), 2) AS avg_upgrade_count,
    ROUND(AVG(ss.downgrade_count), 2) AS avg_downgrade_count,
    ROUND(AVG(ss.trial_subscription_count), 2) AS avg_trial_subscription_count,
    ROUND(100.0 * SUM(ss.auto_renew_count) / SUM(ss.subscription_count), 2) AS auto_renew_subscription_pct
FROM vw_account_churn_status AS acs
LEFT JOIN subscription_summary AS ss
    ON acs.account_id = ss.account_id
GROUP BY acs.analysis_churn_flag
ORDER BY acs.analysis_churn_flag;

-- Active MRR exposure by subscription plan and analytical churn status.
SELECT
    s.plan_tier,
    acs.analysis_churn_flag,
    COUNT(*) AS active_subscription_count,
    ROUND(SUM(s.mrr_amount), 2) AS active_mrr_amount,
    ROUND(SUM(s.arr_amount), 2) AS active_arr_amount
FROM vw_subscriptions_normalized AS s
JOIN vw_account_churn_status AS acs
    ON s.account_id = acs.account_id
WHERE s.end_date IS NULL
GROUP BY s.plan_tier, acs.analysis_churn_flag
ORDER BY s.plan_tier, acs.analysis_churn_flag;


-- 7. CHURN REASONS & REACTIVATION

-- Business Question: What reasons and event patterns are most common in recorded churn activity?
SELECT
    reason_code,
    COUNT(*) AS churn_events,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM vw_churn_events_normalized), 2) AS pct_of_events,
    ROUND(SUM(refund_amount_usd), 2) AS total_refund_amount,
    ROUND(AVG(refund_amount_usd), 2) AS avg_refund_amount
FROM vw_churn_events_normalized
GROUP BY reason_code
ORDER BY churn_events DESC;

-- Reactivation, preceding plan changes, and refund summary.
SELECT
    COUNT(*) AS total_churn_events,
    SUM(is_reactivation) AS reactivation_events,
    ROUND(100.0 * SUM(is_reactivation) / COUNT(*), 2) AS reactivation_rate_pct,
    SUM(preceding_upgrade_flag) AS preceding_upgrade_events,
    ROUND(100.0 * SUM(preceding_upgrade_flag) / COUNT(*), 2) AS preceding_upgrade_pct,
    SUM(preceding_downgrade_flag) AS preceding_downgrade_events,
    ROUND(100.0 * SUM(preceding_downgrade_flag) / COUNT(*), 2) AS preceding_downgrade_pct,
    ROUND(SUM(refund_amount_usd), 2) AS total_refund_amount
FROM vw_churn_events_normalized;

-- Distribution of churn-event counts per affected account.
SELECT
    churn_event_count,
    COUNT(*) AS account_count
FROM (
    SELECT account_id, COUNT(*) AS churn_event_count
    FROM vw_churn_events_normalized
    GROUP BY account_id
)
GROUP BY churn_event_count
ORDER BY churn_event_count;


-- 8. KEY PORTFOLIO METRICS

WITH
plan_rates AS (
    SELECT plan_tier,
           ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS churn_rate_pct
    FROM vw_account_churn_status
    GROUP BY plan_tier
),
industry_rates AS (
    SELECT industry,
           ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS churn_rate_pct
    FROM vw_account_churn_status
    GROUP BY industry
),
referral_rates AS (
    SELECT referral_source,
           ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS churn_rate_pct
    FROM vw_account_churn_status
    GROUP BY referral_source
),
reason_counts AS (
    SELECT reason_code, COUNT(*) AS churn_events
    FROM vw_churn_events_normalized
    GROUP BY reason_code
),
support_account AS (
    SELECT account_id, AVG(satisfaction_score) AS avg_satisfaction_score
    FROM vw_valid_support_tickets
    GROUP BY account_id
),
support_group AS (
    SELECT a.analysis_churn_flag, AVG(s.avg_satisfaction_score) AS avg_satisfaction_score
    FROM vw_account_churn_status a
    LEFT JOIN support_account s ON a.account_id = s.account_id
    GROUP BY a.analysis_churn_flag
),
usage_account AS (
    SELECT s.account_id, COUNT(DISTINCT fu.feature_name) AS distinct_features_used
    FROM vw_valid_feature_usage fu
    JOIN vw_subscriptions_normalized s ON fu.subscription_id = s.subscription_id
    GROUP BY s.account_id
),
usage_group AS (
    SELECT a.analysis_churn_flag, AVG(COALESCE(u.distinct_features_used, 0)) AS avg_distinct_features_used
    FROM vw_account_churn_status a
    LEFT JOIN usage_account u ON a.account_id = u.account_id
    GROUP BY a.analysis_churn_flag
),
active_revenue AS (
    SELECT a.analysis_churn_flag, SUM(s.mrr_amount) AS active_mrr_amount
    FROM vw_account_churn_status a
    JOIN vw_subscriptions_normalized s ON a.account_id = s.account_id
    WHERE s.end_date IS NULL
    GROUP BY a.analysis_churn_flag
)
SELECT
    ROUND(100.0 * SUM(analysis_churn_flag) / COUNT(*), 2) AS overall_churn_rate_pct,
    (SELECT plan_tier FROM plan_rates ORDER BY churn_rate_pct DESC LIMIT 1) AS highest_churn_plan,
    (SELECT churn_rate_pct FROM plan_rates ORDER BY churn_rate_pct DESC LIMIT 1) AS highest_churn_plan_rate_pct,
    (SELECT industry FROM industry_rates ORDER BY churn_rate_pct DESC LIMIT 1) AS highest_churn_industry,
    (SELECT churn_rate_pct FROM industry_rates ORDER BY churn_rate_pct DESC LIMIT 1) AS highest_churn_industry_rate_pct,
    (SELECT referral_source FROM referral_rates ORDER BY churn_rate_pct DESC LIMIT 1) AS highest_churn_referral_source,
    (SELECT churn_rate_pct FROM referral_rates ORDER BY churn_rate_pct DESC LIMIT 1) AS highest_churn_referral_rate_pct,
    (SELECT reason_code FROM reason_counts ORDER BY churn_events DESC LIMIT 1) AS top_churn_reason,
    (SELECT churn_events FROM reason_counts ORDER BY churn_events DESC LIMIT 1) AS top_churn_reason_events,
    ROUND((SELECT avg_satisfaction_score FROM support_group WHERE analysis_churn_flag = 0), 2) AS retained_avg_satisfaction,
    ROUND((SELECT avg_satisfaction_score FROM support_group WHERE analysis_churn_flag = 1), 2) AS churned_avg_satisfaction,
    ROUND((SELECT avg_distinct_features_used FROM usage_group WHERE analysis_churn_flag = 0), 2) AS retained_avg_distinct_features,
    ROUND((SELECT avg_distinct_features_used FROM usage_group WHERE analysis_churn_flag = 1), 2) AS churned_avg_distinct_features,
    ROUND((SELECT active_mrr_amount FROM active_revenue WHERE analysis_churn_flag = 1), 2) AS churned_active_mrr_exposure,
    ROUND(100.0 * (SELECT SUM(is_reactivation) FROM vw_churn_events_normalized) /
          (SELECT COUNT(*) FROM vw_churn_events_normalized), 2) AS reactivation_rate_pct
FROM vw_account_churn_status;
