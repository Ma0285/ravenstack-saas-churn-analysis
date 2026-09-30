
-- RavenStack SaaS Database
-- Database Schema Design
-- Source: River @ Rivalytics

PRAGMA foreign_keys = ON;


-- 1. accounts

CREATE TABLE accounts (
    account_id VARCHAR(20) PRIMARY KEY,
    account_name VARCHAR(100) NOT NULL,
    industry VARCHAR(100) NOT NULL,
    country CHAR(2) NOT NULL,
    signup_date DATE NOT NULL,
    referral_source VARCHAR(100) NOT NULL,
    plan_tier VARCHAR(100) NOT NULL,
    seats INTEGER NOT NULL,
    is_trial BOOLEAN NOT NULL,
    churn_flag BOOLEAN NOT NULL
);


-- 2. subscriptions

CREATE TABLE subscriptions (
    subscription_id VARCHAR(20) PRIMARY KEY,
    account_id VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    plan_tier VARCHAR(100) NOT NULL,
    seats INTEGER NOT NULL,
    mrr_amount DECIMAL(12,2) NOT NULL,
    arr_amount DECIMAL(12,2) NOT NULL,
    is_trial BOOLEAN NOT NULL,
    upgrade_flag BOOLEAN NOT NULL,
    downgrade_flag BOOLEAN NOT NULL,
    churn_flag BOOLEAN NOT NULL,
    billing_frequency VARCHAR(10) NOT NULL,
    auto_renew_flag BOOLEAN NOT NULL,
    
    FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);


-- 3. feature usage
-- Data quality note:
-- Python QA identified 21 duplicated usage_id values affecting 42 rows.
-- usage_id is retained as the source identifier.
-- usage_event_key is used as a surrogate primary key.
-- The raw source CSV remains unchanged.

CREATE TABLE feature_usage (
    usage_event_key INTEGER PRIMARY KEY AUTOINCREMENT,
    usage_id VARCHAR(20) NOT NULL,
    subscription_id VARCHAR(20) NOT NULL,
    usage_date DATE NOT NULL,
    feature_name VARCHAR(20) NOT NULL,
    usage_count INTEGER NOT NULL,
    usage_duration_secs INTEGER NOT NULL,
    error_count INTEGER NOT NULL,
    is_beta_feature BOOLEAN NOT NULL,
    
    FOREIGN KEY (subscription_id)
    	REFERENCES subscriptions(subscription_id)
);


-- 4. support tickets

CREATE TABLE support_tickets (
    ticket_id VARCHAR(20) PRIMARY KEY,
    account_id VARCHAR(20) NOT NULL,
    submitted_at TIMESTAMP NOT NULL,
    closed_at TIMESTAMP NOT NULL,
    resolution_time_hours REAL NOT NULL,
    priority VARCHAR(10) NOT NULL,
    first_response_time_minutes INTEGER NOT NULL,
    satisfaction_score SMALLINT,
    escalation_flag BOOLEAN NOT NULL,
    
    FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);


-- 5. churn events

CREATE TABLE churn_events (
    churn_event_id VARCHAR(20) PRIMARY KEY,
    account_id VARCHAR(20) NOT NULL,
    churn_date DATE NOT NULL,
    reason_code VARCHAR(20) NOT NULL,
    refund_amount_usd DECIMAL(12,2) NOT NULL,
    preceding_upgrade_flag BOOLEAN NOT NULL,
    preceding_downgrade_flag BOOLEAN NOT NULL,
    is_reactivation BOOLEAN NOT NULL,
    feedback_text TEXT,
    
    FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);