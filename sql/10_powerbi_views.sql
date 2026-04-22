-- ================================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 10_powerbi_views.sql
-- PURPOSE : CREATE VIEWs that Power BI connects to directly.
--           avg_monthly_charge computed inside each view.
-- ================================================================

-- ================================================================
-- VIEW 1: vw_customer_master
-- Full customer profile — all dimensions joined in one flat view.
-- This is the PRIMARY view Power BI imports for most visuals.
-- ================================================================
CREATE OR REPLACE VIEW vw_customer_master AS
SELECT
    c.customer_id,
    c.gender,
    CASE c.senior_citizen WHEN 1 THEN 'Senior' ELSE 'Non-Senior' END  AS senior_status,
    c.partner,
    c.dependents,
    c.tenure,
    -- Tenure cohort label for Power BI axis
    CASE
        WHEN c.tenure BETWEEN 0  AND 12 THEN '1 - New (0-12m)'
        WHEN c.tenure BETWEEN 13 AND 36 THEN '2 - Growing (13-36m)'
        WHEN c.tenure BETWEEN 37 AND 60 THEN '3 - Established (37-60m)'
        ELSE                                  '4 - Loyal (60m+)'
    END                                                                AS tenure_cohort,
    c.churn,
    CASE c.churn WHEN 'Yes' THEN 1 ELSE 0 END                        AS churn_flag,
    s.contract,
    s.internet_service,
    s.phone_service,
    s.multiple_lines,
    s.online_security,
    s.online_backup,
    s.device_protection,
    s.tech_support,
    s.streaming_tv,
    s.streaming_movies,
    s.payment_method,
    s.paperless_billing,
    t.monthly_charges,
    COALESCE(t.total_charges, t.monthly_charges * c.tenure)           AS total_charges,
    -- avg_monthly_charge computed here (not in table schema)
    CASE
        WHEN c.tenure > 0 AND t.total_charges IS NOT NULL
        THEN ROUND(t.total_charges / c.tenure, 2)
        ELSE t.monthly_charges
    END                                                               AS avg_monthly_charge,
    -- Value segment (median monthly charge = ~$64.76)
    CASE
        WHEN t.monthly_charges >= 64.76 THEN 'High-Value'
        ELSE 'Low-Value'
    END                                                               AS value_segment,
    -- Loyalty segment
    CASE
        WHEN c.churn = 'No'  AND c.tenure >= 29 THEN 'Loyal'
        WHEN c.churn = 'No'  AND c.tenure <  29 THEN 'At-Risk'
        WHEN c.churn = 'Yes' AND c.tenure <  29 THEN 'Early Churner'
        ELSE                                         'Late Churner'
    END                                                               AS loyalty_segment,
    -- CLV estimate
    ROUND(
        COALESCE(t.total_charges, t.monthly_charges * c.tenure)
        + CASE
            WHEN c.churn = 'No'
            THEN t.monthly_charges * GREATEST(60 - c.tenure, 0)
            ELSE 0
          END,
    2)                                                                AS estimated_clv,
    -- CLV tier
    CASE
        WHEN (COALESCE(t.total_charges, t.monthly_charges * c.tenure)
              + CASE WHEN c.churn = 'No'
                     THEN t.monthly_charges * GREATEST(60 - c.tenure, 0)
                     ELSE 0 END) >= 5000 THEN 'Platinum'
        WHEN (COALESCE(t.total_charges, t.monthly_charges * c.tenure)
              + CASE WHEN c.churn = 'No'
                     THEN t.monthly_charges * GREATEST(60 - c.tenure, 0)
                     ELSE 0 END) >= 2500 THEN 'Gold'
        WHEN (COALESCE(t.total_charges, t.monthly_charges * c.tenure)
              + CASE WHEN c.churn = 'No'
                     THEN t.monthly_charges * GREATEST(60 - c.tenure, 0)
                     ELSE 0 END) >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END                                                               AS clv_tier
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
JOIN transactions  t ON c.customer_id = t.customer_id;

-- ================================================================
-- VIEW 2: vw_kpi_summary
-- One row — feeds Power BI KPI card visuals directly
-- ================================================================
CREATE OR REPLACE VIEW vw_kpi_summary AS
SELECT
    COUNT(*)                                                              AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)                      AS churned,
    SUM(CASE WHEN churn = 'No'  THEN 1 ELSE 0 END)                      AS retained,
    ROUND(AVG(CASE WHEN churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2)    AS churn_rate_pct,
    ROUND(AVG(CASE WHEN churn = 'No'  THEN 1.0 ELSE 0 END) * 100, 2)    AS retention_rate_pct,
    ROUND(AVG(tenure), 2)                                                AS avg_tenure_months
FROM customers;

-- ================================================================
-- VIEW 3: vw_churn_by_segment
-- Churn rate grouped by key dimensions — feeds bar/column charts
-- ================================================================
CREATE OR REPLACE VIEW vw_churn_by_segment AS
SELECT
    s.contract,
    s.internet_service,
    s.payment_method,
    s.tech_support,
    s.online_security,
    COUNT(*)                                                              AS total,
    SUM(CASE WHEN c.churn = 'Yes' THEN 1 ELSE 0 END)                    AS churned,
    ROUND(AVG(CASE WHEN c.churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2)  AS churn_rate_pct,
    ROUND(AVG(t.monthly_charges), 2)                                     AS avg_monthly_charge
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
JOIN transactions  t ON c.customer_id = t.customer_id
GROUP BY
    s.contract,
    s.internet_service,
    s.payment_method,
    s.tech_support,
    s.online_security;

-- ================================================================
-- VIEW 4: vw_tenure_trend
-- Cohort churn trend — feeds Power BI line chart
-- ================================================================
CREATE OR REPLACE VIEW vw_tenure_trend AS
SELECT
    CASE
        WHEN tenure BETWEEN 0  AND 12 THEN '1 - New (0-12m)'
        WHEN tenure BETWEEN 13 AND 24 THEN '2 - Early (13-24m)'
        WHEN tenure BETWEEN 25 AND 36 THEN '3 - Mid (25-36m)'
        WHEN tenure BETWEEN 37 AND 48 THEN '4 - Maturing (37-48m)'
        WHEN tenure BETWEEN 49 AND 60 THEN '5 - Established (49-60m)'
        ELSE                               '6 - Loyal (60m+)'
    END                                                                   AS cohort,
    COUNT(*)                                                              AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)                      AS churned,
    ROUND(AVG(CASE WHEN churn = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2)    AS churn_rate_pct,
    ROUND(AVG(CASE WHEN churn = 'No'  THEN 1.0 ELSE 0 END) * 100, 2)    AS retention_rate_pct
FROM customers
GROUP BY cohort
ORDER BY cohort;

-- ================================================================
-- Verify all 4 views were created
-- ================================================================
SELECT table_name AS view_name
FROM   information_schema.views
WHERE  table_schema = 'public'
  AND  table_name IN (
       'vw_customer_master',
       'vw_kpi_summary',
       'vw_churn_by_segment',
       'vw_tenure_trend'
  )
ORDER  BY table_name;
