-- Basic Questions

-- 1. What is the total number of COVID-19 deaths for each country?

SELECT 
	deaths_location as country,
	SUM(total_deaths) as total_covid_deaths
FROM covid_combined
WHERE total_deaths IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

-- 2. How many vaccinations have been administered in each country?

SELECT 
	continent,
	location as country,
	SUM(total_vaccinations) as total_vaccinations_adminitered
FROM Covid_vaccinations
WHERE location IS NOT NULL
	AND total_vaccinations IS NOT NULL
	AND continent IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- 3. What are the daily new confirmed cases of COVID-19 over a specified period of '2020-01-01' AND '2023-12-31'?

SELECT 
    continent,
    location AS country,
    CASE 
        WHEN "date" LIKE '%/%/%' THEN TO_DATE("date", 'MM/DD/YYYY') -- Handles dates like 3/1/2020
        WHEN "date" LIKE '%-%-%' THEN TO_DATE("date", 'DD-MM-YYYY') -- Handles dates like 13-01-2020
    END AS converted_date,
    COALESCE(new_cases, 0) AS new_cases -- Replaces NULL with 0
FROM 
    covid_deaths
WHERE 
    CASE 
        WHEN "date" LIKE '%/%/%' THEN TO_DATE("date", 'MM/DD/YYYY')
        WHEN "date" LIKE '%-%-%' THEN TO_DATE("date", 'DD-MM-YYYY')
    END BETWEEN '2020-01-01' AND '2023-12-31'
    AND location IS NOT NULL
    AND continent IS NOT NULL
ORDER BY 
    1, 2, 3 ASC;

-- 4. What is the death rate (percentage of deaths to confirmed cases) for each country?

SELECT 
    continent,
    location AS country,
    SUM(total_deaths) AS total_deaths,
    SUM(total_cases) AS cases_reported,
    CASE 
        WHEN SUM(total_cases) = 0 THEN NULL 
        ELSE SUM(total_deaths) * 100.0 / SUM(total_cases) 
    END AS death_rate_percentage
FROM 
    covid_deaths
WHERE 
    location IS NOT NULL
    AND continent IS NOT NULL
GROUP BY 
    continent, location
ORDER BY 
    death_rate_percentage DESC NULLS LAST;
	
-- 5. What percentage of the population in each country has been infected with COVID-19?

SELECT 
    continent,
    location AS country,
    MAX(total_cases) AS total_cases_reported,  -- Usind MAX to get the latest total cases
    MAX(CAST(population AS BIGINT)) AS total_population,  -- Using MAX for latest population
    ROUND(MAX(total_cases) * 100.0 / NULLIF(MAX(CAST(population AS BIGINT)), 0), 2) AS population_infected_percentage
FROM 
    covid_deaths
GROUP BY 
    continent, location
ORDER BY 
    population_infected_percentage DESC NULLS LAST;

-- 6. What is the total number people vaccinated on 2022-04-05?

SELECT 
    continent,
    location AS country,
    MAX(people_vaccinated) AS total_people_vaccinated
FROM 
    covid_vaccinations
WHERE 
    CASE 
        WHEN "date" LIKE '%/%/%' THEN TO_DATE("date", 'MM/DD/YYYY')  -- Handles dates like 3/1/2020
        WHEN "date" LIKE '%-%-%' THEN TO_DATE("date", 'DD-MM-YYYY')  -- Handles dates like 13-01-2020
    END = '2022-04-05'
	AND location IS NOT NULL
    AND continent IS NOT NULL
GROUP BY 
    continent, location
ORDER BY 
    total_people_vaccinated DESC NULLS LAST;

7.	How many deaths occurred each month globally?

SELECT 
    DATE_TRUNC('month', 
        CASE 
            WHEN "date" LIKE '%/%/%' THEN TO_DATE("date", 'MM/DD/YYYY')  -- Handles dates like 3/1/2020
            WHEN "date" LIKE '%-%-%' THEN TO_DATE("date", 'DD-MM-YYYY')  -- Handles dates like 13-01-2020
        END
    ) AS month,
    SUM(new_deaths) AS monthly_deaths
FROM 
    covid_deaths
GROUP BY 
    month
ORDER BY 
    month;

8.	How has the daily count of vaccinations changed over time?

SELECT 
    DATE_TRUNC('month', 
        CASE 
            WHEN "date" ~ '^\d{1,2}/\d{1,2}/\d{4}$' THEN TO_DATE("date", 'MM/DD/YYYY')  -- Handles dates like 3/1/2020
            WHEN "date" ~ '^\d{2}-\d{2}-\d{4}$' THEN TO_DATE("date", 'DD-MM-YYYY')  -- Handles dates like 13-01-2020
        END
    ) AS month,
    SUM(new_deaths) AS monthly_deaths
FROM 
    covid_deaths
WHERE 
    "date" ~ '^\d{1,2}/\d{1,2}/\d{4}$' OR "date" ~ '^\d{2}-\d{2}-\d{4}$' 
GROUP BY 
    month
ORDER BY 
    month;

9.	Which countries have the highest and lowest total cases reported?

-- Highest cases
SELECT 
	continent,
    location AS country,
    SUM(total_cases) AS total_cases
FROM 
    covid_deaths
WHERE continent IS NOT NULL
GROUP BY 
    continent, location
ORDER BY 
    total_cases DESC NULLS LAST
	LIMIT 1;

-- Lowest cases

SELECT 
    location AS country,
    SUM(total_cases) AS total_cases
FROM 
    covid_deaths
GROUP BY 
    location
ORDER BY 
    total_cases ASC
LIMIT 1;

10.	What is the total number of COVID-19 deaths per continent?

SELECT 
    continent,
    SUM(total_deaths) AS total_deaths
FROM 
    covid_deaths
WHERE continent IS NOT NULL
GROUP BY 
    continent
ORDER BY 
    total_deaths DESC;