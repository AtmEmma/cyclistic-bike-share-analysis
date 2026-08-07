
-- Data Cleaning in SSMS
-- Source table: combined_trips (built via UNION ALL of the 12 monthly tables)



--  Check for missing/incomplete values
-- (IS NULL for missing values, LEN() to catch blank/incomplete strings)

SELECT
    SUM(CASE WHEN ride_id IS NULL OR LEN(ride_id) = 0 THEN 1 ELSE 0 END)                       AS missing_ride_id,
    SUM(CASE WHEN rideable_type IS NULL OR LEN(rideable_type) = 0 THEN 1 ELSE 0 END)           AS missing_rideable_type,
    SUM(CASE WHEN started_at IS NULL THEN 1 ELSE 0 END)                                        AS missing_started_at,
    SUM(CASE WHEN ended_at IS NULL THEN 1 ELSE 0 END)                                          AS missing_ended_at,
    SUM(CASE WHEN start_station_name IS NULL OR LEN(start_station_name) = 0 THEN 1 ELSE 0 END) AS missing_start_station_name,
    SUM(CASE WHEN start_station_id IS NULL OR LEN(start_station_id) = 0 THEN 1 ELSE 0 END)     AS missing_start_station_id,
    SUM(CASE WHEN end_station_name IS NULL OR LEN(end_station_name) = 0 THEN 1 ELSE 0 END)     AS missing_end_station_name,
    SUM(CASE WHEN end_station_id IS NULL OR LEN(end_station_id) = 0 THEN 1 ELSE 0 END)         AS missing_end_station_id,
    SUM(CASE WHEN start_lat IS NULL THEN 1 ELSE 0 END)                                         AS missing_start_lat,
    SUM(CASE WHEN start_lng IS NULL THEN 1 ELSE 0 END)                                         AS missing_start_lng,
    SUM(CASE WHEN end_lat IS NULL THEN 1 ELSE 0 END)                                           AS missing_end_lat,
    SUM(CASE WHEN end_lng IS NULL THEN 1 ELSE 0 END)                                           AS missing_end_lng,
    SUM(CASE WHEN member_casual IS NULL OR LEN(member_casual) = 0 THEN 1 ELSE 0 END)           AS missing_member_casual
FROM combined_trips;


-- Remove rows with missing station data
-- (start_station_name, start_station_id, end_station_name, end_station_id
--  had a sizable number of missing values per the Prepare step)

DELETE FROM combined_trips
WHERE start_station_name IS NULL OR LEN(start_station_name) = 0
   OR start_station_id   IS NULL OR LEN(start_station_id)   = 0
   OR end_station_name   IS NULL OR LEN(end_station_name)   = 0
   OR end_station_id     IS NULL OR LEN(end_station_id)     = 0;


--  Check for duplicate ride_id values

SELECT ride_id, COUNT(*) AS occurrences
FROM combined_trips
GROUP BY ride_id
HAVING COUNT(*) > 1;


--  Validate categorical columns
-- (rideable_type should only be electric_bike / classic_bike,
--  member_casual should only be member / casual)

SELECT DISTINCT rideable_type FROM combined_trips;
SELECT DISTINCT member_casual FROM combined_trips;


--  Build clean_combined_trips with new calculated columns
-- (month, day of week, hour, and ride duration in minutes)
-- Outliers removed: rides < 1 minute or > 1440 minutes (24 hours)


IF OBJECT_ID('dbo.clean_combined_trips', 'U') IS NOT NULL
    DROP TABLE dbo.clean_combined_trips;

SELECT
    *,
    DATENAME(MONTH, started_at)                AS ride_month,
    DATENAME(WEEKDAY, started_at)              AS day_of_the_week,
    DATEPART(HOUR, started_at)                 AS ride_hour,
    DATEDIFF(MINUTE, started_at, ended_at)     AS ride_length
INTO clean_combined_trips
FROM combined_trips
WHERE DATEDIFF(MINUTE, started_at, ended_at) >= 1
  AND DATEDIFF(MINUTE, started_at, ended_at) <= 1440;


--  Post-clean validation

SELECT COUNT(*) AS clean_combined_trips_row_count FROM clean_combined_trips;

SELECT MIN(ride_length) AS min_ride_length,
       MAX(ride_length) AS max_ride_length,
       AVG(ride_length) AS avg_ride_length
FROM clean_combined_trips;

SELECT DISTINCT ride_month FROM clean_combined_trips;
SELECT DISTINCT day_of_the_week FROM clean_combined_trips;
