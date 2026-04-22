-- ================================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 05_retention_analysis.sql
-- PURPOSE : Retention by tenure cohort, support services,
--           partner/dependent status
-- ================================================================

-- ================================================================
-- 1. Retention rate by tenure cohort (active customers over time)
-- ================================================================
SELECT
    CASE
        WHEN tenure BETWEEN 0  AND 12 THEN '1 - New (0-12 months)'
        WHEN tenure BETWEEN 13 AND 36 THEN '2 - Growing (13-36 months)'
        WHEN tenure BETWEEN 37 AND 60 THEN '3 - Established (37-60 months)'
        ELSE                               '4 - Loyal (60+ months)'
    END                                                                  AS tenure_cohort,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)                     AS churned,
    SUM(CASE WHEN churn = 'No'  THEN 1 ELSE 0 END)                     AS retained,
    ROUND(AVG(CASE WHEN churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2)   AS churn_pct,
    ROUND(AVG(CASE WHEN churn = 'No'  THEN 1.0 ELSE 0 END) * 100, 2)   AS retention_pct
FROM customers
GROUP BY tenure_cohort
ORDER BY tenure_cohort;

-- ================================================================
-- 2. Impact of Tech Support on churn (3-table join)
-- ================================================================
SELECT
    s.tech_support,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN c.churn = 'Yes' THEN 1 ELSE 0 END)                   AS churned,
    ROUND(AVG(CASE WHEN c.churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS churn_pct,
    ROUND(AVG(t.monthly_charges), 2)                                    AS avg_monthly_charge
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
JOIN transactions  t ON c.customer_id = t.customer_id
GROUP BY s.tech_support
ORDER BY churn_pct DESC;

-- ================================================================
-- 3. Impact of Online Security on churn
-- ================================================================
SELECT
    s.online_security,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN c.churn = 'Yes' THEN 1 ELSE 0 END)                   AS churned,
    ROUND(AVG(CASE WHEN c.churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS churn_pct
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
GROUP BY s.online_security
ORDER BY churn_pct DESC;

-- ================================================================
-- 4. Partner & Dependents effect on retention
-- ================================================================
SELECT
    partner,
    dependents,
    COUNT(*)                                                             AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)                     AS churned,
    ROUND(AVG(CASE WHEN churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2)   AS churn_pct
FROM customers
GROUP BY partner, dependents
ORDER BY churn_pct DESC;

-- ================================================================
-- 5. Streaming services — do they drive retention?
-- ================================================================
SELECT
    s.streaming_tv,
    s.streaming_movies,
    COUNT(*)                                                             AS total,
    ROUND(AVG(CASE WHEN c.churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS churn_pct,
    ROUND(AVG(t.monthly_charges), 2)                                    AS avg_monthly_charge
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
JOIN transactions  t ON c.customer_id = t.customer_id
GROUP BY s.streaming_tv, s.streaming_movies
ORDER BY churn_pct DESC;
