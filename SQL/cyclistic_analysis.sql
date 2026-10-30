-- Cyclistic Bike-Share Analysis
-- Author: Emmanuel Atimbire
-- Purpose: Analyse usage patterns
-- between annual members and casual riders.


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

-- exploratory analysis --


-- total number of trips --
SELECT COUNT(*) AS total_trips
FROM clean_combined_trips; 

-- data range -- 

SELECT 
	MIN(started_at) AS first_trip,
	MAX(started_at) AS last_trip
FROM clean_combined_trips

-- rider types --

SELECT 
    member_casual AS membership_type,
    COUNT(*) AS total_rides_by_member,
    SUM(COUNT(*)) OVER () AS total_rides,
    CAST(
        ROUND(
            COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
            2
        ) AS DECIMAL(5,2)
    ) + '%' AS percentage_membership_type
FROM clean_combined_trips
GROUP BY member_casual
ORDER BY member_casual;
-- calculate ride duration --

SELECT
	member_casual,
	COUNT(*) AS total_rides,
	AVG(ride_length) AS average_minutes,
	MIN(ride_length) AS shortest_ride,
	MAX(ride_length) AS longest_ride
FROM clean_combined_trips
GROUP BY member_casual;

-- bike type preference --

SELECT
	member_casual, 
	rideable_type,
	COUNT(*) AS total_rides
FROM clean_combined_trips
GROUP BY 
	member_casual, rideable_type
ORDER BY 
	member_casual, rideable_type DESC;

-- rides by the day of the week --

SELECT
	day_of_the_week,
	member_casual AS type_membership,
	COUNT(*) AS total_rides
FROM clean_combined_trips
GROUP BY day_of_the_week, member_casual
ORDER BY 
	CASE day_of_the_week
	WHEN 'Monday' THEN 1
	WHEN 'Tuesday' THEN 2
	WHEN 'Wednesday' THEN 3
	WHEN 'Thursday' THEN 4
	WHEN 'Friday' THEN 5
	WHEN 'Saturday' THEN 6
	WHEN 'Sunday' THEN 7
	END,
	member_casual;


-- average ride duration by day --

SELECT
	day_of_the_week,
	member_casual AS membership_type,
	AVG(ride_length) AS avg_ride_length
FROM clean_combined_trips
GROUP BY day_of_the_week, member_casual
ORDER BY 
	CASE day_of_the_week
	WHEN 'Monday' THEN 1
	WHEN 'Tuesday' THEN 2
	WHEN 'Wednesday' THEN 3
	WHEN 'Thursday' THEN 4
	WHEN 'Friday' THEN 5
	WHEN 'Saturday' THEN 6
	WHEN 'Sunday' THEN 7
	END;

-- top 10 start stations --

SELECT TOP 10
	start_station_name,
	COUNT(*) AS total_rides
FROM clean_combined_trips
WHERE start_station_name IS NOT NULL
GROUP BY start_station_name
ORDER BY total_rides DESC;

-- top 10 end station --

SELECT TOP 10
	end_station_name,
	COUNT(*) AS total_rides
FROM clean_combined_trips
WHERE end_station_name IS NOT NULL
GROUP BY end_station_name
ORDER BY total_rides DESC;

-- top start station by rider type --

SELECT 
	member_casual,
	start_station_name,
	COUNT(*) AS total_rides
FROM clean_combined_trips
WHERE start_station_name IS NOT NULL
GROUP BY member_casual, start_station_name
ORDER BY member_casual, total_rides DESC;

-- weekend vs weekday usage --

SELECT
	CASE
		WHEN day_of_the_week IN ('saturday', 'sunday') THEN 'weekend' 
			ELSE 'weekday'
		END AS ride_period,
	member_casual,
	COUNT(*) AS total_rides
FROM clean_combined_trips
GROUP BY 
	CASE
		WHEN day_of_the_week IN ('saturday', 'sunday') THEN 'weekend' 
			ELSE 'weekday'
		END,
	member_casual; 

-- ride duration categories --

SELECT 
	CASE
		WHEN ride_length < 10 THEN 'under 10 minutes' 
		WHEN ride_length BETWEEN 10 AND 20 THEN '10-20 minutes'
		WHEN ride_length BETWEEN 21 AND 30 THEN '21-30 minutes'
		WHEN ride_length BETWEEN 31 AND 60 THEN '31_60 minutes'
	ELSE 'over 60 minutes'
	END AS duration_category,
	member_casual,
	COUNT(*) AS total_rides
