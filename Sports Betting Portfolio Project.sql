/* Sports Betting Data Analysis Portfolio Project */
-- Kaggle Dataset: https://www.kaggle.com/datasets/emiliencoicaud/sports-betting-profiling-dataset

SELECT * FROM bets LIMIT 50;

-- Check for duplicates
SELECT bet_id, COUNT(*)
FROM bets
GROUP BY bet_id
HAVING COUNT(*) > 1
;

-- Brief EDA
-- Most Popular Sport for betting in total bets
SELECT sport, COUNT(*) AS sport_bet_count
FROM bets
GROUP BY sport
ORDER BY sport_bet_count DESC
;

-------------------------------------------------------------------------------------------------------------------------------------
-- SECTION 1 - Identifying User Betting Profiles
-- Classifying users based on key behaviors such as average stake size, preferred sports, and bet types.

-- Betting Profile by Average Stake Size
SELECT user_id,
CASE
	WHEN average_stake <= 100 THEN 'Small Spender'
	WHEN average_stake BETWEEN 100.5 AND 300 THEN 'Medium Spender'
	WHEN average_stake BETWEEN 301 AND 1000 THEN 'Big Spender'
	END AS spender_category
FROM
	(
	SELECT user_id, COUNT(stake), ROUND(AVG(stake),2) AS average_stake
	FROM bets
	GROUP BY user_id
	) AS average_bets_table
ORDER BY spender_category
;

-- Encountered a null where average_stake was 100.94 for user_id '1695', so Medium Spender Min value had to be adjusted from 101 to 100.5.
SELECT user_id, ROUND(AVG(stake),2)
FROM bets
WHERE user_id = 1695
;

-- Amount of bettors in the Small, Medium, and Big Spender Categories
SELECT spender_category, COUNT(*) AS amount_of_bettors
FROM
	(
	SELECT user_id,
	CASE
		WHEN average_stake <= 100 THEN 'Small Spender'
		WHEN average_stake BETWEEN 100.5 AND 300 THEN 'Medium Spender'
		WHEN average_stake BETWEEN 301 AND 1000 THEN 'Big Spender'
		END AS spender_category
	FROM
		(
		SELECT user_id, COUNT(stake), ROUND(AVG(stake),2) AS average_stake
		FROM bets
		GROUP BY user_id
		) AS average_bets_table
	) spender_table
GROUP BY spender_category
;

-- Betting Profile by Sports Preference
-- CTE 1: Count of bets per user + sport
WITH sport_counts AS (
SELECT user_id, sport, COUNT(*) AS sport_bet_count
FROM bets
GROUP BY user_id, sport
),
-- CTE 2: Rank the sports per user
ranked_sports AS (
SELECT *, ROW_NUMBER () OVER(PARTITION BY user_id ORDER BY sport_bet_count DESC) AS sport_rank
FROM sport_counts
)
SELECT user_id, sport AS favorite_sport, sport_bet_count
FROM ranked_sports
WHERE sport_rank = 1
ORDER BY favorite_sport
;

-- Count of User Favorites by Sport
-- CTE 1: Count of bets per user + sport
WITH sport_counts AS (
SELECT user_id, sport, COUNT(*) AS sport_bet_count
FROM bets
GROUP BY user_id, sport
),
-- CTE 2: Rank the sports per user
ranked_sports AS (
SELECT *, ROW_NUMBER () OVER(PARTITION BY user_id ORDER BY sport_bet_count DESC) AS sport_rank
FROM sport_counts
)
  -- GROUP BY Favorites
SELECT sport AS favorite_sport, COUNT(*) AS number_of_users
FROM ranked_sports
WHERE sport_rank = 1
GROUP BY sport
ORDER BY number_of_users DESC
;

-- Profile based on bet_type
-- User and their total bets by bet_type
SELECT user_id, bet_type, COUNT(bet_type) AS total_bets
FROM bets
GROUP BY user_id, bet_type
ORDER BY user_id
;

