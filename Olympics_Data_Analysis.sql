Olympics Data Analysis


--Q1 - Number of olympics Held
select count(year) as Total_Olympic_Games
from(select year,season ,city
	 from olympics_history 
	 group by year, season,city
	 order by year);


--Q2 - List of games held
select year,season, city
	 from olympics_history 
	 group by year, season, city
	 order by year;


--Q3 - Number of countries participated in each games.
select games,count(distinct(noc)) as total_countries 
from olympics_history
group by games;



--Q4 - Lowest and Highest number of countries participated in which olympic.

select min(co)as Min_countries,max(co) as Max_countries from
(select games,count(distinct(noc)) as total_countries ,
 concat(games,'-',count(distinct(noc))) as co
 from olympics_history
 group by games);


--Q5 - Countries that participated in all olympics.

select  * from
(select oh.noc, ohr.region, count(distinct(games)) as played from olympics_history as oh
 join olympics_history_noc_regions as ohr
 on oh.noc=ohr.noc
 group by oh.noc, ohr.region
 order by played desc) 
 where played=(select count(distinct games) from olympics_history )
;


--Q6- Identify the sport which was played in all summer olympics.


select * from
(select sport, count(distinct games) as played_in
from olympics_history
where season='Summer'
group by sport
order by played_in desc)
where played_in=(select count(distinct games) 
				 from olympics_history
				 where season='Summer'
				);


--Q7- Which Sports were just played only once in the olympics.

select oh.*,oh2.games from
(select sport, count(distinct games) as games_played
from olympics_history
group by sport
order by games_played)as oh
join (select games, sport from olympics_history 
	  group by games , sport order by games)as oh2
on oh.sport=oh2.sport
where games_played=1
order by oh.sport
;


--Q8- Fetch the total no of sports played in each olympic games.

select games, count(distinct sport) as sports_played
from olympics_history
group by games
order by sports_played desc;


--Q9- Fetch oldest athletes to win a gold medal

select * from olympics_history
where medal='Gold' and age=(select max(age) from olympics_history
where medal='Gold'and age != 'NA');


--Q10- Find the Ratio of male and female athletes participated in all olympic games.

with t1 as (select sex,count(distinct id) as cnt
			from olympics_history
			group by sex
		   ),
	t2 as (select cnt from t1 where sex='M'),
	t3 as (select cnt from t1 where sex='F')
	select concat(round(t2.cnt::decimal/t3.cnt,2),':1') as male_to_female_ratio from t2,t3;


--Q11- Fetch the top 5 athletes who have won the most gold medals.

with t1 as
	(select name, count(medal) as num from olympics_history
	where medal='Gold'
	group by  name
	order by num desc
	),
 t2 as
	(select *, dense_rank() over(order by num desc) as rnk from t1)
select * from t2
where rnk<=5;	

--Q12- Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

with t1 as
	(select name, count(medal) as num_of_medals from olympics_history
	where medal!='NA'
	group by name
	order by num_of_medals desc),
    t2 as
	(select *, dense_rank() over(order by num_of_medals desc) as rnk
	 from t1
	)
select * from t2 
where rnk<=5;


/* Q13- Fetch the top 5 most successful countries in olympics. 
Success is defined by no of medals won.*/

with t1 as
	(select noc, count(medal)as num_of_medals
	from olympics_history
	 where medal!='NA'
	group by noc
	order by num_of_medals desc),
   t2 as
   (select *, dense_rank() over(order by num_of_medals desc)as rnk from t1)
select t2.*,ohn.region from t2
join olympics_history_noc_regions as ohn
on t2.noc=ohn.noc
where rnk<=5;

		   

--Q14- List down total gold, silver and bronze medals won by each country.


--Using Crosstab function.

