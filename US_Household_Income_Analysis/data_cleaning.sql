/* US Household Income Project Data Cleaning */

SELECT * FROM us_household_income;
SELECT * FROM us_household_income_stats;

---------------------------------------------------------------------------------

-- Step 1: Rename tables for consistency and readability
RENAME TABLE `ushouseholdincome_stats` TO `us_household_income_stats`;
RENAME TABLE `USHouseholdincome` TO `us_household_income`;

-- Step 2: Check for missing data
SELECT COUNT(*) FROM us_household_income_stats;
SELECT COUNT(*) FROM us_household_income;

-- Step 3: Identify duplicate records by 'id'
SELECT id, COUNT(id) AS duplicate_count
FROM us_household_income
GROUP BY id
HAVING COUNT(id) > 1;

-- Step 4: Delete duplicate rows
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

-- Step 5: Correct common typos in State and Type columns
UPDATE us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';

UPDATE us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs';

-- Step 6: Investigate and fill missing 'Place' values for specific records
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
