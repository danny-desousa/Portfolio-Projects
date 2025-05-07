-- This project was based on a guided SQL project by Alex the Analyst
-- The analysis covers life expectancy data and uses SQL for data cleaning and analysis.
-- This project helped me develop foundational skills in data cleaning, querying, and summarization.

/* World Life Expectancy Data Cleaning */

SELECT * FROM world_life_expectancy;

---------------------------------------------------------------------------------

-- Identify duplicate records based on Country-Year combinations
SELECT Country, Year, CONCAT(Country, Year), COUNT(CONCAT(Country,Year))
FROM world_life_expectancy
GROUP BY Country, Year, CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country,Year)) > 1
ORDER BY Country
;

-- Flag duplicate rows beyond the first occurrence for each Country-Year then use ROW_NUMBER() to select which to remove
SELECT *
FROM (
SELECT Row_ID,
CONCAT(Country, Year),
ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
FROM world_life_expectancy
) AS Row_Table
WHERE Row_Num > 1
;

-- Delete all but the first instance of each duplicate Country-Year combination
DELETE FROM world_life_expectancy
WHERE
	Row_ID IN (
	SELECT Row_ID
FROM (
	SELECT Row_ID,
	CONCAT(Country, Year),
	ROW_NUMBER() OVER( PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
	FROM world_life_expectancy
	) AS Row_Table
WHERE Row_Num > 1
)
;

-- Identify rows where the Status field is missing or empty
SELECT * 
FROM world_life_expectancy
WHERE Status = ''
;

-- View all unique non-empty Status values

SELECT DISTINCT(Status)
FROM world_life_expectancy
WHERE Status <> ''
;

-- Identify countries already labeled as 'Developing' for use in imputation
SELECT DISCTINCT(Country)
FROM world_life_expectancy
WHERE Status = 'Developing'
;

-- Fill in missing Status values as 'Developing' if other rows for the same country are labeled 'Developing'
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status ='Developing'
;

-- Fill in missing Status values as 'Developed' if other rows for the same country are labeled 'Developed'

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status ='Developed'
;

-- Preview rows with missing Lifeexpectancy and show estimated value based on the average of the previous and next year for the same country
SELECT t1.Country, t1.Year, t1.`Lifeexpectancy`, 
t2.Country, t2.Year, t2.`Lifeexpectancy`,
t3.Country, t3.Year, t3.`Lifeexpectancy`,
ROUND((t2.`Lifeexpectancy` + t3.`Lifeexpectancy`)/ 2, 1)
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
	AND t1.Year = t3.Year + 1
WHERE t1.`Lifeexpectancy` = ''
    ;

-- Fill missing Lifeexpectancy values by averaging the previous and next year’s values for the same country
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
	AND t1.Year = t3.Year + 1
SET t1.`Lifeexpectancy` = ROUND((t2.`Lifeexpectancy` + t3.`Lifeexpectancy`)/ 2, 1)
WHERE t1.`Lifeexpectancy` = ''
;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

/* World Life Expectancy Exploratory Data Analysis */

SELECT * FROM world_life_expectancy;

---------------------------------------------------------------------------------

-- Minimum and Maximum Life Expectancy by Country (2007-2022)
SELECT Country, MIN(`Life_expectancy`), MAX(`Life_expectancy`)
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life_expectancy`) <> 0
AND MAX(`Life_expectancy`) <> 0
ORDER BY Country DESC
;

-- Life expectancy Change Over 15 Years
-- Shows how the difference in life expectancy from 15 years ago to today.
SELECT Country, MIN(`Life_expectancy`),
MAX(`Life_expectancy`), 
ROUND(MAX(`Life_expectancy`) - MIN(`Life_expectancy`), 1) as Life_Increase_15_Years
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life_expectancy`) <> 0
AND MAX(`Life_expectancy`) <> 0
ORDER BY Life_Increase_15_Years ASC
;

-- Average Life Expectancy by Year
SELECT Year, ROUND(AVG(`Life_expectancy`), 2)
FROM world_life_expectancy
WHERE (`Life_expectancy`) <> 0
GROUP BY Year
ORDER BY Year
;

-- Correlation Between GDP and Life Expectancy
SELECT Country, ROUND(AVG(`Life_expectancy`),1) AS Life_Exp, ROUND(AVG(GDP),1) AS GDP
FROM world_life_expectancy
GROUP BY Country
HAVING Life_Exp <> 0
AND GDP <> 0
ORDER BY GDP DESC
;

-- Correlation Between BMI and Life Expectancy
SELECT Country, ROUND(AVG(`Life_expectancy`),1) AS Life_Exp, ROUND(AVG(BMI),1) AS BMI
FROM world_life_expectancy
GROUP BY Country
HAVING Life_Exp > 0
AND BMI > 0
ORDER BY BMI ASC
;

-- Estimated Top Half vs. Bottom Half GDP
-- Shows the difference in life expectancy between the estimated top and bottom half of GDP
SELECT 
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) High_GDP_Count,
ROUND(AVG(CASE WHEN GDP >= 1500 THEN `Life_expectancy` ELSE NULL END), 2) High_GDP_Life_Expectancy,
SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) Low_GDP_Count,
ROUND(AVG(CASE WHEN GDP <= 1500 THEN `Life_expectancy` ELSE NULL END), 2) Low_GDP_Life_Expectancy
FROM world_life_expectancy
;

-- Rolling Total for Adult Mortality
SELECT Country,
Year,
`Life_expectancy`,
`Adult_Mortality`,
SUM(`Adult_Mortality`) OVER(PARTITION BY Country ORDER BY Year) as Rolling_Total
FROM world_life_expectancy
;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
