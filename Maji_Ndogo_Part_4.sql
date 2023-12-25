USE md_water_services;

SHOW TABLES;

-- Joining pieces together for analysis purposes
-- location and visit table
SELECT 
    location.province_name, location.town_name, 
    visits.visit_count,
    location.location_Id
FROM location                                               
JOIN visits
ON location.location_Id = visits.location_Id
LIMIT 8;

-- joinig visit, location and water source table
SELECT 
    location.province_name, location.town_name, visits.visit_count,
    location.location_Id, water_source.type_of_water_source, 
    water_source.number_of_people_served
FROM location                                                  
JOIN visits 
ON location.location_Id = visits.location_Id
JOIN water_source 
ON visits.source_Id = water_source.source_Id
WHERE visits.visit_count = 1
LIMIT 10;

-- joining the well pollution data

SELECT
    water_source.type_of_water_source,
    location.town_name, location.province_name,
    location.location_type, water_source.number_of_people_served,
    visits.time_in_queue, well_pollution.results
FROM visits 
LEFT JOIN well_pollution 
ON well_pollution.source_id = visits.source_id        
JOIN location 
ON location.location_id = visits.location_id
JOIN water_source 
ON water_source.source_id = visits.source_id
WHERE visits.visit_count = 1
LIMIT 20;

-- Ceate View to simplify analysis
CREATE VIEW combined_analysis_table AS
(SELECT
    water_source.type_of_water_source AS source_type,    
    location.town_name,
    location.province_name,        
    location.location_type,
    water_source.number_of_people_served AS people_served,
    visits.time_in_queue,
    well_pollution.results
FROM visits 
LEFT JOIN well_pollution                           
ON well_pollution.source_id = visits.source_id                
JOIN location 
ON location.location_id = visits.location_id
JOIN water_source 
ON water_source.source_id = visits.source_id
WHERE visits.visit_count = 1);

-- THE LAST ANALYSIS   
-- Pivot table
WITH province_totals AS (                                        -- This CTE calculates the population of each province
			SELECT                                                           
            province_name,
            SUM(people_served) AS total_ppl_serv
            FROM combined_analysis_table        -- These case statements create columns for each type of source.
		    GROUP BY province_name         
)
SELECT
    combined_analysis_table.province_name,                                                                         
        ROUND((SUM(CASE WHEN source_type = 'river'
    THEN people_served ELSE 0 END) * 100.0 / province_totals.total_ppl_serv), 0) AS river,
        ROUND((SUM(CASE WHEN source_type = 'shared_tap'
    THEN people_served ELSE 0 END) * 100.0 / province_totals.total_ppl_serv), 0) AS shared_tap,
        ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
    THEN people_served ELSE 0 END) * 100.0 / province_totals.total_ppl_serv), 0) AS tap_in_home,
        ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
    THEN people_served ELSE 0 END) * 100.0 / province_totals.total_ppl_serv), 0) AS tap_in_home_broken,
        ROUND((SUM(CASE WHEN source_type = 'well'
    THEN people_served ELSE 0 END) * 100.0 /province_totals.total_ppl_serv), 0) AS well
FROM combined_analysis_table 
JOIN  province_totals
ON combined_analysis_table.province_name = province_totals.province_name                                                                                                                                                                                                                                                             
GROUP BY combined_analysis_table.province_name
ORDER BY combined_analysis_table.province_name;                                                                                               
                                                                                                
-- Total number of people served by province
WITH province_totals AS (                                        
		SELECT                                                           
		 province_name, SUM(people_served) AS total_ppl_serv
		FROM combined_analysis_table                     
		GROUP BY province_name)
SELECT *
FROM province_totals;                    

-- Population of people served by town
 SELECT                                                               
    province_name, town_name, SUM(people_served) AS total_ppl_serv         
FROM combined_analysis_table
GROUP BY province_name,town_name;   
                                 
-- Pivot table of population served by province and town
WITH town_totals AS (                                                                     
                SELECT                                                               
                province_name, town_name, SUM(people_served) AS total_ppl_serv         
                FROM combined_analysis_table
                GROUP BY province_name,town_name                                                
)                                                                                    
SELECT                                                                                     
    combined_analysis_table.province_name,
    combined_analysis_table.town_name,
     ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
    THEN people_served ELSE 0 END) * 100.0 / town_totals.total_ppl_serv), 0) AS tap_in_home,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
    THEN people_served ELSE 0 END) * 100.0 / town_totals.total_ppl_serv), 0) AS tap_in_home_broken,
    ROUND((SUM(CASE WHEN source_type = 'shared_tap'
    THEN people_served ELSE 0 END) * 100.0 / town_totals.total_ppl_serv), 0) AS shared_tap,
    ROUND((SUM(CASE WHEN source_type = 'well'                                                        
    THEN people_served ELSE 0 END) * 100.0 / town_totals.total_ppl_serv), 0) AS well,                              
    ROUND((SUM(CASE WHEN source_type = 'river'
    THEN people_served ELSE 0 END) * 100.0 / town_totals.total_ppl_serv), 0) AS river
