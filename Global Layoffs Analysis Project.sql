/* Global Layoffs Project Data Cleaning */
-- Skills Used: Data Aggregation, Filtering, Grouping, Window Functions, CTEs, and Subqueries

SELECT * FROM layoffs;

---------------------------------------------------------------------------------

-- Handle missing industry labels
SELECT industry, COUNT(industry)
FROM layoffs
GROUP BY industry
ORDER BY industry ASC
;

-- Replace blank industry entries with 'Other'
SELECT company, industry
FROM layoffs
WHERE industry = ''
GROUP BY company, industry
ORDER BY industry ASC
;

UPDATE layoffs SET industry = 'Other'
	WHERE industry = ''
;

-- Identify duplicate rows by company and date
SELECT company, `date`, COUNT(*)
FROM layoffs
GROUP BY company, `date`
HAVING COUNT(*) > 1
;

-- Create Temp table to remove duplicates since there is no unique ID column
CREATE TABLE layoffs_no_duplicates AS
SELECT *
FROM (
	  SELECT *, ROW_NUMBER() OVER(PARTITION BY company, `date` ORDER BY company) AS row_num
	  FROM layoffs
	 ) subquery
WHERE row_num = 1
;

-- Replace original table with the table w/o duplicates
DROP TABLE layoffs;
RENAME TABLE layoffs_no_duplicates TO layoffs
;

-- Clean up the funds_raised column
-- Remove dollar signs
UPDATE layoffs 
SET funds_raised = REPLACE(funds_raised, '$', '')
;

-- Convert text dollar values to numeric and scaled to actual dollars in millions
UPDATE layoffs
SET funds_raised = CAST(funds_raised AS DECIMAL) * 1000000
;

-- Add a new column to store the value in millions for readibility
ALTER TABLE layoffs ADD COLUMN funds_raised_millions DECIMAL(10,2);

-- Populate the new column
UPDATE layoffs
SET funds_raised_millions = funds_raised / 1000000;


-- Set blanks to NULL is financial columns
UPDATE layoffs
SET total_laid_off = NULL
WHERE total_laid_off = ''
;

UPDATE layoffs
SET percentage_laid_off = NULL
WHERE percentage_laid_off = ''
;

UPDATE layoffs
SET funds_raised = NULL
WHERE funds_raised = ''
;

-- ROUND total_laid_off to nearest whole number 
UPDATE layoffs
SET total_laid_off = ROUND(total_laid_off, 0)
;

-- Clean the layoff date column by converting date format to DATE type from string
UPDATE layoffs
SET `date` = STR_TO_DATE(`date`, '%c/%e/%Y')
;

-- Keep original string version of date column
ALTER TABLE layoffs ADD COLUMN date_original VARCHAR(255)
;

UPDATE layoffs SET date_original = `date`
;

-- Double check date conversion
SELECT 
  `date`,
  STR_TO_DATE(`date`, '%c/%e/%Y') AS formatted_date
FROM layoffs
LIMIT 10
;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

/* Global Layoffs Project Exploratory Data Analysis */

SELECT * FROM layoffs;

---------------------------------------------------------------------------------

-- Which companies raised the most funds before layoffs?
SELECT company, 
ROUND(SUM(funds_raised_millions)) AS total_funds_raised_millions
FROM layoffs
GROUP BY company
ORDER BY total_funds_raised_millions DESC
;

-- Which companies laid off the most employees?
SELECT company, SUM(total_laid_off) AS total_layoffs
FROM layoffs
GROUP BY company
HAVING total_layoffs IS NOT NULL
ORDER BY total_layoffs DESC
;

-- Total layoffs by industry + number of companies per industry
SELECT 
	industry, 
    COUNT(*) AS number_of_companies, 
    SUM(total_laid_off) AS total_layoffs
FROM layoffs
GROUP BY industry
HAVING SUM(total_laid_off) IS NOT NULL
ORDER BY industry ASC
;

-- Average layoffs per company in each industry + their share of total layoffs
SELECT 
    industry, 
    COUNT(*) AS number_of_companies, 
    SUM(total_laid_off) AS total_layoffs, 
    ROUND(AVG(total_laid_off), 2) AS avg_layoffs_per_company,
    ROUND(((SUM(total_laid_off) / (SELECT SUM(total_laid_off) FROM layoffs)) * 100), 2) AS industry_lay_off_percentage -- Percentage of total layoffs by industry
FROM layoffs
GROUP BY industry
HAVING SUM(total_laid_off) IS NOT NULL
ORDER BY industry ASC
;

-- Rolling layoffs over time for each company
SELECT 
	company,
    total_laid_off,
	SUM(total_laid_off) OVER(PARTITION BY company ORDER BY `date`) AS rolling_total_layoffs,
    `date`
FROM layoffs
WHERE total_laid_off <> 0
ORDER BY company ASC
;

-- CTE: Layoff trends by country - layoff events, total laid off, and average percentage laid off per company
WITH country_layoff_stats AS (
SELECT 
	country,
	COUNT(*) AS layoff_events,
    SUM(total_laid_off),
    ROUND(AVG(percentage_laid_off), 2) AS average_percentage_laid_off
FROM layoffs
WHERE total_laid_off IS NOT NULL 
AND total_laid_off <> 0
AND percentage_laid_off IS NOT NULL
GROUP BY country
ORDER BY layoff_events DESC
) 

SELECT * 
FROM country_layoff_stats
WHERE layoff_events >= 10 /* Countries with at least 10 recorded layoff events */
;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
