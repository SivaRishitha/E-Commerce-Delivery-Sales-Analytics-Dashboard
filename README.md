# E-Commerce Delivery & Sales Analytics — Olist Brazilian E-Commerce Dataset

An end-to-end data project covering data cleaning, SQL feature engineering, a Power BI dashboard, and a machine learning classifier — built on the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (100K+ orders, 2016-2018).

## Overview

This project investigates what drives late deliveries on Olist's marketplace, how delivery delay affects customer satisfaction, and whether late-delivery risk can be predicted before dispatch. It moves through four stages: cleaning 9 raw relational tables, loading and modeling them in MySQL, visualizing SLA metrics in Power BI, and training classification models in Python.

## Tech Stack

- **Python** (Pandas, NumPy, Scikit-learn) — data cleaning and ML
- **MySQL 8.0** — relational schema, joins, CTEs, window functions
- **Power BI** (DAX, M) — dashboard and KPI reporting
- **Jupyter / Google Colab** — notebooks

## Pipeline

1. **Data cleaning** (`olist_data_cleaning.ipynb`) — loaded all 9 raw CSVs, resolved missing values, duplicates, and inconsistent delivery timestamps on a per-table basis. Notable fixes: collapsed heavily duplicated geolocation records to one row per zip prefix, corrected two misspelled source columns in the products table, and standardized text/date formatting across tables.
2. **MySQL schema & load** (`create_tables.sql`, `load_to_mysql.py`) — designed a normalized schema with primary/foreign keys across all 9 tables and loaded the cleaned data via a Python/SQLAlchemy script. Caught and patched a real data-quality issue during load: two legitimate product categories were missing from Olist's own category-translation file, which would otherwise have silently broken the products table's foreign key.
3. **SQL feature engineering** (`sla_and_reviews.sql`, `materialize_tables.sql`) — built views and materialized tables computing delivery SLA metrics (late-order flagging) by region, seller, and product category, using joins, CTEs, and window functions (`NTILE`). Also engineered a customer RFM (Recency, Frequency, Monetary) segmentation.
4. **Power BI dashboard** — three-page report (Delay & Reviews, Regional & Seller Hotspots, Category Breakdown) connected live to MySQL, with custom DAX measures (e.g. `Late Rate %`).
5. **Classification modeling** (`olist_late_delivery_classification.ipynb`) — trained Logistic Regression and Random Forest classifiers to predict late-delivery risk ahead of dispatch, using only features known at order time.

## Key Findings

- **Delivery delay strongly predicts customer dissatisfaction.** Average review score drops from 4.29 (on-time/early) to 1.69 (8+ days late); the share of 1-2 star reviews rises from 9.2% to 79.4% over the same range.
- **Late-delivery rate is concentrated in specific regions and time periods**, not evenly distributed. Northeastern states (AL, MA, PI, CE, SE) show the highest late rates (16-24%), and two sharp seasonal spikes — November 2017 and February-March 2018 — account for a large share of delays, pointing to operational capacity strain during high-volume periods rather than a uniform service problem.
- **An initial hypothesis was tested and revised**: RFM customer segment appeared to correlate with late-delivery rate, but further analysis showed this was almost entirely confounded with order timing (most Olist customers order only once, so "recency" is effectively a re-statement of which month they ordered in). The real driver is time-based operational strain, not customer value or loyalty — a finding reached by deliberately checking an initial result rather than taking it at face value.
- **Random Forest outperformed Logistic Regression** for late-delivery classification (AUC 0.766 vs 0.697), trading a small recall decrease (58% vs 63%) for meaningfully better precision (21% vs 14%) on the minority "late" class (~8% of orders). Feature importances independently corroborated the SQL findings: `purchase_month` was the single strongest predictor, with `estimated_delivery_days` and `avg_distance_km` (tying to the regional hotspot finding) close behind.

## Repository Structure

```
├── olist_data_cleaning.ipynb                  # Cleans all 9 raw CSVs
├── create_tables.sql                          # MySQL schema with PK/FK constraints
├── load_to_mysql.py                           # Loads cleaned CSVs into MySQL
├── materialize_tables.sql                     # Indexed feature tables (RFM, delivery features)
├── sla_and_reviews.sql                        # SLA-by-region/seller/category + review-score link
├── olist_late_delivery_classification.ipynb   # Logistic Regression / Random Forest models
├── dashboard.pbix                              # Power BI dashboard (3 pages)
└── README.md
```

## How to Run

1. Download the [raw dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and run `olist_data_cleaning.ipynb` to produce cleaned CSVs.
2. Set up a local MySQL 8.0 database, run `create_tables.sql`, then `load_to_mysql.py` (update credentials/paths first) to load the cleaned data.
3. Run `materialize_tables.sql` and `sla_and_reviews.sql` to build the feature tables and SLA views.
4. Open `dashboard.pbix` in Power BI Desktop (requires the MySQL Connector/NET driver) and refresh the connection against your local database.
5. Run `olist_late_delivery_classification.ipynb` (update DB credentials) to reproduce the classification results.

## Data Source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — Kaggle, public domain.
