USE md_water_services;

-- to view all tables in the md_water_service_database
SHOW TABLES; 

-- Retrieving records from some tables for viewing
SELECT *
FROM visits
LIMIT 2;   

SELECT *
FROM water_quality
LIMIT 2;   

SELECT *
FROM auditor_report
LIMIT 2;        

-- Retrieving specific columns from the "auditors" table for review.
SELECT 
    location_id, 
    true_water_source_score 
FROM auditor_report
LIMIT 10;

-- INTEGRATING THE REPORT

-- Joining both visit and auditors report
SELECT 
    auditor_report.location_id AS audit_location, 
    auditor_report.true_water_source_score,
    visits.location_id AS visit_location, visits.record_id
FROM Auditor_report
JOIN Visits 
ON  auditor_report.location_id = visits.location_id
LIMIT 10;  

--  Retrieve the corresponding scores from the water_quality table
SELECT 
    auditor_report.location_id AS audit_location, 
    auditor_report.true_water_source_score,
    visits.location_id AS visit_location, visits.record_id, 
    water_quality.subjective_quality_score
FROM Auditor_report 
JOIN Visits 
ON  auditor_report.location_id = visits.location_id
JOIN water_quality 
ON visits.record_id = water_quality.record_id;  

-- Clean up
SELECT 
    auditor_report.location_id, visits.record_id, 
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS employee_score
FROM Auditor_report 
JOIN Visits 
ON  auditor_report.location_id = visits.location_id
JOIN water_quality 
ON visits.record_id = water_quality.record_id                                     
LIMIT 10;

-- Retrieving the records where the auditor's and employee's score agrees and visited once
SELECT 
    auditor_report.location_id, visits.record_id,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS employee_score
FROM Auditor_report 
JOIN Visits 
ON  auditor_report.location_id = visits.location_id
JOIN water_quality 
ON visits.record_id = water_quality.record_id 
WHERE auditor_report.true_water_source_score = water_quality.subjective_quality_score
AND visits.visit_count = 1; 

-- Records where auditor's and employees' scores disagrees (incorrect records)
SELECT 
    auditor_report.location_id, visits.record_id,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS employee_score
FROM Auditor_report 
JOIN Visits 
ON  auditor_report.location_id = visits.location_id
JOIN water_quality 
ON visits.record_id = water_quality.record_id 
WHERE auditor_report.true_water_source_score != water_quality.subjective_quality_score
AND visits.visit_count = 1; 

-- LINKING RECORDS TO EMPLOYEES

/*By tracing the records back to the employees, 
we observe that they are the source of the errors*/
SELECT 
    visits.location_id, visits.record_id, 
    employee.assigned_employee_id,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS employee_score
FROM employee 
JOIN visits 
ON employee.assigned_employee_id = visits.assigned_employee_id                     
JOIN auditor_report 
ON auditor_report.location_id = visits.location_id
JOIN water_quality 
ON water_quality.record_id = visits.record_id
WHERE auditor_report.true_water_source_score != water_quality.subjective_quality_score
AND visits.visit_count = 1
ORDER BY 5 DESC;

-- Linking the incorrect records to employees who recorded them. 
WITH incorrect_records (location_id, record_id, employee_name, auditor_score,employee_score) AS 
				(SELECT 
				auditor_report.location_id, visits.record_id,
				employee.employee_name,
				auditor_report.true_water_source_score AS auditor_score,
				water_quality.subjective_quality_score AS employee_score
				FROM auditor_report 
				JOIN visits 
				ON auditor_report.location_id = visits.location_id   
				JOIN water_quality 
				ON water_quality.record_id = visits.record_id
				JOIN employee 
				ON employee.assigned_employee_id = visits.assigned_employee_id                       
				WHERE auditor_report.true_water_source_score != water_quality.subjective_quality_score
			   AND visits.visit_count = 1)
SELECT *
FROM incorrect_records;

-- Unique list of employee names

SELECT DISTINCT
	employee_name
FROM incorrect_records;

-- Number of mistake each employee made
SELECT 
    employee_name,
    count(*) AS number_of_mistakes
FROM incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes DESC;


-- GATHERING SOME EVIDENCE

-- average number of mistakes employees made
WITH Error_count (employee_name, number_of_mistakes) AS                       
                    (SELECT 
                    employee_name,
                    count(employee_name) AS number_of_mistakes
                FROM incorrect_records
                GROUP BY employee_name
                ORDER BY number_of_mistakes DESC)
SELECT
    avg(number_of_mistakes) AS avg_error_count_per_emp1                              
FROM error_count;

-- Employees who made more mistakes than the average person
WITH Error_count (employee_name, number_of_mistakes) AS                
                    (SELECT 
                    employee_name,
                    count(employee_name) AS number_of_mistakes
                FROM incorrect_records
                GROUP BY employee_name
                ORDER BY number_of_mistakes DESC)
SELECT
    employee_name,
    number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT
                    AVG( number_of_mistakes) AS avg_error_count_per_emp1
                        FROM error_count );

/*Converting to a VIEW. 
We can then use it as if it was a table, and this will make our code much simpler to read*/       
                
CREATE VIEW Incorrect_records AS (
      SELECT 
        auditor_report.location_id, visits.record_id,
        employee.employee_name,
        auditor_report.true_water_source_score AS auditor_score,
        water_quality.subjective_quality_score AS employee_score,
        auditor_report.statements AS statements
        FROM auditor_report 
        JOIN visits 
        ON auditor_report.location_id = visits.location_id   
        JOIN water_quality 
        ON water_quality.record_id = visits.record_id
        JOIN employee 
        ON employee.assigned_employee_id = visits.assigned_employee_id 
        WHERE visits.visit_count =1
		AND auditor_report.true_water_source_score <> water_quality.subjective_quality_score);	
         
--  Retrieving records from view created (incorrect table)
SELECT *                         
FROM Incorrect_records;
 
 -- Names of suspect
 WITH Error_count (employee_name, number_of_mistakes) AS
                    (SELECT 
                    employee_name, count(employee_name) AS number_of_mistakes
                FROM incorrect_records
                GROUP BY employee_name
                ORDER BY number_of_mistakes DESC),
    
Suspect_list (employee_name, number_above_average) AS
                    (SELECT employee_name, number_of_mistakes
                    FROM error_count
                    WHERE number_of_mistakes > (SELECT
                                        AVG( number_of_mistakes) AS avg_error_count_per_emp1
                                            FROM error_count ))
SELECT employee_name            
FROM suspect_list;        
         
-- Records of the names of employees in the suspect list
SELECT *
FROM Incorrect_records
WHERE employee_name IN ("Bello Azibo", "Malachi Mavuso","Zuriel Matembo","Lalitha Kaburi");   

-- To retrieve the names of employees indicted for bribery
SELECT *
FROM Incorrect_records
WHERE employee_name NOT IN ("Bello Azibo", "Malachi Mavuso","Zuriel Matembo","Lalitha Kaburi")
AND statements LIKE "%cash%";     
 



