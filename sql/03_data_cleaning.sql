-- ================================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 03_data_cleaning.sql
-- PURPOSE : Data quality audit — nulls, ranges, distributions
-- ================================================================

-- ================================================================
-- 1. Row count confirmation (all three tables)
-- ================================================================
SELECT
    (SELECT COUNT(*) FROM customers)     AS customers,
    (SELECT COUNT(*) FROM subscriptions) AS subscriptions,
    (SELECT COUNT(*) FROM transactions)  AS transactions;
-- All expected: 7043

-- ================================================================
-- 2. Null audit — TotalCharges (expect 11 NULLs, all with tenure=0)
-- ================================================================
SELECT
    COUNT(*)                                              AS total_rows,
    COUNT(*) FILTER (WHERE t.total_charges IS NULL)      AS null_total_charges,
    COUNT(*) FILTER (WHERE t.monthly_charges IS NULL)    AS null_monthly_charges
FROM transactions t;

-- Show the 11 customers with NULL total_charges (all have tenure = 0)
SELECT
    c.customer_id,
    c.tenure,
    t.monthly_charges,
    t.total_charges
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
WHERE t.total_charges IS NULL
ORDER BY c.customer_id;

-- ================================================================
-- 3. Churn label distribution (the target variable)
-- ================================================================
SELECT
    churn,
    COUNT(*)                                               AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)     AS percentage
FROM customers
GROUP BY churn
ORDER BY churn;
-- Expected: No = 5174 (73.46%), Yes = 1869 (26.54%)

-- ================================================================
-- 4. Tenure range validation
-- ================================================================
SELECT
    MIN(tenure)              AS min_tenure,
    MAX(tenure)              AS max_tenure,
    ROUND(AVG(tenure), 2)    AS avg_tenure,
    COUNT(*) FILTER (WHERE tenure = 0) AS zero_tenure_count
FROM customers;
-- Expected: min=0, max=72, zero_tenure=11

-- ================================================================
-- 5. Monthly charges range validation
-- ================================================================
SELECT
    MIN(monthly_charges)              AS min_charge,
    MAX(monthly_charges)              AS max_charge,
    ROUND(AVG(monthly_charges), 2)    AS avg_charge
FROM transactions;
-- Expected: min=18.25, max=118.75

-- ================================================================
-- 6. Contract type distribution
-- ================================================================
SELECT
    s.contract,
    COUNT(*)                                               AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)     AS pct
FROM subscriptions s
GROUP BY s.contract
ORDER BY count DESC;
-- Expected: Month-to-month=3875, Two year=1695, One year=1473

-- ================================================================
-- 7. Internet service distribution
-- ================================================================
SELECT
    internet_service,
    COUNT(*)                                               AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)     AS pct
FROM subscriptions
GROUP BY internet_service
ORDER BY count DESC;
-- Expected: Fiber optic=3096, DSL=2421, No=1526

-- ================================================================
-- 8. Senior citizen breakdown
-- ================================================================
SELECT
    CASE senior_citizen WHEN 1 THEN 'Senior' ELSE 'Non-Senior' END AS category,
    COUNT(*)                                               AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)     AS pct
FROM customers
GROUP BY senior_citizen;
-- Expected: Non-Senior=5901, Senior=1142

-- ================================================================
-- 9. Payment method distribution
-- ================================================================
SELECT
    payment_method,
    COUNT(*)                                               AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)     AS pct
FROM subscriptions
GROUP BY payment_method
ORDER BY count DESC;
-- Expected: Electronic check=2365, Mailed check=1612, Bank transfer=1544, Credit card=1522
