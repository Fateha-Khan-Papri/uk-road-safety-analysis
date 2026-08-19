--Analysis Queries

--Q1 — Collisions per year
SELECT 
   collision_year, 
  COUNT(*) AS total_collisions, 
  SUM(number_of_casualties) AS total_casualties 
FROM collisions_clean 
GROUP BY collision_year 
ORDER BY collision_year; 


--Q2 — Fatal vs Serious vs Slight % 
SELECT 
  CASE collision_severity 
       WHEN 1 THEN 'Fatal' 
       WHEN 2 THEN 'Serious' 
       WHEN 3 THEN 'Slight' 
  END AS severity_label, 
  COUNT(*) AS collisions, 
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total 
FROM collisions_clean 
GROUP BY collision_severity 
ORDER BY collision_severity;


--Q3a — Which hour of day has most collisions? 
SELECT 
   EXTRACT(HOUR FROM collision_time) AS hour_of_day, 
   COUNT(*) AS total_collisions 
FROM collisions_clean 
WHERE collision_time IS NOT NULL 
GROUP BY hour_of_day 
ORDER BY total_collisions DESC ;

--Q3b — Deadliest hours vs Busiest hours
SELECT 
    EXTRACT(HOUR FROM collision_time) AS hour_of_day,
    COUNT(*) AS total_collisions,
    SUM(CASE WHEN collision_severity = 1 THEN 1 ELSE 0 END) AS fatal_count,
    ROUND(SUM(CASE WHEN collision_severity = 1 THEN 1.0 ELSE 0 END) 
    / COUNT(*) * 100, 2) AS fatal_pct
FROM collisions_clean
WHERE collision_time IS NOT NULL
GROUP BY hour_of_day
ORDER BY fatal_pct DESC;


--Q4 — Most dangerous road types 
SELECT 
    CASE road_type 
        WHEN 1 THEN 'Roundabout' 
        WHEN 2 THEN 'One way street' 
        WHEN 3 THEN 'Dual carriageway' 
		WHEN 6 THEN 'Single carriageway' 
		WHEN 7 THEN 'Slip road' 
        ELSE 'Other' 
END AS road_type_label, 
COUNT(*) AS total_collisions, 
SUM(CASE WHEN collision_severity = 1 THEN 1 ELSE 0 END) AS fatal_count 
FROM collisions_clean 
GROUP BY road_type 
ORDER BY total_collisions DESC; 



--Q5 — Does weather affect severity? 
SELECT 
    CASE weather_conditions 
        WHEN 1 THEN 'Fine no winds' 
        WHEN 2 THEN 'Raining no winds' 
        WHEN 3 THEN 'Snowing no winds' 
        WHEN 4 THEN 'Fine + winds' 
        WHEN 5 THEN 'Raining + winds' 
        WHEN 6 THEN 'Snowing + winds' 
        WHEN 7 THEN 'Fog or mist' 
        ELSE 'Other/Unknown' 
    END AS weather_label, 
    COUNT(*) AS collisions, 
	ROUND(AVG(CASE WHEN collision_severity = 1 THEN 1.0 ELSE 0 END) * 100, 2) AS fatal_pct 
FROM collisions_clean 
GROUP BY weather_conditions 
ORDER BY fatal_pct DESC;


--Q6 — YoY change in fatal collisions (LAG) 
WITH yearly_fatals AS ( 
    SELECT 
        collision_year, 
        COUNT(*) AS fatal_collisions 
    FROM collisions_clean 
    WHERE collision_severity = 1 
    GROUP BY collision_year 
) 
SELECT 
    collision_year, 
    fatal_collisions, 
    LAG(fatal_collisions) OVER (ORDER BY collision_year) AS prev_year, 
    fatal_collisions - LAG(fatal_collisions) OVER (ORDER BY collision_year) AS yoy_change 
FROM yearly_fatals 
ORDER BY collision_year;


--Q7 — Running total of casualties by year 
WITH yearly AS ( 
    SELECT 
        collision_year, 
        SUM(number_of_casualties) AS casualties_this_year 
    FROM collisions_clean 
    GROUP BY collision_year 
) 
SELECT 
    collision_year, 
    casualties_this_year, 
    SUM(casualties_this_year) OVER (ORDER BY collision_year) AS running_total 
FROM yearly 
ORDER BY collision_year;


--Q8 — Urban vs Rural severity breakdown 
SELECT
    CASE urban_or_rural_area
        WHEN 1 THEN 'Urban'
        WHEN 2 THEN 'Rural'
        ELSE 'Unknown'
    END AS area_type,
    COUNT(*) AS total_collisions,
    SUM(CASE WHEN collision_severity = 1 THEN 1 ELSE 0 END) AS fatal_count,
    SUM(CASE WHEN collision_severity = 2 THEN 1 ELSE 0 END) AS serious_count,
    SUM(CASE WHEN collision_severity = 3 THEN 1 ELSE 0 END) AS slight_count,
    ROUND(AVG(CASE WHEN collision_severity = 1 THEN 1.0 ELSE 0 END) * 100, 2) AS fatal_pct
FROM collisions_clean
GROUP BY urban_or_rural_area;


--Q9 — Light conditions and fatal rate 
SELECT 
    CASE light_conditions 
        WHEN 1 THEN 'Daylight' 
        WHEN 4 THEN 'Dark - street lights on' 
        WHEN 5 THEN 'Dark - no street lights' 
        WHEN 6 THEN 'Dark - lights unlit' 
        ELSE 'Other' 
    END AS light_label, 
    COUNT(*) AS collisions, 
    ROUND(AVG(CASE WHEN collision_severity = 1 THEN 1.0 ELSE 0 END) * 100, 2) AS fatal_pct 
FROM collisions_clean 
GROUP BY light_conditions 
ORDER BY fatal_pct DESC;


--Q10 — Driver age group and collision involvement (JOIN) 
SELECT 
    CASE 
        WHEN v.age_of_driver BETWEEN 17 AND 24 THEN '17-24' 
        WHEN v.age_of_driver BETWEEN 25 AND 34 THEN '25-34' 
        WHEN v.age_of_driver BETWEEN 35 AND 49 THEN '35-49' 
        WHEN v.age_of_driver BETWEEN 50 AND 64 THEN '50-64' 
        WHEN v.age_of_driver >= 65 THEN '65+' 
        ELSE 'Unknown' 
    END AS age_group, 
    COUNT(*) AS vehicle_involvements, 
    SUM(CASE WHEN c.collision_severity = 1 THEN 1 ELSE 0 END) AS in_fatal_collision 
FROM vehicles v 
JOIN collisions_clean c ON v.collision_index = c.collision_index 
WHERE v.age_of_driver > 0 
GROUP BY age_group 
ORDER BY vehicle_involvements DESC; 

 
