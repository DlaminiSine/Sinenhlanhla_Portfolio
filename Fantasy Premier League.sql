-- This is a data analysis project that will look into the most recent Fanatsy Premier League data. My aim? To see how players are performing and whole the leaders are

-- First, I need to validate the data 

SELECT *
FROM cleaned_players cp 
LIMIT 50

-- Identifying duplicates

SELECT first_name, second_name, COUNT(*)
FROM cleaned_players cp 
GROUP BY first_name, second_name
HAVING COUNT(*) > 1

SELECT *
FROM cleaned_players cp 
WHERE first_name = 'Ben' AND second_name = 'Davies'

DELETE FROM cleaned_players 
WHERE first_name = 'Ben' AND second_name = 'Davies' AND goals_scored = 0

-- confirm if the row with zero values is actually deleted
SELECT *
FROM cleaned_players cp 
WHERE first_name = 'Ben' AND second_name = 'Davies'

SELECT CONCAT(first_name, ' ', second_name) AS name
FROM cleaned_players cp 
LIMIT 10

ALTER TABLE cleaned_players 
ADD name TEXT

UPDATE cleaned_players 
SET name = CONCAT(first_name, ' ', second_name)

-- The dataset is from vaastav and has no null VALUES 
 
--Moving on to the exploration of the dataset

-- Which players have the highest number of goals scored? Limit to top 20.
SELECT name, goals_scored
FROM cleaned_players cp 
ORDER BY goals_scored DESC
LIMIT 20

--Which players have the highest number of assists? Limit to top 20

SELECT name, assists
FROM cleaned_players cp 
ORDER BY assists DESC
LIMIT 20

--Which players have the lowest points?

SELECT name, total_points
FROM cleaned_players cp 
WHERE minutes > 1
ORDER BY total_points
LIMIT 20

--Count how many players have the exact number of points?

SELECT total_points, COUNT(*) AS number_of_player_with_point
FROM cleaned_players cp 
GROUP BY total_points 
ORDER BY total_points


SELECT MIN(kickoff_time)
FROM merged_gw mg 
LIMIT 5

SELECT MAX(kickoff_time)
FROM merged_gw mg 
LIMIT 5

--So this data set runs from the first game day to new years day


SELECT first_name, second_name, name
FROM cleaned_players cp 

-- Now for a comprehensive data analysis

-- Top 5 goalkeepers with the most points

SELECT cp.name, cp.total_points
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name 
WHERE mg.position = 'GK'
GROUP BY cp.name, cp.total_points 
ORDER BY cp.total_points DESC 
LIMIT 5

-- Top 5 defenders with the most points

SELECT cp.name, cp.total_points
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name 
WHERE mg.position = 'DEF'
GROUP BY cp.name, cp.total_points 
ORDER BY cp.total_points DESC 
LIMIT 5

-- Top 5 midfielders with the most points

SELECT cp.name, cp.total_points
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name 
WHERE mg.position = 'MID'
GROUP BY cp.name, cp.total_points 
ORDER BY cp.total_points DESC 
LIMIT 5

-- Top 5 forwards with the most points

SELECT cp.name, cp.total_points
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name 
WHERE mg.position = 'FWD'
GROUP BY cp.name, cp.total_points 
ORDER BY cp.total_points DESC 
LIMIT 5

SELECT minutes 
FROM cleaned_players cp 
ORDER BY minutes DESC 
LIMIT 1
-- Of the players who have not played every single minute so far, who has the most points

SELECT name, total_points, minutes
FROM cleaned_players cp 
WHERE minutes != 1530
GROUP BY name, minutes, total_points   
ORDER BY total_points DESC
LIMIT 20

-- Of the players who have played every single minute so far, who has the most points

SELECT name, total_points, minutes
FROM cleaned_players cp 
WHERE minutes = 1530
GROUP BY name, minutes, total_points   
ORDER BY total_points DESC
LIMIT 20

-- Of the goalkeepers who have not played every single minute so far, who has the most points

SELECT cp.name, cp.total_points, cp.minutes
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name
WHERE cp.minutes != 1530 AND mg.position = 'GK'
GROUP BY cp.name, cp.minutes, cp.total_points   
ORDER BY cp.total_points DESC
LIMIT 5

-- Of the goalkeepers who have played every single minute so far, who has the most points

SELECT cp.name, cp.total_points, cp.minutes
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name
WHERE cp.minutes = 1530 AND mg.position = 'GK'
GROUP BY cp.name, cp.minutes, cp.total_points   
ORDER BY cp.total_points DESC
LIMIT 5

-- Of the defenders who have not played every single minute so far, who has the most points

SELECT cp.name, cp.total_points, cp.minutes
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name
WHERE cp.minutes != 1530 AND mg.position = 'DEF'
GROUP BY cp.name, cp.minutes, cp.total_points   
ORDER BY cp.total_points DESC
LIMIT 5

-- Of the defenders who have played every single minute so far, who has the most points

SELECT cp.name, cp.total_points, cp.minutes
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name
WHERE cp.minutes = 1530 AND mg.position = 'DEF'
GROUP BY cp.name, cp.minutes, cp.total_points   
ORDER BY cp.total_points DESC
LIMIT 5

-- Of the midfielders who have not played every single minute so far, who has the most points

