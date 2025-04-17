SET SQL_SAFE_UPDATES=0;
USE olympics;

SHOW TABLES;

-- to update the games column
UPDATE olympics.athlete_events
SET games = concat(games, " - ", NOC); 


-- Records of the athlete_events table
SELECT *
FROM olympics.athlete_events
LIMIT 8;

-- Records of the regions table
SELECT *
FROM olympics.noc_regions
LIMIT 4;

-- How many olympics games have been held
SELECT count(distinct games) AS Total_games
FROM olympics.athlete_events;

-- All olympics games held so far
SELECT distinct games AS Games_held
FROM olympics.athlete_events;

-- The total no of nations who participated in each olympics game
WITH All_region AS 
		(SELECT games, reg.region
		FROM olympics.athlete_events athe
		JOIN noc_regions reg
		ON athe.noc=reg.noc
		GROUP BY games, region)
SELECT games, count(distinct region) AS Num_of_nations
FROM All_region
GROUP BY games
ORDER BY games;

-- Which year saw the highest and lowest no of countries participating in olympics
WITH All_countries AS (
			SELECT games, reg.region
			FROM olympics.athlete_events athe
			JOIN noc_regions reg
			ON athe.noc=reg.noc
			GROUP BY games, region
			ORDER BY games),
Total_country AS
			(SELECT games, count(distinct region) AS Num_of_country
			FROM All_countries
			GROUP BY games
			ORDER BY games)
SELECT distinct
		  CONCAT(first_value(games) OVER (order by Num_of_country) , "-", 
		  first_value(Num_of_country) OVER (order by Num_of_country)) AS Lowest_num_of_country,
		 CONCAT(first_value(games) OVER (order by Num_of_country desc), "-",
		  first_value(Num_of_country) OVER (order by Num_of_country desc)) AS Highest_num_of_country
FROM Total_country;

-- Which nation has participated in all of the olympic games
WITH All_countries AS 
		(SELECT games, reg.region
		FROM olympics.athlete_events athe
		JOIN noc_regions reg
		ON athe.noc=reg.noc
		GROUP BY games, region)
SELECT region
FROM All_countries
GROUP BY region
HAVING COUNT(DISTINCT games) = (SELECT COUNT(DISTINCT games) FROM All_countries);

-- Identify the sport which was played in all summer olympics
WITH t1 AS(
		SELECT distinct games, sport
		FROM athlete_events
		WHERE season =  "Summer"),
 t2 AS (
		SELECT count(distinct games) AS Tot_games
		FROM athlete_events
		WHERE season = "Summer"),
  t3 AS (
		  SELECT sport, count(1) AS num_games
		 FROM t1 GROUP BY sport)
SELECT *
FROM t3
JOIN t2
ON t2.tot_games = t3.num_games;

-- Which Sports were just played only once in the olympics

WITH All_games AS (
			SELECT distinct sport, games 
			FROM athlete_events		
			GROUP BY sport,games),
All_sports AS (SELECT sport,count(1) AS num_of_sport
		FROM All_games
		group by sport)
SELECT All_games.*, All_sports.num_of_sport
FROM All_games
JOIN All_sports
ON All_games.sport = All_sports.sport
WHERE num_of_sport =1
ORDER BY All_games.sport;

-- Fetch the total no of sports played in each olympic games
SELECT games, count(sport) AS Num_of_sports
FROM (
		SELECT distinct sport, games
		FROM olympics.athlete_events
		GROUP BY sport, games) w
GROUP BY games
ORDER BY  Num_of_sports DESC;

-- details of the oldest athletes to win a gold medal
SELECT *
FROM olympics.athlete_events
WHERE Medal= "Gold"
ORDER BY Age DESC
LIMIT 1;

-- Ratio of male and female athletes participated in all olympic games
WITH Count_gender AS(
			SELECT sex, count(1) AS sex_count
			FROM  olympics.athlete_events
			GROUP BY SEX),
Gender_num AS (SELECT 
				*, ROW_NUMBER() OVER(ORDER BY sex_count) AS Rankn_num
				FROM Count_gender),
Min_num AS(SELECT sex_count 
			FROM Gender_num
			WHERE Rankn_num =1),
Max_num AS (SELECT sex_count 
			FROM Gender_num
			WHERE Rankn_num =2)
SELECT concat("1:", ROUND(CAST(Max_num.sex_count AS DECIMAL) / Min_num.sex_count, 2)) AS ratio
FROM Max_num, Min_num;

-- Rename the "me" column to "Name"
ALTER TABLE olympics.athlete_events
RENAME column me TO Name;

-- the top 5 athletes who have won the most gold medals.
WITH Gold_info AS (
			SELECT Name, team, count(1) AS num_of_medal
			FROM  olympics.athlete_events
			WHERE Medal = "Gold"
			GROUP BY name, team
			ORDER BY num_of_medal DESC),