FROM combined_analysis_table 
JOIN town_totals  
ON combined_analysis_table.province_name = town_totals.province_name 
AND combined_analysis_table.town_name = town_totals.town_name
GROUP BY combined_analysis_table.province_name,combined_analysis_table.town_name
ORDER BY combined_analysis_table.province_name;

-- Create temporary table
DROP TABLE IF EXISTS town_aggregated_water_access;

CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (                                                                     
                SELECT                                                               
                province_name, town_name, SUM(people_served) AS total_ppl_serv         
                FROM combined_analysis_table
                GROUP BY province_name,town_name                                                
)                                                                                    
SELECT                                                                                     
    combined_analysis_table.province_name,
    combined_analysis_table.town_name,
       ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
    THEN people_served ELSE 0 END) * 100.0 / town_totals.total_ppl_serv), 0) AS tap_in_home,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
    THEN people_served ELSE 0 END) * 100.0 /town_totals.total_ppl_serv), 0) AS tap_in_home_broken,
    ROUND((SUM(CASE WHEN source_type = 'shared_tap'
    THEN people_served ELSE 0 END) * 100.0 / town_totals.total_ppl_serv), 0) AS shared_tap,
    ROUND((SUM(CASE WHEN source_type = 'well'                                                        
    THEN people_served ELSE 0 END) * 100.0 /town_totals.total_ppl_serv), 0) AS well,                              
    ROUND((SUM(CASE WHEN source_type = 'river'
    THEN people_served ELSE 0 END) * 100.0 / town_totals.total_ppl_serv), 0) AS river                              
FROM combined_analysis_table 
JOIN town_totals 
ON combined_analysis_table.province_name = town_totals.province_name 
AND combined_analysis_table.town_name = town_totals.town_name
GROUP BY combined_analysis_table.province_name, combined_analysis_table.town_name
ORDER BY combined_analysis_table.province_name;

-- Retrieving the records of newly created table 
SELECT *
FROM town_aggregated_water_access;

-- -- Percent of people who have taps, but have no running water
SELECT
    province_name, town_name,
    ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100,0) AS Pct_broken_taps
FROM town_aggregated_water_access;

-- Create table
DROP TABLE IF EXISTS project_progress;

CREATE TABLE Project_progress (
    Project_id SERIAL PRIMARY KEY,
    source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
    Address VARCHAR(50),
    Town VARCHAR(30),
    Province VARCHAR(30),
    Source_type VARCHAR(50),
    Improvement VARCHAR(50),
    Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
    Date_of_completion DATE,
    Comments TEXT
);

-- Project progress query
SELECT
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    well_pollution.results,
    CASE
        WHEN water_source.type_of_water_source = 'River' THEN 'Drill well'
			WHEN water_source.type_of_water_source = 'Well' AND well_pollution.results LIKE '%Contaminated: Chemical%' THEN 'Install RO filter'
				WHEN water_source.type_of_water_source = 'Well' AND well_pollution.results LIKE '%Contaminated: Biological%' THEN 'Install UV and RO filter'
					WHEN water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30 THEN 'Install ' || FLOOR(visits.time_in_queue / 30) || ' taps nearby'
						WHEN water_source.type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
        ELSE 'No improvement specified'
    END AS Improvement
FROM water_source
LEFT JOIN well_pollution 
ON water_source.source_id = well_pollution.source_id
INNER JOIN visits 
ON water_source.source_id = visits.source_id
INNER JOIN location 
ON location.location_id = visits.location_id
WHERE(
     (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30) 
        OR (water_source.type_of_water_source = 'River') 
        OR (water_source.type_of_water_source = 'Well' AND well_pollution.results NOT LIKE 'Clean%') 
        OR (water_source.type_of_water_source = 'tap_in_home_broken')
)
AND visits.visit_count = 1
LIMIT 50;

-- Insert into the newly created progress table report
INSERT INTO Project_progress (source_id,Address,Town,Province,Source_type,Improvement,
                              Source_status,Date_of_completion,Comments)
SELECT 
    water_source.source_id,
    location.address,
    location.town_name,
    location.province_name,
    water_source.type_of_water_source,
     CASE
        WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
			WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
				WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'
					WHEN water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue > 30 THEN CONCAT('Install ', FLOOR(visits.time_in_queue / 30), ' taps nearby')
						WHEN water_source.type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose infrastructure'
        ELSE NULL
    END,
   'In progress',            
    current_date(),                
    'null'
FROM water_source
LEFT JOIN well_pollution 
ON water_source.source_id = well_pollution.source_id
INNER JOIN visits 
ON water_source.source_id = visits.source_id
INNER JOIN location 
ON location.location_id = visits.location_id
WHERE(
        (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30) 
        OR (water_source.type_of_water_source = 'River') 
        OR (water_source.type_of_water_source = 'Well' AND well_pollution.results NOT LIKE 'Clean%') 
        OR (water_source.type_of_water_source = 'tap_in_home_broken')
    )
AND visits.visit_count = 1;

-- Retrieve records from project progress table
SELECT *
FROM Project_progress
LIMIT 3;

-- Number of UV filters to install in total
SELECT 
	COUNT(improvement)
FROM Project_progress
WHERE 
	Improvement LIKE "%Install UV and RO filter%";   
    