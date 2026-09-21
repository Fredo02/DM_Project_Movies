-- ============================================================
-- Phase 9 - OLAP Operations & Sample Queries
-- Movies Data Warehouse (Enterprise Schema)
-- ============================================================

-- ============================================================
-- 1. ROLL-UP (Aggregating data up a hierarchy)
-- ============================================================

-- [EASY] Roll-up: Total Revenue by Year
-- Aggregating from daily/monthly granularity up to the Year level.
SELECT 
    d.release_year,
    TO_CHAR(SUM(f.revenue), 'FM$999,999,999,999') AS total_revenue_usd
FROM dw.fact_movie_performance f
JOIN dw.dim_date d ON f.date_id = d.date_id
GROUP BY d.release_year
ORDER BY d.release_year DESC
LIMIT 10;

-- [ADVANCED] Roll-up: Profitability by Decade and Genre
-- Aggregating up to mathematical decades and analyzing average scores.
SELECT 
    (d.release_year / 10) * 10 AS release_decade,
    m.primary_genre,
    COUNT(f.movie_id) AS total_movies,
    TO_CHAR(SUM(f.revenue - f.budget), 'FM$999,999,999,999') AS net_profit_usd,
    ROUND(AVG(f.average_score)::numeric, 2) AS avg_score
FROM dw.fact_movie_performance f
JOIN dw.dim_date d ON f.date_id = d.date_id
JOIN dw.dim_movie m ON f.movie_id = m.movie_id
WHERE f.budget > 0 AND f.revenue > 0
GROUP BY release_decade, m.primary_genre
-- Sort strictly by raw mathematical sum, not the formatted string
ORDER BY release_decade DESC, SUM(f.revenue - f.budget) DESC;


-- ============================================================
-- 2. DRILL-DOWN (Navigating from higher to lower levels)
-- ============================================================

-- [EASY] Drill-down: From Year (2012) down to Quarters
SELECT 
    d.release_year,
    d.release_quarter,
    COUNT(f.movie_id) AS movies_released,
    TO_CHAR(SUM(f.revenue), 'FM$999,999,999,999') AS quarter_revenue_usd
FROM dw.fact_movie_performance f
JOIN dw.dim_date d ON f.date_id = d.date_id
WHERE d.release_year = 2012
GROUP BY d.release_year, d.release_quarter
ORDER BY d.release_quarter;

-- [ADVANCED] Drill-down: From Production Company to Top 3 Movies
-- Uses Window Functions to drill down into the best performing movies per studio.
WITH RankedMovies AS (
    SELECT 
        p.company_name,
        m.title,
        TO_CHAR((f.revenue - f.budget), 'FM$999,999,999,999') AS net_profit_usd,
        -- The rank function must sort by the raw numeric value
        ROW_NUMBER() OVER(PARTITION BY p.company_name ORDER BY (f.revenue - f.budget) DESC) as rank
    FROM dw.fact_movie_performance f
    JOIN dw.dim_production p ON f.production_id = p.production_id
    JOIN dw.dim_movie m ON f.movie_id = m.movie_id
    WHERE f.budget > 0 AND p.company_name IN ('Universal Pictures', 'Paramount Pictures', 'Warner Bros.')
)
SELECT company_name, rank, title, net_profit_usd
FROM RankedMovies
WHERE rank <= 3
ORDER BY company_name, rank;


-- ============================================================
-- 3. SLICE AND DICE (Filtering by specific dimensions)
-- ============================================================

-- [EASY] Slice: Fixing one dimension (Only 'Sci-Fi' movies)
SELECT 
    m.title, 
    d.release_year, 
    TO_CHAR(f.revenue, 'FM$999,999,999,999') AS revenue_usd
FROM dw.fact_movie_performance f
JOIN dw.dim_movie m ON f.movie_id = m.movie_id
JOIN dw.dim_date d ON f.date_id = d.date_id
WHERE m.primary_genre = 'Science Fiction'
ORDER BY f.revenue DESC
LIMIT 5;

