

Select *
From PortfdforlioProject..COVIDDEATH as
Where continent is not null
Order by 3, 4

--Select Data that we are going to use
Select location, date, total_cases, new_cases, total_deaths, population
From PortfdforlioProject..COVIDDEATH
Where continent is not null
order by 1,2 

--Looking at the total cases vs total deaths in China
-- Shows likelihood of dying if you contract covid in China
Select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfdforlioProject..COVIDDEATH
where location like '%China%' and continent is not null
order by 1,2  

--Looking at the total cases vs population in Canada
-- Shows likelihood of dying if you contract covid in Canada
Select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfdforlioProject..COVIDDEATH
where location like '%Canada%' and continent is not null 
order by 1,2  

--Looking at the total cases vs population in US
-- Shows likelihood of dying if you contract covid in US
Select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfdforlioProject..COVIDDEATH
where location like '%states%' and continent is not null
order by 1,2  

--Comments: US recently has the lowest DeathPercentage but their total deaths is the highest. 
--			In other words, US must have a really large total cases number to lead this "low" DeathPercentage. 
--          Let's take a look at total cases percentage in those country


--Looking at Total Cases vs Population --China
--Shows that 0.0064% of population got COVID 
Select location, date, population, total_cases, (total_cases/population)*100 as CasesPercentage
From PortfdforlioProject..COVIDDEATH
where location like '%China%' and continent is not null
order by 1,2  

--Looking at Total Cases vs Population -- Canada
--Shows that 3.8% of population got COVID
Select location, date, population, total_cases, (total_cases/population)*100 as CasesPercentage
From PortfdforlioProject..COVIDDEATH
where location like '%Canada%' and continent is not null
order by 1,2 

--Looking at Total Cases vs Population  -- US
--Shows that 10% of population got COVID
Select location, date, population, total_cases, (total_cases/population)*100 as CasesPercentage
From PortfdforlioProject..COVIDDEATH
where location like '%States%' and continent is not null
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population
Select location, population, MAX(total_cases) as HigestInfectionCount, MAX((total_cases/population)*100) as CasesPercentage
From PortfdforlioProject..COVIDDEATH
Where continent is not null
group by Location, population
order by CasesPercentage desc

-- Showing Countries with Highest Death Count per Population
Select location, MAX(cast(total_deaths as int)) as TotaldeathCount
From PortfdforlioProject..COVIDDEATH
Where continent is not null
group by Location
order by TotaldeathCount desc

--Let's Break Things Down by Continent
-- Showing countries in continents with the highest death count 
select DISTINCT Coviddeath.continent, Coviddeath.location, x.TotaldeathCount
from (
	Select continent, MAX(cast(total_deaths as int)) as TotaldeathCount
	From PortfdforlioProject..COVIDDEATH 
	Where continent is not null
	group by continent
) as x 
inner join PortfdforlioProject..COVIDDEATH as Coviddeath on Coviddeath.continent = x.continent AND Coviddeath.total_deaths=x.TotaldeathCount
order by TotaldeathCount desc

--Globle numbers (not including any location details)
-- show total cases vs total deaths all over the world
Select SUM(new_cases) as totalcases, SUM(cast(new_deaths as int)) as totaldeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfdforlioProject..COVIDDEATH
where continent is not null
order by 1,2  

--Globle numbers (not including any location details)
-- show total cases vs total deaths everyday all over the world
Select date, SUM(new_cases) as totalcases, SUM(cast(new_deaths as int)) as totaldeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfdforlioProject..COVIDDEATH
where continent is not null
group by date
order by 1,2  

--Covid Vaccinations
-- Join two tables
--Looking at Total Population vs Vaccinations
Select DISTINCT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfdforlioProject..COVIDDEATH as dea
join PortfdforlioProject..COVIDVACCINE as vac
	on dea.location = vac.location and dea.date= vac.date
where dea.continent is not null
order by 2,3

--CTE
With popvsvac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(Select DISTINCT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfdforlioProject..COVIDDEATH as dea
join PortfdforlioProject..COVIDVACCINE as vac on dea.location = vac.location and dea.date= vac.date
where dea.continent is not null)
Select *, (RollingPeopleVaccinated/population)*100 as vaccinatedpercentage
from popvsvac
order by 2,3

--Temp table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select DISTINCT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfdforlioProject..COVIDDEATH as dea
join PortfdforlioProject..COVIDVACCINE as vac on dea.location = vac.location and dea.date= vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/population)*100 as vaccinatedpercentage
from #PercentPopulationVaccinated
order by 2,3

--Creating View to store data for later visualizations

Create View PercentPopulationVaccinatedView as
select DISTINCT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfdforlioProject..COVIDDEATH as dea
join PortfdforlioProject..COVIDVACCINE as vac on dea.location = vac.location and dea.date= vac.date
where dea.continent is not null
