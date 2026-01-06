#"""
# This Python file is based on the ETL.py, including the SCD optional bonus. 
#"""



# ==============================
# This Python script processes the ETL stage (Extract, Transform, Load).
# ==============================

import pandas as pd
import psycopg2
import time
# Read CSV
print("Leser fil")
df = pd.read_csv('online_retail_II.csv', dtype={'StockCode': str})  # Force string type

# Convert InvoiceDate to dateTime
df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])

# Fill NULL customer ID values with 0 (anonymous)
df['Customer ID'] = df['Customer ID'].fillna(0).astype('int64')

# ==============================
# REMOVE SPECIFIC STOCKCODES
# ==============================
remove_stockcodes = [
    "TEST002",
    "TEST001",
    "SP1002",
    "S",
    "PADS",
    "M",
    "m",
    "D",
    "BANK CHARGES",
    "B",
    "AMAZONFEE",
    "ADJUST",
    "GIFT_0001_10",
    "GIFT_0001_20",
    "GIFT_0001_30",
    "GIFT_0001_40",
    "GIFT_0001_50",
    "GIFT_0001_60",
    "GIFT_0001_70",
    "GIFT_0001_80",
    "GIFT_0001_90"
]
initial_rows = len(df)
df = df[~df["StockCode"].isin(remove_stockcodes)]
print(f"Removed {initial_rows - len(df):,} rows with unwanted StockCodes")
print(f"Remaining rows: {len(df):,}")

# DEBUG: Count unique StockCodes in df
unique_stockcodes_in_df = df['StockCode'].nunique()
print(f"DEBUG: Unique StockCodes in df: {unique_stockcodes_in_df:,}")

# ==============================
# Connection to Database
# ==============================
print("Opens SQL connection with psycopg2...")
conn = psycopg2.connect(
    dbname="bid3000_eksamen",
    user="postgres",
    password="test123",
    host="localhost",
    port=5432
)
cur = conn.cursor()

# Set schema search path
cur.execute("SET search_path TO bid3000_eksamen")

# Clear dimension tables (so re-runs work)
cur.execute("TRUNCATE TABLE factsales, factcancellations CASCADE")
cur.execute("TRUNCATE TABLE dimdate, dimcustomer, dimproduct, dimcountry CASCADE")
conn.commit()

start_time = time.time()

# Extract unique dates
print("Extracts unique dates...")
dates = df['InvoiceDate'].unique()
for date in dates:
    cur.execute(
        "INSERT INTO dimdate (date, year, month, day) VALUES (%s, %s, %s, %s)",
        (date, date.year, date.month, date.day)
    )
print("Extraction of unique dates complete.")
print(f"Dates done: {time.time() - start_time:.1f}s")

# Extract unique customers
print("=== === ===\nExtracts unique customers...")
cur.execute(
    "INSERT INTO dimcustomer (customerid, customername) VALUES (%s, %s)",
    (0, 'Anonymous')
)

customers = df['Customer ID'].fillna(0).astype('int64').unique()
for cid in customers:
    cid = int(cid)
    if cid != 0:  # Don't re-insert anonymous
        cur.execute(
            "INSERT INTO dimcustomer (customerid, customername) VALUES (%s, %s)",
            (cid, None)
        )
print("Extraction of unique customers complete.")
print(f"Customers done: {time.time() - start_time:.1f}s")







# Extract unique products with SCD Type 2 (Tracks price changes over time)
print("=== === ===\nExtracts unique products (SCD Type 2)...")
products = df[df['Description'].notna()][['StockCode', 'Description', 'Price']].drop_duplicates()
products = products[products['Price'] > 0]

# Load existing products
cur.execute("SELECT stockcode, price, productid, is_current FROM dimproduct WHERE is_current = TRUE")
existing_products = {row[0]: {'price': row[1], 'id': row[2]} for row in cur.fetchall()}

shipping_keywords = ['POSTAGE', 'DOTCOM POSTAGE', 'CARRIAGE']
inserted_products = 0
updated_products = 0

for _, row in products.iterrows():
    description = str(row['Description']).strip().title()
    is_shipping = any(keyword in description.upper() for keyword in shipping_keywords)

    # Check if product exists
    if row['StockCode'] in existing_products:
        existing_price = existing_products[row['StockCode']]['price']

        # Price changed → SCD Type 2
        if existing_price != row['Price']:
            # Close old record
            cur.execute(
                "UPDATE dimproduct SET end_date = CURRENT_DATE, is_current = FALSE WHERE stockcode = %s AND is_current = TRUE",
                (row['StockCode'],)
            )
            # Insert new record
            cur.execute(
                "INSERT INTO dimproduct (stockcode, description, price, is_shipping, effective_date, is_current) VALUES (%s, %s, %s, %s, CURRENT_DATE, TRUE)",
                (row['StockCode'], description, row['Price'], is_shipping)
            )
            updated_products += 1
    else:
        # New product
        cur.execute(
            "INSERT INTO dimproduct (stockcode, description, price, is_shipping, effective_date, is_current) VALUES (%s, %s, %s, %s, CURRENT_DATE, TRUE)",
            (row['StockCode'], description, row['Price'], is_shipping)
        )
        inserted_products += 1

print(f"New products: {inserted_products:,}, Price changes tracked: {updated_products:,}")
print(f"DEBUG: Actually inserted {inserted_products:,} products into dimproduct")
print("Extraction of unique products complete.")
print(f"Products done: {time.time() - start_time:.1f}s")







