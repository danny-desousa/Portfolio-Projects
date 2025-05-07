/* 2022 US Household Income Project Data Cleaning */

SELECT * FROM us_household_income;
SELECT * FROM us_household_income_stats;

---------------------------------------------------------------------------------

-- Rename tables for consistency and readability
RENAME TABLE `ushouseholdincome_stats` TO `us_household_income_stats`;
RENAME TABLE `USHouseholdincome` TO `us_household_income`;


-- Check for missing data
-- Showed MySQL was missing 253 rows
SELECT COUNT(*) FROM us_household_income_stats;
SELECT COUNT(*) FROM us_household_income;


-- Identify duplicate records by 'id'
SELECT id, COUNT(id) AS duplicate_count
FROM us_household_income
GROUP BY id
HAVING COUNT(id) > 1;


-- Delete duplicate rows
DELETE FROM us_household_income
WHERE row_id IN (
    SELECT row_id
    FROM (
        SELECT row_id,
               id,
               ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS row_num
        FROM us_household_income
		 ) 
         AS duplicates
    WHERE row_num > 1
);


-- Correct common typos in State and Type columns
UPDATE us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';

UPDATE us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs';


-- Investigate and fill missing 'Place' values for specific records
-- Example: Fixing mismatched city/place within Autauga County
SELECT *
FROM us_household_income
WHERE County = 'Autauga County'
ORDER BY id;

UPDATE us_household_income
SET Place = 'Autaugaville'
WHERE County = 'Autauga County'
  AND City = 'Vinemont';

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

/* US Household Income Project Exploratory Data Analysis */

SELECT * FROM us_household_income;
SELECT * FROM us_household_income_stats;

---------------------------------------------------------------------------------

-- Average Household Income Ranking by State
SELECT ui.State_Name, 
	ROUND(AVG(Mean), 1) AS Average_Household_Income,  
	RANK() OVER(ORDER BY ROUND(AVG(Mean), 1)DESC) AS Ranking
FROM us_household_income ui
INNER JOIN us_household_income_stats us 
	ON ui.id = us.id
WHERE Mean <> 0
GROUP BY ui.State_Name
ORDER BY 2 DESC
;

-- GEOGRAPHIC INSIGHTS

-- Top 10 Largest States by Land Area
SELECT State_Name,
SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY State_Name
ORDER BY 2 DESC
LIMIT 10
;

-- Top 10 Largest States by Water Area
SELECT State_Name,
SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY State_Name
ORDER BY 3 DESC
LIMIT 10
;

-- CITY DEMOGRAPHICS INSIGHTS

-- Comparing Average Household Incomes by City to the US Average
-- Shows how US city incomes compare to the national average household income
SELECT ui.State_Name, City, ROUND(AVG(Mean), 1) AS Average_Household_Income,
	(
	SELECT ROUND(AVG(Mean), 1) 
	FROM us_household_income_stats
	WHERE Mean <> 0
	) 
    AS National_Average_Income
FROM us_household_income ui
INNER JOIN us_household_income_stats us
	ON ui.id = us.id
WHERE Mean <> 0
GROUP BY ui.State_Name, City
ORDER BY ROUND(AVG(Mean), 1) DESC
;

-- Lowest Average Household Incomes by Cities in the US
SELECT ui.State_Name, City, ROUND(AVG(Mean), 1) AS Average_Household_Income
FROM us_household_income ui
INNER JOIN us_household_income_stats us 
	ON ui.id = us.id
GROUP BY ui.State_Name, City
HAVING ROUND(AVG(Mean), 1) <> 0
ORDER BY ROUND(AVG(Mean), 1) ASC
;

-- Rank of Household Income in Georgia Cities
-- Exploration of cities in my state of residence
SELECT ui.State_Name, 
	City, 
    ROUND(AVG(Mean), 1) AS Average_Household_Income, 
    RANK() OVER(ORDER BY ROUND(AVG(Mean), 1)DESC) As Income_Rank
FROM us_household_income ui
INNER JOIN us_household_income_stats us 
	ON ui.id = us.id
WHERE ui.State_Name = 'Georgia'
GROUP BY ui.State_Name, City
ORDER BY ROUND(AVG(Mean), 1) DESC
;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
