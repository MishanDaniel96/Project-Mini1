create database Police_post_logs;
use Police_post_logs;
create table Police_logs(
stop_date date,
stop_time varchar (20),
country_name varchar(20),
driver_gender char(1),
driver_age_raw int(3),
driver_age int(3),
driver_race varchar(9),
violation_raw varchar(30),
violation varchar(30),
search_conducted varchar(6),
search_type varchar(20),
stop_outcome varchar(20),
is_arrested varchar(7),
stop_duration varchar(25),
drugs_related_stop varchar(6),
vechicle_number varchar(25)
);
select * from Police_logs;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/traffic_stops - traffic_stops_with_vehicle_number.csv'
INTO TABLE Police_logs
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from Police_logs;

 
 
 #Handle the NAN values 
 UPDATE Police_logs
 set search_type ="Not Reported"
 where search_type is null;
 
 #SQL QUERIES
 #1--What are the top 10 vehicle_Number involved in drug-related stops? 
 select vehicle_number,count(*) 
 as DrugStop from Police_logs
 where drugs_related_stop ='True'
 and vehicle_number is not null
 group by vehicle_number
 order by DrugStop desc
 limit 10;
 
 #2--Which vehicles were most frequently searched?
 select vehicle_number, count(vehicle_number) as SearchCount
 from Police_logs
 where search_conducted ="True"
 and vehicle_number is not null
 group by vehicle_number
 order by SearchCount asc limit 10;
 
 select * from Police_logs;
 
 #4--Which driver age group had the highest arrest rate?
 select 
 case 
 when driver_age<25 then 'Kid'
 when driver_age between 25 and 35 then 'Youngster'
 when driver_age between 36 and 50 then 'Adult'
 when driver_age between 51 and 70 then 'Mature'
 when driver_age >=71 then 'Well Mature'
 else 'Unknown'
 end as Age_Group,
 (sum(case when is_arrested ='True' then 1 else 0 end)/ count(*))*100 as Arrest_rate
 from Police_logs
 where driver_age is not null 
 group by Age_Group
 order by Arrest_Rate desc;
 
 #5--What is the gender distribution of drivers stopped in each country?
 select country_name,driver_gender,count(*) as Total_Stops
 from Police_logs
 where country_name is not null and driver_gender is not null
 group by country_name,driver_gender
 order by country_name asc;
 
 #6--Which race and gender combination has the highest search rate? 
 
 select driver_race,driver_gender, count(*) as Total_Stops,sum(case when search_conducted='True' then 1 else 0 end) as search_count,
 (sum(case when search_conducted='True' then 1 else 0 end)/ count(*))
 *100 as Search_Rate from Police_logs
 where driver_race is not null
 and driver_gender is not null
 and driver_race !='Not Reported'
 and driver_gender !='Not Reported'
 group by driver_race,driver_gender
 order by Search_Rate desc;

 
 #7--What time of day sees the most traffic stops?
 select hour(stop_time) as Stop_Hour,count(*) as Total_stops
 from Police_logs
 where stop_time is not null
 group by Stop_Hour;
 
 #8--What is the average stop duration for different violations?
 
 select violation, avg(case stop_duration
 when '0-15 Min' then 7.5
 when '16-30 Min' then 23.0
 when '30+ Min' then 23.0
 else null 
 end) as Estimated_Avg from Police_logs
 where violation is not null
 and stop_duration is not null
 group by violation;
 
 
 #9--Are stops during the night more likely to lead to arrests? 

with Stop_Time_Category as ( 
 select is_arrested,
 case when hour(stop_time)>=21 or hour(stop_time)<=5 then 'Night' else 'day'
 end as Time_of_Day from Police_logs
 where stop_time is not null)
 select Time_of_Day,count(*) as Total_Stops,
 sum(case when is_arrested='True' then 1 else 0 end) as Total_Arrests,(sum(case when is_arrested="true"
 then 1 else 0 end)/count(*)
 ) *100 as Arrest_rate
 from Stop_Time_Category
 group by Time_of_Day;
 
 #10-- Which violations are most associated with searches or arrests?
 select violation,count(*) as Total_Stops,sum(case when search_conducted='True' or is_arrested='True' then 1
 else 0 end)as Total_Actions,(sum(case when search_conducted ='True' or is_arrested='True' then 1 else 0
 end)/count(*))*100 as Action_rate from Police_logs where violation is not null
 group by violation;
 
 #11-- Which violations are most common among younger drivers (<25)? 
select violation, count(*) as Total_Stops from Police_logs
where driver_age <25
and driver_age is not null
and violation is not null
group by violation;


#12--. Is there a violation that rarely results in search or arrest?

select violation, count(*) as Total_Stops,sum(case when search_conducted ='True' or is_arrested ='True' then 1
else 0 end )as Total_actions,
(sum(case when search_conducted ='True' or is_arrested= 'True' then 1
else 0 end)/count(*))* 100 as Action_rate
from Police_logs
where violation is not null
group by violation;

#13--. Which countries report the highest rate of drug-related stops?

