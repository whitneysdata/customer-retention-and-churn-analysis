# power bi dax_measures
-- KPI 1: Total Customers
Total Customers =
    COUNTROWS(vw_customer_master)

-- KPI 2: Churned Customers
Churned Customers =
    CALCULATE(
        COUNTROWS(vw_customer_master),
        vw_customer_master[churn] = "Yes"
    )

-- KPI 3: Churn Rate %
Churn Rate % =
    DIVIDE(
        [Churned Customers],
        [Total Customers],
        0
    ) * 100

-- KPI 4: Retention Rate %
Retention Rate % =
    100 - [Churn Rate %]

-- KPI 5: Average Tenure (months)
Avg Tenure Months =
    AVERAGE(vw_customer_master[tenure])

-- KPI 6: Average Monthly Charge
Avg Monthly Charge =
    AVERAGE(vw_customer_master[monthly_charges])

-- KPI 7: Total Revenue
Total Revenue =
    SUMX(
        vw_customer_master,
        COALESCE(vw_customer_master[total_charges], 0)
    )

-- KPI 8: Revenue Lost to Churn
Revenue Lost to Churn =
    CALCULATE(
        SUMX(
            vw_customer_master,
            COALESCE(vw_customer_master[total_charges], 0)
        ),
        vw_customer_master[churn] = "Yes"
    )

-- KPI 9: Average CLV
Avg Estimated CLV =
    AVERAGE(vw_customer_master[estimated_clv])

-- KPI 10: Retained Customers
Retained Customers =
    CALCULATE(
        COUNTROWS(vw_customer_master),
        vw_customer_master[churn] = "No"
    )

-- Avg CLV for retained customers only
Avg CLV Retained =
    CALCULATE(
        AVERAGE(vw_customer_master[estimated_clv]),
        vw_customer_master[churn] = "No"
    )

-- Avg CLV for churned customers only
Avg CLV Churned =
    CALCULATE(
        AVERAGE(vw_customer_master[estimated_clv]),
        vw_customer_master[churn] = "Yes"
    )