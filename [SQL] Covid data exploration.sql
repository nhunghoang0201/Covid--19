/* 
1. Data wrangling
*/

-- Replace null values with 0 to ensure data uniformity 
update PortfolioProject..CovidDeaths$
set total_cases = ISNULL(total_cases,0)
from PortfolioProject..CovidDeaths$

update PortfolioProject..CovidDeaths$
set new_cases = ISNULL(new_cases,0)
from PortfolioProject..CovidDeaths$

update PortfolioProject..CovidDeaths$
set total_deaths = ISNULL(total_deaths,0)
from PortfolioProject..CovidDeaths$

update PortfolioProject..CovidDeaths$
set new_deaths = ISNULL(new_deaths,0)
from PortfolioProject..CovidDeaths$

-- Change data types to the proper data types
ALTER TABLE PortfolioProject..CovidDeaths$
ALTER COLUMN total_deaths int

ALTER TABLE PortfolioProject..CovidDeaths$
ALTER COLUMN new_deaths int



/*
2. Data Exploration
*/

-- Show two data tables and order by date and location
select *
from PortfolioProject..CovidDeaths$
order by 2,3,4

select *
from PortfolioProject..CovidVaccinations$
order by 2,3,4

-- Show the percentage of cases per population in each country every day
select location,
       continent,
       date, 
       population, 
       total_cases, 
       round((total_cases/population)*100,4) as cases_per_population
from PortfolioProject..CovidDeaths$
where continent is not null
order by 2,1,3

-- Rank countries based on percentage of total cases per population
select location, 
       continent,  
       round(max(total_cases)/max(population)*100,4) as cases_per_population,
       rank() over ( order by round(max(total_cases)/max(population)*100,4) desc) as rank_percentage 
from PortfolioProject..CovidDeaths$
where continent is not null
group by location, continent
order by cases_per_population desc

-- Rank countries based on percentage of total deaths per population
select location, 
       continent,  
       round(max(total_deaths)/max(population)*100,4) as deaths_per_population,
       rank() over ( order by round(max(total_deaths)/max(population)*100,4) desc) as rank_percentage 
from PortfolioProject..CovidDeaths$
where the continent is not null
group by location, continent
order by percentage_of_total_deaths_to_population desc

-- Show the percentage of total vaccinated people per population in each country every day
select vac.location, 
       vac.continent,
       vac.date, 
       dea.population, 
       vac.people_vaccinated, 
       vac.people_fully_vaccinated,
       vac.total_vaccinations,
       round((vac.people_vaccinated/dea.population)*100,4) as vaccinated_population_percentage,
       round((vac.people_fully_vaccinated/dea.population)*100,4) as fully_vaccinated_population_percentage
from PortfolioProject..CovidVaccinations$ vac left join PortfolioProject..CovidDeaths$ dea on vac.location = dea.location and vac.date = dea.date
where vac.continent is not null
order by 2,1,3

-- Rank countries based on percentage of vaccinated people to population and fully vaccinated people to the population
select vac.location,
       vac.continent,
       dea.population,	   
       round(max(vac.people_vaccinated)/max(dea.population)*100,4) as vaccinated_population_percentage,	  
       round(max(vac.people_fully_vaccinated)/max(dea.population)*100,4) as fully_vaccinated_population_percentage, 
       rank() over ( order by round(max(vac.people_vaccinated)/max(dea.population)*100,4) desc) as rank_percentage_people_vaccinated,	   
       rank() over ( order by round(max(vac.people_fully_vaccinated)/max(dea.population)*100,4) desc) as rank_percentage_people_fully_vaccinated
from PortfolioProject..CovidVaccinations$ vac left join PortfolioProject..CovidDeaths$ dea on vac.location = dea.location and vac.date = dea.date
where vac.continent is not null
group by vac.location, vac.continent, dea.population
order by vaccinated_population_percentage desc

-- Calculate the daily new vaccinations in each continent
select a.location, 
       a.continent, 
       a.date, 
       a.total_vaccinations, 
       a.total_vaccinations - b.total_vaccinations as new_vaccinations
from PortfolioProject..CovidVaccinations$ a left join PortfolioProject..CovidVaccinations$ b on a.location = b.location and a.date -1 = b.date
where a.continent is null and a.location not like '%income'
order by 1,2,3

-- Calculate the daily percentage of the population vaccinated in the world
Drop table if exists #Percentagepopulationvaccinated
create table #Percentagepopulationvaccinated
(date datetime,
population numeric,
people_vaccinated numeric,
new_people_vaccinated numeric,
people_fully_vaccinated numeric,
new_people_fully_vaccinated numeric
)

insert into #Percentagepopulationvaccinated
select a.date, 
       dea.population, 
       a.people_vaccinated, 
       a.people_vaccinated - b.people_vaccinated as new_people_vaccinated, 
       a.people_fully_vaccinated, 
       a.people_fully_vaccinated - b.people_fully_vaccinated as new_people_fully_vaccinated
from PortfolioProject..CovidVaccinations$ a 
left join PortfolioProject..CovidVaccinations$ b on a.date -1 = b.date
left join PortfolioProject..CovidDeaths$ dea on a.date = dea.date and a.location = dea.location
where a.location ='world'
order by 1

select *,round(new_people_vaccinated*100/population,4),round(new_people_fully_vaccinated*100/population,4)
from #Percentagepopulationvaccinated 
order by 1



/*
3. Creating View to store data for later visualizations
*/

Create View table_1 as 
select dea.location, 
       dea.continent, 
       dea.date, 
       dea.population, 
       dea.total_cases, 
       dea.new_cases, 
       dea.total_deaths, 
       dea.new_deaths, 
       vac.total_vaccinations, 
       vac.people_vaccinated, 
       vac.people_fully_vaccinated
from PortfolioProject..CovidDeaths$ dea
left join PortfolioProject..CovidVaccinations$ vac on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
