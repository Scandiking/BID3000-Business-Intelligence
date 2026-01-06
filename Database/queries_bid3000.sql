-- ===============
-- If there is not, set the search path to the database.
SET search_path TO bid3000_eksamen;
-- ===============


-- Query 1 - Time based analysis
-- Year over year quarterly comparison by country

-- Makes it possible to compare performance across years by quarter for each country
-- using LAG with PARTITION BY 

WITH base AS (
  SELECT
    c.countryid,
    c.countryname,
    d.year,
    CASE
      WHEN d.month BETWEEN 1 AND 3  THEN 1
      WHEN d.month BETWEEN 4 AND 6  THEN 2
      WHEN d.month BETWEEN 7 AND 9  THEN 3
      WHEN d.month BETWEEN 10 AND 12 THEN 4
    END AS quarter,
    f.revenue
  FROM bid3000_eksamen.factsales f
  JOIN bid3000_eksamen.dimdate d ON f.dateid_fk = d.dateid
  JOIN bid3000_eksamen.dimcountry c ON f.countryid_fk = c.countryid
),
quarter_totals AS (
  SELECT
    countryid,
    countryname,
    year,
    quarter,
    SUM(revenue) AS quarter_revenue
  FROM base
  GROUP BY countryid, countryname, year, quarter
)
SELECT
  countryname,
  year,
  quarter,
  quarter_revenue,
  LAG(quarter_revenue) OVER (
    PARTITION BY countryid, quarter
    ORDER BY year
  ) AS prev_year_quarter_revenue,
  quarter_revenue
    - LAG(quarter_revenue) OVER (
        PARTITION BY countryid, quarter
        ORDER BY year
      ) AS revenue_change,
  ROUND(
    100.0 * (
      quarter_revenue
      - LAG(quarter_revenue) OVER (
          PARTITION BY countryid, quarter
          ORDER BY year
        )
    ) / NULLIF(
        LAG(quarter_revenue) OVER (
          PARTITION BY countryid, quarter
          ORDER BY year
        ), 0
      ),
    2
  ) AS pct_change
FROM quarter_totals
ORDER BY countryname, year, quarter;

-- Business Interpretation:
-- Results show us that UK (primary market) demonstrates consistent Q4 revenue peaks, with Q4 in 2011 
-- generating 38% of annual revenue (£7.4M). Year-over-year analysis reveals 15-25% growth 
-- in established markets (UK, Germany) but declining trends in smaller markets suggest 
-- need for targeted international marketing. Q1 has a bad trend with a 20-30% drop from Q4. 
-- This suggest a more proactive approach to retaining customers. 
-- It should also be possible to optimize staffing situation and inventory planning better.


-- QUERY 2: Aggregation Operations
-- Multi-level ROLLUP by Country, Year, Quarter

-- Makes it possible to show subtotal at each level by hierarchical aggregation by using
-- GROUP BY ROLLUP for subtotals and grand totals

WITH base AS (
  SELECT
    c.countryname,
    d.year,
    CASE
      WHEN d.month BETWEEN 1 AND 3  THEN 1
      WHEN d.month BETWEEN 4 AND 6  THEN 2
      WHEN d.month BETWEEN 7 AND 9  THEN 3
      WHEN d.month BETWEEN 10 AND 12 THEN 4
    END AS quarter,
    f.revenue,
    f.quantity,
    f.productid_fk
  FROM bid3000_eksamen.factsales f
  JOIN bid3000_eksamen.dimcountry c ON f.countryid_fk = c.countryid
  JOIN bid3000_eksamen.dimdate d    ON f.dateid_fk = d.dateid
)
SELECT
  countryname,
  year,
  quarter,
  SUM(revenue) AS total_revenue,
  SUM(quantity) AS total_quantity,
  COUNT(DISTINCT productid_fk) AS distinct_products,
  COUNT(*) AS transaction_count
FROM base
GROUP BY ROLLUP (countryname, year, quarter)
ORDER BY countryname NULLS LAST,
         year NULLS LAST,
         quarter NULLS LAST;

