/*
Review the account churn flag against churn event records
before choosing the churn definition used in the analysis.

This file only reviews the data and does not modify it.
*/

PRAGMA foreign_keys = ON;


-- 1. ACCOUNT-LEVEL SOURCE CHURN FLAG

SELECT
    CASE
        WHEN LOWER(TRIM(CAST(churn_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1
        ELSE 0
    END AS source_churn_flag,
    COUNT(*) AS account_count
FROM accounts
GROUP BY source_churn_flag
ORDER BY source_churn_flag;


-- 2. ACCOUNTS WITH A CHURN EVENT

SELECT
    COUNT(DISTINCT account_id) AS accounts_with_churn_event
FROM churn_events;


-- 3. CHURN DEFINITION RECONCILIATION

SELECT
    CASE
        WHEN LOWER(TRIM(CAST(a.churn_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1
        ELSE 0
    END AS source_churn_flag,
    CASE
        WHEN ce.account_id IS NOT NULL THEN 1
        ELSE 0
    END AS has_churn_event,
    COUNT(*) AS account_count
FROM accounts AS a
LEFT JOIN (
    SELECT DISTINCT account_id
    FROM churn_events
) AS ce
    ON a.account_id = ce.account_id
GROUP BY source_churn_flag, has_churn_event
ORDER BY source_churn_flag, has_churn_event;


-- 4. SOURCE NON-CHURN BUT CHURN EVENT EXISTS

SELECT
    COUNT(*) AS discrepancy_count
FROM accounts AS a
WHERE CASE
          WHEN LOWER(TRIM(CAST(a.churn_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1
          ELSE 0
      END = 0
  AND EXISTS (
      SELECT 1
      FROM churn_events AS ce
      WHERE ce.account_id = a.account_id
  );


-- 5. SOURCE CHURN BUT NO CHURN EVENT EXISTS

SELECT
    COUNT(*) AS discrepancy_count
FROM accounts AS a
WHERE CASE
          WHEN LOWER(TRIM(CAST(a.churn_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1
          ELSE 0
      END = 1
  AND NOT EXISTS (
      SELECT 1
      FROM churn_events AS ce
      WHERE ce.account_id = a.account_id
  );


-- 6. SAMPLE: SOURCE NON-CHURN WITH CHURN EVENT

SELECT
    a.account_id,
    a.churn_flag AS source_churn_flag,
    ce.churn_date,
    ce.reason_code
FROM accounts AS a
JOIN churn_events AS ce
    ON a.account_id = ce.account_id
WHERE CASE
          WHEN LOWER(TRIM(CAST(a.churn_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1
          ELSE 0
      END = 0
LIMIT 20;


-- 7. SAMPLE: SOURCE CHURN WITHOUT CHURN EVENT

SELECT
    a.account_id,
    a.churn_flag AS source_churn_flag
FROM accounts AS a
LEFT JOIN churn_events AS ce
    ON a.account_id = ce.account_id
WHERE CASE
          WHEN LOWER(TRIM(CAST(a.churn_flag AS TEXT))) IN ('true', '1', 'yes', 'y') THEN 1
          ELSE 0
      END = 1
  AND ce.account_id IS NULL
LIMIT 20;

/*
Final churn definition:
An account is considered churned if it has at least one record in churn_events.

The original source churn flag is kept for comparison, but the event-based
churn flag is used for the analysis.
*/
