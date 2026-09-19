-- Create Time Dimension
CREATE TABLE dim_date (
    date_id SERIAL PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    release_month INT NOT NULL,
    release_quarter INT NOT NULL,
    release_year INT NOT NULL
);

-- Create Movie Dimension
CREATE TABLE dim_movie (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL UNIQUE,
    primary_genre VARCHAR(100),
    original_language VARCHAR(50)
);

-- Create Production Dimension
CREATE TABLE dim_production (
    production_id SERIAL PRIMARY KEY,
    company_name VARCHAR(255),
    country_name VARCHAR(100),
    -- Composite Unique Key to prevent duplicating the same studio in the same country
    UNIQUE (company_name, country_name)
);

-- Create Fact Table
CREATE TABLE fact_movie_performance (
    date_id INT REFERENCES dim_date(date_id),
    movie_id INT REFERENCES dim_movie(movie_id),
    production_id INT REFERENCES dim_production(production_id),
    budget NUMERIC(18, 2) DEFAULT 0,
    revenue NUMERIC(18, 2) DEFAULT 0,
    net_profit NUMERIC(18, 2) DEFAULT 0,
    average_score NUMERIC(4, 2),
    -- Composite Primary Key derived from the foreign keys
    PRIMARY KEY (date_id, movie_id, production_id)
);