-- Medium Questions:
-- 1. How does the death rate differ between vaccinated and unvaccinated individuals?

SELECT 
    deaths_location,
    MAX(total_deaths) AS total_deaths,
    MAX(total_cases) AS total_cases,
    MAX(people_vaccinated) AS people_vaccinated,
    ROUND((MAX(total_deaths) * 1.0 / NULLIF(MAX(total_cases), 0)) * 100, 2) AS overall_death_rate_percentage,
    ROUND((MAX(total_deaths) * 1.0 / NULLIF(MAX(people_vaccinated), 0)) * 100, 2) AS vaccinated_death_rate_percentage,
    ROUND(
        (MAX(total_deaths) * 1.0 / 
        NULLIF(
            CASE 
                WHEN MAX(total_cases) - MAX(people_vaccinated) < 0 THEN 0
                ELSE MAX(total_cases) - MAX(people_vaccinated)
            END, 0)) 
        * 100, 2
    ) AS unvaccinated_death_rate_percentage
FROM covid_combined
GROUP BY deaths_location
HAVING 
    MAX(total_deaths) * 1.0 / NULLIF(MAX(total_cases), 0) IS NOT NULL
    AND MAX(total_deaths) * 1.0 / NULLIF(MAX(people_vaccinated), 0) IS NOT NULL
    AND MAX(total_deaths) * 1.0 / NULLIF(
        CASE 
            WHEN MAX(total_cases) - MAX(people_vaccinated) < 0 THEN 0
            ELSE MAX(total_cases) - MAX(people_vaccinated)
        END, 0) IS NOT NULL;

-- 2. What are the death counts segmented by age groups across different countries?
SELECT *FROM covid_combined

SELECT 
	deaths_continent as continent,
	deaths_location as location, 
    CASE 
        WHEN median_age < 30 THEN 'Under 30'
        WHEN median_age BETWEEN 30 AND 50 THEN '30-50'
        WHEN median_age BETWEEN 51 AND 70 THEN '51-70'
        ELSE 'Above 70'
    END AS age_group,
    MAX(total_deaths) AS death_count
FROM covid_combined
WHERE total_deaths IS NOT NULL
	AND deaths_continent is NOT NULL
	AND deaths_location IS NOT NULL
GROUP BY deaths_continent, deaths_location, age_group
ORDER BY death_count DESC;


-- 3. Is there a correlation between vaccination rates and death rates in various countries?

WITH rates AS (
    SELECT 
        deaths_location,
        MAX(CAST(people_vaccinated AS DECIMAL)) * 1.0 / MAX(CAST(population AS DECIMAL)) AS vaccination_rate,
        MAX(CAST(total_deaths AS DECIMAL)) * 1.0 / MAX(CAST(total_cases AS DECIMAL)) AS death_rate
    FROM covid_combined
    GROUP BY deaths_location
    HAVING 
        MAX(CAST(people_vaccinated AS DECIMAL)) IS NOT NULL 
        AND MAX(CAST(population AS DECIMAL)) IS NOT NULL 
        AND MAX(CAST(total_deaths AS DECIMAL)) IS NOT NULL 
        AND MAX(CAST(total_cases AS DECIMAL)) IS NOT NULL
)
SELECT 
    CORR(vaccination_rate, death_rate) AS correlation
FROM rates;

-- 4. How do weekly averages of new cases and deaths compare over time?

SELECT
    deaths_location,
    DATE_TRUNC('week', TO_DATE(date, 'DD-MM-YYYY'))::date AS week_start,
    ROUND(AVG(new_cases::numeric), 2) AS avg_weekly_cases,
    ROUND(AVG(new_deaths::numeric), 2) AS avg_weekly_deaths
FROM covid_combined
GROUP BY deaths_location, DATE_TRUNC('week', TO_DATE(date, 'DD-MM-YYYY'))
ORDER BY week_start;


-- 5. Which regions within countries have the highest case counts?

SELECT 
	deaths_continent AS continent,
    deaths_location AS location, 
    MAX(total_cases) AS highest_case_count
