# Movie Industry Data Warehouse - Financial Analysis

## 1. Project Overview

This project focuses on building an Enterprise-grade Data Warehouse to analyze the financial performance and profitability of the movie industry. By integrating datasets from TMDB and IMDb, the project showcases an end-to-end Data Engineering pipeline: from raw data profiling and Virtual Staging via Pandas, to the design of a strict Star Schema, automated Quality Assurance, and advanced OLAP analytics mathematically validated through Data Reconciliation.

## 2. Environment Setup

To initialize the project environment, use the following commands:

```bash
git clone https://github.com/Fredo02/DM_Project_Movies.git
cd DM_Project_Movies
```

### Initializing the Workspace

- **Virtual Environment:** Create a virtual environment using `python -m venv .venv`.
- **Activation:**
  - Windows: `.venv\Scripts\activate`
  - Mac/Linux: `source .venv/bin/activate`
- **Dependencies:** Install the required libraries with `pip install -r requirements.txt`.

## 3. Data Sources

Two primary datasets from Kaggle are integrated to populate the Data Warehouse:

- **TMDB Movies Dataset:** Used for core financial metrics like budget and revenue.
  - Link: https://www.kaggle.com/datasets/juzershakir/tmdb-movies-dataset
- **IMDb Movies Dataset:** Used for movie ratings, genres, and production details.
  - Link: https://www.kaggle.com/datasets/ashpalsingh1525/imdb-movies-dataset

## 4. Project Structure & Core Files

The repository is structured to separate raw data, processing logic, and physical database operations.

- `data/raw/`: Contains original CSV files from Kaggle. (Not tracked by Git).
- `data/processed/integrated_movies.csv`: The Golden Record. This CSV is the physical output of the Virtual Staging phase. It is saved locally to decouple the heavy text-matching and deduplication logic (Pandas) from the database loading phase. This acts as a reliable backup and guarantees pipeline reproducibility without needing to re-run expensive string operations.
- `notebooks/`: Jupyter Notebook containing the Python ETL pipeline, dynamic key discovery, auto-detect alignment algorithms, and database injection logic.
- `scripts/01_create_warehouse_tables.sql`: The physical Data Definition Language (DDL) script. It creates isolated `dw` and `audit` schemas, establishes the Star Schema (Dimensions, Facts, Bridge Tables), and enforces strict data constraints (e.g., `CHECK (budget >= 0)`).
- `scripts/02_quality_checks.sql`: An automated QA Dashboard. It runs sanity checks for orphan records, negative financials, missing data, and Bridge Table referential integrity, acting as a traffic light for data health.
- `scripts/03_olap_business_views.sql`: Materialized analytical views encapsulating complex logic (e.g., Top Actors by Profit). Features human-readable currency formatting (`TO_CHAR`) for BI tool readiness while preserving mathematical sorting.
- `scripts/04_olap_sample_queries.sql`: Advanced OLAP operations demonstrating Roll-up, Drill-down, Slice and Dice, Pivoting, and Drill-across. Includes advanced SQL techniques like Window Functions (`ROW_NUMBER`) and a final View Showcase.
- `scripts/05_automated_reconciliation.sql`: The ultimate sanity check. Proves mathematically that the dimensional modeling does not duplicate records (zero fan-out) or drop revenue data during complex JOIN operations compared to the raw fact table.

## 5. Development Summary & Methodology

The project was executed in a 9-phase methodology mimicking real-world Data Engineering lifecycles:

### Phase 1: Data Profiling

Analyzed the structure and quality of raw data. Developed a dynamic column analysis script in Python to identify the best text-based join keys, mitigating the absence of a shared unique identifier between TMDB and IMDb.

### Phase 2: Conceptual & Logical Design

Architected the Data Warehouse using a Dimensional Fact Model (DFM) translated into a pure Star Schema. The schema features `dim_date`, `dim_movie`, `dim_production`, `dim_person`, a many-to-many `bridge_movie_cast` table, and a central `fact_movie_performance` table.

### Phase 3 & 4: ETL & Virtual Staging

Implemented a Two-Layer Architecture, using Python/Pandas as a "Virtual Staging" area to avoid overloading the DB with messy data. Executed a rigorous 4-way cross merge on heavily normalized titles (removing spaces, articles, and punctuation) with a +/- 1 year tolerance. Deduplicated the results and dynamically generated unique titles for homonyms. This phase successfully certified a core dataset of 4,188 highly accurate movie matches, saving the results in `integrated_movies.csv`.

### Phase 5: Database Loading (Auto-Detect Engine)

Used SQLAlchemy to map the reconciled Python DataFrame into the physical PostgreSQL tables. Developed an "Auto-Detect" script that dynamically cross-references TMDB columns against the Database to guarantee perfect alignment before generating UUIDs and populating the schema. The execution is logged in a dedicated `audit.load_event` table.

### Phase 6: Automated Quality Assurance

Created a custom SQL dashboard (`02_quality_checks.sql`) to automatically validate the integrity of the upload, guaranteeing 0 orphan records and fully valid financial metrics.

### Phase 7: Business Views

Encapsulated complex queries into highly optimized VIEWS (`03_olap_business_views.sql`). Financial outputs were formatted into executive-ready USD strings, enabling seamless integration with visualization tools like Tableau or Power BI.

### Phase 8: OLAP Analytics

Written comprehensive SQL scripts (`04_olap_sample_queries.sql`) covering all 5 standard OLAP operations. Showcased advanced querying capabilities, including Window Functions to isolate the "Golden Decade" of specific countries and LEFT JOIN aggregations to map Studio dominance.

### Phase 9: Data Reconciliation (Sanity Check)

Implemented a crucial mathematical validation step (`05_automated_reconciliation.sql`). This script dynamically compares the granular raw data against the aggregated dimensional data, proving absolute data integrity, zero loss, and preventing silent analytical errors caused by fan-out.