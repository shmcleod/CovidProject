SELECT * FROM PProject..CovidDeathsM
ORDER BY 3,4

--SELECT * FROM PortfolioProject..CovidVaccinations

-- Select Data Being Used

SELECT location, date, total_cases, total_deaths, population
FROM Pproject..CovidDeathsM

-- Alter date types when needed

ALTER TABLE Pproject..CovidDeathsM
ALTER COLUMN total_deaths float;

ALTER TABLE Pproject..CovidDeathsM
ALTER COLUMN total_cases float;

ALTER TABLE Pproject..CovidDeathsM
ALTER COLUMN population float;

ALTER TABLE Pproject..CovidDeathsM
ALTER COLUMN date date;

ALTER TABLE Pproject..CovidDeathsM
ALTER COLUMN new_cases float;

ALTER TABLE Pproject..CovidDeathsM
ALTER COLUMN new_deaths float;

ALTER TABLE Pproject..CovidDeathsM 
ALTER COLUMN continent VARCHAR(50);

-- This needed for showing TotalDeathCount because location was showing continents

UPDATE Pproject..CovidDeathsM
SET continent = NULL
WHERE continent = ' '

-- Examine diffence between Total Cases vs Total Deaths (% Difference)
-- Shows the likelihood of death due to COVID
 
SELECT location, date, total_cases, total_deaths, 
	(total_deaths/NULLIF(total_cases,0)*100) AS DeathPercentage
FROM Pproject..CovidDeathsM
WHERE LOCATION like '%states%'
ORDER BY 1,2;

SELECT location, date, total_cases, total_deaths, 
	(total_deaths/NULLIF(total_cases,0))*100 AS DeathPercentage
FROM Pproject..CovidDeathsM
ORDER BY 1,2;

-- Looking at Total Cases vs. Population
-- Shows what % of population infected by COVID

SELECT location, date, population, total_cases, 
	(total_cases/population)*100 AS InfectedPopPercentage
FROM Pproject..CovidDeathsM
WHERE LOCATION like '%states'
ORDER BY date desc;

-- Looking at Countries with Highest Infection Rates compared to Populations

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
	MAX(nullif(total_cases,0)/nullif(population,0))*100 AS InfectedPopPercentage
FROM Pproject..CovidDeathsM
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectedPopPercentage DESC;

-- Showing countries with highest death count per population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM Pproject..CovidDeathsM
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Break things down by continent Total Death Count

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM Pproject..CovidDeathsM
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global numbers per day

SELECT date, SUM(new_cases) as TotalCasesPerDay
FROM Pproject..CovidDeathsM
--WHERE LOCATION like '%states%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- Global numbers per day

SELECT date, SUM(new_cases) as NewCases, SUM(new_deaths) as NewDeaths
FROM Pproject..CovidDeathsM
--WHERE LOCATION like '%states%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;


-- Death Percentage Globally per Day

SELECT date, SUM(new_cases) as tota_cases, SUM(new_deaths) as total_deaths,
SUM(new_deaths)/SUM(NULLIF(new_cases,0))*100 as DeathPrecentage
FROM Pproject..CovidDeathsM
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- ALTERNATIVE - IF the above calculation does not work (getting 0's for all DeathPercentage) the below will work.
-- Had to change the data type of both new deaths and new cases to float and not bigINT/INT for the above. DO NOT use CAST here.

SELECT date, 
       SUM(new_cases) AS total_cases, 
       SUM(new_deaths) AS total_deaths, 
       (SUM(new_deaths) * 100.0) / (SUM(NULLIF(new_cases, 0)))AS DeathPercentage
FROM Pproject..CovidDeathsM
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1, 2


-- Total Death Percentage

SELECT SUM(new_cases) as NewCases, SUM(new_deaths) as NewDeaths,
SUM(new_deaths)/SUM(NULLIF(new_cases,0))*100 as TotalDeathPrecentage
FROM Pproject..CovidDeathsM
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;


-- Looking at COVID Vaccinations

SELECT * FROM Pproject..CovidVaccinationsM

-- Altering Columns as needed

ALTER TABLE Pproject..CovidVaccinationsM
ALTER COLUMN new_vaccinations bigINT;

-- Joining Tables Together

SELECT *
FROM Pproject..CovidDeathsM dea
JOIN Pproject..CovidVaccinationsM vac
	ON dea.location = vac.location
	AND dea.date = vac.date;

-- Total Vaccinations in the world per day

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM Pproject..CovidDeathsM dea
JOIN Pproject..CovidVaccinationsM vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- Rolling Count of Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (partition by dea.Location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM Pproject..CovidDeathsM dea
JOIN Pproject..CovidVaccinationsM vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;


-- Total Population vs Vaccinated Percentage

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (partition by dea.Location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM Pproject..CovidDeathsM dea
JOIN Pproject..CovidVaccinationsM vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/cast(population as float))*100 FROM PopvsVac

-- Temp Table

-- DROP TABLE if Exists 
CREATE TABLE #PercentPopulationVaccinated (
continent varchar(150),
location varchar(150),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)
 -- Inserting Data 

INSERT INTO #PercentPopulationVaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (partition by dea.Location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM Pproject..CovidDeathsM dea
JOIN Pproject..CovidVaccinationsM vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- Order By 2,3

-- Selecting New Table

SELECT *, (rolling_people_vaccinated/cast(population as float))*100 FROM #PercentPopulationVaccinated


-- Creating View to store data for later visuals

CREATE VIEW Percent_Population_Vaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (partition by dea.Location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM Pproject..CovidDeathsM dea
JOIN Pproject..CovidVaccinationsM vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * FROM Percent_Population_Vaccinated

