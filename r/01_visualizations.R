# Churn analysis visualizations
# Create plots from SQL-exported CSV files

required_packages <- c("ggplot2", "readr", "scales")
missing_packages <- required_packages[!(required_packages %in% rownames(installed.packages()))]
if (length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}

library(ggplot2)
library(readr)
library(scales)

input_dir <- file.path("..", "data", "sql_output")
output_dir <- file.path("..", "output", "figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

save_plot <- function(filename, plot_obj, width = 8, height = 5) {
  ggsave(file.path(output_dir, filename), plot = plot_obj,
         width = width, height = height, dpi = 300)
}

# 1. Churn Rate by Plan Tier
plan <- read_csv(file.path(input_dir, "02_churn_by_plan.csv"), show_col_types = FALSE)
p1 <- ggplot(plan, aes(x = reorder(plan_tier, churn_rate_pct), y = churn_rate_pct)) +
  geom_col() +
  coord_flip() +
  geom_text(aes(label = paste0(sprintf("%.1f", churn_rate_pct), "%")), hjust = -0.15) +
  scale_y_continuous(limits = c(0, max(plan$churn_rate_pct) + 8), labels = label_number(suffix = "%")) +
  labs(title = "Churn Rate by Plan Tier", x = NULL, y = "Churn rate") +
  theme_minimal(base_size = 12)
save_plot("01_churn_by_plan.png", p1)

# 2. Churn Rate by Referral Source
ref <- read_csv(file.path(input_dir, "04_churn_by_referral.csv"), show_col_types = FALSE)
p2 <- ggplot(ref, aes(x = reorder(referral_source, churn_rate_pct), y = churn_rate_pct)) +
  geom_col() +
  coord_flip() +
  geom_text(aes(label = paste0(sprintf("%.1f", churn_rate_pct), "%")), hjust = -0.15) +
  scale_y_continuous(limits = c(0, max(ref$churn_rate_pct) + 8), labels = label_number(suffix = "%")) +
  labs(title = "Churn Rate by Referral Source", x = NULL, y = "Churn rate") +
  theme_minimal(base_size = 12)
save_plot("02_churn_by_referral.png", p2)


# 3. Churn Reasons
reasons <- read_csv(file.path(input_dir, "08_churn_reasons.csv"), show_col_types = FALSE)
p3 <- ggplot(reasons, aes(x = reorder(reason_code, churn_events), y = churn_events)) +
  geom_col() +
  coord_flip() +
  geom_text(aes(label = churn_events), hjust = -0.15) +
  scale_y_continuous(limits = c(0, max(reasons$churn_events) + 15)) +
  labs(title = "Recorded Churn Events by Reason", x = NULL, y = "Churn events") +
  theme_minimal(base_size = 12)
save_plot("03_churn_reasons.png", p3)

# 4. Support Response Time by Churn Status
support <- read_csv(file.path(input_dir, "05_support_by_churn.csv"), show_col_types = FALSE)
support$churn_status <- ifelse(support$analysis_churn_flag == 1, "Churned", "Retained")
p4 <- ggplot(support, aes(x = churn_status, y = avg_first_response_minutes)) +
  geom_col() +
  geom_text(aes(label = sprintf("%.1f min", avg_first_response_minutes)), vjust = -0.4) +
  scale_y_continuous(limits = c(0, max(support$avg_first_response_minutes) + 15)) +
  labs(title = "Average First Response Time by Churn Status", x = NULL, y = "Minutes") +
  theme_minimal(base_size = 12)
save_plot("04_support_response_by_churn.png", p4)

# 5. Product Engagement by Churn Status
usage <- read_csv(file.path(input_dir, "06_usage_by_churn.csv"), show_col_types = FALSE)
usage$churn_status <- ifelse(usage$analysis_churn_flag == 1, "Churned", "Retained")
p5 <- ggplot(usage, aes(x = churn_status, y = avg_distinct_features_used)) +
  geom_col() +
  geom_text(aes(label = sprintf("%.2f", avg_distinct_features_used)), vjust = -0.4) +
  scale_y_continuous(limits = c(0, max(usage$avg_distinct_features_used) + 2)) +
  labs(title = "Average Distinct Features Used by Churn Status", x = NULL, y = "Distinct features") +
  theme_minimal(base_size = 12)
save_plot("05_feature_engagement_by_churn.png", p5)

message("Saved portfolio figures to: ", output_dir)
