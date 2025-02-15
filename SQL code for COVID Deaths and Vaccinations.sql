-- COVID 19 Deaths
DROP TABLE IF EXISTS covid_deaths;
CREATE TABLE covid_deaths (
    iso_code VARCHAR(10),
    continent VARCHAR(15),
    location VARCHAR(35),
    "date" VARCHAR(15),
    population VARCHAR(15),
    total_cases BIGINT,
    new_cases INT,
    total_deaths INT,
    new_deaths INT,
    total_deaths_per_million FLOAT,
    new_deaths_per_million FLOAT,
    reproduction_rate FLOAT,
    icu_patients INT,
    hosp_patients INT, 
    weekly_icu_admissions INT,
    weekly_hosp_admissions INT,
	PRIMARY KEY (iso_code, "date")
);

-- COVID 19 Vaccinations

DROP TABLE IF EXISTS covid_vaccinations; 
CREATE TABLE covid_vaccinations(
	iso_code VARCHAR(15),
	continent VARCHAR(20),
	location VARCHAR(40),
	"date" VARCHAR(15),
	total_tests BIGINT,
	new_tests BIGINT,
	positive_rate FLOAT,
	tests_per_case FLOAT,
	tests_units VARCHAR(20),
	total_vaccinations BIGINT,
	people_vaccinated BIGINT,
	people_fully_vaccinated BIGINT,
	total_boosters BIGINT,
	new_vaccinations BIGINT,
	stringency_index FLOAT,
	population_density FLOAT,
	median_age FLOAT,
	aged_65_older FLOAT,
	aged_70_older FLOAT,
	gdp_per_capita FLOAT,
	extreme_poverty FLOAT,
	cardiovasc_death_rate FLOAT,
	diabetes_prevalence FLOAT,
	handwashing_facilities FLOAT,
	life_expectancy FLOAT,
	human_development_index FLOAT,
	excess_mortality_cumulative FLOAT,
	excess_mortality FLOAT,
	PRIMARY KEY (iso_code, "date")
);

-- Join the table:

DROP TABLE IF EXISTS covid_combined;

CREATE TABLE covid_combined AS
SELECT 
    cd.iso_code,
    cd.continent AS deaths_continent,
    cd.location AS deaths_location,
    cd."date",
    cd.population,
    cd.total_cases,
    cd.new_cases,
    cd.total_deaths,
    cd.new_deaths,
    cd.total_deaths_per_million,
    cd.new_deaths_per_million,
    cd.reproduction_rate,
    cd.icu_patients,
    cd.hosp_patients,
    cd.weekly_icu_admissions,
    cd.weekly_hosp_admissions,
    cv.continent AS vaccinations_continent,
    cv.location AS vaccinations_location,
    cv.total_tests,
    cv.new_tests,
    cv.positive_rate,
    cv.tests_per_case,
    cv.tests_units,
    cv.total_vaccinations,
    cv.people_vaccinated,
    cv.people_fully_vaccinated,
    cv.total_boosters,
    cv.new_vaccinations,
    cv.stringency_index,
    cv.population_density,
    cv.median_age,
    cv.aged_65_older,
    cv.aged_70_older,
    cv.gdp_per_capita,
    cv.extreme_poverty,
    cv.cardiovasc_death_rate,
    cv.diabetes_prevalence,
    cv.handwashing_facilities,
    cv.life_expectancy,
    cv.human_development_index,
    cv.excess_mortality_cumulative,
    cv.excess_mortality
FROM 
    covid_deaths cd
INNER JOIN 
    covid_vaccinations cv
ON 
    cd.iso_code = cv.iso_code AND cd."date" = cv."date";

ALTER TABLE covid_deaths
ADD CONSTRAINT fk_iso_date
FOREIGN KEY (iso_code, "date")
REFERENCES covid_vaccinations (iso_code, "date");

SELECT * FROM covid_combined LIMIT 5

-- Checking the New table

SELECT * FROM covid_combined;

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
	Max(total_vaccinations) as total_vaccinations_adminitered
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
    END AS date,
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
	AND new_cases > 0
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

-- 7. How many deaths occurred each month globally?

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

