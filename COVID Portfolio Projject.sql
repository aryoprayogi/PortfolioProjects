USE PortfolioProject;

SELECT * FROM CovidDeaths;
SELECT * FROM CovidVaccinations;

-----------------------------------------------------------------------------------------------------------------------------------------
								-- Select data that we are going to be using, understands the data !.

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2; --order by location and date.


-----------------------------------------------------------------------------------------------------------------------------------------
												-- Looking at Total Cases vs Total Deaths:
											-- And also calculate the total death percentage.

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;


-----------------------------------------------------------------------------------------------------------------------------------------
											-- Death Percentage Just for United States.

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths 
WHERE Location LIKE '%states%'
ORDER BY 1,2;


-----------------------------------------------------------------------------------------------------------------------------------------
											-- Calculate total death for each locations.

SELECT Location, sum(cast(total_deaths as int)) AS TotalDeath
FROM PortfolioProject..CovidDeaths
GROUP BY Location;




-----------------------------------------------------------------------------------------------------------------------------------------
                                      -- Look for locations with the highest total deaths

WITH TotalDeathsPerLocation AS (
    SELECT Location, SUM(CAST(total_deaths AS int)) AS TotalDeath
    FROM PortfolioProject..CovidDeaths
    WHERE Location NOT LIKE '%World%' 
      AND Location NOT LIKE '%Europe%' 
      AND Location NOT LIKE '%North America%'
    GROUP BY Location
)
SELECT Location, TotalDeath
FROM TotalDeathsPerLocation
WHERE TotalDeath = (SELECT MAX(TotalDeath) FROM TotalDeathsPerLocation);


-----------------------------------------------------------------------------------------------------------------------------------------
                                      -- Look for locations with the lowest total deaths

WITH TotalDeathsPerLocation AS (
    SELECT Location, SUM(CAST(total_deaths AS int)) AS TotalDeath
    FROM PortfolioProject..CovidDeaths
    WHERE Location NOT LIKE '%World%' 
      AND Location NOT LIKE '%Europe%' 
      AND Location NOT LIKE '%North America%'
    GROUP BY Location
)
SELECT Location, TotalDeath
FROM TotalDeathsPerLocation
WHERE TotalDeath = (SELECT MIN(TotalDeath) FROM TotalDeathsPerLocation);




-----------------------------------------------------------------------------------------------------------------------------------------
                                            -- Look at Total Cases vs Population
								      -- Shows what percentage of population got Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2;

											    -- Not only in United States

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
ORDER BY 1,2;




-----------------------------------------------------------------------------------------------------------------------------------------
                               -- Looking at countries with highest infection rate compared to population

SELECT location,  population, MAX(total_cases) AS HighestInfectionCount, 
MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC; --Desc to look from the highest to lowest.



-----------------------------------------------------------------------------------------------------------------------------------------
                               -- Showing countries with highest death count per population

SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
GROUP BY location
ORDER BY TotalDeathCount DESC;

SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC;



-----------------------------------------------------------------------------------------------------------------------------------------
                                               -- Break things down by CONTINENT

SELECT location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC;



-----------------------------------------------------------------------------------------------------------------------------------------
                                  -- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;



-----------------------------------------------------------------------------------------------------------------------------------------
                                                       -- GLOBAL NUMBERS

-- PER DAY													   
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
SUM(CAST(new_deaths AS INT)) / SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;


--Throughout the dataset period
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
SUM(CAST(new_deaths AS INT)) / SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;



-----------------------------------------------------------------------------------------------------------------------------------------
                                                     
SELECT * FROM PortfolioProject..CovidVaccinations;



-----------------------------------------------------------------------------------------------------------------------------------------
										   -- Looking at total population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;
-- Partition by location -> so that when the location changes, the cumulative sum will reset again from 0.
-- The cumulative (RollingPeopleVaccinated) can be seen from the 756th data line.




								     -- USE CTE (Common Table Expression -> temporary tables) 

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/dea.population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentPopulationVaccinated
FROM PopvsVac
ORDER BY 2,3;



-----------------------------------------------------------------------------------------------------------------------------------------
								    -- Creating View to store data for later vizualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;



SELECT * FROM PercentPopulationVaccinated;
