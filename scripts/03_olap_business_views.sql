-- ============================================================
-- OLAP Analysis Business Views
-- Movies Data Warehouse
-- ============================================================

-- ============================================================
-- Analysis 1: Top 5 US Action Movies by Profit
-- Business question: Which Action movies produced in the US yielded the highest net profit?
-- OLAP operations: Slice on genre ('Action'); Dice by geography ('US').
-- ============================================================
CREATE OR REPLACE VIEW view_top_us_action_movies AS
SELECT 
    m.title,
    m.original_language,
    p.company_name,
    f.budget,
    f.revenue,
    (f.revenue - f.budget) AS net_profit
FROM fact_movie_performance f
JOIN dim_movie m ON f.movie_id = m.movie_id
JOIN dim_production p ON f.production_id = p.production_id
WHERE m.primary_genre = 'Action' 
  AND p.country_name = 'US'
ORDER BY net_profit DESC
LIMIT 5;

-- ============================================================
-- Analysis 2: Top Production Companies by Total Revenue
-- Business question: Which production studios generated the most revenue, and their avg score?
-- OLAP operations: Roll-up from individual movies to Production Companies.
-- ============================================================
CREATE OR REPLACE VIEW view_top_production_companies AS
SELECT 
    p.company_name,
    COUNT(f.movie_id) AS total_movies_produced,
    SUM(f.revenue) AS total_revenue,
    ROUND(AVG(f.average_score)::numeric, 2) AS avg_imdb_score
FROM fact_movie_performance f
JOIN dim_production p ON f.production_id = p.production_id
GROUP BY p.company_name
HAVING COUNT(f.movie_id) > 10
ORDER BY total_revenue DESC
LIMIT 10;

-- ============================================================
-- Analysis 3: Monthly Revenue Trends (2010-2019)
-- Business question: How did revenues and average scores trend monthly during the 2010s?
-- OLAP operations: Drill-down the Time dimension from Year to Quarter to Month.
-- ============================================================
CREATE OR REPLACE VIEW view_monthly_revenue_trends AS
SELECT 
    d.release_year,
    d.release_quarter,
    d.release_month,
    SUM(f.revenue) AS seasonal_revenue,
    ROUND(AVG(f.average_score)::numeric, 2) AS seasonal_avg_score
FROM fact_movie_performance f
JOIN dim_date d ON f.date_id = d.date_id
WHERE d.release_year BETWEEN 2010 AND 2019
GROUP BY d.release_year, d.release_quarter, d.release_month
ORDER BY d.release_year DESC, d.release_quarter DESC, d.release_month DESC
LIMIT 12;

-- ============================================================
-- Analysis 4: Historical Profitability by Country and Decade
-- Business question: Which countries generated the most profitable movies across decades?
-- OLAP operations: Roll-up to Production Country and Release Decade.
-- ============================================================
CREATE OR REPLACE VIEW view_historical_profitability AS
SELECT
    COALESCE(p.country_name, 'Unknown') AS production_country,
    (d.release_year / 10) * 10 AS release_decade,
    COUNT(f.movie_id) AS total_movies,
    SUM(f.revenue - f.budget) AS total_net_profit,
    ROUND(AVG(f.average_score)::numeric, 2) AS avg_imdb_score
FROM fact_movie_performance f
JOIN dim_production p ON f.production_id = p.production_id
JOIN dim_date d ON f.date_id = d.date_id
WHERE f.budget > 0 AND f.revenue > 0
GROUP BY
    COALESCE(p.country_name, 'Unknown'),
    (d.release_year / 10) * 10
ORDER BY 
    total_net_profit DESC,
    release_decade DESC;