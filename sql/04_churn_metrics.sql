-- ================================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 04_churn_metrics.sql
-- PURPOSE : Core churn & retention KPIs — overall + by category
-- ================================================================

-- ================================================================
-- 1. Overall portfolio KPIs (feeds Power BI card visuals)
-- ================================================================
SELECT
    COUNT(*)                                                             AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)                     AS churned_customers,
    SUM(CASE WHEN churn = 'No'  THEN 1 ELSE 0 END)                     AS retained_customers,
    ROUND(AVG(CASE WHEN churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2)   AS churn_rate_pct,
    ROUND(AVG(CASE WHEN churn = 'No'  THEN 1.0 ELSE 0 END) * 100, 2)   AS retention_rate_pct,
    ROUND(AVG(tenure), 2)                                               AS avg_tenure_months
FROM customers;

-- ================================================================
-- 2. Churn rate by contract type (most impactful single factor)
-- ================================================================
SELECT
    s.contract,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN c.churn = 'Yes' THEN 1 ELSE 0 END)                   AS churned,
    ROUND(AVG(CASE WHEN c.churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(t.monthly_charges), 2)                                    AS avg_monthly_charge
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
JOIN transactions  t ON c.customer_id = t.customer_id
GROUP BY s.contract
ORDER BY churn_rate_pct DESC;

-- ================================================================
-- 3. Churn rate by internet service type
-- ================================================================
SELECT
    s.internet_service,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN c.churn = 'Yes' THEN 1 ELSE 0 END)                   AS churned,
    ROUND(AVG(CASE WHEN c.churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(t.monthly_charges), 2)                                    AS avg_monthly_charge
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
JOIN transactions  t ON c.customer_id = t.customer_id
GROUP BY s.internet_service
ORDER BY churn_rate_pct DESC;

-- ================================================================
-- 4. Churn rate by payment method
-- ================================================================
SELECT
    s.payment_method,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN c.churn = 'Yes' THEN 1 ELSE 0 END)                   AS churned,
    ROUND(AVG(CASE WHEN c.churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS churn_rate_pct
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
GROUP BY s.payment_method
ORDER BY churn_rate_pct DESC;

-- ================================================================
-- 5. Churn by senior citizen status
-- ================================================================
SELECT
    CASE senior_citizen WHEN 1 THEN 'Senior' ELSE 'Non-Senior' END     AS category,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)                     AS churned,
    ROUND(AVG(CASE WHEN churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2)   AS churn_rate_pct
FROM customers
GROUP BY senior_citizen
ORDER BY churn_rate_pct DESC;

-- ================================================================
-- 6. Churn by paperless billing
-- ================================================================
SELECT
    s.paperless_billing,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN c.churn = 'Yes' THEN 1 ELSE 0 END)                   AS churned,
    ROUND(AVG(CASE WHEN c.churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS churn_rate_pct
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
GROUP BY s.paperless_billing
ORDER BY churn_rate_pct DESC;