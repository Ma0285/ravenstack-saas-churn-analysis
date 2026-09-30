# Analysis Methodology

## Churn Definition

The source data contains two churn indicators: `accounts.churn_flag` and detailed records in `churn_events`. They are not interchangeable. Of 500 accounts, 277 are marked non-churned in `accounts` despite having at least one churn-event record, while 35 are marked churned without a corresponding churn event.

For this portfolio analysis, an account is classified as **churned when it has at least one record in `churn_events`**. The event-based definition is used because the event table records dated churn activity, reasons, refunds, plan-change context, and reactivation behavior. The original account flag is retained as `source_churn_flag` for source traceability.

## Analysis Layer and Source Preservation

The raw tables are not edited or overwritten. SQL views form a separate analytical layer so that data-quality rules remain explicit and reproducible.

- Boolean-like fields imported into SQLite as text (`True`/`False`) are normalized to integer `1`/`0` inside analysis views.
- Blank subscription end dates are treated as analytical `NULL` values.
- Blank support satisfaction scores are treated as analytical `NULL` values rather than zero.
- Feature-usage records are included only when `usage_date` falls on or after subscription start and on or before subscription end when an end date exists.
- Support tickets are included only when they were submitted on or after account signup.

## Temporal Data-Quality Rules

Python QA identified 19,142 feature-usage records before subscription start, 290 after subscription end, and 1,077 support tickets before account signup. These rows are preserved in the raw source but excluded from behavioral comparisons through `vw_valid_feature_usage` and `vw_valid_support_tickets`.

This leaves:

- 5,568 valid feature-usage rows from 25,000 source rows.
- 923 valid support tickets from 2,000 source rows.

## Duplicate Usage Identifiers

The source `feature_usage.usage_id` field contains 21 duplicated identifier values affecting 42 records. Because the affected rows are not exact duplicates, no records were deleted. The SQLite model retains `usage_id` for traceability and uses the database-generated `usage_event_key` as the relational primary key.

## Grain and Join Strategy

Support, product-usage, and subscription tables are one-to-many relative to accounts. Each domain is first aggregated to account level before it is joined to churn status. This prevents row multiplication and distorted averages or totals.

## Revenue Terminology

MRR and ARR are reported as **recurring-revenue exposure associated with churn-classified accounts**, not realized revenue loss. The event-based churn definition captures historical churn activity, and the synthetic source contains accounts with both churn events and active subscription records. The data therefore does not support a claim that all associated MRR or ARR was actually lost.

## Interpretation Standard

This is descriptive analysis of a synthetic dataset. Findings use language such as *associated with*, *observed*, and *may indicate*. The analysis does not claim causal relationships.
