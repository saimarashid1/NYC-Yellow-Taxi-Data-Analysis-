/*
Project: NYC Yellow Taxi Data Analysis
Analysis Period: January (dataset scope defined in Python cleaning stage)
A small number of records from late Dec 2023 and early Feb 2024 exist.
-- All analyses explicitly filter pickup datetime to Jan 2024.
Purpose:
- Trip volume analysis
- Location-based analysis
- Revenue and payment analysis

Note:
Data cleaning and validation were performed in Python.
Feature engineering and aggregations are handled in SQL.
*/

/* 
    SCHEMA FIX: Normalize Pickup/Dropoff Time
    Convert VARCHAR time columns to TIME    */

    ALTER TABLE nyc_taxi_clean
    ADD Pickup_Time_tmp TIME,
    Dropoff_Time_tmp TIME;

        UPDATE nyc_taxi_clean
SET
    Pickup_Time_tmp  = CAST(tpep_pickup_datetime AS TIME),
    Dropoff_Time_tmp = CAST(tpep_dropoff_datetime AS TIME);

    ALTER TABLE nyc_taxi_clean
    DROP COLUMN Pickup_Time, Dropoff_Time;

--Rename columns
EXEC sp_rename 'nyc_taxi_clean.Pickup_Time_tmp', 'Pickup_Time';
EXEC sp_rename 'nyc_taxi_clean.Dropoff_Time_tmp', 'Dropoff_Time';


-- Verification Query

    SELECT
    tpep_pickup_datetime,
    pickup_date,
    pickup_time,
    tpep_dropoff_datetime,
    dropoff_date,
    dropoff_time
FROM nyc_taxi_clean;

----Analysis period: January 2024

---Trip Analysis

-- Calculates total number of taxi trips for the analysis period
SELECT 
    COUNT(*) AS total_trips
FROM nyc_taxi_clean;


--Total trips per day 

Select pickup_date,count(pickup_date) as totalTrips_perDay
from nyc_taxi_clean
WHERE pickup_date >= '2024-01-01' 
  AND pickup_date < '2024-02-01'
group by pickup_date
order by totalTrips_perDay desc

---Total trips per month 
Select Month(Pickup_date) as Trip_month,
count(pickup_date) as totalTrips_perMonth
from nyc_taxi_clean
WHERE pickup_date >= '2024-01-01' 
  AND pickup_date < '2024-02-01'
group by Month(Pickup_date)

--Total trips per Day/Hour 
SELECT pickup_date,
    CONCAT(
        DATEPART(HOUR, tpep_pickup_datetime), ':00 - ', 
        DATEPART(HOUR, tpep_pickup_datetime) + 1, ':00'
    ) AS hour_range,
    COUNT(*) AS total_trips
FROM nyc_taxi_clean
WHERE tpep_pickup_datetime >= '2024-01-01' 
  AND tpep_pickup_datetime < '2024-02-01'
GROUP BY pickup_date,DATEPART(HOUR, tpep_pickup_datetime)
ORDER BY pickup_date,DATEPART(HOUR, tpep_pickup_datetime);

--top 10 Peak pickup and drop-off times
SELECT Top 10 pickup_date,
    CONCAT(
        DATEPART(HOUR, tpep_pickup_datetime), ':00 - ', 
        DATEPART(HOUR, tpep_pickup_datetime) + 1, ':00'
    ) AS hour_range,
    COUNT(*) AS total_trips
FROM nyc_taxi_clean
WHERE tpep_pickup_datetime >= '2024-01-01' 
  AND tpep_pickup_datetime < '2024-02-01'
GROUP BY pickup_date,DATEPART(HOUR, tpep_pickup_datetime)
ORDER BY Total_trips desc,pickup_date,DATEPART(HOUR, tpep_pickup_datetime);

--top 10 drop-off times
SELECT Top 10 dropoff_date,
    CONCAT(
        DATEPART(HOUR, tpep_dropoff_datetime), ':00 - ', 
        DATEPART(HOUR, tpep_dropoff_datetime) + 1, ':00'
    ) AS hour_range,
    COUNT(*) AS total_trips
FROM nyc_taxi_clean
WHERE tpep_dropoff_datetime >= '2024-01-01' 
  AND tpep_dropoff_datetime < '2024-02-01'
GROUP BY dropoff_date,DATEPART(HOUR, tpep_dropoff_datetime)
ORDER BY Total_trips desc ,dropoff_date,DATEPART(HOUR, tpep_dropoff_datetime);


--Average trip distance
Select avg(trip_distance) as avg_tripDistance
from nyc_taxi_clean