-- 8. How has the daily count of vaccinations changed over time?

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

-- 9. Which countries have the highest and lowest total cases reported?

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

-- 10. What is the total number of COVID-19 deaths per continent?

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


-- Advanced Questions:

-- 1. How can we use historical data to forecast future COVID-19 cases and deaths for the next month?

WITH historical_data AS (
    SELECT 
        location,
        continent,
        TO_DATE(date, 'DD-MM-YYYY') AS date,  -- Convert VARCHAR to DATE
        total_cases::NUMERIC,  
        total_deaths::NUMERIC, 
        (TO_DATE(date, 'DD-MM-YYYY') - 
         (SELECT MIN(TO_DATE(date, 'DD-MM-YYYY')) 
          FROM covid_deaths WHERE location = location)) 
          AS days_since_start  -- Direct subtraction gives days as an integer
    FROM covid_deaths
    WHERE continent IS NOT NULL
		AND location IS NOT NULL
),
regression AS (
    SELECT 
        location,
        continent,
        regr_slope(total_cases, days_since_start) AS case_slope,
        regr_intercept(total_cases, days_since_start) AS case_intercept,
        regr_slope(total_deaths, days_since_start) AS death_slope,
        regr_intercept(total_deaths, days_since_start) AS death_intercept,
        MAX(days_since_start) AS last_day,
        MAX(date) AS last_date
    FROM historical_data
    GROUP BY location, continent
)
SELECT 
    location,
    continent,
    last_date + generate_series(1, 30) AS future_date,  -- Add days to last known date
    ROUND(case_slope * (last_day + generate_series(1, 30)) + case_intercept) AS predicted_cases,
    ROUND(death_slope * (last_day + generate_series(1, 30)) + death_intercept) AS predicted_deaths
FROM regression;

--2. Is there a significant time lag between vaccination rollouts and decreases in death rates across different regions?

WITH vaccination_data AS (
    SELECT 
        covid_deaths.location,
        covid_deaths.continent,
        TO_DATE(covid_deaths.date, 'DD-MM-YYYY') AS date,  
        covid_deaths.total_deaths::NUMERIC, 
        covid_vaccinations.total_vaccinations::NUMERIC
    FROM covid_deaths
    JOIN covid_vaccinations ON covid_deaths.iso_code = covid_vaccinations.iso_code AND covid_deaths.date = covid_vaccinations.date
    WHERE covid_deaths.continent IS NOT NULL AND covid_vaccinations.total_vaccinations IS NOT NULL
),
death_rate_changes AS (
    SELECT 
        location,
        continent,
        date,
        total_deaths,
        total_vaccinations,
        LAG(total_deaths) OVER (PARTITION BY location ORDER BY date) AS previous_total_deaths,
        total_deaths - LAG(total_deaths) OVER (PARTITION BY location ORDER BY date) AS death_rate_change
    FROM vaccination_data
)
SELECT 
	continent,
    location,
    CORR(total_vaccinations, death_rate_change) AS correlation
FROM death_rate_changes
GROUP BY location, continent
ORDER BY correlation ASC;

-- 3.  Calculate the correlation coefficient between new_cases and new_deaths for each location.

WITH Stats AS (
    SELECT
        deaths_location,
        AVG(new_cases) AS avg_cases,
        AVG(new_deaths) AS avg_deaths
    FROM covid_combined
    GROUP BY deaths_location
),
Covariance AS (
    SELECT
		c.deaths_continent,
        c.deaths_location,
        SUM((c.new_cases - s.avg_cases) * (c.new_deaths - s.avg_deaths)) AS covariance,
        SQRT(SUM(POWER(c.new_cases - s.avg_cases, 2))) AS std_dev_cases,
        SQRT(SUM(POWER(c.new_deaths - s.avg_deaths, 2))) AS std_dev_deaths
    FROM covid_combined c
    JOIN Stats s ON c.deaths_location = s.deaths_location
    GROUP BY c.deaths_location, c.deaths_continent
)
SELECT 
	deaths_continent,
    deaths_location,
    Round(covariance / (std_dev_cases * std_dev_deaths),2) AS correlation_coefficient