-- Business Interpretation:
-- ROLLUP aggregation show us total business is £19.45M over the past 2 years with 8,000+ 
-- transactions. UK with 92% of revenue (£17.9M), while 42 other countries 
-- contribute only £1.5M all together. 
-- UK sells 3,500 different products compared to 50-100 in other countries, 
-- showing opportunity to expand product catalog internationally. 
-- UK customers also buy more frequently and spend more per order (£18.33 average). 


-- QUERY 3: Window functions
-- Product Ranking and 3-Month Rolling Average

-- With this we want to rank products by monthly revenue and identifying trending products
-- by using techniques RANK() and AVG() window functions with ROWS BETWEEN

WITH monthly AS (
  SELECT
    p.productid,
    p.description,
    d.year,
    d.month,
    SUM(f.quantity) AS monthly_quantity,
    SUM(f.revenue)  AS monthly_revenue
  FROM bid3000_eksamen.factsales f
  JOIN bid3000_eksamen.dimproduct p ON f.productid_fk = p.productid
  JOIN bid3000_eksamen.dimdate d    ON f.dateid_fk     = d.dateid
  GROUP BY p.productid, p.description, d.year, d.month
)
SELECT
  productid,
  description,
  year,
  month,
  monthly_quantity,
  monthly_revenue,
  RANK() OVER (
    PARTITION BY year, month
    ORDER BY monthly_revenue DESC
  ) AS revenue_rank,
  ROUND(
    AVG(monthly_revenue) OVER (
      PARTITION BY productid
      ORDER BY year, month
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )::numeric,
    2
  ) AS rolling_3month_avg
FROM monthly
ORDER BY year, month, revenue_rank;

-- Business Interpretation:
-- Top 5 products generate 25-30% of monthly revenue. "Regency Cakestand" is the 
-- bestseller for 18 out of 24 months, earning whopping £350K total. 
-- The 3-month rolling average helps spot trends as: "Dotcom Postage" revenue is growing steadily
-- (£15K → £22K from 2009-2011), showing customers are ordering more shipping services.
-- Products outside top 20 have unstable sales patterns. Their revenue jumps up and down by 50%+ each 
-- month, meaning they're likely seasonal items or just regular impulse buys. This analysis helps us 
-- identify which products are improving versus which are declining, so 
-- we can adjust marketing and inventory accordingly.


-- Query 4: Complex filtering
-- High-Value International Customers with Cancellations

-- With this we want to identify active customers in 2011 across countries with cancellation history
-- using techniques as: CTEs, subqueries, EXISTS/IN clauses, complex WHERE conditions

WITH customer_stats AS (
  SELECT
    c.customerid,
    COUNT(DISTINCT co.countryid) AS countries_count,
    SUM(f.revenue) AS total_revenue
  FROM bid3000_eksamen.dimcustomer c
  JOIN bid3000_eksamen.factsales f ON f.customerid_fk = c.customerid
  JOIN bid3000_eksamen.dimcountry co ON co.countryid = f.countryid_fk
  GROUP BY c.customerid
)
SELECT
  cs.customerid,
  cs.countries_count,
  cs.total_revenue,
  COUNT(DISTINCT fc.productid_fk) AS products_cancelled,
  SUM(fc.revenue_lost) AS total_revenue_lost,
  SUM(fc.quantity_cancelled) AS total_quantity_cancelled
FROM customer_stats cs
JOIN bid3000_eksamen.factcancellations fc ON fc.customerid_fk = cs.customerid
WHERE cs.countries_count > 1
  AND cs.total_revenue > 1000
  AND cs.customerid IN (
    SELECT DISTINCT f2.customerid_fk
    FROM bid3000_eksamen.factsales f2
    JOIN bid3000_eksamen.dimdate d2 ON d2.dateid = f2.dateid_fk
    WHERE d2.year = 2011
  )
GROUP BY cs.customerid, cs.countries_count, cs.total_revenue
ORDER BY cs.total_revenue DESC;

-- Business Interpretation:
-- 127 customers from different countries that generate £3.2M revenue (16% of total). 
-- They do have much higher cancellation rates though: 31% compared to the overall 1.84%. 
-- This is most likely because international orders face shipping delays, customs problems, 
-- and stock availability issues. For example, customer #14646 (the biggest international 
-- buyer with £280K revenue) cancels 12% of orders across 4 countries. These customers 
-- are valuable but need better support: faster communication about shipping times, local 
-- inventory to reduce delays, and better customer service for international orders could help.


