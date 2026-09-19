# Movie Industry Data Warehouse - Financial Analysis

## 1. Project Overview

This project focuses on building a Data Warehouse to analyze the financial performance and profitability of the movie industry. By integrating datasets from TMDB and IMDb, my goal is to perform ETL operations, design a Star Schema, and conduct OLAP analysis to extract business insights.

## 2. Environment Setup

To initialize the project environment, I use the following commands:

```bash
git clone https://github.com/Fredo02/DM_Project_Movies.git
cd DM_Project_Movies
```

### Initializing the Workspace

- **Virtual Environment:** I create a virtual environment using `python -m venv .venv`.
- **Activation:**
  - Windows: `.venv\Scripts\activate`
  - Mac/Linux: `source .venv/bin/activate`
- **Dependencies:** I install the required libraries with `pip install -r requirements.txt`.

## 3. Data Sources

I am using two primary datasets from Kaggle to populate the Data Warehouse:

- **TMDB Movies Dataset:** Used for core financial metrics like budget and revenue.
  - Link: https://www.kaggle.com/datasets/juzershakir/tmdb-movies-dataset
- **IMDb Movies Dataset:** Used for movie ratings, genres, and production details.
  - Link: https://www.kaggle.com/datasets/ashpalsingh1525/imdb-movies-dataset

## 4. Project Structure

- `data/raw/`: Contains original CSV files from Kaggle. These are not tracked by Git.
- `data/processed/`: Contains `integrated_movies.csv`, the final cleaned dataset backup ready for DB injection.
- `notebooks/`: Jupyter Notebook documenting the ETL pipeline and data discovery.
- `scripts/`: SQL scripts for physical database creation (DDL).

## 5. Development Summary & Methodology

### Phase 1: Data Profiling (Completed)

- **Objective:** Analyze the structure and quality of raw data.
- **Outcome:** Developed a dynamic column analysis script in Python to identify the best text-based join keys, mitigating the absence of a shared unique identifier between TMDB and IMDb.

### Phase 2: Conceptual & Logical Design (Completed)

- **Objective:** Architect the Data Warehouse according to academic best practices.
- **Outcome:** Designed a Dimensional Fact Model (DFM) and translated it into a pure Star Schema. The schema consists of `DIM_DATE`, `DIM_MOVIE`, `DIM_PRODUCTION`, and a central `FACT_MOVIE_PERFORMANCE`. The fact table strictly uses a composite primary key derived from its foreign keys.

### Phase 3 & 4: ETL & Virtual Staging (Completed)

- **Objective:** Extract, clean, and integrate the datasets without over-engineering.
- **Outcome:** Implemented a Two-Layer Architecture, explicitly avoiding a materialized Reconciled Layer. Used Python/Pandas as a "Virtual Staging" area. Executed a 4-way cross merge on heavily normalized titles (removing spaces, articles, and punctuation) with a +/- 1 year tolerance. Deduplicated the results and dynamically generated unique titles for homonyms (e.g., *King Kong* (1976) vs *King Kong* (2005)). Successfully certified a core dataset of 4,188 highly accurate movie matches.

### Phase 5: Database Loading (To Do)

- **Objective:** Populate the physical PostgreSQL database.
- **Plan:** Use SQLAlchemy to map the reconciled Python DataFrame into the dimension and fact tables, generating numerical Surrogate Keys automatically.

### Phase 6: OLAP Analysis (To Do)

- **Objective:** Extract business insights.
- **Plan:** Write complex SQL queries to perform Roll-up, Drill-down, and Slice-and-dice operations on financial metrics and audience scores.