FROM Covariance
WHERE std_dev_cases > 0 AND std_dev_deaths > 0
	AND deaths_location IS NOT NULL
	AND deaths_continent IS NOT NULL;

-- 4. How do new COVID-19 case rates compare between vaccinated and unvaccinated populations over time across different locations?

WITH Cohort AS (
    SELECT 
        CASE
            WHEN date ~ '^\d{2}/\d{2}/\d{4}$' THEN TO_DATE(date, 'MM/DD/YYYY')  -- Handle MM/DD/YYYY format
            WHEN date ~ '^\d{4}-\d{2}-\d{2}$' THEN TO_DATE(date, 'YYYY-MM-DD')  -- Handle YYYY-MM-DD format
        END AS date,
        deaths_location,
        deaths_continent,  -- Added deaths_continent column
        CAST(population AS NUMERIC) AS population,
        CAST(people_vaccinated AS NUMERIC) AS people_vaccinated,
        (CAST(people_vaccinated AS NUMERIC) / NULLIF(CAST(population AS NUMERIC), 0)) AS vaccinated_rate,
        (1 - (CAST(people_vaccinated AS NUMERIC) / NULLIF(CAST(population AS NUMERIC), 0))) AS unvaccinated_rate,
        CAST(new_cases AS NUMERIC) AS new_cases
    FROM covid_combined
    WHERE people_vaccinated IS NOT NULL AND population IS NOT NULL
),
ReinfectionRates AS (
    SELECT 
        deaths_location,
        deaths_continent,  -- Include deaths_continent in the GROUP BY and SELECT
        DATE_TRUNC('month', date) AS month,  -- Grouping by Month
        AVG(vaccinated_rate * new_cases) AS vaccinated_reinfection_rate,
        AVG(unvaccinated_rate * new_cases) AS unvaccinated_reinfection_rate,
        MAX(population) AS population,  -- Bring population to this level
        MAX(people_vaccinated) AS people_vaccinated,  -- Bring people_vaccinated to this level
        MAX(new_cases) AS new_cases  -- Bring new_cases to this level
    FROM Cohort
    GROUP BY deaths_location, deaths_continent, month  -- Include deaths_continent in the GROUP BY
)
SELECT 
    deaths_location,
    deaths_continent,  -- Include deaths_continent in the final SELECT
    month,
    population,  -- Initial columns from which calculations are done
    people_vaccinated,
    new_cases,
    ROUND(vaccinated_reinfection_rate, 2) AS vaccinated_reinfection_rate,
    ROUND(unvaccinated_reinfection_rate, 2) AS unvaccinated_reinfection_rate,
    ROUND((unvaccinated_reinfection_rate - vaccinated_reinfection_rate), 2) AS reinfection_difference
FROM ReinfectionRates
WHERE deaths_continent IS NOT NULL
  AND deaths_location IS NOT NULL
  AND month IS NOT NULL
ORDER BY deaths_location, deaths_continent, month;

-- 5. How can we classify countries into COVID-19 hotspots based on key pandemic indicators such as total cases, total deaths, 
-- new cases, hospitalizations, testing rates, and vaccinations?

