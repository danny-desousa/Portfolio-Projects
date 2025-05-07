/* US Household Income Project Exploratory Data Analysis */

SELECT * FROM us_household_income;
SELECT * FROM us_household_income_stats;

---------------------------------------------------------------------------------

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

-- Ranking of Average Household Income by State
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

-- Comparing Average Household Incomes by City to the US Average
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
