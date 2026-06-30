-- POSTGRESQL VIDEO GAME SALES DATA ANALYSIS
SELECT * FROM vgsales;

-- ------------------------------------------------------------------------------
-- QUERY 11: Console Platform Lifespan and Peak Performance Years
-- Question: What is the active lifespan of each console, and what was its peak sales year?
-- Purpose: Profiles platform life cycles to help estimate time windows for maximizing sales.
-- ------------------------------------------------------------------------------
WITH platform_years AS (
    SELECT 
        console,
        MIN(release_year) AS launch_year,
        MAX(release_year) AS sunset_year,
        MAX(release_year) - MIN(release_year) AS active_lifespan_years
    FROM vgsales
    WHERE release_year IS NOT NULL
    GROUP BY console
),
platform_annual_sales AS (
    SELECT 
        console,
        release_year,
        SUM(total_sales_mil) AS annual_sales,
        ROW_NUMBER() OVER (PARTITION BY console ORDER BY SUM(total_sales_mil) DESC) as sales_rank
    FROM vgsales
    WHERE release_year IS NOT NULL AND total_sales_mil IS NOT NULL
    GROUP BY console, release_year
),
platform_peaks AS (
    SELECT 
        console,
        release_year AS peak_sales_year,
        annual_sales AS peak_annual_sales
    FROM platform_annual_sales
    WHERE sales_rank = 1
)
SELECT 
    py.console,
    py.launch_year,
    py.sunset_year,
    py.active_lifespan_years,
    pp.peak_sales_year,
    ROUND(pp.peak_annual_sales::numeric, 2) AS peak_sales_millions
FROM platform_years py
JOIN platform_peaks pp ON py.console = pp.console
ORDER BY peak_sales_millions DESC;


-- ------------------------------------------------------------------------------
-- QUERY 12: Top Developer & Publisher Strategic Partnerships
-- Question: Which developer-publisher partnerships have generated the highest revenue?
-- Purpose: Evaluates business relationships and co-development ventures.
-- ------------------------------------------------------------------------------
SELECT 
    developer,
    publisher,
    COUNT(title) AS collaborative_releases_count,
    ROUND(SUM(total_sales_mil)::numeric, 2) AS total_sales_millions,
    ROUND(AVG(critic_score)::numeric, 2) AS average_critic_score_out_of_10
FROM vgsales
WHERE developer IS NOT NULL AND publisher IS NOT NULL AND total_sales_mil IS NOT NULL
GROUP BY developer, publisher
HAVING COUNT(title) >= 5 -- Look at consistent partnerships of at least 5 games
ORDER BY total_sales_millions DESC
LIMIT 15;


-- ------------------------------------------------------------------------------
-- QUERY 13: Console vs. PC Sales Contribution Over Time
-- Question: How has the sales distribution between PC and Consoles evolved across decades?
-- Purpose: Monitors the shift in platform paradigms (PC gaming vs. console ecosystems).
-- ------------------------------------------------------------------------------
WITH platform_decades AS (
    SELECT 
        (release_year / 10 * 10) AS release_decade,
        CASE WHEN console = 'PC' THEN 'PC' ELSE 'Console' END AS platform_type,
        SUM(total_sales_mil) AS sales_volume
    FROM vgsales
    WHERE release_year IS NOT NULL AND total_sales_mil IS NOT NULL
    GROUP BY (release_year / 10 * 10), platform_type
),
decade_totals AS (
    SELECT 
        release_decade,
        SUM(sales_volume) AS total_decade_sales
    FROM platform_decades
    GROUP BY release_decade
)
SELECT 
    pd.release_decade,
    pd.platform_type,
    ROUND(pd.sales_volume::numeric, 2) AS sales_millions,
    ROUND((pd.sales_volume / dt.total_decade_sales * 100)::numeric, 2) AS market_share_percent
FROM platform_decades pd
JOIN decade_totals dt ON pd.release_decade = dt.release_decade
ORDER BY pd.release_decade DESC, pd.platform_type ASC;


-- ------------------------------------------------------------------------------
-- QUERY 14: Seasonal Analysis of Video Game Release Dates
-- Question: Does the month of release impact the sales yield of video games?
-- Purpose: Investigates holiday shopping season trends (Q4 vs. Q1-Q3 releases) for scheduling launch windows.
-- ------------------------------------------------------------------------------
SELECT 
    release_month,
    COUNT(title) AS games_released,
    ROUND(SUM(total_sales_mil)::numeric, 2) AS total_sales_millions,
    ROUND(AVG(total_sales_mil)::numeric, 2) AS average_sales_per_game_millions,
    ROUND((SUM(total_sales_mil) / (SELECT SUM(total_sales_mil) FROM vgsales WHERE total_sales_mil IS NOT NULL) * 100)::numeric, 2) AS percentage_of_global_sales
FROM vgsales
WHERE release_month IS NOT NULL AND total_sales_mil IS NOT NULL
GROUP BY release_month
ORDER BY release_month ASC;


-- ------------------------------------------------------------------------------
-- QUERY 15: Re-releases and Multi-Platform Ports Performance
-- Question: Which games have been ported to the most console platforms, and what are their combined sales?
-- Purpose: Assesses porting profitability and intellectual property (IP) consistency.
-- ------------------------------------------------------------------------------
SELECT 
    title,
    COUNT(DISTINCT console) AS platform_ports_count,
    ROUND(SUM(total_sales_mil)::numeric, 2) AS combined_sales_millions,
    ROUND(AVG(critic_score)::numeric, 2) AS average_critic_score_across_platforms
FROM vgsales
WHERE total_sales_mil IS NOT NULL
GROUP BY title
HAVING COUNT(DISTINCT console) > 1
ORDER BY platform_ports_count DESC, combined_sales_millions DESC
LIMIT 15;

