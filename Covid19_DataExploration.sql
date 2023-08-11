SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjects.coviddeaths
WHERE continent is not null
ORDER BY 1, 2;


-- Insights on Total Cases v Total Deaths
-- Shows likelihood of dying after contracting Covid by Country (Ireland & Uruguay)

SELECT location, date, total_cases, new_cases, total_deaths, population, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProjects.coviddeaths
WHERE location IN ('Ireland', 'Uruguay')
and continent is not null
ORDER BY 1, 2;


-- Insights on Total Cases v Population
-- Shows percentage of population w/Covid (Ireland & Uruguay)

SELECT location, date, total_cases, population, (total_cases/population)*100 as CasePercentage
FROM PortfolioProjects.coviddeaths
WHERE location IN ('Ireland', 'Uruguay')
and continent is not null
ORDER BY 1, 2;


-- Insights on Countries with Highest Infection Rate Compared to Population

SELECT location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 as CasePercentage
FROM PortfolioProjects.coviddeaths
-- WHERE location IN ('Ireland', 'Uruguay')
WHERE TRIM(continent) <> ""
GROUP BY location, population
ORDER BY CasePercentage DESC;


-- Looking into Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths as signed)) as TotalDeathCount
FROM PortfolioProjects.coviddeaths
WHERE TRIM(continent) <> ""
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Exploring Data by Continent with Highest Death Count by Population

SELECT continent, MAX(cast(total_deaths as signed)) as TotalDeathCount
FROM PortfolioProjects.coviddeaths
WHERE TRIM(continent) <> ""
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- Exploring Global Numbers

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as signed)) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as GlobalDeathPercentage
FROM PortfolioProjects.coviddeaths
WHERE TRIM(continent) <> ""
GROUP BY date
ORDER BY 1, 2;


-- Vaccination Insights
-- Looking at Total Population v Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as signed)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccineCount
FROM PortfolioProjects.coviddeaths dea
JOIN PortfolioProjects.covidvaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3;


-- Creating a CTE (to be able to use RollingCount column)

WITH PopVsVac AS
(
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as signed)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccineCount
FROM PortfolioProjects.coviddeaths dea
JOIN PortfolioProjects.covidvaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingVaccineCount/population)*100 as VaccinatedPpplPercentage
FROM PopVsVac;


-- Creatinng View to store data for later visualizations

CREATE View PortfolioProjects.VaccinatedPpplPercentage as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as signed)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccineCount
FROM PortfolioProjects.coviddeaths dea
JOIN PortfolioProjects.covidvaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null

