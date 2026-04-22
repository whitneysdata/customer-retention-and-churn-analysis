-- ================================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 09_monthly_churn_trends.sql
-- PURPOSE : Tenure-based trend analysis using LAG and running totals
-- NOTE    : The Telco dataset has no date column. Tenure (months with
--           company) is used as a time proxy — each band represents
--           the cohort of customers at that stage of their lifecycle.
-- ================================================================

-- ================================================================
-- 1. Churn counts and rates at each tenure month (0-72)
-- ================================================================
WITH TenureBands AS (
    SELECT
        c.tenure                                              AS month_band,
        COUNT(*)                                             AS total_at_tenure,
        SUM(CASE WHEN c.churn = 'Yes' THEN 1 ELSE 0 END)    AS churned,
        SUM(CASE WHEN c.churn = 'No'  THEN 1 ELSE 0 END)    AS retained,
        ROUND(AVG(t.monthly_charges), 2)                     AS avg_monthly_charge,
        ROUND(SUM(COALESCE(t.total_charges, 0)), 2)          AS total_revenue
    FROM customers c
    JOIN transactions t ON c.customer_id = t.customer_id
    GROUP BY c.tenure
),
WithLag AS (
    SELECT
        month_band,
        total_at_tenure,
        churned,
        retained,
        avg_monthly_charge,
        total_revenue,
        ROUND(churned * 100.0 / NULLIF(total_at_tenure, 0), 2)  AS churn_rate_pct,
        -- LAG: previous month's churn count for comparison
        LAG(churned, 1, 0) OVER (ORDER BY month_band)           AS prev_month_churned,
        -- Running cumulative churners across all tenure months
        SUM(churned) OVER (
            ORDER BY month_band
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                        AS cumulative_churned,
        -- Running cumulative revenue
        SUM(total_revenue) OVER (
            ORDER BY month_band
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                        AS cumulative_revenue
    FROM TenureBands
)
SELECT
    month_band,
    total_at_tenure,
    churned,
    retained,
    churn_rate_pct,
    -- Month-over-month churn change (LAG in action)
    churned - prev_month_churned                 AS churn_mom_change,
    cumulative_churned,
    ROUND(cumulative_revenue, 2)                 AS cumulative_revenue,
    avg_monthly_charge
FROM WithLag
ORDER BY month_band;

-- ================================================================
-- 2. Churn rate by tenure cohort (simplified — for Power BI line chart)
-- ================================================================
SELECT
    CASE
        WHEN tenure BETWEEN 0  AND 12 THEN '1 - New (0-12m)'
        WHEN tenure BETWEEN 13 AND 24 THEN '2 - Early (13-24m)'
        WHEN tenure BETWEEN 25 AND 36 THEN '3 - Mid (25-36m)'
        WHEN tenure BETWEEN 37 AND 48 THEN '4 - Maturing (37-48m)'
        WHEN tenure BETWEEN 49 AND 60 THEN '5 - Established (49-60m)'
        ELSE                               '6 - Loyal (60m+)'
    END                                                                  AS cohort,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)                     AS churned,
    ROUND(AVG(CASE WHEN churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2)   AS churn_rate_pct
FROM customers
GROUP BY cohort
ORDER BY cohort;