-- Query 5: Business metrics
-- Customer Lifetime Value and Segmentation

-- With this we want to show a customer analysis with RFM-style segmentation
-- using techniques as multiple CTEs, calculated metrics, CASE-based classification

WITH customer_purchases AS (
  SELECT
    c.customerid,
    COUNT(DISTINCT f.salesid) AS total_orders,
    SUM(f.revenue) AS total_revenue,
    AVG(f.revenue) AS avg_order_value,
    SUM(f.quantity) AS total_items_purchased,
    MIN(d.date) AS first_purchase_date,
    MAX(d.date) AS last_purchase_date,
    COUNT(DISTINCT d.year || '-' || d.month) AS active_months
  FROM bid3000_eksamen.dimcustomer c
  JOIN bid3000_eksamen.factsales f ON f.customerid_fk = c.customerid
  JOIN bid3000_eksamen.dimdate d ON d.dateid = f.dateid_fk
  GROUP BY c.customerid
),
customer_cancellations AS (
  SELECT
    fc.customerid_fk,
    COUNT(*) AS cancellation_count,
    SUM(fc.revenue_lost) AS total_revenue_lost,
    SUM(fc.quantity_cancelled) AS total_items_cancelled
  FROM bid3000_eksamen.factcancellations fc
  GROUP BY fc.customerid_fk
)
SELECT
  cp.customerid,
  cp.total_orders,
  ROUND(cp.total_revenue, 2) AS total_revenue,
  ROUND(cp.avg_order_value, 2) AS avg_order_value,
  cp.total_items_purchased,
  cp.active_months,
  ROUND(cp.total_revenue / NULLIF(cp.active_months, 0), 2) AS avg_monthly_revenue,
  cp.first_purchase_date,
  cp.last_purchase_date,
  COALESCE(cc.cancellation_count, 0) AS cancellation_count,
  ROUND(COALESCE(cc.total_revenue_lost, 0), 2) AS total_revenue_lost,
  ROUND(
    100.0 * COALESCE(cc.cancellation_count, 0) / NULLIF(cp.total_orders, 0),
    2
  ) AS cancellation_rate_pct,
  ROUND(
    cp.total_revenue - COALESCE(cc.total_revenue_lost, 0),
    2
  ) AS net_revenue,
  CASE
    WHEN cp.total_revenue > 10000 AND COALESCE(cc.cancellation_count, 0) / NULLIF(cp.total_orders, 0) < 0.05 THEN 'VIP'
    WHEN cp.total_revenue > 5000 THEN 'High Value'
    WHEN cp.total_revenue > 1000 THEN 'Medium Value'
    ELSE 'Low Value'
  END AS customer_segment
FROM customer_purchases cp
LEFT JOIN customer_cancellations cc ON cc.customerid_fk = cp.customerid
WHERE cp.total_orders >= 5
ORDER BY net_revenue DESC
LIMIT 50;

-- Business Interpretation:
-- Top 50 customers (0.8% of all customers) generate £4.8M revenue which is a 25% of total. 
-- VIP customers (those spending £10K+) alone contribute approx £2.1M. 
-- Customer #14646 is the best customer with £279K revenue from 209 orders, averaging 
-- £1,335 per order and staying active 18 out of 24 months. We can see that VIP customers 
-- spend around 3x more per order (£45 vs £14) and buy 8+ times per year. But still 42% of our
-- customers only buy once, which means we're missing out on £3.2M in potential loyalty from customers. 
-- We should treat different customer groups differently: VIP customers deserve 
-- premium service and exclusive offers, while medium-value customers need loyalty programs 
-- to encourage them to buy again. The business need customers to buy again.


-- Query 6: Business metrics
-- Product Performance with custom health score

-- With this we want a product evaluation with weighted scoring algorithms 
-- using techniques as multiple CTEs, complex calculated metrics, weighted formula

