-- ================================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 07_clv_analysis.sql
-- PURPOSE : Customer Lifetime Value (CLV) calculation
--           avg_monthly_charge computed in CTE, not in table schema
-- ================================================================

-- ================================================================
-- 1. Full CLV calculation per customer
-- ================================================================
WITH CLV_Base AS (
    SELECT
        c.customer_id,
        c.tenure,
        c.churn,
        s.contract,
        s.internet_service,
        t.monthly_charges,
        -- Use total_charges where available; estimate for tenure=0 rows
        COALESCE(t.total_charges, t.monthly_charges * c.tenure) AS realised_revenue,
        -- avg_monthly_charge = total / tenure (computed here, not in schema)
        CASE
            WHEN c.tenure > 0 AND t.total_charges IS NOT NULL
            THEN ROUND(t.total_charges / c.tenure, 2)
            ELSE t.monthly_charges
        END AS avg_monthly_charge,
        -- Projected future value (60-month horizon for retained customers)
        CASE
            WHEN c.churn = 'No'
            THEN ROUND(t.monthly_charges * GREATEST(60 - c.tenure, 0), 2)
            ELSE 0
        END AS projected_future_value
    FROM customers c
    JOIN subscriptions s ON c.customer_id = s.customer_id
    JOIN transactions  t ON c.customer_id = t.customer_id
)
SELECT
    customer_id,
    tenure,
    churn,
    contract,
    internet_service,
    monthly_charges,
    avg_monthly_charge,
    realised_revenue,
    projected_future_value,
    ROUND(realised_revenue + projected_future_value, 2) AS total_clv,
    CASE
        WHEN (realised_revenue + projected_future_value) >= 5000 THEN 'Platinum'
        WHEN (realised_revenue + projected_future_value) >= 2500 THEN 'Gold'
        WHEN (realised_revenue + projected_future_value) >= 1000 THEN 'Silver'
        ELSE                                                           'Bronze'
    END AS clv_tier
FROM CLV_Base
ORDER BY total_clv DESC;

-- ================================================================
-- 2. CLV tier summary (Power BI KPI card and pie chart)
-- ================================================================
WITH CLV_Computed AS (
    SELECT
        c.customer_id,
        c.churn,
        s.contract,
        COALESCE(t.total_charges, t.monthly_charges * c.tenure)
        + CASE
            WHEN c.churn = 'No'
            THEN t.monthly_charges * GREATEST(60 - c.tenure, 0)
            ELSE 0
          END AS total_clv
    FROM customers c
    JOIN subscriptions s ON c.customer_id = s.customer_id
    JOIN transactions  t ON c.customer_id = t.customer_id
)
SELECT
    CASE
        WHEN total_clv >= 5000 THEN 'Platinum'
        WHEN total_clv >= 2500 THEN 'Gold'
        WHEN total_clv >= 1000 THEN 'Silver'
        ELSE                        'Bronze'
    END                          AS clv_tier,
    COUNT(*)                     AS customers,
    ROUND(AVG(total_clv), 2)    AS avg_clv,
    ROUND(SUM(total_clv), 2)    AS total_portfolio_value,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_in_tier
FROM CLV_Computed
GROUP BY clv_tier
ORDER BY AVG(total_clv) DESC;
