-- ================================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 06_customer_segmentation.sql
-- PURPOSE : Segment customers by value and loyalty using CTEs
--           avg_monthly_charge computed here (not in table schema)
-- ================================================================

-- ================================================================
-- 1. Full customer segmentation using CTE
-- ================================================================
WITH CustomerMetrics AS (
    SELECT
        c.customer_id,
        c.tenure,
        c.churn,
        c.senior_citizen,
        c.partner,
        c.dependents,
        s.contract,
        s.internet_service,
        t.monthly_charges,
        -- avg_monthly_charge computed here (avoids subquery in schema)
        ROUND(
            COALESCE(t.total_charges, t.monthly_charges * NULLIF(c.tenure, 0))
            / NULLIF(c.tenure, 0),
        2) AS avg_monthly_charge,
        COALESCE(t.total_charges, 0) AS total_charges
    FROM customers c
    JOIN subscriptions s ON c.customer_id = s.customer_id
    JOIN transactions  t ON c.customer_id = t.customer_id
),
Thresholds AS (
    -- Compute portfolio medians once — used as benchmarks
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_charges) AS median_charge,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY tenure)          AS median_tenure
    FROM CustomerMetrics
)
SELECT
    cm.customer_id,
    cm.tenure,
    cm.churn,
    cm.contract,
    cm.internet_service,
    cm.monthly_charges,
    cm.avg_monthly_charge,
    cm.total_charges,
    -- Value segment: above/below median monthly charge
    CASE
        WHEN cm.monthly_charges >= th.median_charge THEN 'High-Value'
        ELSE 'Low-Value'
    END AS value_segment,
    -- Loyalty segment: based on tenure and churn outcome
    CASE
        WHEN cm.churn = 'No'  AND cm.tenure >= th.median_tenure THEN 'Loyal'
        WHEN cm.churn = 'No'  AND cm.tenure <  th.median_tenure THEN 'At-Risk'
        WHEN cm.churn = 'Yes' AND cm.tenure <  th.median_tenure THEN 'Early Churner'
        ELSE                                                         'Late Churner'
    END AS loyalty_segment
FROM CustomerMetrics cm
CROSS JOIN Thresholds th
ORDER BY cm.monthly_charges DESC;

-- ================================================================
-- 2. Segment summary — churn rate per segment (Power BI ready)
-- ================================================================
WITH Segmented AS (
    SELECT
        c.customer_id,
        c.churn,
        t.monthly_charges,
        c.tenure,
        CASE
            WHEN t.monthly_charges >= (
                SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_charges)
                FROM transactions
            ) THEN 'High-Value'
            ELSE 'Low-Value'
        END AS value_segment,
        CASE
            WHEN c.churn = 'No'  AND c.tenure >= 29 THEN 'Loyal'
            WHEN c.churn = 'No'  AND c.tenure <  29 THEN 'At-Risk'
            WHEN c.churn = 'Yes' AND c.tenure <  29 THEN 'Early Churner'
            ELSE                                         'Late Churner'
        END AS loyalty_segment
    FROM customers c
    JOIN transactions t ON c.customer_id = t.customer_id
)
SELECT
    value_segment,
    loyalty_segment,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)                     AS churned,
    ROUND(AVG(CASE WHEN churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2)   AS churn_pct,
    ROUND(AVG(monthly_charges), 2)                                      AS avg_monthly_charge
FROM Segmented
GROUP BY value_segment, loyalty_segment
ORDER BY churn_pct DESC;