WITH CountryCluster AS (
    SELECT 
        deaths_continent, 
        deaths_location, 
        ROUND(AVG(total_cases)::numeric, 2) AS avg_total_cases, 
        ROUND(AVG(new_cases)::numeric, 2) AS avg_new_cases, 
        ROUND(AVG(total_deaths)::numeric, 2) AS avg_total_deaths, 
        ROUND(AVG(new_deaths)::numeric, 2) AS avg_new_deaths,
        ROUND(AVG(total_deaths_per_million)::numeric, 2) AS avg_deaths_per_million,
        ROUND(AVG(excess_mortality_cumulative)::numeric, 2) AS avg_excess_mortality,
        ROUND(AVG(icu_patients)::numeric, 2) AS avg_icu_patients,
        ROUND(AVG(hosp_patients)::numeric, 2) AS avg_hosp_patients,
        ROUND(AVG(total_tests)::numeric, 2) AS avg_total_tests,
        ROUND(AVG(new_tests)::numeric, 2) AS avg_new_tests,
        ROUND(AVG(positive_rate)::numeric, 2) AS avg_positive_rate,
        ROUND(AVG(total_vaccinations)::numeric, 2) AS avg_total_vaccinations,
        ROUND(AVG(people_vaccinated)::numeric, 2) AS avg_people_vaccinated,
        ROUND(AVG(people_fully_vaccinated)::numeric, 2) AS avg_fully_vaccinated,
        ROUND(AVG(total_boosters)::numeric, 2) AS avg_total_boosters,
        ROUND(AVG(stringency_index)::numeric, 2) AS avg_stringency_index
    FROM Covid_Combined
    WHERE 
        deaths_continent IS NOT NULL AND 
        deaths_location IS NOT NULL AND 
        total_cases IS NOT NULL AND 
        new_cases IS NOT NULL AND 
        total_deaths IS NOT NULL AND 
        new_deaths IS NOT NULL AND 
        total_deaths_per_million IS NOT NULL AND 
        excess_mortality_cumulative IS NOT NULL AND 
        icu_patients IS NOT NULL AND 
        hosp_patients IS NOT NULL AND 
        total_tests IS NOT NULL AND 
        new_tests IS NOT NULL AND 
        positive_rate IS NOT NULL AND 
        total_vaccinations IS NOT NULL AND 
        people_vaccinated IS NOT NULL AND 
        people_fully_vaccinated IS NOT NULL AND 
        total_boosters IS NOT NULL AND 
        stringency_index IS NOT NULL
    GROUP BY deaths_continent, deaths_location
)
SELECT 
    deaths_continent, 
    deaths_location, 
    avg_total_cases, 
    avg_new_cases, 
    avg_total_deaths, 
    avg_new_deaths,
    avg_deaths_per_million, 
    avg_excess_mortality, 
    avg_icu_patients, 
    avg_hosp_patients,
    avg_total_tests, 
    avg_new_tests, 
    avg_positive_rate, 
    avg_total_vaccinations,
    avg_people_vaccinated, 
    avg_fully_vaccinated, 
    avg_total_boosters, 
    avg_stringency_index,
    NTILE(4) OVER (
         ORDER BY 
         avg_total_cases DESC, 
         avg_total_deaths DESC, 
         avg_excess_mortality DESC, 
         avg_icu_patients DESC, 
         avg_positive_rate DESC, 
         avg_stringency_index DESC
     ) AS hotspot_cluster
FROM CountryCluster;

-- 6. How can we analyze disparities among different demographic groups in COVID-19 outcomes based on age distribution, 
-- healthcare accessibility, economic factors, and disease prevalence across countries?

