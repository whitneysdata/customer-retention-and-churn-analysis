# Customer Retention & Churn Analysis
### Business Analytics Case Study | SQL + Power BI Portfolio Project

![Status](https://img.shields.io/badge/Status-Complete-brightgreen)
![PostgreSQL](https://img.shields.io/badge/SQL-PostgreSQL%2016-336791?logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?logo=powerbi&logoColor=black)
![VS Code](https://img.shields.io/badge/Editor-VS%20Code-007ACC?logo=visualstudiocode&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## Project Overview

This project investigates customer churn behaviour in a telecom company through
a complete business analytics pipeline — from raw data ingestion and relational
database engineering in PostgreSQL, through structured SQL analysis, to an
interactive executive dashboard in Power BI.

The analysis answers a core business question:

> **"Why are customers leaving, which segments are most at risk,
> and what actions can the business take to improve retention?"**

---

## Business Problem

Customer churn is one of the most costly challenges in subscription-based industries.
Acquiring a new customer costs 5–7× more than retaining an existing one. In this
dataset, **26.54% of customers have churned** — representing 1,869 lost customers
and significant foregone revenue. Understanding the behavioural and contractual
drivers of churn enables targeted, data-driven retention interventions.

---

## Dataset

| Attribute | Detail |
|---|---|
| Source | [IBM Telco Customer Churn — Kaggle (blastchar)](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) |
| File | `WA_Fn-UseC_-Telco-Customer-Churn.csv` → renamed `telco_churn.csv` |
| Rows | 7,043 customers |
| Columns | 21 |
| Churn rate | 26.54% (1,869 churned / 5,174 retained) |
| Coverage | Demographics, services, contract, billing, charges |

---

## Key Findings

| Finding | Detail | Business Implication |
|---|---|---|
| Month-to-month contracts | 42.7% churn rate | Converting to annual plans is the highest-impact retention lever |
| Two-year contracts | 2.8% churn rate | Long-term contracts are 15× more retentive than month-to-month |
| Fiber optic internet | 41.9% churn rate | Service quality or value-perception problem in the fiber line |
| No tech support | 41.5% churn rate | Proactive support outreach could recover significant revenue |
| With tech support | 15.2% churn rate | Tech support reduces churn by 63% |
| Senior citizens | 41.7% churn rate vs 23.6% for non-seniors | Tailored retention programme for senior segment needed |
| New customers (0–12 months) | Highest churn cohort | First-year onboarding programme would have greatest portfolio impact |
| Electronic check payment | Highest churn of all payment methods | Incentivise migration to auto-pay methods |

---

## Project Structure

```
customer-retention-churn-analysis/
│
├── data/                        # telco_churn.csv (gitignored — Kaggle terms)
│   └── exports/                      # SQL view exports for Power BI
│       ├── export_customer_master.csv
│       ├── export_kpi_summary.csv
│       ├── export_churn_by_segment.csv
│       └── export_tenure_trend.csv
│
├── sql/                              # All SQL scripts (run in numbered order)
│   ├── 01_create_tables.sql          # 3NF schema: customers, subscriptions, transactions
│   ├── 02_import_data.sql            # Staging table + ETL pipeline
│   ├── 03_data_cleaning.sql          # Quality audit — nulls, ranges, distributions
│   ├── 04_churn_metrics.sql          # Core churn & retention KPIs
│   ├── 05_retention_analysis.sql     # Retention by tenure, support, demographics
│   ├── 06_customer_segmentation.sql  # CTE segmentation — value & loyalty tiers
│   ├── 07_clv_analysis.sql           # Customer Lifetime Value + CLV tiers
│   ├── 08_advanced_window_functions.sql  # RANK, NTILE, ROW_NUMBER, running totals
│   ├── 09_monthly_churn_trends.sql   # Tenure-band trends with LAG + cumulative windows
│   └── 10_powerbi_views.sql          # CREATE VIEWs for Power BI direct connection
│
├── powerbi/
│   └── dax_measures.md              # All DAX measures (readable on GitHub)
│
├── screenshots/                 # Dashboard page screenshots (PNG)
│       ├── page1_overview.png
│       ├── page2_churn.png
│       ├── page3_segments.png
│       └── page4_retention.png
│
├── .gitignore
├── requirements.txt
└── README.md
```

---

## Phase 1 — SQL (PostgreSQL 16 + pgAdmin 4)

### Database Design

A **Third Normal Form (3NF)** relational database (`churn_db`) was designed
with three normalised tables:

| Table | Rows | Description |
|---|---|---|
| `customers` | 7,043 | Demographics, tenure, churn label |
| `subscriptions` | 7,043 | Services, contract type, billing, payment method |
| `transactions` | 7,043 | Monthly charges, total charges |

A staging table (`staging_telco`) buffered the CSV import with all columns
as TEXT, preventing type-casting errors. An ETL pipeline then cleaned and
loaded the data — handling 11 blank `TotalCharges` entries (customers with
`tenure = 0`) by converting them to NULL.

### SQL Analyses Conducted

| Script | Analysis |
|---|---|
| `04_churn_metrics.sql` | Overall churn/retention rate, breakdown by contract, internet, payment method |
| `05_retention_analysis.sql` | Tenure cohort retention, tech support & online security impact |
| `06_customer_segmentation.sql` | CTE: High/Low-value + Loyal/At-Risk/Early Churner classification |
| `07_clv_analysis.sql` | CLV per customer with Platinum/Gold/Silver/Bronze tiers |
| `08_advanced_window_functions.sql` | RANK by spend, NTILE quartiles, ROW_NUMBER revenue loss ranking |
| `09_monthly_churn_trends.sql` | LAG-based month-over-month change, cumulative running totals |
| `10_powerbi_views.sql` | 4 views: `vw_customer_master`, `vw_kpi_summary`, `vw_churn_by_segment`, `vw_tenure_trend` |

### Advanced SQL Techniques Used

- **CTEs** (`WITH` statements) — multi-step segmentation logic
- **Window functions** — `RANK()`, `NTILE()`, `ROW_NUMBER()`, `LAG()`, running totals
- **PERCENTILE_CONT** — median-based segment thresholds
- **GENERATED columns** — computed flags in schema
- **Views** — reusable analytical layers for Power BI

---

## Phase 2 — Power BI Dashboard

### Connection Method

Power BI connects directly to PostgreSQL via the four views created in
`10_powerbi_views.sql`. Connection: `localhost → churn_db → Import mode`.

### DAX Measures (12 total)

All measures are documented in [`powerbi/dax_measures.md`](powerbi/dax_measures.md).
Key measures include:

| Measure | Formula logic |
|---|---|
| `Churn Rate %` | `DIVIDE(Churned Customers, Total Customers) * 100` |
| `Retention Rate %` | `100 - Churn Rate %` |
| `Revenue Lost to Churn` | `CALCULATE(SUM(total_charges), churn = "Yes")` |
| `Avg Estimated CLV` | `AVERAGE(estimated_clv)` |
| `Avg CLV Retained` | `CALCULATE(AVERAGE(estimated_clv), churn = "No")` |

### Dashboard Pages

**Page 1 — Executive Overview**
5 KPI cards · Churn vs Retained donut · Churn by contract bar chart ·
Tenure cohort line chart · Revenue Lost to Churn card

**Page 2 — Churn Analysis**
Churn by internet service · Churn by payment method · Churn by senior status ·
Contract × internet matrix · Interactive slicers (contract, internet, gender)

**Page 3 — Customer Segments**
CLV tier donut · Avg CLV by contract · Tenure vs monthly charge scatter
(coloured by churn) · Loyalty segment column chart

**Page 4 — Retention Trends & Drivers**
Cohort line + column combo chart · Tech support impact · Online security impact ·
Partner/dependents effect · 4 business insight callout boxes

---

## Business Insights

> **"Month-to-month customers churn at 42.7% — nearly 3× the rate of two-year
> contract holders (2.8%). Converting at-risk customers to annual plans is the
> single highest-impact retention lever available."**

> **"Customers without tech support are 2.6× more likely to churn (41.5% vs 15.2%).
> A proactive support outreach programme targeting unprotected customers would
> recover significant revenue."**

> **"Fiber optic customers churn at 41.9% despite paying ~$20/month more than DSL
> users. This signals a service quality or value-perception issue specific to the
> fiber product line — not a pricing problem."**

> **"New customers (0–12 months) churn at the highest rate. The first year is the
> highest-risk period. An onboarding retention programme targeting months 1–6
> would have the greatest impact on overall portfolio churn rate."**

---

## How to Run

### Prerequisites

```bash
# Install PostgreSQL 16 (includes pgAdmin 4)
# https://www.postgresql.org/download/

# Install Power BI Desktop (free)
# https://powerbi.microsoft.com/desktop

# Clone the repo
git clone https://github.com/YourUsername/customer-retention-churn-analysis.git
cd customer-retention-churn-analysis
```

### Step 1 — Set up the database

1. Open **pgAdmin 4**
2. Create a new database named `churn_db`
3. Open the **Query Tool** (`Tools → Query Tool`)

### Step 2 — Download the dataset

Download `WA_Fn-UseC_-Telco-Customer-Churn.csv` from
[Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
and place it in `data/raw/telco_churn.csv`

### Step 3 — Run SQL scripts in order

Open each file in VS Code, copy the content, paste into pgAdmin Query Tool,
and run with **F5**. Run in numbered order:

```
01_create_tables.sql       → creates the 3NF schema
02_import_data.sql         → run up to the staging table creation,
                             then use pgAdmin Import Wizard to load
                             data/raw/telco_churn.csv into staging_telco,
                             then run the ETL INSERT blocks
03_data_cleaning.sql       → audit and validate
04_churn_metrics.sql       → core KPIs
05_retention_analysis.sql  → retention breakdown
06_customer_segmentation.sql → CTE segmentation
07_clv_analysis.sql        → CLV tiers
08_advanced_window_functions.sql → window functions
09_monthly_churn_trends.sql → trend analysis
10_powerbi_views.sql       → creates the 4 Power BI views
```

> **Import note (02_import_data.sql):** After creating `staging_telco`,
> use pgAdmin's Import Wizard — right-click `staging_telco` →
> **Import/Export Data → Import** → select `data/raw/telco_churn.csv` →
> Format: csv · Header: **YES** · Delimiter: , · Encoding: UTF8.
> Do not use the `COPY` command on Windows — it will fail with a permissions error.

### Step 4 — Export views to CSV

For each view, run `SELECT * FROM view_name;` in pgAdmin, then click the
**download icon** in the Data Output toolbar → save to `data/exports/`.

### Step 5 — Open Power BI

1. **Get Data → PostgreSQL database**
2. Server: `localhost` · Database: `churn_db` · Mode: **Import**
3. Select all four views → **Load**
4. Create DAX measures from `powerbi/dax_measures.md`
5. Build the 4 dashboard pages

### Step 6 — Open SQL files in VS Code

```bash
# Open the entire project in VS Code
code .
```

Install the **SQLTools** extension + **SQLTools PostgreSQL Driver** in VS Code
to run SQL queries directly without switching to pgAdmin:

- Extension: `mtxr.sqltools`
- Driver: `mtxr.sqltools-driver-pg`
- Connect with: host `localhost` · database `churn_db` · user `postgres`

---

## Opening in VS Code

```bash
# From Git Bash or terminal, inside the project folder:
code .
```

**Recommended VS Code extensions for this project:**

| Extension | ID | Purpose |
|---|---|---|
| SQLTools | `mtxr.sqltools` | Run SQL queries from VS Code |
| SQLTools PostgreSQL Driver | `mtxr.sqltools-driver-pg` | PostgreSQL connection |
| SQL Formatter | `adpyke.codeigniter4-snippets` | Format SQL on save |
| GitLens | `eamodio.gitlens` | Enhanced Git history in VS Code |
| Markdown Preview Enhanced | `shd101wyy.markdown-preview-enhanced` | Preview README and dax_measures.md |

Once SQLTools is connected, you can run any `.sql` file directly in VS Code
by opening it and pressing **Ctrl + Shift + P → SQLTools: Run Current File**.
No need to copy-paste into pgAdmin.

---

## Tools & Technologies

| Tool | Version | Purpose |
|---|---|---|
| PostgreSQL | 16+ | Relational database engine |
| pgAdmin 4 | Latest | Database management + import wizard |
| VS Code | Latest | SQL file editing + Git integration |
| Power BI Desktop | Latest | Interactive dashboard |
| Git + GitHub | — | Version control + portfolio hosting |

---

## Git Commit History

This project was built commit-by-commit, with each SQL script and dashboard
page committed separately. The commit history documents the full analytical
workflow from schema design to final dashboard.

---

## Limitations

- No explicit timestamp column — tenure (months) used as a time proxy for trend analysis
- Cross-sectional snapshot data — no longitudinal observation of individual customers over time
- CLV projection assumes a 60-month customer horizon, which may not reflect actual business model
- Power BI `.pbix` file is gitignored (binary) — dashboard is represented by screenshots and DAX measures file

---

## Project Progress

- [x] Phase 1: Database design (3NF schema, staging table, ETL)
- [x] Phase 1: SQL analysis (10 scripts, 4 views)
- [x] Phase 1: Data exports to `data/exports/`
- [x] Phase 2: Power BI connection (PostgreSQL → Import)
- [x] Phase 2: DAX measures (12 measures documented)
- [x] Phase 2: Dashboard (4 pages, 4 screenshots committed)
- [x] Phase 2: README + requirements

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*Whitney Kemuma*
*Customer Retention & Churn Analysis | Business Analytics Case Study*
*BSc Actuarial Science → Data Science Portfolio*