FROM covid_combined
WHERE deaths_continent IS NOT NULL
	AND deaths_location IS NOT NULL
GROUP BY deaths_continent,deaths_location
ORDER BY highest_case_count DESC NULLS LAST;

-- 6. What is the cumulative vaccination rate compared to total population size across regions?

SELECT * FROM covid_combined

SELECT 
    deaths_continent AS continent,
    deaths_location AS location,
	MAX(people_vaccinated),
	MAX(population) as population,
    ROUND((MAX(CAST(people_vaccinated AS DECIMAL)) * 1.0 / MAX(CAST(population AS DECIMAL))) * 100, 2) 
	AS cumulative_vaccination_rate_percentage
FROM covid_combined
WHERE deaths_continent IS NOT NULL
	AND deaths_location IS NOT NULL 
GROUP BY deaths_continent, deaths_location
HAVING ROUND((MAX(CAST(people_vaccinated AS DECIMAL)) * 1.0 / MAX(CAST(population AS DECIMAL))) * 100, 2) > 0;


-- 7. What are the recovery rates (percentage recovered to confirmed cases) for each country?

SELECT 
	deaths_continent as continent,
    deaths_location as location,
	Max(total_cases),
	Max(total_deaths),
    Round((Max(total_cases) - Max(total_deaths)) * 1.0 / NULLIF(Max(total_cases), 0), 2) AS recovery_rate
FROM covid_combined
WHERE deaths_continent IS NOT NULL
	AND deaths_location IS NOT NULL 
GROUP BY deaths_continent, deaths_location;

-- 8. How have death rates changed over time in specific countries or regions?

SELECT 
	deaths_continent as continent,
    deaths_location as location,
    date,
    ROUND((MAX(total_deaths) * 1.0 / NULLIF(MAX(total_cases), 0)),2)*100 AS death_rate_percentage
FROM covid_combined
WHERE deaths_continent IS NOT NULL
	AND deaths_location IS NOT NULL
GROUP BY deaths_continent, deaths_location, date
HAVING (SUM(total_deaths) * 1.0 / NULLIF(SUM(total_cases), 0)) IS NOT NULL
ORDER BY date ASC;

-- 9. Which continent has the highest infection rate relative to its population size?

SELECT 
    deaths_continent,
	MAX(total_cases) AS total_cases,
	MAX(population) AS population,
    CAST(MAX(total_cases) AS DECIMAL) * 1.0 / CAST(MAX(population) AS DECIMAL) AS infection_rate
FROM covid_combined
GROUP BY deaths_continent
ORDER BY infection_rate DESC
LIMIT 1;

-- 10. How does the vaccination rate (percentage of people vaccinated) correlate with death rates across different locations?

SELECT 
	deaths_continent AS continent,
    deaths_location AS location,
    MAX(CAST(population AS DECIMAL)) AS population,
    MAX(CAST(people_vaccinated AS DECIMAL)) AS people_vaccinated,
    ROUND((MAX(CAST(people_vaccinated AS DECIMAL)) * 1.0 / MAX(CAST(population AS DECIMAL))) * 100, 2) AS vaccination_rate_percentage,
    ROUND((MAX(CAST(total_deaths AS DECIMAL)) * 1.0 / NULLIF(MAX(CAST(total_cases AS DECIMAL)), 0)) * 100, 2) AS death_rate_percentage
FROM covid_combined
WHERE deaths_location IS NOT NULL
	AND deaths_continent IS NOT NULL
    AND CAST(population AS DECIMAL) > 0
    AND CAST(total_cases AS DECIMAL) > 0
GROUP BY deaths_continent, deaths_location
HAVING MAX(CAST(people_vaccinated AS DECIMAL)) IS NOT NULL
	AND ROUND((MAX(CAST(total_deaths AS DECIMAL)) * 1.0 / NULLIF(MAX(CAST(total_cases AS DECIMAL)), 0)) * 100, 2) > 0
ORDER BY vaccination_rate_percentage DESC;