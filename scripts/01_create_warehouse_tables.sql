-- ============================================================
-- Enterprise Data Warehouse Schema Setup
-- Run this script to define the hardened architecture.
-- ============================================================

-- Clean up previous failed attempts to recreate the schema cleanly
DROP SCHEMA IF EXISTS dw CASCADE;

-- Create isolated schemas for data and logging
CREATE SCHEMA IF NOT EXISTS dw;
CREATE SCHEMA IF NOT EXISTS audit;

-- ============================================================
-- Audit & Logging
-- ============================================================
CREATE TABLE IF NOT EXISTS audit.load_event (
    load_event_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    loaded_movies INT,
    loaded_persons INT,
    status TEXT
);
COMMENT ON TABLE audit.load_event IS 'Tracks ETL pipeline execution and row counts.';

-- ============================================================
-- Dimensions
-- ============================================================
CREATE TABLE IF NOT EXISTS dw.dim_movie (
    movie_id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    original_language TEXT,
    primary_genre TEXT,
    runtime_minutes NUMERIC
);
COMMENT ON TABLE dw.dim_movie IS 'Core movie attributes.';

CREATE TABLE IF NOT EXISTS dw.dim_production (
    production_id TEXT PRIMARY KEY,
    company_name TEXT,
    country_name TEXT
);
COMMENT ON TABLE dw.dim_production IS 'Production companies and geographical origin.';

CREATE TABLE IF NOT EXISTS dw.dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE,
    release_year INT,
    release_month INT,
    release_quarter INT
);
COMMENT ON TABLE dw.dim_date IS 'Time dimension for release dates.';

CREATE TABLE IF NOT EXISTS dw.dim_person (
    person_id TEXT PRIMARY KEY,
    primary_name TEXT NOT NULL
);
COMMENT ON TABLE dw.dim_person IS 'Unified dimension for actors and directors.';

-- ============================================================
-- Facts & Bridge Tables
-- ============================================================
CREATE TABLE IF NOT EXISTS dw.fact_movie_performance (
    movie_id TEXT REFERENCES dw.dim_movie(movie_id),
    production_id TEXT REFERENCES dw.dim_production(production_id),
    date_id INT REFERENCES dw.dim_date(date_id),
    budget NUMERIC CHECK (budget >= 0),
    revenue NUMERIC CHECK (revenue >= 0),
    net_profit NUMERIC,
    average_score NUMERIC CHECK (average_score BETWEEN 0 AND 100),
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (movie_id)
);
COMMENT ON TABLE dw.fact_movie_performance IS 'Transactional fact table containing financial and critical performance.';

CREATE TABLE IF NOT EXISTS dw.bridge_movie_cast (
    movie_id TEXT REFERENCES dw.dim_movie(movie_id),
    person_id TEXT REFERENCES dw.dim_person(person_id),
    job_role TEXT NOT NULL CHECK (job_role IN ('Director', 'Actor')),
    PRIMARY KEY (movie_id, person_id, job_role)
);
COMMENT ON TABLE dw.bridge_movie_cast IS 'Many-to-many bridge resolving relationships between movies and people.';

-- ============================================================
-- Indexes
-- ============================================================
-- Create indexes to optimize BI queries
CREATE INDEX IF NOT EXISTS idx_fact_movie ON dw.fact_movie_performance(movie_id);
CREATE INDEX IF NOT EXISTS idx_bridge_person ON dw.bridge_movie_cast(person_id);