FROM clean_combined_trips
GROUP BY 
	CASE
		WHEN ride_length < 10 THEN 'under 10 minutes' 
		WHEN ride_length BETWEEN 10 AND 20 THEN '10-20 minutes'
		WHEN ride_length BETWEEN 21 AND 30 THEN '21-30 minutes'
		WHEN ride_length BETWEEN 31 AND 60 THEN '31_60 minutes'
	ELSE 'over 60 minutes'
	END,
	member_casual
ORDER BY duration_category;


-- monthly rides trends --

SELECT 
	ride_month,
	member_casual AS membership_type,
	COUNT(*) AS total_rides
FROM clean_combined_trips
GROUP BY 
	ride_month, member_casual
ORDER BY 
	CASE ride_month
		WHEN 'January' THEN 1
		WHEN 'Febuary' THEN 2
		WHEN 'March' THEN 3
		WHEN 'April' THEN 4
		WHEN 'May' THEN 5
		WHEN 'June' THEN 6
		WHEN 'July' THEN 7
		WHEN 'August' THEN 8
		WHEN 'September' THEN 9
		WHEN 'October' THEN 10
		WHEN 'November' THEN 11
		WHEN 'December' THEN 12
	END;
	
-- peak riding hours --

SELECT 
	ride_hour,
	member_casual AS membership_type,
	COUNT(*) AS total_rides
FROM clean_combined_trips
GROUP BY 
	ride_hour,
	member_casual
ORDER BY
	ride_hour;

	-- total riders --

SELECT 
	member_casual
	COUNT(*) AS total_rides
FROM clean_combined_trips
GROUP BY member_casual;

-- Average ride duration by month (in minutes) --
SELECT
    ride_month,
    member_casual AS membership_type,
    AVG(CAST(ride_length AS FLOAT)) AS average_ride_duration_minutes
FROM clean_combined_trips
GROUP BY
    ride_month,
    member_casual
ORDER BY
    CASE ride_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END,
    member_casual;

	SELECT
    AVG(CAST(ride_length AS FLOAT)) AS average_ride_length_minutes
FROM clean_combined_trips;


SELECT
member_casual,
ROUND(AVG(CAST(ride_length AS FLOAT)),2) AS Avg_Ride_Length
FROM clean_combined_trips
GROUP BY member_casual;

SELECT
    ride_month,
    COUNT(*) AS total_rows
FROM clean_combined_trips
GROUP BY ride_month
ORDER BY
    CASE ride_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END;
-- Check missing values for all important columns by month--

SELECT
    ride_month,
  
    SUM(CASE WHEN ride_id IS NULL THEN 1 ELSE 0 END) AS missing_ride_id,
    SUM(CASE WHEN rideable_type IS NULL THEN 1 ELSE 0 END) AS missing_rideable_type,
    SUM(CASE WHEN started_at IS NULL THEN 1 ELSE 0 END) AS missing_started_at,
    SUM(CASE WHEN ended_at IS NULL THEN 1 ELSE 0 END) AS missing_ended_at,
    SUM(CASE WHEN start_station_name IS NULL THEN 1 ELSE 0 END) AS missing_start_station_name,
    SUM(CASE WHEN start_station_id IS NULL THEN 1 ELSE 0 END) AS missing_start_station_id,
    SUM(CASE WHEN end_station_name IS NULL THEN 1 ELSE 0 END) AS missing_end_station_name,
    SUM(CASE WHEN end_station_id IS NULL THEN 1 ELSE 0 END) AS missing_end_station_id,
    SUM(CASE WHEN start_lat IS NULL THEN 1 ELSE 0 END) AS missing_start_lat,
    SUM(CASE WHEN start_lng IS NULL THEN 1 ELSE 0 END) AS missing_start_lng,
    SUM(CASE WHEN end_lat IS NULL THEN 1 ELSE 0 END) AS missing_end_lat,
    SUM(CASE WHEN end_lng IS NULL THEN 1 ELSE 0 END) AS missing_end_lng,
    SUM(CASE WHEN member_casual IS NULL THEN 1 ELSE 0 END) AS missing_member_casual

FROM clean_combined_trips
GROUP BY ride_month
ORDER BY
    CASE ride_month
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
        WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END;

	
