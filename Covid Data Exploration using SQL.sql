SELECT * FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * FROM dbo.CovidVaccinations
--ORDER BY 3,4

#select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total_Cases vs Total_Deaths
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage 
FROM dbo.CovidDeaths
WHERE location LIKE 'India'
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population has got covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS Case_Percentage
FROM dbo.CovidDeaths
WHERE location LIKE 'India'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to the Population
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population))*100 AS Case_Percentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY Case_Percentage DESC

--Showing Countries with Highest Death Count
SELECT location, MAX(cast(total_deaths as INT)) AS Highest_Death_Count
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Highest_Death_Count DESC

SELECT location, population, MAX(total_deaths) AS Highest_Death_Count, MAX((total_deaths/population))*100 AS Death_Percentage
FROM dbo.CovidDeaths
GROUP BY population, location
ORDER BY Death_Percentage DESC

--total deaths by continent
SELECT location, MAX(cast(total_deaths as INT)) AS Highest_Death_Count
FROM dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Highest_Death_Count DESC

--total covid cases in the whole world each day
SELECT date, SUM(new_cases) as total_cases_everyday FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--total covid cases and deaths in the whole world each day
SELECT date, SUM(new_cases) AS total_cases_everyday, SUM(cast(new_deaths as INTEGER)) as new_deaths_everyday FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--new deaths percentage globally for each day
SELECT date, SUM(new_cases) AS total_cases_everyday, SUM(cast(new_deaths as INTEGER)) as new_deaths_everyday,
(SUM(cast(new_deaths AS INT))/SUM(new_cases))*100 AS new_everyday_deaths_percentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- joining the two tables ('dea' and 'vac' are alias for the two tables so that we don't have to type their full name)
SELECT * 
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--Finding Total Population vs Total Vaccinations(by aggregating daily new vaccinations)
--using this syntax instead of the above shows a step by step aggregation of vaccinations, 
--whereas the above method aggregates, all the vaccinations in one go.
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) 
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS total_vaccinations_on_a_rolling_count
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--finding total vaccinations compared to populatoin using 'total_vaccinations_on_a_rolling_count' column and CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, total_vaccinations_on_a_rolling_count)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) 
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS total_vaccinations_on_a_rolling_count
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (total_vaccinations_on_a_rolling_count/population)*100 AS vaccinations_in_relation_to_the_population 
FROM PopvsVac

--creating a temporary table for the above query
CREATE TABLE #Percentage_of_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
total_vaccinations_on_a_rolling_count numeric
)
INSERT INTO #Percentage_of_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) 
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS total_vaccinations_on_a_rolling_count
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
SELECT *, (total_vaccinations_on_a_rolling_count/population)*100 AS vaccinations_in_relation_to_the_population 
FROM #Percentage_of_population_vaccinated

-- creating views for visualisation
CREATE VIEW Percentage_of_population_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) 
OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS total_vaccinations_on_a_rolling_count
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

