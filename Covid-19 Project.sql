--This project is courtesy of Alex the Analyst. This is part 1 of his data analyst projects series

SELECT *
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

-- SELECT *
-- FROM covid_vaccinations 
-- ORDER BY 3, 4

--Selecting the data I will be working with 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths cd 
WHERE continent IS NOT NULL
ORDER BY location, date

-- Looking at total deaths vs total cases
-- Shows the likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 death_percentage
FROM covid_deaths cd
-- WHERE location LIKE '%eswatini%'
WHERE continent IS NOT NULL
ORDER BY location, date


-- Looking at the total cases vs the population
-- Shows what percentage of the population got covid

SELECT location, date, total_cases, population, (total_cases/population)*100 case_percentage
FROM covid_deaths cd
-- WHERE location LIKE '%eswatini%'
WHERE continent IS NOT NULL
ORDER BY location, date

-- What countries have the highest infection rates?

SELECT location, population, MAX(total_cases) highest_infection_count, (MAX(total_cases)/population)*100 case_percentage
FROM covid_deaths cd
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY case_percentage DESC

-- How many people died from covid by country?

SELECT location, MAX(CAST (total_deaths AS INT)) AS total_death_count
FROM covid_deaths cd
WHERE continent IS NOT NULL AND continent != ''
GROUP BY location
ORDER BY total_death_count DESC
 
-- Let's break things down by continent

SELECT location, MAX(CAST (total_deaths AS INT)) AS total_death_count
FROM covid_deaths cd
WHERE continent IS NULL OR continent = ''
GROUP BY location
ORDER BY total_death_count DESC


-- What continents have the highest death counts

SELECT continent, MAX(CAST (total_deaths AS INT)) AS total_death_count
FROM covid_deaths cd
WHERE continent IS NOT NULL AND continent != ''
GROUP BY continent
ORDER BY total_death_count DESC;



-- Global numbers


SELECT date, SUM(new_cases), SUM(new_deaths), SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths cd 
WHERE continent IS NOT NULL AND continent != ''
GROUP BY date
ORDER BY 1, 2

SELECT date, SUM(new_cases), SUM(new_deaths), SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths cd 
WHERE continent IS NOT NULL AND continent != ''
--GROUP BY date
ORDER BY 1, 2


-- Lookin at total population vs vaccinations

SELECT cd.continent, cd.location, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER (Partition by cd.location Order by cd.location, cd.date) AS rolling_people_vaccinated
FROM covid_deaths cd 
JOIN covid_vaccinations cv 
	ON cd.date = cv.date
WHERE cd.continent IS NOT NULL AND cd.continent != ''
ORDER BY 2, 3

Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population real,
New_vaccinations real,
RollingPeopleVaccinated real
)

Insert into PercentPopulationVaccinated
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(cv.new_vaccinations) OVER (Partition by cd.Location Order by cd.location, cd.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid_deaths cd
Join covid_vaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated;

-- Creating View to store data for later visualizations

Create View Percent_Population_Vaccinated as
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(cv.new_vaccinations) OVER (Partition by cd.Location Order by cd.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM covid_deaths cd 
JOIN covid_vaccinations cv 
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL AND cd.continent != ''

