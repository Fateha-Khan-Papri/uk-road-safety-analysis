--Check for nulls 
SELECT 
    COUNT(*) AS total_rows, 
    COUNT(collision_date) AS has_date, 
    COUNT(collision_time) AS has_time, 
    COUNT(collision_severity) AS has_severity 
FROM collisions; 


--Check severity values 
-- 1 = Fatal, 2 = Serious, 3 = Slight 
SELECT 
    collision_severity, COUNT(*) AS count 
FROM collisions 
GROUP BY collision_severity 
ORDER BY collision_severity; 


--Check date range 
SELECT
    MIN(collision_date), 
	MAX(collision_date) 
FROM collisions;


--Create a clean view  
CREATE VIEW collisions_clean AS 
SELECT * 
FROM collisions 
WHERE 
    collision_date IS NOT NULL 
	AND collision_severity IN (1, 2, 3) 
	AND longitude BETWEEN -8 AND 2  
	AND latitude BETWEEN 49 AND 61;