Medal_count AS (
			SELECT 
				*, DENSE_RANK() OVER(ORDER BY num_of_medal DESC) AS Rank_medal
			FROM Gold_info
			GROUP BY Name, team
			ORDER BY Rank_medal) 
SELECT *
FROM Medal_count
WHERE Rank_medal <=5;

-- the top 5 athletes who have won the most medals (gold/silver/bronze)
WITH Medal_info AS (
			SELECT
					Name, team, count(1) AS num_of_medals
			FROM  olympics.athlete_events
			WHERE Medal IN ("Gold", "Silver","bronze")
			GROUP BY Name, team
			ORDER BY num_of_medals DESC),
Medal_count AS (
			SELECT 
				*, DENSE_RANK() OVER(ORDER BY num_of_medals DESC) AS Medal_rank
			FROM Medal_info
			GROUP BY Name,team
			ORDER BY Medal_rank)
SELECT Name, team, num_of_medals
FROM Medal_count
WHERE Medal_rank <=5;

-- the top 5 most successful countries in olympics. Success is defined by no of medals won
WITH Country_medal AS (
		SELECT  reg.region, count(1) AS num_of_medals
		FROM olympics.athlete_events athe
		JOIN noc_regions reg
		ON athe.noc=reg.noc
        WHERE Medal <> " "
		GROUP BY reg.region
        ORDER BY num_of_medals DESC),
Country_position AS (
			SELECT 
				*, DENSE_RANK() OVER(ORDER BY num_of_medals DESC) AS Country_rank
			FROM Country_medal)
SELECT *
FROM Country_position
WHERE Country_rank <=5;
            
-- total gold, silver and broze medals won by each country.
SELECT
	country,
	COALESCE(SUM(CASE WHEN medal="Gold" THEN 1 ELSE 0 END),0) AS Gold,
    COALESCE(SUM(CASE WHEN medal="Silver" THEN 1 ELSE 0 END),0) AS Silver,
    COALESCE(SUM(CASE WHEN medal="Bronze" THEN 1 ELSE 0 END),0) AS Bronze
FROM (
		SELECT reg.region AS country, medal
		FROM olympics.athlete_events athe
		JOIN noc_regions reg
		ON athe.noc=reg.noc
        WHERE Medal IN ("Gold", "Silver", "Bronze")) country_medal
GROUP BY country
ORDER BY Gold DESC, silver DESC, bronze DESC;	
 
--  total gold, silver and broze medals won by each country corresponding to each olympic games.
SELECT
	SUBSTRING_INDEX(games, ' - ', 1) AS games,
    SUBSTRING_INDEX(games, ' - ', -1) AS country,
	COALESCE(SUM(CASE WHEN medal="Gold" THEN 1 ELSE 0 END),0) AS Gold,
    COALESCE(SUM(CASE WHEN medal="Silver" THEN 1 ELSE 0 END),0) AS Silver,
    COALESCE(SUM(CASE WHEN medal="Bronze" THEN 1 ELSE 0 END),0) AS Bronze
FROM olympics.athlete_events athe
JOIN noc_regions reg
ON athe.noc=reg.noc
WHERE Medal <> " "
GROUP BY games, country
ORDER BY games, country;


-- which country won the most gold, most silver and most bronze medals in each olympic games 
WITH medals_info AS (
			SELECT
				SUBSTRING_INDEX(games, ' - ', 1) AS games,
				SUBSTRING_INDEX(games, ' - ', -1) AS country,
				COALESCE(SUM(CASE WHEN medal="Gold" THEN 1 ELSE 0 END),0) AS Gold,
				COALESCE(SUM(CASE WHEN medal="Silver" THEN 1 ELSE 0 END),0) AS Silver,
				COALESCE(SUM(CASE WHEN medal="Bronze" THEN 1 ELSE 0 END),0) AS Bronze
			FROM olympics.athlete_events athe
			JOIN noc_regions reg
			ON athe.noc=reg.noc
			WHERE Medal <> " "
			GROUP BY games, country)
SELECT
	games,
    CONCAT(MAX(CASE WHEN Ranks = 1 THEN country END), ' - ', MAX(CASE WHEN Ranks = 1 THEN gold END)) AS Max_Gold,
    CONCAT(MAX(CASE WHEN Ranks = 1 THEN country END), ' - ', MAX(CASE WHEN Ranks = 1 THEN silver END)) AS Max_Silver,
    CONCAT(MAX(CASE WHEN Ranks = 1 THEN country END), ' - ', MAX(CASE WHEN Ranks = 1 THEN bronze END)) AS Max_Bronze
FROM (
		SELECT games,country, gold, silver,bronze,
				ROW_NUMBER() OVER (PARTITION BY games ORDER BY gold DESC) AS Ranks
			FROM medals_info) Rank_medals
GROUP BY games
ORDER BY games;









            
            
            
 