# Extract unique countries
print("=== === ===\nExtracts unique countries...")
countries = df[['Country']].drop_duplicates()
for country in countries['Country']:
    cur.execute("INSERT INTO dimcountry (countryname) VALUES (%s)", (country,))
print("Extraction of unique countries complete.")
print(f"Countries done: {time.time() - start_time:.1f}s")

# ==============================
# Creating dimension tables...
# ==============================
print("=== === ===\nLoading dimension tables into memory for faster processing...")
cur.execute("SELECT date, dateid FROM dimdate")
date_map = {row[0]: row[1] for row in cur.fetchall()}

cur.execute("SELECT customerid FROM dimcustomer")
customer_ids = {row[0] for row in cur.fetchall()}

cur.execute("SELECT stockcode, productid FROM dimproduct WHERE is_current = TRUE")
product_map = {row[0]: row[1] for row in cur.fetchall()}
print(f"DEBUG: product_map has {len(product_map):,} entries")

cur.execute("SELECT countryname, countryid FROM dimcountry")
country_map = {row[0]: row[1] for row in cur.fetchall()}

# Create set of valid StockCodes for faster lookup
valid_stockcodes = set(product_map.keys())
print(f"DEBUG: valid_stockcodes has {len(valid_stockcodes):,} entries")

# DEBUG: Check for missing StockCodes
df_stockcodes = set(df['StockCode'].unique())
missing_stockcodes = df_stockcodes - valid_stockcodes
print(f"DEBUG: StockCodes in df but NOT in product_map: {len(missing_stockcodes):,}")
if len(missing_stockcodes) > 0 and len(missing_stockcodes) <= 20:
    print(f"DEBUG: Missing StockCodes: {sorted(list(missing_stockcodes))}")
elif len(missing_stockcodes) > 20:
    print(f"DEBUG: First 20 missing StockCodes: {sorted(list(missing_stockcodes))[:20]}")

# Inserting into facts sales table...
print("Inserting fact sales... This might take a few minutes...")

# DEBUG counters
total_rows = 0
skipped_quantity_zero = 0
skipped_price_zero = 0
skipped_stockcode_missing = 0
inserted_rows = 0

for _, row in df.iterrows():
    total_rows += 1
    
    if row['Quantity'] == 0:
        skipped_quantity_zero += 1
        continue
    
    if row['Price'] <= 0:
        skipped_price_zero += 1
        continue
    
    if row['StockCode'] not in valid_stockcodes:
        skipped_stockcode_missing += 1
        continue

    date_id = date_map[row['InvoiceDate'].date()]
    cid = int(row['Customer ID']) if pd.notna(row['Customer ID']) else 0
    product_id = product_map[row['StockCode']]
    country_id = country_map[row['Country']]
    revenue = row['Quantity'] * row['Price']

    cur.execute(
        """INSERT INTO factsales (dateid_fk, customerid_fk, productid_fk,
        countryid_fk, quantity, unitprice, revenue)
        VALUES (%s, %s, %s, %s, %s, %s, %s)""",
        (date_id, cid, product_id, country_id, row['Quantity'], row['Price'], revenue)
    )
    inserted_rows += 1

print(f"\nDEBUG SUMMARY FOR FACTSALES:")
print(f"  Total rows processed: {total_rows:,}")
print(f"  Skipped (Quantity == 0): {skipped_quantity_zero:,}")
print(f"  Skipped (Price <= 0): {skipped_price_zero:,}")
print(f"  Skipped (StockCode not in product_map): {skipped_stockcode_missing:,}")
print(f"  Actually inserted: {inserted_rows:,}")

conn.commit()  # Commit once after loop, not per row
print("Insertion of fact sales complete.")
print(f"FactSales complete: {time.time() - start_time:.1f}s ({(time.time() - start_time)/60:.1f} minutes)")

# Insert into FactCancellations (cancelled invoices, Invoice starts with 'C')
cancelled = df[df['Quantity'] < 0].copy()
cancelled = cancelled[cancelled['Price'] > 0]  # Skip zero/negative prices
print("=== === ===\nInserting into fact-table factcancellations...")

# DEBUG counters for cancellations
cancelled_total = len(cancelled)
cancelled_skipped = 0
cancelled_inserted = 0

for _, row in cancelled.iterrows():
    if row['StockCode'] not in valid_stockcodes:
        cancelled_skipped += 1
        continue
    
    date_id = date_map[row['InvoiceDate'].date()]
    cid = int(row['Customer ID']) if pd.notna(row['Customer ID']) else 0
    product_id = product_map[row['StockCode']]
    country_id = country_map[row['Country']]
    revenue_lost = abs(row['Quantity'] * row['Price'])
    
    cur.execute(
        """INSERT INTO factcancellations (dateid_fk, customerid_fk, productid_fk,
        countryid_fk, quantity_cancelled, revenue_lost)
        VALUES (%s, %s, %s, %s, %s, %s)""",
        (date_id, cid, product_id, country_id, abs(row['Quantity']), revenue_lost)
    )
    cancelled_inserted += 1

print(f"\nDEBUG SUMMARY FOR FACTCANCELLATIONS:")
print(f"  Total cancelled rows: {cancelled_total:,}")
print(f"  Skipped (StockCode not in product_map): {cancelled_skipped:,}")
print(f"  Actually inserted: {cancelled_inserted:,}")

conn.commit()
print("Insertion of fact cancellations complete.")
print(f"FactCancellations complete: {time.time() - start_time:.1f}s ({(time.time() - start_time)/60:.1f} minutes)")

cur.close()
conn.close()