-- [ADVANCED] Dice: Multi-dimensional filtering
-- Filtering by Genre, Time, Geography, and Quality. (No financial formatting needed here)
SELECT 
    m.title,
    p.country_name,
    m.primary_genre,
    d.release_year,
    f.average_score
FROM dw.fact_movie_performance f
JOIN dw.dim_movie m ON f.movie_id = m.movie_id
JOIN dw.dim_production p ON f.production_id = p.production_id
JOIN dw.dim_date d ON f.date_id = d.date_id
WHERE m.primary_genre IN ('Action', 'Adventure')
  AND d.release_year BETWEEN 2010 AND 2015
  AND p.country_name IN ('US', 'GB')
  AND f.average_score > 75
ORDER BY f.average_score DESC;


-- ============================================================
-- 4. PIVOTING (Cross-tabulation of data)
-- ============================================================

-- [MEDIUM] Pivoting: Total Revenue by Quarter (Columns) for Top Genres (Rows)
-- Simulates a Pivot Table using conditional aggregation (CASE WHEN).
SELECT 
    m.primary_genre,
    TO_CHAR(SUM(CASE WHEN d.release_quarter = 1 THEN f.revenue ELSE 0 END), 'FM$999,999,999,999') AS Q1_Revenue,
    TO_CHAR(SUM(CASE WHEN d.release_quarter = 2 THEN f.revenue ELSE 0 END), 'FM$999,999,999,999') AS Q2_Revenue,
    TO_CHAR(SUM(CASE WHEN d.release_quarter = 3 THEN f.revenue ELSE 0 END), 'FM$999,999,999,999') AS Q3_Revenue,
    TO_CHAR(SUM(CASE WHEN d.release_quarter = 4 THEN f.revenue ELSE 0 END), 'FM$999,999,999,999') AS Q4_Revenue,
    TO_CHAR(SUM(f.revenue), 'FM$999,999,999,999') AS Total_Yearly_Revenue
FROM dw.fact_movie_performance f
JOIN dw.dim_movie m ON f.movie_id = m.movie_id
JOIN dw.dim_date d ON f.date_id = d.date_id
WHERE d.release_year = 2015
  AND m.primary_genre IN ('Action', 'Comedy', 'Drama', 'Science Fiction', 'Thriller')
GROUP BY m.primary_genre
ORDER BY SUM(f.revenue) DESC;


-- ============================================================
-- 5. DRILL-ACROSS (Combining distinct business processes/roles)
-- ============================================================

-- [ADVANCED] Drill-Across: Actor Performance vs Director Performance
-- Compares two different relationships (Actor vs Director) sharing the same conformed dimensions.
WITH ActorStats AS (
    SELECT 
        p.person_id,
        COUNT(f.movie_id) AS acted_movies,
        SUM(f.revenue) AS actor_revenue
    FROM dw.fact_movie_performance f
    JOIN dw.bridge_movie_cast b ON f.movie_id = b.movie_id
    JOIN dw.dim_person p ON b.person_id = p.person_id
    WHERE b.job_role = 'Actor'
    GROUP BY p.person_id
),
DirectorStats AS (
    SELECT 
        p.person_id,
        COUNT(f.movie_id) AS directed_movies,
        SUM(f.revenue) AS director_revenue
    FROM dw.fact_movie_performance f
    JOIN dw.bridge_movie_cast b ON f.movie_id = b.movie_id
    JOIN dw.dim_person p ON b.person_id = p.person_id
    WHERE b.job_role = 'Director'
    GROUP BY p.person_id
)
SELECT 
    dp.primary_name,
    COALESCE(a.acted_movies, 0) AS movies_as_actor,
    TO_CHAR(COALESCE(a.actor_revenue, 0), 'FM$999,999,999,999') AS revenue_as_actor_usd,
    COALESCE(d.directed_movies, 0) AS movies_as_director,
    TO_CHAR(COALESCE(d.director_revenue, 0), 'FM$999,999,999,999') AS revenue_as_director_usd
