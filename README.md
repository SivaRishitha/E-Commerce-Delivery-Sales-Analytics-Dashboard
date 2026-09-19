# E-Commerce Delivery & Sales Analytics Dashboard

End-to-end analytics pipeline turning raw e-commerce data into SLA insights, a Power BI dashboard, and a late-delivery prediction model — built on the [Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

![Status](https://img.shields.io/badge/status-complete-brightgreen) ![Python](https://img.shields.io/badge/python-3.x-blue) ![SQL](https://img.shields.io/badge/SQL-PostgreSQL%2FMySQL-orange) ![Power BI](https://img.shields.io/badge/Power%20BI-dashboard-yellow) ![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## Overview

This project analyzes 100K+ real e-commerce orders to identify what drives late deliveries and where sellers, regions, and product categories underperform against delivery SLAs. It covers the full analyst workflow: cleaning messy relational data, transforming it with SQL, visualizing it in an interactive dashboard, and layering on a predictive model to flag late-delivery risk before dispatch.

## Business Questions Answered

- Which states, sellers, and product categories have the highest late-delivery rates?
- How strongly does delivery delay correlate with customer review scores?
- Which sellers are consistently underperforming on delivery SLAs?
- Can late-delivery risk be predicted at order time, before shipment?

## Dataset

**Source:** [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)

9 relational tables spanning 100K+ orders:
`customers`, `geolocation`, `orders`, `order_items`, `products`, `product_category_translation`, `sellers`, `order_payments`, `order_reviews`

## Pipeline

```
Raw CSVs (Kaggle)
   → Pandas: null handling, duplicate key resolution, timestamp standardization
   → SQL: joins, CTEs, window functions → delivery SLA metrics, delay aggregation
   → Power BI: dashboard (late-delivery hotspots, review-delay correlation, seller KPIs)
   → Scikit-learn: Logistic Regression / Random Forest → late-delivery risk prediction
```

## What Was Done

**1. Data Cleaning (Pandas + SQL)**
Resolved null values, duplicate keys, and inconsistent delivery timestamps across all 9 tables before joining them into an analysis-ready relational structure.

**2. SQL Analysis**
Used joins, CTEs, and window functions to:
- Flag orders delivered later than their estimated delivery date
- Aggregate delay rates by region, seller, and product category

**3. Power BI Dashboard**
Built an interactive dashboard surfacing:
- Late-delivery hotspots by state and category
- Correlation between review scores and delivery delay
- Seller-level performance KPIs

**4. Predictive Modeling**
Trained Logistic Regression and Random Forest classifiers on order, seller, and shipping features to predict late-delivery risk ahead of dispatch, enabling proactive SLA monitoring.

## Repository Structure

```
├── data/                  # Raw and cleaned datasets (or data-loading scripts, if raw files are excluded)
├── sql/                   # SQL scripts — cleaning, joins, SLA metric queries
├── notebooks/             # Pandas cleaning + model training notebooks
├── dashboard/              # Power BI (.pbix) file and/or exported screenshots
├── model/                  # Trained model artifacts and evaluation scripts
└── README.md
```

## Tech Stack

Python (Pandas, NumPy, Scikit-learn) · SQL · Power BI · DAX

## Future Improvements

- Extend the prediction model with delivery-carrier-level features
- Add time-series forecasting for regional delivery volume and delay trends
- Deploy the classification model behind a simple API for real-time SLA risk scoring

## License

MIT
