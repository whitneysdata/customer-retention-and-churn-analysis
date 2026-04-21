-- ================================================================
-- PROJECT : Customer Retention & Churn Analysis
-- FILE    : 02_import_data.sql
-- PURPOSE : Staging table + ETL load into normalised tables
-- RAW FILE: data/telco_churn.csv  (7,043 rows)
-- ================================================================

-- ================================================================
-- STEP 1: Create staging table
-- All columns TEXT to prevent any type error during CSV import
-- ================================================================
DROP TABLE IF EXISTS staging_telco;

CREATE TABLE staging_telco (
    customerID        TEXT,
    gender            TEXT,
    SeniorCitizen     TEXT,
    Partner           TEXT,
    Dependents        TEXT,
    tenure            TEXT,
    PhoneService      TEXT,
    MultipleLines     TEXT,
    InternetService   TEXT,
    OnlineSecurity    TEXT,
    OnlineBackup      TEXT,
    DeviceProtection  TEXT,
    TechSupport       TEXT,
    StreamingTV       TEXT,
    StreamingMovies   TEXT,
    Contract          TEXT,
    PaperlessBilling  TEXT,
    PaymentMethod     TEXT,
    MonthlyCharges    TEXT,
    TotalCharges      TEXT,
    Churn             TEXT
);

-- ================================================================
-- STEP 2: Import the CSV using pgAdmin Import Wizard
-- Right-click staging_telco → Import/Export Data → Import
-- File   : data/telco_churn.csv
-- Format : csv
-- Header : YES (toggle ON)
-- Delimiter: , (comma)
-- Encoding : UTF8
-- ================================================================

-- Run this after import to confirm row count:
SELECT COUNT(*) AS staging_rows FROM staging_telco;
-- Expected: 7043

-- Preview first 3 rows to confirm columns loaded correctly:
SELECT * FROM staging_telco LIMIT 3;

-- ================================================================
-- STEP 3: Clear final tables before loading
-- (safe to re-run this whole file)
-- ================================================================
TRUNCATE transactions  RESTART IDENTITY CASCADE;
TRUNCATE subscriptions RESTART IDENTITY CASCADE;
TRUNCATE customers     RESTART IDENTITY CASCADE;

-- ================================================================
-- STEP 4: Load customers
-- ================================================================
INSERT INTO customers (
    customer_id, gender, senior_citizen,
    partner, dependents, tenure, churn
)
SELECT
    customerID,
    gender,
    SeniorCitizen::SMALLINT,
    Partner,
    Dependents,
    tenure::INT,
    Churn
FROM staging_telco;

SELECT COUNT(*) AS customers_loaded FROM customers;
-- Expected: 7043

-- ================================================================
-- STEP 5: Load subscriptions
-- ================================================================
INSERT INTO subscriptions (
    customer_id, phone_service, multiple_lines,
    internet_service, online_security, online_backup,
    device_protection, tech_support, streaming_tv,
    streaming_movies, contract, paperless_billing,
    payment_method
)
SELECT
    customerID,
    PhoneService,
    MultipleLines,
    InternetService,
    OnlineSecurity,
    OnlineBackup,
    DeviceProtection,
    TechSupport,
    StreamingTV,
    StreamingMovies,
    Contract,
    PaperlessBilling,
    PaymentMethod
FROM staging_telco;

SELECT COUNT(*) AS subscriptions_loaded FROM subscriptions;
-- Expected: 7043

-- ================================================================
-- STEP 6: Load transactions
-- TotalCharges has 11 blank strings (tenure=0 customers) → NULL
-- ================================================================
INSERT INTO transactions (customer_id, monthly_charges, total_charges)
SELECT
    customerID,
    MonthlyCharges::DECIMAL(8,2),
    NULLIF(TRIM(TotalCharges), '')::DECIMAL(10,2)
FROM staging_telco;

SELECT COUNT(*) AS transactions_loaded FROM transactions;
-- Expected: 7043

-- ================================================================
-- STEP 7: Final verification — all three tables
-- ================================================================
SELECT 'customers'     AS table_name, COUNT(*) AS rows FROM customers
UNION ALL
SELECT 'subscriptions' AS table_name, COUNT(*) AS rows FROM subscriptions
UNION ALL
SELECT 'transactions'  AS table_name, COUNT(*) AS rows FROM transactions;
-- All three should show 7043