WITH DemographicAnalysis AS (
    SELECT 
        deaths_continent, 
        deaths_location, 
        ROUND(AVG(population_density)::numeric, 2) AS avg_population_density,
        ROUND(AVG(median_age)::numeric, 2) AS avg_median_age,
        ROUND(AVG(aged_65_older)::numeric, 2) AS avg_aged_65_older,
        ROUND(AVG(aged_70_older)::numeric, 2) AS avg_aged_70_older,
        ROUND(AVG(life_expectancy)::numeric, 2) AS avg_life_expectancy,
        ROUND(AVG(human_development_index)::numeric, 2) AS avg_hdi,
        ROUND(AVG(gdp_per_capita)::numeric, 2) AS avg_gdp_per_capita,
        ROUND(AVG(extreme_poverty)::numeric, 2) AS avg_extreme_poverty,
        ROUND(AVG(handwashing_facilities)::numeric, 2) AS avg_handwashing_facilities,
        ROUND(AVG(cardiovasc_death_rate)::numeric, 2) AS avg_cardiovasc_death_rate,
        ROUND(AVG(diabetes_prevalence)::numeric, 2) AS avg_diabetes_prevalence,
        ROUND(AVG(total_cases)::numeric, 2) AS avg_total_cases,
        ROUND(AVG(total_deaths)::numeric, 2) AS avg_total_deaths,
        ROUND(AVG(total_deaths_per_million)::numeric, 2) AS avg_deaths_per_million,
        ROUND(AVG(excess_mortality_cumulative)::numeric, 2) AS avg_excess_mortality
    FROM Covid_Combined
    WHERE 
        deaths_continent IS NOT NULL AND 
        deaths_location IS NOT NULL AND 
        population_density IS NOT NULL AND
        median_age IS NOT NULL AND
        aged_65_older IS NOT NULL AND
        aged_70_older IS NOT NULL AND
        life_expectancy IS NOT NULL AND
        human_development_index IS NOT NULL AND
        gdp_per_capita IS NOT NULL AND
        extreme_poverty IS NOT NULL AND
        handwashing_facilities IS NOT NULL AND
        cardiovasc_death_rate IS NOT NULL AND
        diabetes_prevalence IS NOT NULL AND
        total_cases IS NOT NULL AND
        total_deaths IS NOT NULL AND
        total_deaths_per_million IS NOT NULL AND
        excess_mortality_cumulative IS NOT NULL
    GROUP BY 
        deaths_continent, 
        deaths_location
)
SELECT 
    deaths_continent, 
    deaths_location, 
    avg_population_density, 
    avg_median_age, 
    avg_aged_65_older, 
    avg_aged_70_older, 
    avg_life_expectancy, 
    avg_hdi, 
    avg_gdp_per_capita, 
    avg_extreme_poverty, 
    avg_handwashing_facilities,  
    avg_cardiovasc_death_rate, 
    avg_diabetes_prevalence,
    avg_total_cases, 
    avg_total_deaths, 
    avg_deaths_per_million, 
    avg_excess_mortality,
    NTILE(4) OVER (
         ORDER BY 
         avg_aged_70_older DESC, 
         avg_deaths_per_million DESC, 
         avg_excess_mortality DESC,
         avg_cardiovasc_death_rate DESC, 
         avg_diabetes_prevalence DESC, 
         avg_hdi ASC
     ) AS disparity_cluster
FROM DemographicAnalysis;

-- 7. Analyze the temporal patterns in vaccine distribution, including the rolling average of new vaccinations and the vaccination rate per population.

WITH VaccinationTrends AS (
    SELECT 
        date,
        deaths_continent AS continent,
        vaccinations_location AS location,
        CAST(population AS BIGINT) AS population,
        total_vaccinations,
        people_vaccinated,
        people_fully_vaccinated,
        total_boosters,
        new_vaccinations,
        ROUND(
            SUM(new_vaccinations) OVER (
                PARTITION BY vaccinations_location 
                ORDER BY date 
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ) / 7, 2
        ) AS rolling_avg_new_vaccinations,
        ROUND((people_vaccinated::NUMERIC / population::NUMERIC) * 100, 2) AS vaccination_rate
    FROM covid_combined
    WHERE new_vaccinations IS NOT NULL
        AND vaccinations_location IS NOT NULL
        AND deaths_continent IS NOT NULL
)
SELECT * FROM VaccinationTrends
ORDER BY continent, location, date;

-- 8. Analyze survival trends based on ICU and hospitalization data, including rolling averages and mortality rates.

