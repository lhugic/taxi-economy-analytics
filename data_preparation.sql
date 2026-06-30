-- 1. Создание очищенной витрины данных
CREATE TABLE yellow_tripdata_clean AS
SELECT
    "VendorID",
    passenger_count,
    trip_distance,
    "RatecodeID",
    store_and_fwd_flag,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    -- приводим строковые даты к timestamp
    tpep_pickup_datetime::timestamp AS pickup_datetime,
    tpep_dropoff_datetime::timestamp AS dropoff_datetime,
    -- считаем длительность поездки в минутах
    EXTRACT(EPOCH FROM (tpep_dropoff_datetime::timestamp - tpep_pickup_datetime::timestamp)) / 60 AS trip_duration_minutes,
    -- извлекаем час посадки (0-23)
    EXTRACT(HOUR FROM tpep_pickup_datetime::timestamp) AS pickup_hour,
    -- извлекаем день недели (1-Пн, 7-Вс)
    EXTRACT(ISODOW FROM tpep_pickup_datetime::timestamp) AS pickup_day_of_week
FROM yellow_tripdata
-- избавляемся от аномалий и ошибок
WHERE
    passenger_count > 0
    AND trip_distance > 0
    AND trip_distance < 100
    AND total_amount > 0
    AND tpep_dropoff_datetime::timestamp > tpep_pickup_datetime::timestamp;

-- 2. Выгрузка случайного сэмпла для анализа в python
SELECT *
FROM yellow_tripdata_clean
ORDER BY random()
LIMIT 500000;

-- 3. Создание витрины для дашборда
SELECT
    pickup_datetime::date AS trip_date,
    pickup_day_of_week,
    pickup_hour,
    CASE
        WHEN payment_type = 1 THEN 'Credit Card'
        WHEN payment_type = 2 THEN 'Cash'
        ELSE 'Other'
    END AS payment_method,
    COUNT(*) AS trips_count,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue,
    ROUND(SUM(trip_distance)::numeric, 2) AS total_distance
FROM yellow_tripdata_clean
GROUP BY trip_date, pickup_day_of_week, pickup_hour, payment_method
ORDER BY trip_date, pickup_hour;