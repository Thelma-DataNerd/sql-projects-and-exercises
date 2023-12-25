SET SQL_SAFE_UPDATES=0;
USE md_water_services;


-- CLEANING THE DATA

-- To retrieve the records in the employee table
SELECT *
FROM md_water_services.employee
LIMIT 2;

-- Adding up the email address of each employee
SELECT 
	CONCAT(
		LOWER(REPLACE(employee_name," ",".")), "@ndogowater.gov") AS New_email
FROM md_water_services.employee;
    
-- Update the newly created email address
UPDATE md_water_services.employee
SET email = CONCAT(LOWER(REPLACE(employee_name," ",".")), "@ndogowater.gov");

-- to view the length of phone numbers, in other to correct/clean them
SELECT 
	LENGTH(phone_number) AS Length_phone_num
FROM employee;

-- Trim the spaces
SELECT 
	TRIM(phone_number) AS New_phone_number
FROM md_water_services.employee;

-- Update the trimmed phone number
UPDATE md_water_services.employee
SET phone_number =TRIM(phone_number);

-- Determing the number of employees in each town.
SELECT 
     town_name, 
     COUNT(town_name) AS num_employees 
FROM md_water_services.employee 
GROUP BY town_name;

-- How many employees live in Harare, Kilimani
SELECT 
	COUNT(*)
FROM employee
WHERE town_name ="Harare"
AND province_name = "Kilimani";


-- HONOURING THE WORKERS 

-- Retrieving the number of record each employee collected
SELECT 
    assigned_employee_id,
    COUNT(visit_count) AS number_of_visits
FROM md_water_services.visits
GROUP BY assigned_employee_id
ORDER BY assigned_employee_id ASC;

-- Employees with the highest number of visits
SELECT 
    assigned_employee_id,
    COUNT(visit_count) AS number_of_visits
FROM md_water_services.visits
GROUP BY assigned_employee_id
ORDER BY COUNT(visit_count) DESC
LIMIT 3;

-- Employees with lowest vist counts
SELECT 
    assigned_employee_id,
    COUNT(visit_count) AS number_of_visits
FROM md_water_services.visits
GROUP BY assigned_employee_id
ORDER BY COUNT(visit_count) ASC
LIMIT 3;

-- Info of our 3 top employees with the highest visit
SELECT 
	employee_name, 
    email, phone_number
FROM md_water_services.employee
WHERE assigned_employee_id IN (1,30,34);

-- Info of the worst employees
SELECT 
	employee_name, 
    email, phone_number
FROM md_water_services.employee
WHERE assigned_employee_id IN (20,22,44);


-- ANALYSING LOCATIONS
SELECT *
FROM location
LIMIT 2;

-- count of records taken  per town
SELECT
    COUNT(town_name) AS records_per_town, town_name
FROM md_water_services.location
GROUP BY town_name; 

-- count of records per province
 SELECT
    COUNT(province_name) AS records_per_province, province_name
FROM md_water_services.location
GROUP BY province_name;    

-- Retrieving both records of province and town 
SELECT 
    province_name, town_name,
    COUNT(*) AS records_per_town
FROM md_water_services.location
GROUP BY province_name, town_name
ORDER BY province_name;
    
-- count of records for each location (Urban and rural)
SELECT
    COUNT(*) AS num_of_sources,
    location_type
FROM md_water_services.location
GROUP BY location_type;

-- Percentage of water sources (rural)
    SELECT 
        ROUND(23740/(15910+23740)*100,2);


-- DIVING INTO SOURCES
-- View of the water source table
SELECT *
FROM md_water_services.water_source
LIMIT 3;

-- Total number of people surveyed in total
SELECT
    SUM(number_of_people_served) AS Total_people_surveyed
FROM md_water_services.water_source;

-- Number of wells, taps and rivers in Maji Ndogo
SELECT 
    COUNT(type_of_water_source) AS Num_of_water_sources,
    type_of_water_source
FROM md_water_services.water_source
GROUP BY type_of_water_source;

-- Number of people that share particular types of water sources on average
SELECT
    type_of_water_source, 
    ROUND(AVG(number_of_people_served),0) AS avg_people_per_source
FROM md_water_services.water_source
GROUP BY type_of_water_source;

-- Total people getting water from each type of source
SELECT
    type_of_water_source, 
    ROUND(SUM(number_of_people_served),0) AS total_people_per_source