--Average Trip Distance/day and trip duration/day
SELECT pickup_date,
    Round(AVG(trip_distance),2) AS avg_trip_distance_miles,
    AVG(DATEDIFF(
    MINUTE,
    tpep_pickup_datetime,
    tpep_dropoff_datetime
)) AS avg_trip_duration_minutes
FROM nyc_taxi_clean
WHERE tpep_pickup_datetime >= '2024-01-01'
  AND tpep_pickup_datetime < '2024-02-01'
  group by pickup_date
  order by pickup_date

  ---Revenue & Pricing Analysis

  -- Computes total and average revenue to assess overall business performance
SELECT
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_revenue_per_trip
FROM nyc_taxi_clean;


--Total revenue 
Select Round(Sum(total_amount),2) as Total_Revenue
From nyc_taxi_clean
WHERE pickup_date >= '2024-01-01' 
  AND pickup_date < '2024-02-01'
 

--- Compares revenue between weekdays and weekends

Select 
     datepart(week,pickup_date) as week_number,
     case
        when DATENAME(weekday,pickup_date) in ('saturday','sunday')
        then 'weekend'
        else 'weekday'
        end as day_type,
        Round(sum(total_amount),2) as Total_Revenue
        From nyc_taxi_clean
WHERE pickup_date >= '2024-01-01' 
  AND pickup_date < '2024-02-01'
Group by datepart(week,pickup_date) ,
     case
        when DATENAME(weekday,pickup_date) in ('saturday','sunday')
        then 'weekend'
        else 'weekday'
       END
ORDER BY week_number, day_type;


--Average fare per trip and average trip duration

Select pickup_date,Round(Avg(fare_amount),2) as avg_fareAmount,
        avg(datediff(Minute,Pickup_time,dropoff_time)) as Avg_trip_duration_minutes
From nyc_taxi_clean
WHERE pickup_date >= '2024-01-01' 
  AND pickup_date < '2024-02-01'
group by pickup_date
order by Pickup_Date 

---Revenue per mile
SELECT 
    pickup_date,
    ROUND(SUM(total_amount) / SUM(trip_distance), 2) AS revenue_per_mile,
    ROUND(AVG(total_amount / NULLIF(trip_distance, 0)), 2) AS avg_revenue_per_mile_per_trip
FROM nyc_taxi_clean
WHERE tpep_pickup_datetime >= '2024-01-01' 
  AND tpep_pickup_datetime < '2024-02-01'
  AND trip_distance > 0
GROUP BY pickup_date
ORDER BY pickup_date

--Tips by payment type/total/Avg/Tripcount
SELECT 
    t.pickup_date, 
    p.payment_desc,
    ROUND(COALESCE(SUM(t.tip_amount), 0), 2) AS total_tip,
    ROUND(COALESCE(AVG(t.tip_amount), 0), 2) AS avg_tip,
    COUNT(*) AS trip_count
FROM nyc_taxi_clean AS t
JOIN dim_payment_type p ON p.payment_type = t.payment_type
WHERE t.pickup_date >= '2024-01-01' AND t.pickup_date < '2024-02-01'
GROUP BY t.pickup_date, p.payment_desc
ORDER BY t.pickup_date, total_tip DESC;

--Revenue by rate code

SELECT 
    t.pickup_date, 
    R.rate_desc,
    ROUND(COALESCE(SUM(t.Total_amount), 0), 2) AS Total_Revenue,
    ROUND(COALESCE(AVG(t.total_amount), 0), 2) AS Avg_Revenue,
    COUNT(*) AS trip_count
FROM nyc_taxi_clean AS t
JOIN dim_rate_code R ON R.rate_code_id = t.RatecodeID
WHERE t.pickup_date >= '2024-01-01' AND t.pickup_date < '2024-02-01'
GROUP BY t.pickup_date,  R.rate_desc
ORDER BY t.pickup_date, Total_Revenue DESC;

--Congestion surcharge impact
SELECT 
    pickup_date,
    ROUND(SUM(congestion_surcharge), 2) AS total_congestion_surcharge,
    ROUND(SUM(total_amount), 2) AS total_revenue_incl_surcharge,
    ROUND(AVG(congestion_surcharge), 2) AS avg_surcharge_per_trip,
    ROUND(100 * SUM(congestion_surcharge) / SUM(total_amount), 2) AS surcharge_percent_of_revenue,
    COUNT(*) AS trip_count
FROM nyc_taxi_clean
WHERE pickup_date >= '2024-01-01' AND pickup_date < '2024-02-01'
GROUP BY pickup_date
ORDER BY pickup_date;

--Location Analysis (NON-MAP)

--Trips by borough

SELECT
    t.pickup_date,
    z.Borough,z.Zone,
    z.service_zone,
    ROUND(SUM(t.Total_amount), 2) AS Total_Revenue,
    COUNT(*) AS trip_count,
    ROUND(AVG(t.Total_amount), 2) AS Avg_Fare
FROM nyc_taxi_clean AS t
JOIN taxi_zone_lookup z ON z.locationID = t.PULocationID
WHERE t.pickup_date >= '2024-01-01' AND t.pickup_date < '2024-02-01'
GROUP BY t.pickup_date, z.Borough,z.Zone,z.service_zone
ORDER BY t.pickup_date, Total_Revenue DESC;

