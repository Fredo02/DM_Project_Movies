# Movie Industry Data Warehouse - Financial Analysis

## Project Overview
This project aims to build a Data Warehouse to analyze the financial performance (budget, revenue, ROI) of the movie industry. It integrates heterogeneous data from TMDB and IMDb to provide insights through OLAP sessions.

## 1. Environment Setup
To ensure consistency across different machines, follow these steps:

### Prerequisites
* VS Code
* Python 3.x
* PostgreSQL

### Initialization
1. **Clone the repository**:
```bash
git clone <your-repository-url>
cd Movies-Data-Warehouse
```

2. **Setup Virtual Environment**:
```bash
python -m venv .venv

# Windows activation:
.venv\Scripts\activate

# Mac/Linux activation:
source .venv/bin/activate
```

3. **Install Dependencies**:
```bash
pip install -r requirements.txt
```

## 2. Project Structure
* `data/raw/`: Contains original CSV files from Kaggle (excluded from Git).
* `data/processed/`: Contains cleaned datasets after Python ETL.
* `notebooks/`: Jupyter Notebooks for data profiling and cleaning.
* `scripts/`: Python/SQL scripts for database loading and analysis.

## 3. Data Sources
* **TMDB Dataset**: Financial metrics (Budget, Revenue).
* **IMDb Dataset**: Ratings and detailed metadata (Score, Cast).

## 4. Development Roadmap
- [x] **Phase 1: Data Profiling**: Initial analysis of TMDB and IMDb datasets using Python/Pandas.
- [ ] **Phase 2: Design**: DFM (Dimensional Fact Model) and Star Schema design.
- [ ] **Phase 3: ETL & Reconciled Layer**: Data cleaning and integration in PostgreSQL.
- [ ] **Phase 4: OLAP Analysis**: Execution of complex SQL queries (Roll-up, Drill-down).
- [ ] **Phase 5: Presentation**: Preparation of slides and live demo.

## 5. How to Contribute / Important Reminders
* **Git Sync**: Always use `git pull` before starting work on a different machine to get the latest code.
* **Data Privacy**: NEVER push the `data/` folder to GitHub. The datasets are too large and should remain local (this is handled by the `.gitignore` file). If changing computers, re-download the CSV files from Kaggle and place them in `data/raw/`.
* **Documentation**: Document every major ETL decision (e.g., how null values were handled) in the Jupyter Notebooks for the final presentation.