SELECT cp.name, cp.total_points, cp.minutes
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name
WHERE cp.minutes != 1530 AND mg.position = 'MID'
GROUP BY cp.name, cp.minutes, cp.total_points   
ORDER BY cp.total_points DESC
LIMIT 5

-- Of the midfielders who have played every single minute so far, who has the most points

SELECT cp.name, cp.total_points, cp.minutes
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name
WHERE cp.minutes = 1530 AND mg.position = 'MID'
GROUP BY cp.name, cp.minutes, cp.total_points   
ORDER BY cp.total_points DESC
LIMIT 5


-- Of the forwards who have not played every single minute so far, who has the most points

SELECT cp.name, cp.total_points, cp.minutes
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name
WHERE cp.minutes != 1530 AND mg.position = 'FWD'
GROUP BY cp.name, cp.minutes, cp.total_points   
ORDER BY cp.total_points DESC
LIMIT 5

-- Of the forwards who have played every single minute so far, who has the most points

SELECT cp.name, cp.total_points, cp.minutes
FROM cleaned_players cp 
JOIN merged_gw mg 
	ON cp.name = mg.name
WHERE cp.minutes = 1530 AND mg.position = 'FWD'
GROUP BY cp.name, cp.minutes, cp.total_points   
ORDER BY cp.total_points DESC
LIMIT 5 --No forwards have played every minute

-- Top 3 players of each team with the most points

SELECT team, name, total_points FROM 
(
    SELECT mg.team team,
    cp.name name,
    cp.total_points total_points,
    ROW_NUMBER() OVER (PARTITION BY mg.team Order by cp.total_points DESC) AS rank 
    FROM cleaned_players cp 
    JOIN merged_gw mg
    	ON mg.name = cp.name 
    GROUP BY mg.team, cp.name, cp.total_points 
)RNK 
WHERE rank <=3

--Count the number of players in each position 

SELECT mg.position position, COUNT(DISTINCT(cp.name)) number_of_players
FROM cleaned_players cp 
RIGHT JOIN merged_gw mg 
	ON cp.name = mg.name 
GROUP BY position 

-- Count the total number of players

SELECT COUNT(*) number_of_players
FROM cleaned_players cp 

SELECT COUNT(DISTINCT(name))
FROM merged_gw mg 

SELECT name 
FROM cleaned_players cp 
WHERE name NOT IN (SELECT name FROM merged_gw)

-- I noticed that the two tables had different total players so I needed to find these extra values.

-- Most creative players 

SELECT name 
FROM cleaned_players cp 
ORDER BY creativity DESC 
LIMIT 5

-- Most influencial players

SELECT name 
FROM cleaned_players cp 
ORDER BY influence DESC 
LIMIT 5

-- Most threatening players

SELECT name 
FROM cleaned_players cp 
ORDER BY threat  DESC
LIMIT 5

--Defenders with the most goals scored

SELECT cp.name, cp.goals_scored 
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'DEF'
ORDER BY cp.goals_scored DESC 
LIMIT 5

-- Defenders with the most assists

SELECT cp.name, cp.assists  
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'DEF'
GROUP BY cp.name, cp.assists
ORDER BY cp.assists  DESC 
LIMIT 5

--Midfielders with the most goals scored

SELECT cp.name, cp.goals_scored 
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'MID'
GROUP BY cp.name, cp.goals_scored 
ORDER BY cp.goals_scored DESC 
LIMIT 5

-- Midfielders with the most assists

SELECT cp.name, cp.assists  
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'MID'
GROUP BY cp.name, cp.assists 
ORDER BY cp.assists  DESC 
LIMIT 5

--Forwards with the most goals scored

SELECT cp.name, cp.goals_scored 
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'FWD'
GROUP BY cp.name, cp.goals_scored 
ORDER BY cp.goals_scored DESC 
LIMIT 5

-- Forwards with the most assists

SELECT cp.name, cp.assists  
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'FWD'
GROUP BY cp.name, cp.assists 
ORDER BY cp.assists  DESC 
LIMIT 5

-- Goalkeepers with the most assists

SELECT cp.name, cp.assists  
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'GK' AND cp.assists > 0
GROUP BY cp.name, cp.assists 
ORDER BY cp.assists  DESC 


-- Goalkeepers with the most goals_conceded

SELECT cp.name, cp.goals_conceded  
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'GK'
GROUP BY cp.name, cp.goals_conceded  
ORDER BY cp.goals_conceded DESC 
LIMIT 5

-- Defenders with the most goals_conceded

SELECT cp.name, cp.goals_conceded  
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'DEF'
GROUP BY cp.name, cp.goals_conceded  
ORDER BY cp.goals_conceded DESC 
LIMIT 5

-- Goalkeepers with the most clean sheets

SELECT cp.name, cp.clean_sheets  
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'GK'
GROUP BY cp.name, cp.clean_sheets  
ORDER BY cp.clean_sheets DESC 
LIMIT 5

-- Defenders with the most clean sheets

SELECT cp.name, cp.clean_sheets  
FROM cleaned_players cp
JOIN merged_gw mg
	ON cp.name = mg.name 
WHERE mg."position" = 'DEF'
GROUP BY cp.name, cp.clean_sheets  
ORDER BY cp.clean_sheets DESC 
LIMIT 5