select country_name,count(*) as Total_Stops,
sum(case when drugs_related_stop='True' then 1 else 0 end) as Drug_count,
(sum(case when drugs_related_stop= 'True' then 1 else 0 end)/ count(*))
*100 as Drug_stop from Police_logs
where country_name is not null
group by country_name;

#14-- What is the arrest rate by country and violation?

select country_name,violation,count(*) as Total_stops,
sum( case when is_arrested='True' then 1 else 0 end) as Toatl_arrests,
(sum(case when is_arrested ='True' then 1 else 0 end)/count(*))*100 as arrest_rate
from Police_logs
where country_name is not null
and violation is not null
group by country_name,violation;

#15-- Which country has the most stops with search conducted?

select country_name,count(*) as Total_search
from Police_logs
where search_conducted='True'
and country_name is not null
group by country_name 
order by Total_search asc;



#COMPLEX
#1--Yearly Breakdown of Stops and Arrests by Country (Using Subquery and Window Functions) 

with Yearly_Data as (select year(stop_date) as Stop_year,country_name,is_arrested 
from Police_logs
where stop_date is not null 
and country_name is not null)
select Stop_Year,country_name, count(*) as Total_stops,
sum(case when is_arrested ='True' then 1 else 0 end) as Total_arrested from Yearly_Data
group by Stop_Year,country_name;

#2--.Driver Violation Trends Based on Age and Race (Join with Subquery) 

with demo as (
select  case 
when driver_age<25 then 'Kid'
 when driver_age between 25 and 35 then 'Youngster'
 when driver_age between 36 and 50 then 'Adult'
 when driver_age between 51 and 70 then 'Mature'
 when driver_age >=71 then 'Well Mature'
 else 'Unknown'
 end as Age_Group, driver_race,violation
 from Police_logs
 where driver_age is not null 
 and driver_race is not null
 and violation is not null)
 select Age_Group, driver_race,violation,count(*) as Violation_Frequency 
 from demo
 group by Age_Group,driver_race,violation;
 
 
 #3--Time Period Analysis of Stops (Joining with Date Functions) , Number of Stops 
#by Year,Month, Hour of the Day 


with time_breakdown as (
select year(stop_date) as Stop_Year,
monthname(stop_date) as Stop_Month,
hour(stop_time) as Stop_hour
from Police_logs
where 
stop_date is not null
and stop_time is not null)
select Stop_Year,Stop_Month,Stop_hour,count(*) as Total_stops
from time_breakdown
group by Stop_Year,Stop_Month,Stop_hour;

#4--Violations with High Search and Arrest Rates (Window Function) 

with violation_rates as (
select violation,count(*) as Total_stops,
sum(case when search_conducted ='True' then 1 else 0 end) as Total_search,
sum(case when is_arrested ='True' then 1 else 0 end) as Total_arrest,
(sum(case when search_conducted ='True' then 1 else 0 end)/count(*)) * 100 as Search_rate,
(sum(case when is_arrested ='True' then 1 else 0 end)/count(*))* 100 as Arrest_rate
from Police_logs
where violation is not null
group by violation),
Ranked_violations as (
select *, rank() over (order by Arrest_rate asc,Search_rate asc) as overall_rank
from violation_rates)
select violation,Total_stops,Arrest_rate,Search_rate,overall_rank
from Ranked_violations
where Total_stops >=10
order by overall_rank;

#5--Driver Demographics by Country (Age, Gender, and Race)

with Country_demo as(
select country_name,driver_age,driver_gender,driver_race,
case when driver_age<25 then 'Kid'
 when driver_age between 25 and 35 then 'Youngster'
 when driver_age between 36 and 50 then 'Adult'
 when driver_age between 51 and 70 then 'Mature'
 when driver_age >=71 then 'Well Mature'
 else 'Unknown Age'
 end as Age_Group 
 from Police_logs
 where country_name is not null
 and driver_age is not null)
 select cd.country_name,
 round(avg(cd.driver_age)) as Average_driver_age,
 sum(case when cd.driver_gender ='M' then 1 else 0 end) as total_Male_drivers,
 sum(case when cd.driver_gender='F' then 1 else 0 end) as total_female_drivers,
 sum(case when cd.driver_race='White' then 1 else 0 end)as total_white_driver,
 sum(case when cd.driver_race='Black' then 1 else 0 end)as total_black_driver,
 sum(case when cd.driver_race='Asian' then 1 else 0 end)as total_asian_driver,
 (select t.Age_Group from Country_demo t
 where t.country_name=cd.country_name
 group by t.Age_Group
 order by count(*)desc limit 1) as Most_frequent_age_group,
 count(*) as total_stops_country
 from Country_demo cd
 group by cd.country_name;
 
 
 #6--top 5 Violations with Highest Arrest Rates
 
 select violation, count(*) as Total_stops,
 sum(case when is_arrested ='True' then 1 else 0 end) as Total_arrests,
 (sum(case when is_arrested = 'True' then 1 else 0 end) / count(*))*100 as Arrest_rate_percent
 from Police_logs
 where violation is not null
 group by violation;
 
 use  Police;
 select * from Police_log;
 alter table Police_log drop column timestamp;
 
 SET SESSION wait_timeout = 3600; -- Set to 1 hour (3600 seconds)
SET SESSION interactive_timeout = 3600;