-- Betting Profile by bet_type (Single, Multiple, Even)
-- CTE 1: Count of single bets placed
WITH single_count AS (
	SELECT user_id, COUNT(bet_type) AS single_bet_count
	FROM bets
	WHERE bet_type = 'single'
	GROUP BY user_id),
-- CTE 2: Count of parlays
multiple_count AS (
	SELECT user_id, COUNT(bet_type) AS multiple_bet_count
	FROM bets
	WHERE bet_type = 'multiple'
	GROUP BY user_id)
SELECT s.user_id,
CASE 
	WHEN multiple_bet_count > single_bet_count THEN 'Parlayor'
	WHEN single_bet_count > multiple_bet_count THEN 'Single Bettor'
	ELSE 'Even Split' 
	END AS bettor_type
FROM single_count s
JOIN multiple_count m ON s.user_id = m.user_id
ORDER BY s.user_id
;

-------------------------------------------------------------------------------------------------------------------------------------
-- SECTION 2 - Analyzing Gross Gaming Revenue(GGR) by User Behavior Profiles

-- Average + Total GGR based on Spender Categories
SELECT spender_category, 
	COUNT(*) AS total_bettors,
	ROUND(AVG(total_revenue_per_user),2) AS average_revenue,
	ROUND(SUM(total_revenue_per_user),2) AS total_revenue
FROM
	(
	SELECT user_id, total_revenue_per_user,
	CASE
		WHEN average_stake <= 100 THEN 'Small Spender'
		WHEN average_stake BETWEEN 100.5 AND 300 THEN 'Medium Spender'
		WHEN average_stake BETWEEN 301 AND 1000 THEN 'Big Spender'
		END AS spender_category
	FROM
		(
		SELECT user_id, ROUND(AVG(stake),2) AS average_stake, ROUND(SUM(GGR),2) AS total_revenue_per_user
		FROM bets
		GROUP BY user_id
		) AS average_bets_table
	) spender_table
GROUP BY spender_category
;

/* Sport preference breakdown excluded: 90% of users prefer Football, skewing potential GGR insights */

-- Average + Total GGR by bet_type Profile
WITH single_count AS (
	SELECT user_id, 
		COUNT(bet_type) AS single_bet_count, 
		ROUND(SUM(GGR),2) AS single_bet_revenue
	FROM bets
	WHERE bet_type = 'single'
	GROUP BY user_id),
multiple_count AS (
	SELECT user_id, 
		COUNT(bet_type) AS multiple_bet_count, 
		ROUND(SUM(GGR),2) AS multiple_bet_revenue
	FROM bets
	WHERE bet_type = 'multiple'
	GROUP BY user_id),
bettor_table AS(
	SELECT s.user_id,
		s.single_bet_revenue,
		m.multiple_bet_revenue,
    ROUND(s.single_bet_revenue + m.multiple_bet_revenue, 2) AS total_bettor_revenue,
	CASE 
		WHEN multiple_bet_count > single_bet_count THEN 'Parlayor'
		WHEN single_bet_count > multiple_bet_count THEN 'Single Bettor'
		ELSE 'Even Split' 
		END AS bettor_type
	FROM single_count s
	JOIN multiple_count m ON s.user_id = m.user_id)
SELECT bettor_type, 
	ROUND(AVG(total_bettor_revenue),2) AS avg_revenue_per_bet_type,
	ROUND(SUM(total_bettor_revenue),2) AS total_revenue_per_bet_type,
    COUNT(*) as number_of_bettors,
    ROUND(COUNT(*) * 100.0 / 5000, 1) AS percent_of_bettors
FROM bettor_table
GROUP BY bettor_type
;

-------------------------------------------------------------------------------------------------------------------------------------
-- SECTION 3 Betting Performance by Sport

-- Average Profitability by Sport
SELECT sport,
	COUNT(*) AS total_bets,
	ROUND(SUM(GGR),2) AS total_revenue,
	ROUND(AVG(GGR),2) AS average_revenue_per_bet
