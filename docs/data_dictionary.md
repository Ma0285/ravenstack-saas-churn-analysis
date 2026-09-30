# RavenStack Data Dictionary

This data dictionary documents the five tables in the RavenStack synthetic SaaS dataset. Column descriptions are based on the source README. NULL information reflects the current CSV files. 

This document describes the final SQLite database structure after data-quality validation and schema design.


## Table Relationships

```text
accounts
PK: account_id

subscriptions
PK: subscription_id
FK: account_id -> accounts.account_id

feature_usage
PK: usage_event_key
Source ID: usage_id
FK: subscription_id -> subscriptions.subscription_id

support_tickets
PK: ticket_id
FK: account_id -> accounts.account_id

churn_events
PK: churn_event_id
FK: account_id -> accounts.account_id
```
---

## 1. accounts

**Primary Key:** `account_id`

| Column | Description |
|---|---|
| `account_id` | Unique customer (primary key) |
| `account_name` | Fictional company name |
| `industry` | SaaS vertical (e.g., DevTools, EdTech) |
| `country` | ISO-2 country code |
| `signup_date` | Account creation date |
| `referral_source` | organic, ads, event, partner, other |
| `plan_tier` | Initial plan (Basic, Pro, Enterprise) |
| `seats` | Licensed user count |
| `is_trial` | Currently trialing |
| `churn_flag` | Churned at any point |

**Current NULLs:** None. All columns contain 0 NULL values.

---

## 2. subscriptions

**Primary Key:** `subscription_id`  
**Foreign Key:** `account_id` -> `accounts.account_id`

| Column | Description |
|---|---|
| `subscription_id` | Unique subscription (primary key) |
| `account_id` | Links to accounts.account_id |
| `start_date` | Subscription start |
| `end_date` | Nullable for active plans |
| `plan_tier` | Plan at time of billing |
| `seats` | Licensed seats |
| `mrr_amount` | Monthly revenue |
| `arr_amount` | Annual revenue |
| `is_trial` | Trial status |
| `upgrade_flag` | Plan upgraded mid-cycle |
| `downgrade_flag` | Plan downgraded mid-cycle |
| `churn_flag` | True if ended |
| `billing_frequency` | monthly or annual |
| `auto_renew_flag` | 80% true |

**Current NULLS:** 
| Column | NULL count | NULL % |
|---|---:|---:| 
| `end_date` | 4,514 | 90.28% |

All other columns contain 0 NULL vaules.

---

## 3. feature_usage

**Primary Key:** `usage_event_key`

**Source Identifier:** `usage_id`

**Foreign Key:** `subscription_id` -> `subscriptions.subscription_id`

> `usage_event_key` is a database-generated surrogate primary key added during schema design. The source `usage_id` column contains duplicate values identified during Python data-quality assessment, so it is retained for source traceability but is not used as the relational primary key.

| Column | Description |
|---|---|
| `usage_event_key` | Database-generated surrogate identifier for each feature-usage row; primary key |
| `usage_id` | Original source identifier for a feature-usage record; duplicate values are present, so it is retained for traceability but is not used as the primary key |
| `subscription_id` | Subscription associated with the usage event; foreign key to subscriptions.subscription_id |
| `usage_date` | Date of usage |
| `feature_name` | SaaS feature used |
| `usage_count` | Number of recorded uses |
| `usage_duration_secs` | Duration of feature usage in seconds |
| `error_count` | Number of logged errors |
| `is_beta_feature` | Indicates whether the feature was a beta feature |

**Current NULLs:**

| Column | NULL Count | NULL % |
|---|---:|---:|
| `usage_duration_secs` | 0 | 0% |

All other columns contain 0 NULL values.

---

## 4. support_tickets

**Primary Key:** `ticket_id`  
**Foreign Key:** `account_id` -> `accounts.account_id`

| Column | Description |
|---|---|
| `ticket_id` | Unique ticket |
| `account_id` | Links to accounts.account_id |
| `submitted_at` | Time opened |
| `closed_at` | Time resolved |
| `resolution_time_hours` | Duration |
| `priority` | low, medium, high, urgent |
| `first_response_time_minutes` | Minutes to first response |
| `satisfaction_score` | 1–5 (null = no response) |
| `escalation_flag` | True if escalated |

**Current NULLs:**

| Column | NULL Count | NULL % |
|---|---:|---:|
| `satisfaction_score` | 825 | 41.25% |

All other columns contain 0 NULL values.

---

## 5. churn_events

**Primary Key:** `churn_event_id`  
**Foreign Key:** `account_id` -> `accounts.account_id`

| Column | Description |
|---|---|
| `churn_event_id` | Unique churn instance |
| `account_id` | Links to accounts.account_id |
| `churn_date` | When account left |
| `reason_code` | pricing, support, features, etc. |
| `refund_amount_usd` | $0 default, 25% have credit/refund |
| `preceding_upgrade_flag` | Had upgrade within 90 days |
| `preceding_downgrade_flag` | Had downgrade within 90 days |
| `is_reactivation` | 10% were previously churned |
| `feedback_text` | Optional customer comment |

**Current NULLs:**

| Column | NULL Count | NULL % |
|---|---:|---:|
| `feedback_text` | 148 | 24.67% |

All other columns contain 0 NULL values.

---

## Current NULL Summary

| Table | Column | NULL Count | NULL % |
|---|---|---:|---:|
| `subscriptions` | `end_date` | 4,514 | 90.28% |
| `support_tickets` | `satisfaction_score` | 825 | 41.25% |
| `churn_events` | `feedback_text` | 148 | 24.67% |

All other columns contain 0 NULL values in the current version of the dataset.

### Data Quality Finding — Duplicate `usage_id` Values in `feature_usage`

The source documentation identifies `usage_id` as the primary key candidate for the `feature_usage` table. Pre-import Python quality checks identified 42 affected records representing 21 duplicated `usage_id` values.

Because a relational primary key must uniquely identify each record, `usage_id` will be retained as the original source identifier but will not be used as the primary key in the SQLite database. Instead, a database-generated surrogate key named `usage_event_key` will be created as the primary key.

The raw `ravenstack_feature_usage.csv` file will remain unchanged so that the original source data is preserved.