WITH SurvivalAnalysis AS (
    SELECT 
        date,
        deaths_continent AS continent,
        deaths_location AS location,
        CAST(population AS BIGINT) AS population,
        total_cases,
        total_deaths,
        new_deaths,
        icu_patients,
        hosp_patients,
        weekly_icu_admissions,
        weekly_hosp_admissions,
        ROUND((icu_patients::NUMERIC / NULLIF(total_cases, 0)) * 100, 2) AS icu_admission_rate,
        ROUND((hosp_patients::NUMERIC / NULLIF(total_cases, 0)) * 100, 2) AS hospitalization_rate,
        ROUND((total_deaths::NUMERIC / NULLIF(total_cases, 0)) * 100, 2) AS mortality_rate,
        ROUND(100 - (total_deaths::NUMERIC / NULLIF(total_cases, 0)) * 100, 2) AS estimated_recovery_rate,
        ROUND(
            AVG(weekly_icu_admissions) OVER (
                PARTITION BY deaths_location 
                ORDER BY date 
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 2
        ) AS rolling_avg_weekly_icu_admissions,
        ROUND(
            AVG(weekly_hosp_admissions) OVER (
                PARTITION BY deaths_location 
                ORDER BY date 
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 2
        ) AS rolling_avg_weekly_hosp_admissions
    FROM covid_combined
    WHERE total_cases IS NOT NULL 
        AND total_deaths IS NOT NULL
        AND deaths_location IS NOT NULL
        AND deaths_continent IS NOT NULL
)
SELECT * FROM SurvivalAnalysis
ORDER BY continent, location, date;

-- 9. Analyze the network of infection spread across different locations by evaluating infection density, spread rate, mortality, 
-- and government intervention effectiveness.

WITH InfectionSpread AS (
    SELECT 
        date,
        deaths_continent AS continent,
        deaths_location AS location,
        CAST(population AS NUMERIC) AS population,
        total_cases,
        new_cases,
        total_deaths,
        new_deaths,
        reproduction_rate,
        stringency_index,
        ROUND((total_cases::NUMERIC / NULLIF(CAST(population AS NUMERIC), 0)) * 100, 2) AS infection_density,
        ROUND((total_deaths::NUMERIC / NULLIF(total_cases, 0)) * 100, 2) AS mortality_rate,
        ROUND(
            AVG(new_cases) OVER (
                PARTITION BY deaths_location 
                ORDER BY date 
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 2
        ) AS rolling_avg_new_cases
    FROM covid_combined
    WHERE total_cases IS NOT NULL
        AND new_cases IS NOT NULL
        AND deaths_location IS NOT NULL
        AND deaths_continent IS NOT NULL
)
SELECT * FROM InfectionSpread
ORDER BY continent, location, date;

-- 10. Can we detect a structural break in COVID-19 case trends to identify when significant changes occurred in transmission rates?

WITH daily_change AS (
    SELECT 
        date,
        deaths_continent AS continent,
        deaths_location AS location,
        new_cases,
        LAG(new_cases) OVER (PARTITION BY deaths_location ORDER BY date) AS prev_cases,
        new_deaths,
        LAG(new_deaths) OVER (PARTITION BY deaths_location ORDER BY date) AS prev_deaths
    FROM covid_combined
    WHERE deaths_continent IS NOT NULL AND deaths_location IS NOT NULL
),
growth_rate AS (
    SELECT 
        date,
        continent,
        location,
        new_cases,
        prev_cases,
        new_deaths,
        prev_deaths,
        ROUND((new_cases - prev_cases) / NULLIF(prev_cases, 0), 2) AS case_growth_rate,
        ROUND((new_deaths - prev_deaths) / NULLIF(prev_deaths, 0), 2) AS death_growth_rate
    FROM daily_change
),
z_scores AS (
    SELECT 
        date,
        continent,
        location,
        new_cases,
        prev_cases,
        new_deaths,
        prev_deaths,
        case_growth_rate,
        death_growth_rate,
        ROUND(AVG(case_growth_rate) OVER (PARTITION BY location), 2) AS mean_case_growth,
        ROUND(STDDEV(case_growth_rate) OVER (PARTITION BY location), 2) AS std_dev_case,
        ROUND(AVG(death_growth_rate) OVER (PARTITION BY location), 2) AS mean_death_growth,
        ROUND(STDDEV(death_growth_rate) OVER (PARTITION BY location), 2) AS std_dev_death,
        ROUND((case_growth_rate - AVG(case_growth_rate) OVER (PARTITION BY location)) / 
              NULLIF(STDDEV(case_growth_rate) OVER (PARTITION BY location), 0), 2) AS case_z_score,
        ROUND((death_growth_rate - AVG(death_growth_rate) OVER (PARTITION BY location)) / 
              NULLIF(STDDEV(death_growth_rate) OVER (PARTITION BY location), 0), 2) AS death_z_score
    FROM growth_rate
)
SELECT 
    date,
    continent,
    location,
    new_cases,
    prev_cases,
    new_deaths,
    prev_deaths,
    case_growth_rate,
    death_growth_rate,
    mean_case_growth,
    std_dev_case,
    mean_death_growth,
    std_dev_death,
    case_z_score,
    death_z_score
FROM z_scores
WHERE ABS(case_z_score) > 2 OR ABS(death_z_score) > 2
ORDER BY continent, location, date;
