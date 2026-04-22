-- ================================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 08_advanced_window_functions.sql
-- PURPOSE : RANK, NTILE, ROW_NUMBER, running totals, LAG
-- ================================================================

-- ================================================================
-- 1. RANK customers by monthly spend within each contract type
-- ================================================================
SELECT
    c.customer_id,
    s.contract,
    t.monthly_charges,
    c.churn,
    -- Rank within contract group (1 = highest spender in that group)
    RANK() OVER (
        PARTITION BY s.contract
        ORDER BY t.monthly_charges DESC
    )                                             AS spend_rank_in_contract,
    -- Average charge across the entire contract group
    ROUND(AVG(t.monthly_charges) OVER (
        PARTITION BY s.contract
    ), 2)                                         AS avg_charge_in_contract,
    -- Total count in that contract group
    COUNT(*) OVER (
        PARTITION BY s.contract
    )                                             AS contract_group_size
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
JOIN transactions  t ON c.customer_id = t.customer_id
ORDER BY s.contract, spend_rank_in_contract;

-- ================================================================
-- 2. NTILE — divide customers into 4 spend quartiles
-- ================================================================
SELECT
    spend_quartile,
    COUNT(*)                                                             AS customers,
    ROUND(AVG(CASE WHEN churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2)   AS churn_pct,
    ROUND(AVG(monthly_charges), 2)                                      AS avg_charge,
    MIN(monthly_charges)                                                 AS quartile_min,
    MAX(monthly_charges)                                                 AS quartile_max
FROM (
    SELECT
        c.customer_id,
        c.churn,
        t.monthly_charges,
        NTILE(4) OVER (ORDER BY t.monthly_charges)   AS spend_quartile
    FROM customers c
    JOIN transactions t ON c.customer_id = t.customer_id
) quartile_data
GROUP BY spend_quartile
ORDER BY spend_quartile;

-- ================================================================
-- 3. ROW_NUMBER — top 20 highest-value customers who churned
--    (revenue loss ranking)
-- ================================================================
SELECT *
FROM (
    SELECT
        c.customer_id,
        c.tenure,
        s.contract,
        t.monthly_charges,
        COALESCE(t.total_charges, 0)  AS total_revenue_lost,
        ROW_NUMBER() OVER (
            ORDER BY COALESCE(t.total_charges, 0) DESC
        )                             AS loss_rank
    FROM customers c
    JOIN subscriptions s ON c.customer_id = s.customer_id
    JOIN transactions  t ON c.customer_id = t.customer_id
    WHERE c.churn = 'Yes'
) ranked
WHERE loss_rank <= 20
ORDER BY loss_rank;

-- ================================================================
-- 4. Running cumulative revenue retained customers generate
-- ================================================================
SELECT
    c.customer_id,
    c.tenure,
    t.monthly_charges,
    COALESCE(t.total_charges, t.monthly_charges * c.tenure) AS total_charges,
    -- Running total of revenue ordered by tenure (longest customers first)
    SUM(COALESCE(t.total_charges, t.monthly_charges * c.tenure)) OVER (
        ORDER BY c.tenure DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                          AS cumulative_revenue
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
WHERE c.churn = 'No'
ORDER BY c.tenure DESC, total_charges DESC;
