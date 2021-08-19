--1.
--Globle numbers (not including any location details)
-- show total cases vs total deaths all over the world
Select SUM(new_cases) as totalcases, SUM(cast(new_deaths as int)) as totaldeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfdforlioProject..COVIDDEATH
where continent is not null
order by 1,2  

--2.
-- We take these out as they are not included in the above queries and want to stay consistent
-- European Union is part of Europe
Select location, SUM(cast(new_deaths as int)) as TotaldeathCount
From PortfdforlioProject..COVIDDEATH
Where continent is null and location not in ('World','European Union','International')
group by Location
order by TotaldeathCount desc

--3.
---- Looking at Countries with Highest Infection Rate compared to Population
Select location, COALESCE(population,0) as population, COALESCE(HigestInfectionCount,0) as HigestInfectionCount, COALESCE(CasesPercentage,0) as CasesPercentage
From(
Select location, population, MAX(total_cases) as HigestInfectionCount, MAX((total_cases/population)*100) as CasesPercentage
From PortfdforlioProject..COVIDDEATH
Where continent is not null
group by Location, population
--order by CasesPercentage desc
) as tb1
order by CasesPercentage desc

--4.
Select location, population, date, MAX(total_cases) as HigestInfectionCount, MAX((total_cases/population)*100) as CasesPercentage
From PortfdforlioProject..COVIDDEATH
group by Location, population, date
order by CasesPercentage desc

-- 5.
select DISTINCT Coviddeath.continent, Coviddeath.location, x.TotalCasesCount
from (
	Select continent, MAX(cast(total_cases as int)) as TotalCasesCount
	From PortfdforlioProject..COVIDDEATH 
	Where continent is not null
	group by continent
) as x 
inner join PortfdforlioProject..COVIDDEATH as Coviddeath on Coviddeath.continent = x.continent AND Coviddeath.total_cases=x.TotalCasesCount
order by TotalCasesCount desc