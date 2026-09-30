# Key Findings and Business Recommendations

## 1. Event-based analytical churn is high

**Finding:** 352 of 500 accounts have at least one recorded churn event, producing an analytical churn rate of **70.40%**.

**Evidence:** The source account flag and detailed event table disagree substantially, so the event-based definition is used consistently throughout the portfolio.

**Interpretation:** The absolute rate should not be treated as a real-world SaaS benchmark because the dataset is synthetic and the source indicators conflict. It is the internally consistent rate for this analysis.

## 2. Acquisition channel shows a larger churn-rate spread than plan tier

**Finding:** Partner-referred accounts have the highest observed churn rate at **75.28%**, followed by organic at **74.56%**. Ads-referred accounts are lowest at **60.20%**.

**Evidence:** The referral-source range is **15.08 percentage points**. By comparison, plan-tier churn ranges from **68.45%** to **72.47%**, only **4.02 percentage points**.

**Interpretation:** Acquisition source is a more visibly differentiated segmentation variable than plan tier in this dataset. This is descriptive, not causal.

## 3. Feature-related churn is the most common recorded reason

**Finding:** `features` is the most common churn reason with **114 events (19.00%)**. `support` and `budget` follow with **104 events each (17.33%)**.

**Evidence:** The churn-event table contains 600 records across six reason categories.

**Interpretation:** Product capability or product-market-fit issues deserve investigation, but the broad `features` label does not identify which capabilities were missing or unsatisfactory.

## 4. Support experience differs only modestly by churn status

**Finding:** Churned accounts average **90.59 minutes** to first response versus **87.02** for retained accounts, and **35.94 hours** to resolution versus **34.27**. Average satisfaction is essentially identical at **3.97 vs. 3.96**.

**Evidence:** Support metrics were calculated only from the 923 temporally valid tickets and aggregated to account level before joining to churn status.

**Interpretation:** The dataset does not support a strong claim that lower support satisfaction distinguishes churned accounts. Slightly slower response/resolution and higher escalation activity may be worth monitoring, but the observed gaps are small.

## 5. General product engagement is not lower among churned accounts

**Finding:** Churned accounts average **113.27** total valid uses and **9.28** distinct features, compared with **107.11** uses and **8.91** features among retained accounts.

**Evidence:** Product metrics were calculated from 5,568 usage rows that fall inside their referenced subscription windows.

**Interpretation:** Simple aggregate engagement volume does not separate churned from retained accounts here. More useful future analysis would examine time trends, recency, specific feature combinations, or engagement decline before a churn date.

## 6. Churn-classified accounts carry substantial recurring-revenue exposure in the source subscription records

**Finding:** Accounts classified as churned are associated with **$7,139,868 active MRR** and **$85,678,416 active ARR** in the source subscription records.

**Interpretation:** These figures are **exposure, not realized revenue loss**. Event-based churn captures historical churn activity, and the synthetic source can simultaneously show churn events and active subscription records.

## 7. Repeat churn and reactivation are meaningful event patterns

**Finding:** **61 of 600 churn events (10.17%)** are marked as reactivations. **123 events (20.50%)** follow an upgrade within 90 days, while **53 (8.83%)** follow a downgrade.

**Interpretation:** Customer lifecycle behavior is not strictly one-directional. Repeat churn/reactivation and recent plan changes should be considered when designing retention monitoring.

# Business Recommendations

1. **Investigate feature-related churn in more detail.** Replace the broad `features` reason with more specific exit categories or structured product feedback so Product and Customer Success can identify which capability gaps matter most.
2. **Review acquisition quality and onboarding by referral source.** Partner and organic cohorts show higher observed churn than ads cohorts, so onboarding expectations, customer fit, and early adoption should be compared across channels before changing acquisition spend.
3. **Use lifecycle triggers rather than support satisfaction alone.** Support satisfaction shows almost no separation by churn status. Retention monitoring should combine plan changes, repeated churn/reactivation history, usage recency, and channel rather than relying on a single support metric.
4. **Build engagement measures around change over time.** Aggregate usage is not lower for churned accounts. Future analysis should measure declining usage, days since last use, feature abandonment, and behavior in the 30/60/90 days before churn.
5. **Improve upstream data controls.** Enforce date-window rules, explicit SQL NULL handling, and consistent boolean types during ETL so future analyses require fewer corrective views.
