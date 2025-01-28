-- COVID 19 Deaths

-- Agggregating Data

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

-- Checking the New table

SELECT * FROM covid_combined;