-- ============================================================
-- Automated Data Quality Checks (Enterprise)
-- ============================================================

WITH orphan_check AS (
    SELECT COUNT(*) AS issues
    FROM dw.fact_movie_performance f
    LEFT JOIN dw.dim_movie m ON f.movie_id = m.movie_id
    WHERE m.movie_id IS NULL
),
negative_financials_check AS (
    SELECT COUNT(*) AS issues
    FROM dw.fact_movie_performance
    WHERE budget < 0 OR revenue < 0
),
duplicate_movies_check AS (
    SELECT COUNT(*) AS issues
    FROM (
        SELECT title
        FROM dw.dim_movie
        GROUP BY title
        HAVING COUNT(*) > 1
    ) d
),
imdb_score_range AS (
    SELECT COUNT(*) AS issues
    FROM dw.fact_movie_performance
    WHERE average_score < 0 OR average_score > 100
),
missing_financials AS (
    SELECT COUNT(*) AS issues
    FROM dw.fact_movie_performance
    WHERE budget = 0 AND revenue = 0
),
bridge_integrity_check AS (
    SELECT COUNT(*) AS issues 
    FROM dw.bridge_movie_cast b
    LEFT JOIN dw.dim_movie m ON b.movie_id = m.movie_id
    LEFT JOIN dw.dim_person p ON b.person_id = p.person_id
    WHERE m.movie_id IS NULL OR p.person_id IS NULL
)

SELECT 'Referential Integrity (Orphans)' AS validation_test, issues AS issue_count, CASE WHEN issues = 0 THEN 'PASS' ELSE 'CHECK' END AS status FROM orphan_check
UNION ALL
SELECT 'Negative Financials', issues, CASE WHEN issues = 0 THEN 'PASS' ELSE 'CHECK' END FROM negative_financials_check
UNION ALL
SELECT 'Duplicate Movies', issues, CASE WHEN issues = 0 THEN 'PASS' ELSE 'CHECK' END FROM duplicate_movies_check
UNION ALL
SELECT 'Invalid IMDb Score Range', issues, CASE WHEN issues = 0 THEN 'PASS' ELSE 'CHECK' END FROM imdb_score_range
UNION ALL
SELECT 'Missing Financial Data (Both 0)', issues, CASE WHEN issues = 0 THEN 'PASS' ELSE 'INFO' END FROM missing_financials
UNION ALL
SELECT 'Bridge Referential Integrity', issues, CASE WHEN issues = 0 THEN 'PASS' ELSE 'CHECK' END FROM bridge_integrity_check;