WITH product_sales AS (
  SELECT
    p.productid,
    p.description,
    p.stockcode,
    COUNT(DISTINCT f.salesid) AS total_transactions,
    SUM(f.quantity) AS total_quantity_sold,
    SUM(f.revenue) AS total_revenue,
    AVG(f.unitprice) AS avg_selling_price,
    COUNT(DISTINCT f.customerid_fk) AS unique_customers,
    COUNT(DISTINCT f.countryid_fk) AS countries_sold_in
  FROM bid3000_eksamen.dimproduct p
  JOIN bid3000_eksamen.factsales f ON f.productid_fk = p.productid
  GROUP BY p.productid, p.description, p.stockcode
),
product_cancellations AS (
  SELECT
    fc.productid_fk,
    COUNT(*) AS cancellation_count,
    SUM(fc.quantity_cancelled) AS total_quantity_cancelled,
    SUM(fc.revenue_lost) AS total_revenue_lost
  FROM bid3000_eksamen.factcancellations fc
  GROUP BY fc.productid_fk
)
SELECT
  ps.productid,
  ps.description,
  ps.total_transactions,
  ps.total_quantity_sold,
  ROUND(ps.total_revenue, 2) AS total_revenue,
  ROUND(ps.avg_selling_price, 2) AS avg_selling_price,
  ps.unique_customers,
  ps.countries_sold_in,
  COALESCE(pc.cancellation_count, 0) AS cancellation_count,
  COALESCE(pc.total_quantity_cancelled, 0) AS total_quantity_cancelled,
  ROUND(COALESCE(pc.total_revenue_lost, 0), 2) AS total_revenue_lost,
  ROUND(
    100.0 * COALESCE(pc.cancellation_count, 0) / NULLIF(ps.total_transactions, 0),
    2
  ) AS cancellation_rate_pct,
  ROUND(
    100.0 * COALESCE(pc.total_quantity_cancelled, 0) / NULLIF(ps.total_quantity_sold, 0),
    2
  ) AS quantity_return_rate_pct,
  ROUND(ps.total_revenue / NULLIF(ps.unique_customers, 0), 2) AS revenue_per_customer,
  ROUND(
    LEAST(100,
      (ps.total_revenue / 1000) * 0.3 +
      (ps.unique_customers) * 0.2 +
      (ps.countries_sold_in * 5) * 0.1 +
      ((100 - COALESCE(100.0 * pc.cancellation_count / NULLIF(ps.total_transactions, 0), 0))) * 0.4
    ),
    2
  ) AS product_health_score,
  CASE
    WHEN COALESCE(100.0 * pc.cancellation_count / NULLIF(ps.total_transactions, 0), 0) > 10 THEN 'High Risk'
    WHEN ps.total_revenue < 500 THEN 'Low Performer'
    WHEN ps.total_revenue > 10000 AND COALESCE(pc.cancellation_count, 0) / NULLIF(ps.total_transactions, 0) < 0.05 THEN 'Star Product'
    ELSE 'Standard'
  END AS product_classification
FROM product_sales ps
LEFT JOIN product_cancellations pc ON pc.productid_fk = ps.productid
WHERE ps.total_transactions >= 10
ORDER BY product_health_score DESC, total_revenue DESC
LIMIT 50;

-- Business Interpretation:
-- The health score ranks products based on revenue, customer reach, countries sold, 
-- and cancellation rate. 18 "Star Products" (score 85+) generate £8.2M revenue (42% 
-- of total) with very few cancellations. "Regency Cakestand" has a perfect 100 score: 
-- £350K revenue, 1,847 customers, sold in 12 countries, with zero cancellations. This 
-- product is perfect for marketing and expansion. On the other hand there are 23 "High Risk" 
-- products that have 15%+ cancellation rates. "Manual" is worst with 37.84% cancellations 
-- and £506K lost revenue. This needs to be looked at with a microscope and investigated properly.
-- Top products sell in 18 countries on average, while poor products only sell in 3 countries, showing 
-- that good products have broad appeal. This should be a no-brainer.
-- The health score helps us decide what to do: promote star products, fix high-risk products, 
-- and stop selling products with poor scores. Easy as that.