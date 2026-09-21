-- ============================================================
-- Automated Data Reconciliation (Sanity Checks)
-- Compares granular fact data against aggregated dimensional data
-- to ensure zero data loss and zero fan-out duplication.
-- ============================================================

WITH Revenue_No_Joins AS (
    -- 1. I calculate the absolute total directly from the base table (the absolute truth).
    SELECT SUM(revenue) AS total_revenue 
    FROM dw.fact_movie_performance
),
Revenue_Via_Date_Dim AS (
    -- 2. I calculate the total by going through the time dimension (to check for record losses).
    SELECT SUM(f.revenue) AS total_revenue
    FROM dw.fact_movie_performance f
    JOIN dw.dim_date d ON f.date_id = d.date_id
),
Profit_Raw_Calc AS (
    -- 3. I calculate the filtered aggregate net profit (the absolute truth for business metrics).
    SELECT SUM(revenue - budget) AS total_net_profit
    FROM dw.fact_movie_performance
    WHERE budget > 0 AND revenue > 0
),
Profit_Via_Genre_Rollup AS (
    -- 4. I calculate the net profit by using the film dimension and grouping by genre.
    SELECT SUM(net_profit) AS total_net_profit
    FROM (
        SELECT m.primary_genre, SUM(f.revenue - f.budget) AS net_profit
        FROM dw.fact_movie_performance f
        JOIN dw.dim_movie m ON f.movie_id = m.movie_id
        WHERE f.budget > 0 AND f.revenue > 0
        GROUP BY m.primary_genre
    ) sub
)

-- ============================================================
-- RECONCILIATION DASHBOARD
-- ============================================================
SELECT 
    'Time Dimension Fan-out Check' AS reconciliation_test,
    'Ensures joining the Date dimension does not duplicate or drop revenue.' AS description,
    TO_CHAR(r_base.total_revenue, 'FM$999,999,999,999') AS expected_value_usd,
    TO_CHAR(r_dim.total_revenue, 'FM$999,999,999,999') AS actual_value_usd,
    CASE 
        WHEN r_base.total_revenue = r_dim.total_revenue THEN '✅ PASS' 
        ELSE '❌ FAIL' 
    END AS status
FROM Revenue_No_Joins r_base, Revenue_Via_Date_Dim r_dim

UNION ALL

SELECT 
    'Genre Rollup Integrity Check' AS reconciliation_test,
    'Ensures aggregating net profit by genre matches the global raw net profit.' AS description,
    TO_CHAR(p_base.total_net_profit, 'FM$999,999,999,999') AS expected_value_usd,
    TO_CHAR(p_dim.total_net_profit, 'FM$999,999,999,999') AS actual_value_usd,
    CASE 
        WHEN p_base.total_net_profit = p_dim.total_net_profit THEN '✅ PASS' 
        ELSE '❌ FAIL' 
    END AS status
FROM Profit_Raw_Calc p_base, Profit_Via_Genre_Rollup p_dim;