-- CovidDeaths Table

select*
from CovidDeaths$
order by 3, 4


-- Select data we will be using for this analysis
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths$
order by 1, 2


-- Total cases x total deaths: calculating the % of people who died (always multiple by 100 for percentages)
-- Shows the likelihood of dying if you contract COVID in your Country (analysing Australia)

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths$
where location like 'Australia'
order by 1, 2

-- (1) By looking at results, we can say that on the date 30/April/21, it was a 3.05% of chance of people dying if they get COVID in the Australia.
-- (2) When we look at the results, we noticed that death percentage in Australia was its highest on 08/March/2020, with about 3.95%, which is very controlled rate compared to other Countries.



-- Total cases x Population
-- Shows what percentage of population got COVID

select location, date, population, total_cases, (total_cases/population)*100 as COVIDPercentage
from CovidDeaths$
where location like 'Australia'
order by 1, 2

-- (3) We see that population in Australia is about 25.49 million people, and in the beginning of the Pandemic on 26/January/2020, we see a total of 4 cases which is about 1.57%.


-- Countries with Highest Infection rate compared to population (since we are lookig for the highest, we don't want to look at every single case but the overall cases, so we use MAX total cases
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as COVIDPercentage
from CovidDeaths$
Group By location, population
order by COVIDPercentage desc

-- (5) The first Country with 17% is Andorra. Not a big surprise since it has a small population. But looking at USA with a 9.77%, means that the Country just didn't keep it under control since a large amount of the population has gotten COVID.
-- (6) Australia is in the 161 place with less than 1% of population getting infected with COVID.


-- Countries with Highest Deah Count per Population
select location, MAX(total_deaths) as TotalDeathsCount
from CovidDeaths$
Group By location
order by TotalDeathsCount desc

-- (7) The results are not accurate since it is not showing the exact order. This is an issue with how the data type is read when using this aggregate function.
-- To fix it, we needd to convert or cast it. So, let's cast this as an integer so that is read as a numeric. (A common issue that we need to pay attention on data type)

select location, MAX(cast(total_deaths as int)) as TotalDeathsCount
from CovidDeaths$
Group By location
order by TotalDeathsCount desc

-- (8) Even though the results are more accurated now, we still have the issue of showing locations that shouldn't be there such as world, Africa, South America because they are grouping entire continents.
-- It's another issue with data type. When we go to CovidDeaths table, we see that, Continent and Location columns might get mixed up. To fix it, let's specify that we don't want NULL continents.

select location, MAX(cast(total_deaths as int)) as TotalDeathsCount
from CovidDeaths$
where continent is not null
Group By location
order by TotalDeathsCount desc

-- (9) Now we can see that USA is the number one in total deaths due to COVID, followed by Brazil.
-- (10) While Australia is in 101 place with 910 total deaths.


-- Count TotalDeaths by Continent instead of Countries
select continent, MAX(cast(total_deaths as int)) as TotalDeathsCount
from CovidDeaths$
where continent is not null
Group By continent
order by TotalDeathsCount desc

-- (11) Here, we can see the total deaths by continent showing North America as the highest total death continent. 
-- We noticed that it's not perfect because North America is including only USA count, not including Canada for example. However, for the purpose of this project, we'll work with thid data not being too precise.


-- Count TotalDeaths by location using continent is NULL (Just to verify numbers)
select location, MAX(cast(total_deaths as int)) as TotalDeathsCount
from CovidDeaths$
where continent is null
Group By location
order by TotalDeathsCount desc

-- The results now look more accurated.

-- GLOBAL NUMBER

-- 1. Total cases and total deaths per day
select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from CovidDeaths$
where continent is not null
group by date
order by 1, 2

-- (13) Results bring the total amount of cases, deaths, and percentage of deaths per day worldwide.

-- If we want to see the general total cases, we remove the date.
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from CovidDeaths$
where continent is not null
order by 1, 2

-- (14) Result brings the total cases, deaths, and percentage of deaths worldwide for the entire time data was collected.


-- Join CovidVaccinations Table (with location and date)

select *
from CovidDeaths$ dea
join CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
order by 1, 2 

-- Total population vs vaccinations per day
select dea.continent, dea.location, dea.date, dea.population, vac. new_vaccinations
from CovidDeaths$ dea
join CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- (15) Results show us the new vaccinations per day per location.

-- Let's add new vaccinations together per location
select dea.continent, dea.location, dea.date, dea.population, vac. new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths$ dea
join CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- (16) We just created a column that sums up the new vaccinations per location.

-- Total population vs the vaccinations (create a CTE or Temp table)

-- CTE example
with PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(select dea.continent, dea.location, dea.date, dea.population, vac. new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths$ dea
join CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null)
Select *, (RollingPeopleVaccinated/Population)*100 as Pop_Vac
from PopvsVac

-- (17) From the result table, we can see that, on 28/April/2021, about 33.98% of the Canadian population was vaccinated.

-- Temp Table example
DROP Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population numeric, 
New_vaccinations numeric, 
RollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac. new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths$ dea
join CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
Select *, (RollingPeopleVaccinated/Population)*100 as Pop_Vac
from #PercentPopulationVaccinated

-- (18) Using a temp table, we get the same result: on 28/April/2021, about 33.98% of the Canadian population was vaccinated.
-- I personally found CTE easier to query than temp table in this case.

-- DROP Table if exists"" statement is used in database management systems to remove a table only if it exists, preventing errors if the table doesn't exist.


-- Create view to store data for later visualization
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac. new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths$ dea
join CovidVaccinations$ vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null

-- Use crt + shift + R to remove red underlines in query
-- (19) Work View Table.

