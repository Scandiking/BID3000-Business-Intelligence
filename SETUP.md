# Setup Guide - BID3000 Business Intelligence Project

This guide will walk you through setting up the complete Business Intelligence pipeline.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Python 3.8 or higher** - [Download Python](https://www.python.org/downloads/)
- **PostgreSQL 13 or higher** - [Download PostgreSQL](https://www.postgresql.org/download/)
- **PowerBI Desktop** - [Download PowerBI](https://powerbi.microsoft.com/desktop/) (Windows only)
- **Git** - [Download Git](https://git-scm.com/downloads)

## Step-by-Step Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Karmaburner/BID3000-Business-Intelligence.git
cd BID3000-Business-Intelligence
```

### 2. Set Up Python Environment

#### Option A: Using venv (Recommended)
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

#### Option B: Using conda
```bash
# Create conda environment
conda create -n bid3000 python=3.8

# Activate environment
conda activate bid3000

# Install dependencies
pip install -r requirements.txt
```

### 3. Set Up PostgreSQL Database

#### Create Database
```bash
# Connect to PostgreSQL (default user is 'postgres')
psql -U postgres

# In psql, create the database:
CREATE DATABASE bid3000_eksamen;

# Exit psql
\q
```

#### Run Schema Creation Script
```bash
psql -U postgres -d bid3000_eksamen -f Database/create_schema.sql
```

**Expected output:**
```
DROP SCHEMA
CREATE SCHEMA
SET
CREATE TABLE
CREATE TABLE
... (all tables created)
```

### 4. Obtain the Dataset

The project uses the "Online Retail II" dataset from UCI Machine Learning Repository.

**Option 1: Download from Kaggle**
1. Visit [Kaggle: Online Retail II UCI](https://www.kaggle.com/datasets/mashlyn/online-retail-ii-uci)
2. Download `online_retail_II.csv`
3. Place it in the `ETL/` directory

**Option 2: Download from UCI**
1. Visit [UCI ML Repository](https://archive.ics.uci.edu/ml/datasets/Online+Retail+II)
2. Download the dataset
3. Ensure it's named `online_retail_II.csv` and place it in `ETL/`

### 5. Configure Database Connection

Edit `ETL/etl.py` with your PostgreSQL credentials:

```python
conn = psycopg2.connect(
    dbname="bid3000_eksamen",
    user="postgres",          # Your PostgreSQL username
    password="your_password", # Your PostgreSQL password
    host="localhost",
    port=5432
)
```

**Security Note:** Never commit credentials to GitHub! Consider using environment variables:

```python
import os
conn = psycopg2.connect(
    dbname="bid3000_eksamen",
    user=os.getenv('DB_USER', 'postgres'),
    password=os.getenv('DB_PASSWORD'),
    host=os.getenv('DB_HOST', 'localhost'),
    port=os.getenv('DB_PORT', 5432)
)
```

### 6. Run the ETL Process

```bash
cd ETL
python etl.py
```

**Expected output:**
```
Leser fil
Removed 19,234 rows with unwanted StockCodes
Remaining rows: 1,048,575
Opens SQL connection with psycopg2...
Extracts unique dates...
...
Extraction complete.
```

**This process takes approximately 2-3 minutes for 1M+ rows.**

### 7. Verify Data Load

Check that data was loaded correctly:

```bash
psql -U postgres -d bid3000_eksamen

# Run verification queries:
SELECT COUNT(*) FROM bid3000_eksamen.factsales;
SELECT COUNT(*) FROM bid3000_eksamen.factcancellations;
SELECT COUNT(*) FROM bid3000_eksamen.dimcustomer;
SELECT COUNT(*) FROM bid3000_eksamen.dimproduct;
```

Expected counts:
- factsales: ~530,000 rows
- factcancellations: ~490,000 rows
- dimcustomer: ~4,400 customers
- dimproduct: ~4,000 products

### 8. Run Analytics Notebook

```bash
cd ../Analytics
jupyter notebook BID3000.ipynb
```

This will:
- Open the notebook in your browser
- Connect to the database
- Run descriptive analytics
- Perform predictive modeling (RFM clustering, CLV prediction)

### 9. Set Up PowerBI Dashboard

1. Open PowerBI Desktop
2. Click "Open" and select `Dashboard/PowerBI.pbix`
3. If prompted to update data source:
   - Click "Transform data" → "Data source settings"
   - Update PostgreSQL connection:
     - Server: `localhost`
     - Database: `bid3000_eksamen`
4. Click "Refresh" to load data from your database

### 10. Run SQL Queries (Optional)

Execute the 6 advanced business intelligence queries:

```bash
psql -U postgres -d bid3000_eksamen -f Database/queries_bid3000.sql
```

## Troubleshooting

### Issue: ETL script fails with "StockCode not in product_map"
**Solution:** This is expected for removed stock codes. The script handles this automatically.

### Issue: PostgreSQL connection refused
**Solutions:**
- Check PostgreSQL is running: `sudo service postgresql status` (Linux) or check Services (Windows)
- Verify port 5432 is correct: `psql -U postgres -p 5432`
- Check firewall settings

### Issue: PowerBI can't connect to PostgreSQL
**Solution:** Install PostgreSQL ODBC driver for PowerBI:
- Download from [PostgreSQL ODBC](https://www.postgresql.org/ftp/odbc/versions/)
- Restart PowerBI Desktop after installation

### Issue: Python packages fail to install
**Solution:**
```bash
# Upgrade pip first
python -m pip install --upgrade pip

# Then install requirements
pip install -r requirements.txt
```

### Issue: Jupyter notebook kernel crashes
**Solution:**
```bash
# Install ipykernel in your virtual environment
pip install ipykernel
python -m ipykernel install --user --name=bid3000
```

## Next Steps

After successful setup:

1. **Explore the Dashboard** - Navigate through all 5 pages in PowerBI
2. **Run Analytics** - Execute the Jupyter notebook end-to-end
3. **Review Documentation** - Check `Documentation/` folder for design decisions
4. **Experiment** - Try modifying SQL queries or ML parameters

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PowerBI Documentation](https://docs.microsoft.com/power-bi/)
- [scikit-learn Documentation](https://scikit-learn.org/stable/)
- [pandas Documentation](https://pandas.pydata.org/docs/)

## Getting Help

If you encounter issues:
1. Check the [Troubleshooting](#troubleshooting) section above
2. Review error messages carefully
3. Check that all prerequisites are installed
4. Verify database credentials are correct

For questions:
- Email: kenneth.andreas.hansen@gmail.com
- Create an issue on GitHub
