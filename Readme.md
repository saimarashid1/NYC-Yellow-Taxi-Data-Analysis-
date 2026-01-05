# NYC Yellow Taxi Data Analysis (End-to-End Project)

## Overview
This project presents an end-to-end data analysis of New York City Yellow Taxi trip data using **Python, SQL, and Power BI**.  
The objective is to clean raw taxi data, perform analytical transformations, and deliver business insights through interactive dashboards.

The project follows a structured analytics workflow commonly used in real-world data teams.

---

## Tools & Technologies
- **Python** (Pandas, NumPy) – Data cleaning, validation, outlier handling
- **SQL** – Feature engineering, aggregations, analytical queries
- **Power BI** – KPIs, dashboards, interactivity, storytelling
- **GitHub** – Version control and portfolio presentation

---

## Dataset
- **Source:** NYC Yellow Taxi Trip Records
- **Period Covered:** January (analysis scope)
- **Granularity:** Trip-level transactional data
- **Key Fields:** Pickup & drop-off timestamps, trip distance, fare components, payment type, vendor, location IDs

---

## Project Workflow

### 1. Data Cleaning & Preparation (Python)
- Removed duplicate taxi trips to avoid inflated metrics
- Handled missing values and corrected data types
- Identified and separated negative fare records (cancellations/adjustments)
- Removed unrealistic trip distances using domain-based thresholds
- Performed validation checks to ensure analytical readiness

**Output:** Cleaned dataset exported for SQL analysis

---

### 2. Analytical Transformations (SQL)
- Centralized feature engineering in SQL to maintain a single source of truth
- Performed:
  - Trip volume analysis
  - Revenue analysis
  - Payment type analysis
  - Location-based analysis
- Used aggregations, CASE logic, and time-based groupings

---

### 3. Business Intelligence & Visualization (Power BI)
- Built interactive dashboards using cleaned and transformed data
- Designed KPIs including:
  - Total Trips
  - Total Revenue
  - Average Fare per Trip
- Implemented slicers, cross-filtering, and drill interactions
- Organized all measures into a dedicated **KPI Measures** folder for model clarity

---

## Key Insights
- Weekday trips generate higher overall revenue than weekends
- Credit card payments dominate both trip volume and revenue
- Peak activity occurs during commuting and evening hours
- Short to medium-distance trips account for the majority of rides

---

## Repository Structure
nyc-taxi-data-analysis/
│
├── python/
│   └── nyc_taxi_data_cleaning.ipynb
│
├── sql/
│   └── nyc_taxi_analysis.sql
│
├── powerbi/
│   └── nyc_taxi_dashboard.pbix
│
├── visuals/
│   └── dashboard_screenshots.png
│
└── README.md