FROM bets
GROUP BY sport
ORDER BY average_revenue_per_bet DESC
;

-- User Win Percentage by Sport
SELECT sport, 
	COUNT(CASE WHEN is_win = 'True' THEN 1 END) AS bet_wins,
    COUNT(CASE WHEN is_win = 'False' THEN 1 END) AS bet_losses,
    ROUND(
	COUNT(CASE WHEN is_win = 'True' THEN 1 END) * 100.0 /
    (COUNT(CASE WHEN is_win IN ('True', 'False') THEN 1 END)), 1
  ) AS win_percentage
FROM bets
GROUP BY sport
ORDER BY win_percentage DESC
;

-------------------------------------------------------------------------------------------------------------------------------------
-- SECTION 4 Bet Type Impact
-- Which bet types are more successful or generate more losses?
-- Win Percentage by bet_type
SELECT bet_type, 
	COUNT(CASE WHEN is_win = 'True' THEN 1 END) AS bet_wins,
    COUNT(CASE WHEN is_win = 'False' THEN 1 END) AS bet_losses,
    ROUND(
	COUNT(CASE WHEN is_win = 'True' THEN 1 END) * 100.0 /
    (COUNT(CASE WHEN is_win IN ('True', 'False') THEN 1 END)), 1
  ) AS win_percentage,
	ROUND(AVG(GGR),2) AS average_revenue,
	ROUND(SUM(GGR),2) AS total_revenue
FROM bets
GROUP BY bet_type
ORDER BY win_percentage DESC
;

-------------------------------------------------------------------------------------------------------------------------------------
-- SECTION 5 Relationship Between Odds and Outcomes
-- Are users better off betting on lower or higher odds?
-- Odds range 1.1 - 62.15

SELECT
	CASE
	WHEN odds < 3 THEN 'Low Risk'
	WHEN odds BETWEEN 3 AND 7 THEN 'Moderate Risk'
	WHEN odds BETWEEN 7 AND 15 THEN 'High Risk'
	ELSE 'Longshot'
	END AS risk_categories,
    ROUND(AVG(GGR),2) AS average_revenue,
	COUNT(CASE WHEN is_win = 'True' THEN 1 END) AS bet_wins,
    COUNT(CASE WHEN is_win = 'False' THEN 1 END) AS bet_losses,
    ROUND(
	COUNT(CASE WHEN is_win = 'True' THEN 1 END) * 100.0 /
    (COUNT(CASE WHEN is_win IN ('True', 'False') THEN 1 END)), 1)  AS win_percentage
FROM bets
GROUP BY risk_categories
ORDER BY win_percentage DESC
;

-- Average Bet by Risk Category
SELECT
	CASE
	WHEN odds < 3 THEN 'Low Risk'
	WHEN odds BETWEEN 3 AND 7 THEN 'Moderate Risk'
	WHEN odds BETWEEN 7 AND 15 THEN 'High Risk'
	ELSE 'Longshot'
	END AS risk_categories,
	ROUND(AVG(stake), 2) AS average_stake
FROM bets
GROUP BY risk_categories
ORDER BY average_stake DESC
;


-------------------------------------------------------------------------------------------------------------------------------------
-- SECTION 6 Stake Size and Reward
-- Do larger stakes generally yield higher gains or bigger losses?

SELECT 
	CASE 
    WHEN stake <= 100 THEN 'Small Bet'
    WHEN stake BETWEEN 100.5 AND 300 THEN 'Medium Bet'
    ELSE 'Large Bet'
    END AS stake_categories,
    COUNT(*) AS num_bets,
	  ROUND(AVG(GGR), 2) AS avg_revenue_per_bet,
    ROUND(SUM(GGR),2) AS total_revenue
FROM bets
GROUP BY stake_categories
;

-------------------------------------------------------------------------------------------------------------------------------------
/* 
Future Extensions: 
- Gather time series data for exploration of seasonal trends
- Segmenting bettors by geography or betting frequency
*/
-------------------------------------------------------------------------------------------------------------------------------------
