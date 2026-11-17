# World Layoffs: Data Cleaning in MySQL

## Overview
Cleaned a raw global layoffs dataset in MySQL, turning inconsistent, duplicated data into an analysis-ready table. All work was done on staging tables, so the raw data was never modified.

**Tools:** MySQL (CTEs, window functions, string and date functions)

## The Problem
The raw `layoffs` table had:
- Duplicate records
- Extra whitespace in company names
- The same industry spelled several ways (e.g., three variants of "Crypto")
- Country inconsistencies (e.g., "United States" vs. "United States.")
- Dates stored as text instead of a DATE type
- NULL and blank values in key columns
- Rows with no layoff information

## Approach

### 1. Staging tables to protect the raw data
Created `layoffs_staging` as a copy of the raw table and did all cleaning there.

### 2. Removed duplicates
Used `ROW_NUMBER() OVER (PARTITION BY ...)` across every column, wrapped in a CTE, to flag duplicates (`row_num > 1`). MySQL doesn't allow deleting directly from a CTE, so I created a second staging table (`layoffs_staging2`) with a `row_num` column, inserted the flagged data, and deleted the duplicates there.

### 3. Standardized the data
- Trimmed whitespace from company names with `TRIM()`
- Consolidated the Crypto industry variants into one label using `LIKE 'Crypto%'`
- Fixed the duplicate country entry for the United States
- Converted dates from text with `STR_TO_DATE()`, then changed the column type with `ALTER TABLE ... MODIFY COLUMN`

### 4. Handled NULL and blank values
Identified NULL and blank values in the industry column and removed rows where both `total_laid_off` and `percentage_laid_off` were NULL, since those rows contained no usable layoff data.

### 5. Removed unnecessary columns
Dropped the helper `row_num` column once duplicates were removed.

## Results
- Rows: 2361 raw → 1992 cleaned
- Duplicate records removed: 5
- Industry labels consolidated: 3 Crypto variants → 1
- Date column converted from TEXT to DATE
- Rows removed for having no layoff data: 362

## Lessons Learned
- **Order of operations matters.** I deleted NULL/blank industry rows before reviewing the rest of the data. Next time I'll follow the full sequence (duplicates → standardize → nulls → drop) and decide what to delete only after reviewing everything.
- **Be careful when deleting data.** Deleting should be a last resort, reserved for rows that are unrecoverable.

## Next Steps
- Run exploratory analysis (layoffs by industry, country, and year)
- Build a dashboard on the cleaned table
