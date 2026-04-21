-- ================================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 01_create_tables.sql
-- PURPOSE : Create 3NF schema — customers, subscriptions, transactions
-- DATABASE: churn_db
-- DATASET : IBM Telco Customer Churn (7,043 rows, 21 columns)
-- ================================================================

-- Drop in FK order so re-runs never fail
DROP TABLE IF EXISTS transactions  CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS customers     CASCADE;

-- ================================================================
-- TABLE 1: CUSTOMERS
-- Demographics + tenure + churn label (target variable)
-- ================================================================
CREATE TABLE customers (
    customer_id      VARCHAR(20)  PRIMARY KEY,
    gender           VARCHAR(10),
    senior_citizen   SMALLINT,          -- 0 = No, 1 = Yes
    partner          VARCHAR(5),        -- Yes / No
    dependents       VARCHAR(5),        -- Yes / No
    tenure           INT,               -- months with company (0-72)
    churn            VARCHAR(5)         -- Yes = churned, No = retained
);

-- ================================================================
-- TABLE 2: SUBSCRIPTIONS
-- Services subscribed to + contract & billing info
-- ================================================================
CREATE TABLE subscriptions (
    subscription_id    SERIAL        PRIMARY KEY,
    customer_id        VARCHAR(20)   REFERENCES customers(customer_id),
    phone_service      VARCHAR(5),
    multiple_lines     VARCHAR(25),   -- Yes / No / No phone service
    internet_service   VARCHAR(15),   -- DSL / Fiber optic / No
    online_security    VARCHAR(25),
    online_backup      VARCHAR(25),
    device_protection  VARCHAR(25),
    tech_support       VARCHAR(25),
    streaming_tv       VARCHAR(25),
    streaming_movies   VARCHAR(25),
    contract           VARCHAR(20),   -- Month-to-month / One year / Two year
    paperless_billing  VARCHAR(5),
    payment_method     VARCHAR(40)    -- Electronic check / Mailed check / etc.
);

-- ================================================================
-- TABLE 3: TRANSACTIONS
-- Financial data — monthly and total charges
-- NOTE: avg_monthly_charge removed from GENERATED column
--       (PostgreSQL does not allow subqueries in GENERATED expressions)
--       It is computed in analysis queries and views instead.
-- ================================================================
CREATE TABLE transactions (
    transaction_id    SERIAL          PRIMARY KEY,
    customer_id       VARCHAR(20)     REFERENCES customers(customer_id),
    monthly_charges   DECIMAL(8,2)    NOT NULL,
    total_charges     DECIMAL(10,2)   -- NULL for 11 customers with tenure = 0
);

-- ================================================================
-- Verify all three tables were created
-- ================================================================
SELECT table_name
FROM   information_schema.tables
WHERE  table_schema = 'public'
  AND  table_name IN ('customers', 'subscriptions', 'transactions')
ORDER  BY table_name;
