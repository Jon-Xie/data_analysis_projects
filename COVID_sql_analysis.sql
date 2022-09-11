-- data set from https://ourworldindata.org/covid-deaths 


-- observing entire dataset
select * 
from PortfolioProject..CovidDeaths
order by 3,4

select *
from PortfolioProject..CovidVaccinations
order by 3,4 

-- finding length of dataset
select count(*)
from PortfolioProject..CovidVaccinations

-- select data that we will be using 
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2

-- looking at total cases vs. total deaths 
-- shows likelihood of dying if you contract covid in the states
select location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 deathPercentage
from PortfolioProject..CovidDeaths
where location like '%states' and continent is not null
order by 1,2

-- looking at the total cases vs the population 
select location, date, total_cases, population, (total_cases/population) * 100 as populationPercentage
from PortfolioProject..CovidDeaths
where location like '%states' and continent is not null
order by 1,2 desc


-- looking at countries with highest infection rate compared to population
select location, population, MAX(total_cases) as highestInfectionCount, max((total_cases/population))* 100 as percentPopulationInfected
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by percentPopulationInfected desc 

-- showing countries with the highest death count per population
select location, MAX(cast(total_deaths as int)) as totalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by totalDeathCount desc

-- let's break things down by continent 
select continent, MAX(cast(total_deaths as int)) as totalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by totalDeathCount desc

-- global numbers for new cases and deaths 
select date, SUM(new_cases) total_new_cases, SUM(cast(new_deaths as int)) total_new_deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as deathpercentage
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2


-- use cte
with PopulationVsVaccination (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations)
as 
(	
-- looking at total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

Select *, (RollingVaccinations / Population)*100
from PopulationVsVaccination 
	
-- create a temp table
drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_Vaccinations numeric,
	RollingVaccinations numeric
)

Insert into #percentpopulationvaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RollingVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

Select *, (RollingVaccinations / Population) * 100
from #percentpopulationvaccinated


-- create a view for later use
create view percentpopulationvaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RollingVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


