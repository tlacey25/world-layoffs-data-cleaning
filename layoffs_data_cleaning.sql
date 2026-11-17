# World Layoffs Data Cleaning Project

SELECT * 
FROM layoffs
;

-- We want to start by creating a staging table in order to maintain a table of raw data and a table with all of our changes.

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * 
FROM layoffs_staging
;

INSERT layoffs_staging
SELECT *
FROM layoffs;

# REMOVING THE DUPLICATES 

-- ROW_NUMBER() is being used here to locate any duplicate values. 

SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `Date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
;

-- A CTE is used here as an easy reference for our table consisting of duplicate rows that we can filter on.  

WITH duplicate_cte AS 
	(SELECT *,
	ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `Date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging
	)
    SELECT *
    FROM duplicate_cte
    WHERE row_num > 1;

-- Now that we have found our duplicates, I'm creating a second staging table with the addition of a 'row_num' column. 
    
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, 
percentage_laid_off, `Date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- The following statement is meant to filter on our new table to return our duplicate rows and then delete those duplicates.

SELECT *
FROM layoffs_staging2
WHERE row_num > 1
; 

DELETE
FROM layoffs_staging2
WHERE row_num > 1
; 

# STANDARDIZING THE DATA

-- I noticed that there was some white space in the company column and updated the strings to trimmed text.

SELECT company, TRIM(company)
FROM layoffs_staging2
; 

UPDATE layoffs_staging2
SET company = TRIM(company);

-- In the industry column, there are NULLS, blanks, and duplicate categories worded or spelled a little differently. 

SELECT DISTINCT(industry)
FROM layoffs_staging2
; 

-- There were three separate labels for the Crypto industry, so we searched for those values in our statement to seclude them.

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'
; 

-- After locating all of our values, I used an UPDATE statement to change our industry values to 'Crypto' wherever the value included 'Crypto' in the name.
-- There were also NULL and blank values that I deleted from our table. 

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

DELETE FROM layoffs_staging2
WHERE industry IN (NULL, '');

-- After looking over the remaining columns, I did notice a duplicate in the Country column. There were 'United States' and 'United States.' 
-- I worked towards standardizing these data values with an UPDATE statement here.

SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1
; 

UPDATE layoffs_staging2
SET country = 'United States' 
WHERE country LIKE 'United States%';

-- The Date column came in as a string and not in a date format. The easiest way to go about the invalid data type was to convert from string to date format, and then update the table to that data type.

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2
; 

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- You will notice that the data type for the date column is still text. Our data was still converted, but the use of the ALTER TABLE statmenet is necessary here to change the data type. 

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

# ADDRESSING NULL AND BLANK VALUES

-- There weren't any NULLS or blanks to address here since we deleted a few NULL/blank rows ealier in my process.

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
; 

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- The Bally's row didn't delete earlier in our DELETE statement for NULL values in the industry column because this company is unique (as in it is the only value for the particular company). 

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

# REMOVING UNECESSARY COLUMNS OR ROWS

-- We are going to get rid of the rows where the total_laid_off column and percentage_laid_off column have NULL values. 

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
; 

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Finally, I am dropping the row_num column that we created earlier, as it is no longer needed.

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Here is our fully cleaned and standardized table. 

SELECT *
FROM layoffs_staging2
;







