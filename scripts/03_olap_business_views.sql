-- ============================================================
-- OLAP Analysis Business Views (Enterprise)
-- ============================================================

-- View 1: Top 5 US Action Movies by Profit
CREATE OR REPLACE VIEW dw.view_top_us_action_movies AS
SELECT 
    m.title,
    m.original_language,
    p.company_name,
    f.budget,
    f.revenue,
    (f.revenue - f.budget) AS net_profit
FROM dw.fact_movie_performance f
JOIN dw.dim_movie m ON f.movie_id = m.movie_id
JOIN dw.dim_production p ON f.production_id = p.production_id
WHERE m.primary_genre = 'Action' 
  AND p.country_name = 'US'
ORDER BY net_profit DESC
LIMIT 5;

-- View 2: Top Production Companies by Total Revenue
CREATE OR REPLACE VIEW dw.view_top_production_companies AS
SELECT 
    p.company_name,
    COUNT(f.movie_id) AS total_movies_produced,
    SUM(f.revenue) AS total_revenue,
    ROUND(AVG(f.average_score)::numeric, 2) AS avg_imdb_score
FROM dw.fact_movie_performance f
JOIN dw.dim_production p ON f.production_id = p.production_id
GROUP BY p.company_name
HAVING COUNT(f.movie_id) > 10
ORDER BY total_revenue DESC
LIMIT 10;

-- View 3: Monthly Revenue Trends (2010-2019)
CREATE OR REPLACE VIEW dw.view_monthly_revenue_trends AS
SELECT 
    d.release_year,
    d.release_quarter,
    d.release_month,
    SUM(f.revenue) AS seasonal_revenue,
    ROUND(AVG(f.average_score)::numeric, 2) AS seasonal_avg_score
FROM dw.fact_movie_performance f
JOIN dw.dim_date d ON f.date_id = d.date_id
WHERE d.release_year BETWEEN 2010 AND 2019
GROUP BY d.release_year, d.release_quarter, d.release_month
ORDER BY d.release_year DESC, d.release_quarter DESC, d.release_month DESC
LIMIT 12;

-- View 4: Historical Profitability by Country and Decade
CREATE OR REPLACE VIEW dw.view_historical_profitability AS
SELECT
    COALESCE(p.country_name, 'Unknown') AS production_country,
    (d.release_year / 10) * 10 AS release_decade,
    COUNT(f.movie_id) AS total_movies,
    SUM(f.revenue - f.budget) AS total_net_profit,
    ROUND(AVG(f.average_score)::numeric, 2) AS avg_imdb_score
FROM dw.fact_movie_performance f
JOIN dw.dim_production p ON f.production_id = p.production_id
JOIN dw.dim_date d ON f.date_id = d.date_id
WHERE f.budget > 0 AND f.revenue > 0
GROUP BY
    COALESCE(p.country_name, 'Unknown'),
    (d.release_year / 10) * 10
ORDER BY 
    total_net_profit DESC,
    release_decade DESC;

-- ============================================================
-- NEW CAST & CREW ANALYSIS
-- ============================================================

-- View 5: Box Office Draw (Top Actors by Net Profit)
CREATE OR REPLACE VIEW dw.view_top_actors_by_profit AS
SELECT
    p.primary_name AS actor_name,
    COUNT(f.movie_id) AS movies_starred,
    ROUND(AVG(f.average_score)::numeric, 2) AS avg_imdb_score,
    TO_CHAR(SUM(f.revenue - f.budget), 'FM$999,999,999,999') AS total_net_profit_usd
FROM dw.fact_movie_performance f
JOIN dw.bridge_movie_cast b ON f.movie_id = b.movie_id
JOIN dw.dim_person p ON b.person_id = p.person_id
WHERE b.job_role = 'Actor' 
  AND f.budget > 0 AND f.revenue > 0
GROUP BY p.primary_name
HAVING COUNT(f.movie_id) >= 3
ORDER BY SUM(f.revenue - f.budget) DESC
LIMIT 10;

-- View 6: Most Reliable Directors (Critically & Commercially Successful)
CREATE OR REPLACE VIEW dw.view_top_directors_by_score AS
SELECT
    p.primary_name AS director_name,
    COUNT(f.movie_id) AS movies_directed,
    ROUND(AVG(f.average_score)::numeric, 2) AS avg_imdb_score,
    TO_CHAR(SUM(f.revenue - f.budget), 'FM$999,999,999,999') AS total_net_profit_usd
FROM dw.fact_movie_performance f
JOIN dw.bridge_movie_cast b ON f.movie_id = b.movie_id
JOIN dw.dim_person p ON b.person_id = p.person_id
WHERE b.job_role = 'Director' 
  AND f.budget > 0 AND f.revenue > 0
GROUP BY p.primary_name
HAVING COUNT(f.movie_id) >= 3
ORDER BY AVG(f.average_score) DESC, SUM(f.revenue - f.budget) DESC
LIMIT 10;