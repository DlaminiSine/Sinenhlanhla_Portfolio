-- Create the table that will house all the data from the other tables

CREATE TABLE  cyclistics_bike_share_data (
    ride_id            VARCHAR (255),
    bike_type          VARCHAR (50),
    started_at         TIMESTAMP,
    ended_at           TIMESTAMP,
    start_station_name VARCHAR (255),
    start_station_id   VARCHAR(255),
    end_station_name   VARCHAR (255),
    end_station_id     VARCHAR(255),
    start_lat          FLOAT,
    start_lng          FLOAT,
    end_lat            FLOAT,
    end_lng            FLOAT,
    membership_type    VARCHAR (255),
    ride_length        INT
);

-- Add the data from the other tables into the  table

INSERT INTO cyclistics_bike_share_data 
    (ride_id, 
    bike_type, 
    started_at, 
    ended_at, 
    start_station_name, 
    start_station_id, 
    end_station_name, 
    end_station_id, 
    start_lat, 
    start_lng, 
    end_lat, 
    end_lng, 
    membership_type)
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Oct2021
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Nov2021
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Dec2021
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Jan2022
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Feb2022
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Mar2022
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Apr2022
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM May2022
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Jun2022
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Jul2022
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Aug2022
UNION ALL
SELECT 
    ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, start_lat, start_lng, end_lat, end_lng,  member_casual
FROM Sep2022;

-- Add a new column that calculates the ride length 

UPDATE cyclistics_bike_share_data
SET ride_length = DATE_PART('hour', ended_at::time - started_at::time) * 60 + DATE_PART('minute', ended_at::time - started_at::time);

-- Removing any rows with missing data or whitespace values

DELETE FROM  cyclistics_bike_share_data
WHERE start_station_name IS NULL OR trim(start_station_name) = ''
OR end_station_name IS NULL OR trim(end_station_name) = '' ;

-- Delete rows that have ended_at < started_at or rows that have ride length <= 0 also deleting rows with ride legths over a day

DELETE FROM cyclistics_bike_share_data
WHERE ride_id IS NULL OR
start_station_name IS NULL OR 
ride_length IS NULL OR 
ride_length = 0 OR 
ride_length < 0;

DELETE FROM cyclistics_bike_share_data
WHERE ride_length > 1440 ;


SELECT DISTINCT(ride_id) AS unique_id, bike_type, started_at, ended_at, ride_length, start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, membership_type
FROM cyclistics_bike_share_data;

-- Extract the day of the week from each started_at column because I now know that each rider rode the bike within the 24 hour time span, making it a one day trip, just differing ride lengths
-- Also, I want to extract the month and the year from each datetime column

ALTER TABLE cyclistics_bike_share_data
ADD COLUMN weekday_of_ride VARCHAR(50),
	ADD COLUMN ride_month VARCHAR(50),
   	ADD COLUMN ride_year VARCHAR(50);

UPDATE cyclistics_bike_share_data
SET weekday_of_ride = DATE_PART('DAY', started_at),
    ride_month = DATE_PART('MONTH', started_at),
    ride_year = DATE_PART('YEAR', started_at);

alter table cyclistics_bike_share_data 
add column day_of_the_week VARCHAR(50)

update cyclistics_bike_share_data 
set day_of_the_week = EXTRACT(dow from started_at::timestamp);


SELECT started_at, weekday_of_ride, ride_month, ride_year, day_of_the_week
FROM cyclistics_bike_share_data
LIMIT 10;

ALTER TABLE cyclistics_bike_share_data
ADD COLUMN num_of_mon INT,
    ADD COLUMN date_of_the_ride DATE;

UPDATE cyclistics_bike_share_data
SET num_of_mon = DATE_PART('MONTH', started_at),
    date_of_the_ride = CAST(started_at as DATE);

SELECT COUNT(DISTINCT(ride_id)) AS total_unique_ids, COUNT(ride_id) AS total_ids
FROM cyclistics_bike_share_data;

SELECT *
FROM cyclistics_bike_share_data;
 
 -- Creating a couple of views that will be used in future visualizations

