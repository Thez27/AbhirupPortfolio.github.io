-- SQL Project - Data Cleaning

-- https://www.kaggle.com/datasets/swaptr/layoffs-2022


SELECT * 
FROM layoffs; 

-- first thing we want to do is create a staging table. We want a table with the raw data in case something happens

CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT layoffs_staging 
SELECT * 
FROM world_layoffs.layoffs;

SELECT *
FROM layoffs_staging;

-- When we are data cleaning, we will follow a few steps:
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values
-- 4. remove any columns and rows that are not necessary


-- 1. Remove Duplicates

# First let's check for duplicates (all columns partioned by win func)

SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging;

SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging;

WITH duplicate_CTE AS
(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging
)
SELECT *
FROM duplicate_CTE
WHERE row_num > 1;


-- we can now see the exact duplicate rows and will remove 1 of each, since all have row_num as 2

-- but in MySQL workbench we can't delete directly from a CTE, so we will create a new table layoffs_staging2
-- also in new table, create a new column and add those row numbers in. Then delete where row numbers are over 2, and then delete that column

CREATE TABLE `layoffs_staging2` 
(
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



SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`, stage, country, funds_raised_millions) AS row_num
FROM world_layoffs.layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- VALIDATED: Duplicates have been removed


-- 2. Standardize Data


SELECT *
FROM layoffs_staging2;

-- we can see that some companies have blank spaces


SELECT DISTINCT company, (TRIM(company))
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- white spaces have been trimmed as required

-- lets look at industry

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- crypto, cryptocurrency and crypto currency should be the same industry

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- 3 anomalies found for this

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM layoffs_staging2;

-- validated they have now come under the same industry - 'Crypto'

SELECT *
FROM layoffs_staging2;

-- we have checked company, industry, will have to check similarly all columns, to ensure everyting is standardised or we will fix as required

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- 2 UNITED STATES FOUND

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

-- or we can use this too

-- UPDATE layoffs_staging2
-- SET country = TRIM(TRAILING '.' FROM country)
-- WHERE country LIKE 'United States%';

-- validated this has been fixed

-- date column is set to text, need to change to date column

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

-- updated fields to date type, under 'date'
-- now, we can change the datatype of 'date'

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. Look at NULL/BLANK values


SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- 3 blanks 1 null, lets check each company to see if we can ascertain their industry type in a different row

SELECT *
FROM layoffs_staging2
WHERE company = 'Juul';

-- Checked for all: Airbnb -Travel Industry, Carvana -transportation, Juul - Consumer, Bally's Interactive - NUll (Industry)

SELECT t1.company, t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- We need to set the blank values as NULL first 

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- now we can run the required join query to fill in the Industry columns

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- validated that this is working now

-- this dataset is for layoff data of 2022
-- if total_laid_off and percentage_laid_off are both null in any row, we need to remove those rows, as they wouldn't be really useful


SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL ;


DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 4. Remove unwanted columns

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;