FROM dw.dim_person dp
JOIN ActorStats a ON dp.person_id = a.person_id
JOIN DirectorStats d ON dp.person_id = d.person_id
-- We look for people who are BOTH successful actors and directors
WHERE a.acted_movies > 0 AND d.directed_movies > 0
ORDER BY (COALESCE(a.actor_revenue, 0) + COALESCE(d.director_revenue, 0)) DESC
LIMIT 10;

-- ============================================================
-- 6. VIEW ANALYTICS
-- ============================================================

-- [1] The "Hall of Fame" (UNION ALL)
-- Combines the elite Top 10 Actors and Top 10 Directors into a single 
-- ranking of 20 professionals, sorted by their critical success (IMDb score).
-- Guaranteed to return 20 rows.
SELECT 
    actor_name AS professional_name,
    'Actor' AS primary_role,
    movies_starred AS credited_movies,
    avg_imdb_score,
    total_net_profit_usd
FROM dw.view_top_actors_by_profit
UNION ALL
SELECT 
    director_name AS professional_name,
    'Director' AS primary_role,
    movies_directed AS credited_movies,
    avg_imdb_score,
    total_net_profit_usd
FROM dw.view_top_directors_by_score
ORDER BY avg_imdb_score DESC;


-- [2] The "Golden Decade" per Country (Window Function)
-- Finds the single most profitable decade for every film-producing country.
-- Uses ROW_NUMBER to isolate the #1 decade per partition.
WITH RankedDecades AS (
    SELECT 
        production_country,
        release_decade,
        total_movies,
        total_net_profit,
        avg_imdb_score,
        ROW_NUMBER() OVER(PARTITION BY production_country ORDER BY total_net_profit DESC) as rank
    FROM dw.view_historical_profitability
)
SELECT 
    production_country,
    release_decade AS golden_decade,
    total_movies,
    TO_CHAR(total_net_profit, 'FM$999,999,999,999') AS peak_decade_profit_usd,
    avg_imdb_score
FROM RankedDecades
WHERE rank = 1 
  AND total_net_profit > 0
ORDER BY total_net_profit DESC
LIMIT 10;


-- [3] Studio Dominance & Action Blockbusters (LEFT JOIN)
-- Analyzes the Top 10 Production Companies and checks if they also happen 
-- to be the creators of the Top 5 US Action Movies.
-- The LEFT JOIN ensures we always see the Top 10 companies, even if they didn't make an action hit.
SELECT 
    c.company_name,
    TO_CHAR(c.total_revenue, 'FM$999,999,999,999') AS studio_total_revenue,
    c.avg_imdb_score AS studio_avg_score,
    COALESCE(a.title, 'No Top 5 Action Movie') AS flagship_action_movie,
    COALESCE(TO_CHAR(a.net_profit, 'FM$999,999,999,999'), '-') AS movie_net_profit_usd
FROM dw.view_top_production_companies c
LEFT JOIN dw.view_top_us_action_movies a 
    ON c.company_name = a.company_name
ORDER BY c.total_revenue DESC;


-- [4] Running Total of Monthly Revenues (Cumulative Analysis)
-- Takes the seasonal trend view and calculates how the revenue accumulates 
-- month over month within each specific year.
SELECT 
    release_year,
    release_month,
    TO_CHAR(seasonal_revenue, 'FM$999,999,999,999') AS monthly_revenue_usd,
    seasonal_avg_score,
    -- Calculates the cumulative sum resetting every year
    TO_CHAR(SUM(seasonal_revenue) OVER(PARTITION BY release_year ORDER BY release_month), 'FM$999,999,999,999') AS YTD_revenue_usd
FROM dw.view_monthly_revenue_trends
ORDER BY release_year DESC, release_month ASC;