SET SQL_SAFE_UPDATES=0;
USE md_water_services;

-- Retrieve all tables in the database
SHOW TABLES;

-- The unique sources of water
SELECT 
	DISTINCT type_of_water_source
FROM md_water_services.water_source;	
	
-- Hours in queue greater than 8hours
SELECT *
FROM md_water_services.visits
WHERE 
	time_in_queue > 500;

-- Records of water sources with ridiculous queue time
SELECT *
FROM md_water_services.water_source
WHERE 
	source_id IN ('AkKi00881224','SoRu35083224','HaZa21742224');
    
-- Visit table
SELECT *
FROM md_water_services.water_quality
LIMIT 6;

/*Retrieve water quality data for locations with a subjective quality score of 10
and have been visited 2 times*/
SELECT *
FROM md_water_services.water_quality
WHERE 
	subjective_quality_score = 10
	AND 
	visit_count =2;

-- Well pollution data with wrongly recorded descriptions
SELECT *
FROM well_pollution
WHERE 
	description LIKE 'clean_%';
    
/* Update the well_pollution table in the md_water_services schema
Set the description to 'Bacteria: E. coli' where it was previously `Clean Bacteria: E. coli`*/

UPDATE md_water_services.well_pollution
SET description = 'Bacteria: E. coli'
WHERE description =  'Clean Bacteria: E. coli';

/*Update well_pollution table  in the md_water_services schema
Set the description to'Bacteria: Giardia Lamblia' where it was previousy 'Clean Bacteria: Giardia Lamblia'*/

UPDATE md_water_services.well_pollution
SET description = 'Bacteria: Giardia Lamblia'
WHERE description =  'Clean Bacteria: Giardia Lamblia';

/*Update well_pollution table 
Change result to'Contaminated: Biological' Where biological is >0.01 and results is clean*/

UPDATE md_water_services.well_pollution
SET results = 'Contaminated: Biological'
WHERE biological > 0.01
AND results = 'clean';

-- To Verify the update in the well_pollution table in the md_water_services schema
SELECT *
FROM md_water_services.well_pollution
WHERE 
	description LIKE "Clean_%"
	OR (results = "Clean" AND biological > 0.01);