-- Top 5 Revenue by pickup zone

SELECT Top 5
    z.Zone,z.Borough,
    ROUND(SUM(t.Total_amount), 2) AS Total_Revenue,
    COUNT(*) AS trip_count,
    ROUND(AVG(t.Total_amount), 2) AS Avg_Fare
FROM nyc_taxi_clean AS t
JOIN taxi_zone_lookup z ON z.locationID = t.PULocationID
GROUP BY z.Zone,z.Borough
ORDER BY Total_Revenue DESC;


--Zone-to-zone trip flows
SELECT Top 20
    pu.Zone AS pickup_zone,
    pu.Borough AS pickup_borough,
    do.Zone AS dropoff_zone,
    do.Borough AS dropoff_borough,
    COUNT(*) AS trip_count,
    ROUND(SUM(t.total_amount), 2) AS total_revenue,
    ROUND(AVG(t.total_amount), 2) AS avg_fare
FROM nyc_taxi_clean AS t
JOIN taxi_zone_lookup pu ON pu.locationID = t.PULocationID
JOIN taxi_zone_lookup do ON do.locationID = t.DOLocationID
WHERE t.pickup_date >= '2024-01-01' 
  AND t.pickup_date < '2024-02-01'
GROUP BY pu.Zone, pu.Borough, do.Zone, do.Borough
ORDER BY trip_count DESC
 
-- Operational Insights
--Store-and-forward trips percentage

SELECT 
    ROUND(100.0 * SUM(CASE WHEN store_and_fwd_flag = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_store_and_forward,
    COUNT(*) AS total_trips,
    SUM(CASE WHEN store_and_fwd_flag = 'Y' THEN 1 ELSE 0 END) AS store_and_forward_trips,
    SUM(CASE WHEN store_and_fwd_flag = 'N' THEN 1 ELSE 0 END) AS real_time_trips
FROM nyc_taxi_clean
WHERE pickup_date >= '2024-01-01' 
  AND pickup_date < '2024-02-01';


--Vendor performance comparison
SELECT 
    v.vendor_name,
    ROUND(COALESCE(SUM(t.Total_amount), 0), 2) AS Total_Revenue,
    ROUND(COALESCE(AVG(t.total_amount), 0), 2) AS Avg_Revenue,
    RANK() OVER (ORDER BY AVG(t.total_amount) DESC) AS avg_fare_rank,
    COUNT(*) AS trip_count
FROM nyc_taxi_clean AS t
JOIN dim_vendor v ON v.vendor_id = t.VendorID
WHERE t.pickup_date >= '2024-01-01' AND t.pickup_date < '2024-02-01'
GROUP BY v.vendor_name
ORDER BY  Total_Revenue DESC;

--Cash vs card behavior

SELECT 
    p.payment_desc,
    ROUND(COALESCE(SUM(t.Total_amount), 0), 2) AS Total_Revenue,
    ROUND(COALESCE(AVG(t.total_amount), 0), 2) AS Avg_Revenue,
    RANK() OVER (ORDER BY AVG(t.total_amount) DESC) AS avg_Revenue_rank,
    COUNT(*) AS trip_count
FROM nyc_taxi_clean AS t
JOIN dim_payment_type p ON p.payment_type = t.payment_type
WHERE t.pickup_date >= '2024-01-01' AND t.pickup_date < '2024-02-01'
and  p.payment_desc in ('Cash' ,'Credit Card')
GROUP BY p.payment_desc
ORDER BY Total_Revenue DESC;

--Negative fare investigation
SELECT 
    pickup_date,
    ROUND(SUM(total_amount), 2) AS total_negative_revenue,
    COUNT(*) AS trip_count
FROM nyc_taxi_clean
WHERE pickup_date >= '2024-01-01'
  AND pickup_date < '2024-02-01'
  AND total_amount < 0
GROUP BY pickup_date
ORDER BY pickup_date, total_negative_revenue DESC;

--Negative fare investigation by vendore and payment type

SELECT 
     v.vendor_name,
     p.payment_desc,
    ROUND(SUM(t.total_amount), 2) AS total_negative_revenue,
    COUNT(*) AS trip_count
FROM nyc_taxi_clean t
JOIN dim_vendor v ON v.vendor_id = t.VendorID
JOIN dim_payment_type p ON p.payment_type = t.payment_type
WHERE pickup_date >= '2024-01-01' AND pickup_date < '2024-02-01'
and total_amount < 0
and  p.payment_desc in ('Cash' ,'Credit Card')
GROUP BY v.vendor_name,
         p.payment_desc
ORDER BY total_negative_revenue desc;

-- End of SQL analysis
-- Output tables are used as input for Power BI dashboards