CREATE View number_of_riders_per_day AS
SELECT 
    COUNT(CASE WHEN membership_type = 'member' THEN 1 ELSE NULL END) AS num_of_member_riders,
    COUNT(CASE WHEN membership_type = 'casual' THEN 1 ELSE NULL END) AS num_of_casual_riders,
    COUNT(*) as num_of_riders,
    weekday_of_ride AS day_of_the_week
FROM cyclistics_bike_share_data
GROUP BY weekday_of_ride; 

CREATE VIEW average_ride_length AS 
SELECT membership_type AS rider_type, AVG(ride_length) AS average_ride_length
FROM cyclistics_bike_share_data
GROUP BY membership_type;


SELECT *
FROM number_of_riders_per_day
ORDER BY day_of_the_week;

SELECT *
FROM average_ride_length;

--Create two temporary tables that will separate the casual riders and the member riders


SELECT *
into temp table member_riders
FROM cyclistics_bike_share_data
WHERE membership_type = 'member';

select *
from member_riders;

SELECT *
INTO temp table casual_riders
FROM cyclistics_bike_share_data
WHERE membership_type = 'casual';

select *
from casual_riders;

--Calculating the average ride length

SELECT AVG(ride_length) AS average_ride_length, weekday_of_ride AS day_of_the_week
FROM member_riders
GROUP BY weekday_of_ride
ORDER BY average_ride_length;

SELECT AVG(ride_length) AS average_ride_length, ride_month AS Month
FROM member_riders
GROUP BY ride_month
ORDER BY average_ride_length;

SELECT AVG(ride_length) AS average_ride_length, ride_year AS Year
FROM member_riders
GROUP BY ride_year
ORDER BY average_ride_length;

SELECT AVG(ride_length) AS average_ride_length, weekday_of_ride AS day_of_the_week
FROM casual_riders
GROUP BY weekday_of_ride
ORDER BY average_ride_length;

SELECT AVG(ride_length) AS average_ride_length, ride_month AS Month
FROM casual_riders
GROUP BY ride_month
ORDER BY average_ride_length;

SELECT AVG(ride_length) AS average_ride_length, ride_year AS Year
FROM casual_riders
GROUP BY ride_year
ORDER BY average_ride_length;

SELECT num_of_mon,
    ride_month,
    ride_year,
    COUNT(CASE WHEN membership_type = 'member' THEN 1 ELSE NULL END) as num_of_member_riders,
    COUNT(CASE WHEN membership_type = 'casual' THEN 1 ELSE NULL END) as num_of_casual_riders,
    COUNT(membership_type) AS total_num_of_users
FROM cyclistics_bike_share_data
GROUP BY ride_year, ride_month, num_of_mon
ORDER BY ride_year, ride_month, num_of_mon;

SELECT (CASE
            WHEN day_of_the_week = '0' THEN 'Sunday'
            WHEN day_of_the_week = '1' THEN 'Monday'
            WHEN day_of_the_week = '2' THEN 'Tuesday'
            WHEN day_of_the_week = '3' THEN 'Wednesday'
            WHEN day_of_the_week = '4' THEN 'Thursday'
            WHEN day_of_the_week = '5' THEN 'Friday'
            WHEN day_of_the_week = '6' THEN 'Saturday'
            END) ,
    COUNT(CASE WHEN membership_type = 'member' THEN 1 ELSE NULL END) AS number_of_member_riders,
    COUNT(CASE WHEN membership_type = 'casual' THEN 1 ELSE NULL END) AS number_of_casual_riders,
    COUNT(*) AS number_of_users
FROM cyclistics_bike_share_data
GROUP BY day_of_the_week 
ORDER BY day_of_the_week ;

-- including  the start latitude and longitude to build a map in my visualization on tableau
SELECT start_station_name, start_lat, start_lng, COUNT(CASE WHEN membership_type = 'casual' THEN 1 ELSE NULL END) AS number_of_casual_riders
FROM cyclistics_bike_share_data
GROUP BY start_station_name, start_lat, start_lng
ORDER BY number_of_casual_riders DESC
LIMIT 20;

-- This is the end of my sql analysis.Moving on to visualization and report building
