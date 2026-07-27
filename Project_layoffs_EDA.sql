-- EXPLORATORY DATA ANALYSIS

SELECT * 
FROM world_layoffs.layoffs_staging2;

SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging2;

-- Looking at Percentage to see how big these layoffs were

SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off IS NOT NULL;

-- Some companies laid off all their staff as max percentage is 1
-- Let's check those companies

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY total_laid_off DESC;

 -- these are mostly startups it looks like who all went out of business during this time

-- if we order by funds_raised_millions we can see how big some of these companies were

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


-- Companies with the biggest single Layoff

SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;


-- now let's check date range for this dataset for layoffs

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- 11/03/2020 - 06/03/2023; almost 3 years, about when Covid started

SELECT SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2;

-- 383659 jobs lost during this period

-- let's see which industry took the biggest hit

SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- consumer, retail, transportation took the biggest hits, which makes sense, since this was when covid happened

-- lets check which country was impacted the most

SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- The US tops the charts here

SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 DESC;

-- year-wise layoffs

-- Lets check funding stage and layoffs

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2;


SELECT SUBSTRING(`date`, 6, 2) AS `Month`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY `Month`;

-- here we can see layoffs on month, for all yearr, lets try month/year

SELECT SUBSTRING(`date`, 1 , 7) AS `Month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1 , 7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC;

-- GETTING NULL SO ADDED, WHERE CLAUSE

-- Let's do a rolling sum of this here

WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`, 1 , 7) AS `Month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1 , 7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
)
SELECT `Month`, total_off, SUM(total_off) OVER (ORDER BY `Month`) AS rolling_total
FROM Rolling_Total;


-- lets see company wise layoffs year to year

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 1 ASC;


-- Earlier we looked at Companies with the most Layoffs. 
-- Now let's look at that per year, AND SEE WHICH COMPANIES LAID OFF THE MOST EACH YEAR


WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
)
SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
ORDER BY Ranking ASC;



WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS 
(
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)

SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE years IS NOT NULL
AND ranking <= 3
ORDER BY years ASC, total_laid_off DESC;








