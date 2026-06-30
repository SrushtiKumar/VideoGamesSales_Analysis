-- POSTGRESQL VIDEO GAME SALES DATA ANALYSIS
SELECT * FROM vgsales;

-- ------------------------------------------------------------------------------
-- QUERY 6: Regional Consumer Footprint by Platform (NA, JP, PAL, Other)
-- Question: Which sales regions dominate for major console platforms?
-- Purpose: Identifies platform popularity and regional preferences to guide localization.
-- ------------------------------------------------------------------------------
SELECT 
    console,
    ROUND(SUM(total_sales_mil)::numeric, 2) AS global_sales_millions,
    ROUND((SUM(na_sales_mil) / SUM(total_sales_mil) * 100)::numeric, 2) AS na_sales_share_percent,
    ROUND((SUM(jp_sales_mil) / SUM(total_sales_mil) * 100)::numeric, 2) AS jp_sales_share_percent,
    ROUND((SUM(pal_sales_mil) / SUM(total_sales_mil) * 100)::numeric, 2) AS pal_sales_share_percent,
    ROUND((SUM(other_sales_mil) / SUM(total_sales_mil) * 100)::numeric, 2) AS other_sales_share_percent
FROM vgsales
WHERE total_sales_mil > 0
GROUP BY console
HAVING SUM(total_sales_mil) >= 10.0 -- Filter to consoles with at least $10M total sales
ORDER BY global_sales_millions DESC;


-- ------------------------------------------------------------------------------
-- QUERY 7: Publisher Portfolio Size vs. Commercial Yield Efficiency
-- Question: Which publishers (with at least 10 releases) have the highest revenue efficiency?
-- Purpose: Discovers efficient publishers (high avg sales) rather than just volume leaders.
-- ------------------------------------------------------------------------------
SELECT 
    publisher,
    COUNT(title) AS total_releases,
    ROUND(SUM(total_sales_mil)::numeric, 2) AS total_revenue_millions,
    ROUND(AVG(total_sales_mil)::numeric, 2) AS average_sales_per_game_millions
FROM vgsales
WHERE total_sales_mil IS NOT NULL
GROUP BY publisher
HAVING COUNT(title) >= 10
ORDER BY average_sales_per_game_millions DESC
LIMIT 15;


-- ------------------------------------------------------------------------------
-- QUERY 8: Top-Selling Game per Genre per Decade (Window Functions)
-- Question: What are the highest-selling games in each genre for each decade?
-- Purpose: Displays historical consumer demand shifts and genre champions over time.
-- ------------------------------------------------------------------------------
WITH decade_genre_sales AS (
    SELECT 
        (release_year / 10 * 10) AS release_decade,
        genre,
        title,
        console,
        publisher,
        total_sales_mil,
        DENSE_RANK() OVER (
            PARTITION BY (release_year / 10 * 10), genre 
            ORDER BY total_sales_mil DESC
        ) AS sales_rank
    FROM vgsales
    WHERE release_year IS NOT NULL AND genre IS NOT NULL AND total_sales_mil IS NOT NULL
)
SELECT 
    release_decade,
    genre,
    sales_rank,
    title,
    console,
    publisher,
    ROUND(total_sales_mil::numeric, 2) AS global_sales_millions
FROM decade_genre_sales
WHERE sales_rank = 1 AND release_decade >= 1970
ORDER BY release_decade DESC, genre ASC, global_sales_millions DESC;


-- ------------------------------------------------------------------------------
-- QUERY 9: Publisher Platform Footprint and Diversification
-- Question: Which publishers publish across the most platforms, and does platform diversity yield higher sales?
-- Purpose: Analyzes multi-platform publishing strategies.
-- ------------------------------------------------------------------------------
SELECT 
    publisher,
    COUNT(DISTINCT console) AS unique_consoles_supported,
    COUNT(title) AS total_games_released,
    ROUND(SUM(total_sales_mil)::numeric, 2) AS global_sales_millions,
    ROUND(AVG(total_sales_mil)::numeric, 2) AS average_sales_per_game_millions
FROM vgsales
WHERE total_sales_mil IS NOT NULL
GROUP BY publisher
ORDER BY unique_consoles_supported DESC, global_sales_millions DESC
LIMIT 15;


-- ------------------------------------------------------------------------------
-- QUERY 10: Genre-Specific Critic Score Premium
-- Question: How much of a sales premium do critically acclaimed games get compared to average games within the same genre?
-- Purpose: Quantifies the financial return on software quality across different genres.
-- ------------------------------------------------------------------------------
WITH genre_quality_sales AS (
    SELECT 
        genre,
        AVG(CASE WHEN critic_score >= 8.5 THEN total_sales_mil END) AS avg_sales_excellent,
        AVG(CASE WHEN critic_score >= 5.0 AND critic_score < 7.0 THEN total_sales_mil END) AS avg_sales_average
    FROM vgsales
    WHERE total_sales_mil IS NOT NULL AND critic_score IS NOT NULL
    GROUP BY genre
)
SELECT 
    genre,
    ROUND(avg_sales_excellent::numeric, 2) AS avg_sales_excellent_millions,
    ROUND(avg_sales_average::numeric, 2) AS avg_sales_average_millions,
    ROUND((avg_sales_excellent - avg_sales_average)::numeric, 2) AS absolute_premium_millions,
    ROUND((avg_sales_excellent / NULLIF(avg_sales_average, 0))::numeric, 2) AS sales_multiplier_for_quality
FROM genre_quality_sales
WHERE avg_sales_excellent IS NOT NULL AND avg_sales_average IS NOT NULL
ORDER BY absolute_premium_millions DESC;