select noc,
coalesce(gold,0) as Gold,
coalesce(silver,0)as Silver,
coalesce(bronze,0)as Bronze
from crosstab
('select noc, medal, count(medal)
from olympics_history
where medal!=''NA''
group by noc,medal','values(''Bronze''),(''Gold''),
(''Silver'')') as result (noc varchar, Bronze bigint, Gold bigint, Silver bigint )
order by Gold desc, Silver desc, Bronze desc
;


/*Q15- List down total gold, silver and bronze medals won by each 
country corresponding to each olympic games.*/


select games,
coalesce(gold,0) as Gold,
coalesce(silver,0)as Silver,
coalesce(bronze,0)as Bronze
from crosstab
('select concat(games,'' '',noc), medal, count(medal)
from olympics_history
where medal!=''NA''
group by games,noc,medal order by games,noc,medal','values(''Bronze''),(''Gold''),
(''Silver'')') as result (games varchar,
						  Bronze bigint,
						  Gold bigint,
						  Silver bigint
						 )						 
order by games
;


/*Q16- Identify which country won the most gold,
most silver and most bronze medals in each olympic games.*/

--Using CTE

with 
  t1 as
	(select games,noc,count(medal) as gold
	from olympics_history
	where medal='Gold'
	group by games,noc
	order by games,gold desc),
  t2 as
	(select *, dense_rank() over(partition by games order by gold desc)as rnk from t1),

  t3 as
	(select games,noc,count(medal) as silver
	from olympics_history
	where medal='Silver'
	group by games,noc
	order by games,silver desc),
  t4 as
	(select *, dense_rank() over(partition by games order by silver desc)as rnk 
	 from t3),
  t5 as(select games,concat(noc,' ',gold)as max_gold from t2 where rnk<=1),
  t6 as(select games,concat(noc,' ',silver)as max_silver from t4 where rnk<=1),
  t7 as
	(select games,noc,count(medal) as bronze
	from olympics_history
	where medal='Bronze'
	group by games,noc
	order by games,bronze desc),
  t8 as
	(select *, dense_rank() over(partition by games order by bronze desc)as rnk 
	 from t7),
  t9 as (select games,concat(noc,' ',bronze)as max_bronze from t8 where rnk<=1)
select t5.games,t5.max_gold,t6.max_silver,t9.max_bronze from t5
join t6 on t5.games=t6.games
join t9 on t6.games=t9.games
;

--Q16- Using Crosstab and CTE

with t1 as
(select substring(games,1,11)as games_year,substring(games,12)as country,
coalesce(gold,0) as Gold,
coalesce(silver,0)as Silver,
coalesce(bronze,0)as Bronze
from crosstab
('select concat(games,'' '',noc), medal, count(medal)
from olympics_history
where medal!=''NA''
group by games,noc,medal order by games,noc,medal','values(''Bronze''),(''Gold''),
(''Silver'')') as result (games varchar,
						  Bronze bigint,
						  Gold bigint,
						  Silver bigint
						 )						 
order by games
),
 t2 as 
  (select *, dense_rank() over(partition by games_year order by gold desc)
   as gold_rnk from t1),
 t3 as (select games_year,concat(country,' - ',gold) from t2 where gold_rnk=1),  
 t4 as
  (select *, dense_rank() over(partition by games_year order by silver desc)
   as silver_rnk from t1),
 t5 as (select games_year,concat(country,' - ',silver) from t4 where silver_rnk=1 ),
 t6 as(select *, dense_rank() over(partition by games_year order by bronze desc)
   as bronze_rnk from t1),
 t7 as (select games_year,concat(country,' - ',bronze) from t6 where bronze_rnk=1),
 t8 as (select * from t3
	    join t5 on t3.games_year=t5.games_year
	    join t7 on t5.games_year=t7.games_year)
select * from t8




/*Q17- Identify which country won the most gold, most silver, most 
bronze medals and the most medals in each olympic games.*/


with t1 as
(select substring(games,1,11)as games_year,substring(games,12)as country,
coalesce(gold,0) as Gold,
coalesce(silver,0)as Silver,
coalesce(bronze,0)as Bronze
from crosstab
('select concat(games,'' '',noc), medal, count(medal)
from olympics_history
where medal!=''NA''
group by games,noc,medal order by games,noc,medal','values(''Bronze''),(''Gold''),
(''Silver'')') as result (games varchar,
						  Bronze bigint,
						  Gold bigint,
						  Silver bigint
						 )						 
order by games
),
 t2 as 
  (select *, dense_rank() over(partition by games_year order by gold desc)
   as gold_rnk from t1),
 t3 as (select games_year,concat(country,' - ',gold)as max_gold 
		from t2 where gold_rnk=1),--GIVES MAX GOLD  
 t4 as
  (select *, dense_rank() over(partition by games_year order by silver desc)
   as silver_rnk from t1),
 t5 as (select games_year,concat(country,' - ',silver)as max_silver from t4 
		where silver_rnk=1 ),--GIVES MAX SILVER
 t6 as(select *, dense_rank() over(partition by games_year order by bronze desc)
   as bronze_rnk from t1),
 t7 as (select games_year,concat(country,' - ',bronze)as max_bronze from t6 
		where bronze_rnk=1),--GIVES MAX BRONZE
 t8 as  (select *,(gold+silver+bronze)as total_medals
		   from t1),
 t11 as (select *,
		 dense_rank() over(partition by games_year order by total_medals desc)as rnk
		from t8),		   
 t9 as(select *,concat(country,' - ',total_medals)as max_medals
	   from t11 where rnk=1)	,  --GIVES MAX MEDALS 
 t10 as (select t3.games_year,t3.max_gold,t5.max_silver,t7.max_bronze,
		 t9.max_medals
		 from t3
	    join t5 on t3.games_year=t5.games_year
	    join t7 on t5.games_year=t7.games_year
		join t9 on t9.games_year=t7.games_year) 
select * from t10 ;


--Q18- Which countries have never won gold medal but have won silver/bronze medals?

with t1 as
		(select country,
		coalesce(gold,0)as gold_medal,
		coalesce(silver,0)as silver_medal,
		coalesce(bronze,0)as bronze_medal
		from crosstab
		('select  noc, medal,count(medal)as medals
		from olympics_history
		where medal!=''NA''
		group by noc, medal
		order by noc, medal','values(''Bronze''),(''Gold''),(''Silver'')') 
		as result(country varchar,
				 bronze bigint,
				 gold bigint,
				 silver bigint)
		) ,
	t2 as (select nr.region,t1.*  from t1
		   join olympics_history_noc_regions as nr
		   on t1.country=nr.noc
		  where gold_medal=0 
		  )
select * from t2
order by silver_medal desc,bronze_medal desc;

--19. In which Sport/event, India has won highest medals.
with t1 as
		(select noc,sport,count(medal)as medals,
		dense_rank() over(order by count(medal) desc)as rnk
		from olympics_history
		where noc='IND' and medal!='NA'
		group by noc, sport
		order by medals desc),
     t2 as(select sport,medals from t1
		   where rnk=1
		  )
select * from t2;


/*    Q20- Break down all olympic games where India won medal 
for Hockey and how many medals in each olympic games	*/ 


select noc,sport,games,count(medal) as medals
from olympics_history
where noc='IND' and sport='Hockey' and medal!='NA'
group by noc, sport,games
order by medals desc;
