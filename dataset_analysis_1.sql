-- POSTGRESQL VIDEO GAME SALES DATA ANALYSIS
SELECT * FROM vgsales;

-- ------------------------------------------------------------------------------
-- QUERY 1: Platform Revenue & Game Volume Analysis
-- Question: Which console platforms have generated the most revenue and catalog volume?
-- Purpose: Identifies the historical market size and game counts of each console platform.
-- ------------------------------------------------------------------------------
SELECT 
    console,
    COUNT(title) AS total_games_released,
    ROUND(SUM(total_sales_mil)::numeric, 2) AS global_sales_usd_millions,
    ROUND((SUM(total_sales_mil) / (SELECT SUM(total_sales_mil) FROM vgsales WHERE total_sales_mil IS NOT NULL) * 100)::numeric, 2) AS global_revenue_market_share_percent
FROM vgsales
WHERE total_sales_mil IS NOT NULL
GROUP BY console
ORDER BY global_sales_usd_millions DESC;


-- ------------------------------------------------------------------------------
-- QUERY 2: Genre Performance and Average Yield per Release
-- Question: Which genres drive the most industry revenue, and which yield the highest average sales?
-- Purpose: Helps developers allocate investment to genres with high total market size or high average sales.
-- ------------------------------------------------------------------------------
SELECT 
    genre,
    COUNT(title) AS total_games_released,
    ROUND(SUM(total_sales_mil)::numeric, 2) AS total_sales_usd_millions,
    ROUND(AVG(total_sales_mil)::numeric, 2) AS average_sales_per_game_millions,
    ROUND((SUM(total_sales_mil) / (SELECT SUM(total_sales_mil) FROM vgsales WHERE total_sales_mil IS NOT NULL) * 100)::numeric, 2) AS revenue_market_share_percent
FROM vgsales
WHERE total_sales_mil IS NOT NULL
GROUP BY genre
ORDER BY total_sales_usd_millions DESC;


-- ------------------------------------------------------------------------------
-- QUERY 3: Chronological Revenue Growth Rate (Year-over-Year)
-- Question: How has global revenue changed annually, and what is the YoY growth rate?
-- Purpose: Measures industry growth trends and helps detect inflection points or market cycles.
-- ------------------------------------------------------------------------------
WITH yearly_sales AS (
    SELECT 
        release_year,
        ROUND(SUM(total_sales_mil)::numeric, 2) AS annual_sales_millions
    FROM vgsales
    WHERE release_year IS NOT NULL AND total_sales_mil IS NOT NULL
    GROUP BY release_year
)
SELECT 
    release_year,
    annual_sales_millions,
    LAG(annual_sales_millions) OVER (ORDER BY release_year) AS previous_year_sales_millions,
    ROUND(
        ((annual_sales_millions - LAG(annual_sales_millions) OVER (ORDER BY release_year)) / 
        NULLIF(LAG(annual_sales_millions) OVER (ORDER BY release_year), 0) * 100)::numeric, 
        2
    ) AS yoy_growth_percentage
FROM yearly_sales
ORDER BY release_year ASC;


-- ------------------------------------------------------------------------------
-- QUERY 4: Market Concentration of Top 10 Publishers
-- Question: How much of the global revenue is dominated by the top 10 publishers?
-- Purpose: Identifies market monopolization vs. fragmentation.
-- ------------------------------------------------------------------------------
WITH publisher_sales AS (
    SELECT 
        publisher,
        SUM(total_sales_mil) AS publisher_total_sales
    FROM vgsales
    WHERE total_sales_mil IS NOT NULL
    GROUP BY publisher
),
ranked_publishers AS (
    SELECT 
        publisher,
        publisher_total_sales,
        DENSE_RANK() OVER (ORDER BY publisher_total_sales DESC) AS publisher_rank,
        (SELECT SUM(total_sales_mil) FROM vgsales WHERE total_sales_mil IS NOT NULL) AS industry_total_sales
    FROM publisher_sales
)
SELECT 
    publisher_rank,
    publisher,
    ROUND(publisher_total_sales::numeric, 2) AS sales_millions,
    ROUND((publisher_total_sales / industry_total_sales * 100)::numeric, 2) AS industry_share_percent,
    ROUND((SUM(publisher_total_sales) OVER (ORDER BY publisher_total_sales DESC) / industry_total_sales * 100)::numeric, 2) AS cumulative_industry_share_percent
FROM ranked_publishers
WHERE publisher_rank <= 10
ORDER BY publisher_rank ASC;


-- ------------------------------------------------------------------------------
-- QUERY 5: Game Quality (Critic Scores) vs. Commercial Performance
-- Question: Does review score quality correspond to higher sales?
-- Purpose: Tests whether high scores correspond to higher sales brackets.
-- ------------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN critic_score IS NULL THEN 'Unrated'
        WHEN critic_score < 5.0 THEN 'Poor (< 5.0)'
        WHEN critic_score >= 5.0 AND critic_score < 7.0 THEN 'Average (5.0 - 7.0)'
        WHEN critic_score >= 7.0 AND critic_score < 8.5 THEN 'Good (7.0 - 8.5)'
        ELSE 'Excellent (>= 8.5)'
    END AS quality_category,
    COUNT(title) AS game_count,
    ROUND(AVG(total_sales_mil)::numeric, 2) AS avg_sales_millions,
    ROUND(SUM(total_sales_mil)::numeric, 2) AS total_sales_millions
FROM vgsales
GROUP BY quality_category
ORDER BY avg_sales_millions DESC;