FROM md_water_services.water_source
GROUP BY type_of_water_source
ORDER BY  total_people_per_source DESC;
 
 -- Percentage people served per source
 SELECT
  type_of_water_source,
    ROUND((SUM(number_of_people_served)/(SELECT
    SUM(number_of_people_served)
FROM md_water_services.water_source)*100),0)AS percent_served_per_source
FROM md_water_services.water_source
 GROUP BY type_of_water_source
 ORDER BY  percent_served_per_source DESC; 
 
 
 -- START OF A SOLUTION 
 
-- fixing the water source that affects most people
-- first, rank each type of source based on people served
 SELECT
	type_of_water_source, 
    SUM(number_of_people_served) AS total_people_per_served,
      RANK() OVER(ORDER BY SUM(number_of_people_served)DESC) AS population_served
FROM md_water_services.water_source
-- exclude tap_in_home because they already have the best source available
WHERE type_of_water_source <> "tap_in_home"
GROUP BY type_of_water_source;
    
--  Assigning ranks to each source type 
SELECT
	source_id,
    type_of_water_source,
    number_of_people_served,
    RANK () OVER(PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS priority_rank
FROM md_water_services.water_source
WHERE type_of_water_source <> "tap_in_home"
ORDER BY type_of_water_source, priority_rank
LIMIT 10;

-- using dense_rank function to rank
SELECT
	source_id,
    type_of_water_source,
    number_of_people_served,
    DENSE_RANK () OVER(PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS priority_rank
FROM md_water_services.water_source
WHERE type_of_water_source <> "tap_in_home"
ORDER BY type_of_water_source, priority_rank
LIMIT 10;

-- using the row_number function to rank
SELECT
	source_id,
    type_of_water_source,
    number_of_people_served,
    ROW_NUMBER() OVER(PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS priority_rank
FROM md_water_services.water_source
WHERE type_of_water_source <> "tap_in_home"
ORDER BY type_of_water_source, priority_rank
LIMIT 10;


-- ANALYSING QUEUES

-- view of the visit table
SELECT *
FROM md_water_services.visits;

-- How long (days) the survey took
  SELECT
    MIN(time_of_record) AS early_start,
    MAX(time_of_record) AS late_start,
    DATEDIFF( MAX(time_of_record),MIN(time_of_record)) AS Survey_length
FROM md_water_services.visits;
    
-- the average total queue time for water
SELECT 
    ROUND(AVG(NULLIF(time_in_queue,0)),0) AS avg_queue_time
FROM md_water_services.visits;

-- Average queue time on different days of the week.
SELECT
    DAYNAME(time_of_record) AS day_of_week,
  ROUND(AVG(NULLIF(time_in_queue,0)),0)  AS avg_queue_time
FROM md_water_services.visits
GROUP BY day_of_week
ORDER BY day_of_week ASC;

-- The most time (hour) during the day people collect water
SELECT
    TIME_FORMAT(TIME(time_of_record), "%H:00") AS hour_of_day,
     ROUND(AVG(NULLIF(time_in_queue,0)),0) AS avg_queue_time
FROM md_water_services.visits
GROUP BY hour_of_day
ORDER BY hour_of_day ASC;

-- Seperating the avg queue time in each day (pivot table)
SELECT
	TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
-- Sunday
	ROUND(AVG(
		CASE
           WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
		ELSE NULL
     END),0) AS Sunday,
-- Monday
	ROUND(AVG(
		CASE
           WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
		ELSE NULL
        END),0) AS Monday,
-- Tuesday
     ROUND(AVG(
		CASE
           WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
		ELSE NULL
        END),0) AS Tuesday,
-- Wednesday
	 ROUND(AVG(
		CASE
           WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
		ELSE NULL
        END),0) AS Wednesday,
-- Thursday
      ROUND(AVG(
		CASE
           WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
		ELSE NULL
        END),0) AS Thursday,
-- Friday
       ROUND(AVG(
		CASE
           WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
		ELSE NULL
        END),0) AS Friday,
-- Saturday
	ROUND(AVG(
		CASE
           WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
		ELSE NULL
        END),0) AS Saturday
FROM md_water_services.visits
WHERE time_in_queue != 0 -- this excludes other sources with 0 queue times
GROUP BY hour_of_day
ORDER BY hour_of_day;
