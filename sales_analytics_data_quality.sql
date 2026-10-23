-- =====================================================================
-- Sales Performance Analytics & Data Quality Engineering
-- Tools: Snowflake / SQL Server (simple, mostly standard SQL)
-- Author: Karthigaipriya
--
-- Sections
--   1. Create dimensional model (fact + dimension tables)
--   2. Load sample data (includes a few deliberate data issues)
--   3. Sales analytics queries (Revenue, AOV, CLV, trends)
--   4. Data quality checks (duplicates, orphan keys, missing values)
-- =====================================================================


-- =====================================================================
-- 1. CREATE TABLES (star schema)
-- Note: Snowflake does not enforce primary / foreign keys, which is why
-- the quality checks in section 4 are needed.
-- =====================================================================

CREATE OR REPLACE TABLE dim_customer (
    customer_key   INT,
    customer_name  VARCHAR(100),
    city           VARCHAR(50),
    email          VARCHAR(100)
);

CREATE OR REPLACE TABLE dim_product (
    product_key    INT,
    product_name   VARCHAR(100),
    category       VARCHAR(50),
    unit_price     DECIMAL(10, 2)
);

CREATE OR REPLACE TABLE dim_date (
    date_key       INT,          -- format YYYYMMDD
    full_date      DATE,
    year_num       INT,
    month_num      INT
);

CREATE OR REPLACE TABLE fact_sales (
    sale_id        INT,
    order_id       INT,
    customer_key   INT,
    product_key    INT,
    date_key       INT,
    quantity       INT,
    revenue        DECIMAL(12, 2)
);


-- =====================================================================
-- 2. SAMPLE DATA
-- =====================================================================

INSERT INTO dim_customer VALUES
    (1, 'Arun Kumar',   'Chennai',   'arun@example.com'),
    (2, 'Meena Iyer',   'Bengaluru', 'meena@example.com'),
    (3, 'Rahul Singh',  'Mumbai',    'rahul@example.com'),
    (4, 'Divya Nair',   'Chennai',   NULL);                 -- missing email

INSERT INTO dim_product VALUES
    (101, 'Laptop',      'Electronics', 55000.00),
    (102, 'Headphones',  'Electronics',  2500.00),
    (103, 'Office Chair','Furniture',    7000.00),
    (104, 'Notebook',    NULL,             60.00);          -- missing category

INSERT INTO dim_date VALUES
    (20260105, '2026-01-05', 2026, 1),
    (20260118, '2026-01-18', 2026, 1),
    (20260209, '2026-02-09', 2026, 2),
    (20260315, '2026-03-15', 2026, 3);

INSERT INTO fact_sales VALUES
    (1, 5001, 1, 101, 20260105, 1, 55000.00),
    (2, 5001, 1, 102, 20260105, 2,  5000.00),
    (3, 5002, 2, 103, 20260118, 1,  7000.00),
    (4, 5003, 3, 102, 20260209, 1,  2500.00),
    (5, 5004, 1, 104, 20260315, 10,  600.00),
    (6, 5005, 2, 101, 20260315, 1, 55000.00),
    (7, 5003, 3, 102, 20260209, 1,  2500.00),   -- duplicate of sale_id 4
    (8, 5006, 99, 103, 20260315, 1,  7000.00),  -- orphan customer_key 99
    (9, 5007, 4, 999, 20260315, 1,   500.00);   -- orphan product_key 999


-- =====================================================================
-- 3. SALES ANALYTICS
-- =====================================================================

-- 3.1 Overall revenue, orders and Average Order Value (AOV)
SELECT
    SUM(revenue)                              AS total_revenue,
    COUNT(DISTINCT order_id)                  AS total_orders,
    SUM(revenue) / COUNT(DISTINCT order_id)   AS average_order_value
FROM fact_sales;

-- 3.2 Customer Lifetime Value (simple version: total revenue per customer)
SELECT
    c.customer_key,
    c.customer_name,
    COUNT(DISTINCT f.order_id)                AS orders_placed,
    SUM(f.revenue)                            AS customer_lifetime_value,
    SUM(f.revenue) / COUNT(DISTINCT f.order_id) AS avg_order_value
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_name
ORDER BY customer_lifetime_value DESC;

-- 3.3 Product performance and revenue contribution (%)
SELECT
    p.product_name,
    SUM(f.quantity)                           AS units_sold,
    SUM(f.revenue)                            AS product_revenue,
    ROUND(100.0 * SUM(f.revenue) / SUM(SUM(f.revenue)) OVER (), 2) AS revenue_contribution_pct
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY product_revenue DESC;

-- 3.4 Monthly sales trend
SELECT
    d.year_num,
    d.month_num,
    SUM(f.revenue)                            AS monthly_revenue,
    COUNT(DISTINCT f.order_id)                AS monthly_orders
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year_num, d.month_num
ORDER BY d.year_num, d.month_num;

-- 3.5 Rank customers by revenue (window function)
SELECT
    c.customer_name,
    SUM(f.revenue)                            AS total_revenue,
    RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS revenue_rank
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_name;


-- =====================================================================
-- 4. DATA QUALITY CHECKS
-- Each query should return ZERO rows when the data is clean.
-- =====================================================================

-- 4.1 Duplicate records in the fact table
--     (same order, product and date appearing more than once)
SELECT
    order_id,
    product_key,
    date_key,
    COUNT(*)                                  AS duplicate_count
FROM fact_sales
GROUP BY order_id, product_key, date_key
HAVING COUNT(*) > 1;

-- 4.2 Duplicate primary keys in the fact table
SELECT sale_id, COUNT(*) AS duplicate_count
FROM fact_sales
GROUP BY sale_id
HAVING COUNT(*) > 1;

-- 4.3 Orphan keys: fact rows with no matching customer
SELECT f.*
FROM fact_sales f
LEFT JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

-- 4.4 Orphan keys: fact rows with no matching product
SELECT f.*
FROM fact_sales f
LEFT JOIN dim_product p ON f.product_key = p.product_key
WHERE p.product_key IS NULL;

-- 4.5 Orphan keys: fact rows with no matching date
SELECT f.*
FROM fact_sales f
LEFT JOIN dim_date d ON f.date_key = d.date_key
WHERE d.date_key IS NULL;

-- 4.6 Missing data attributes in dimension tables
SELECT 'dim_customer' AS table_name, customer_key AS record_key, 'email is missing' AS issue
FROM dim_customer
WHERE email IS NULL OR TRIM(email) = ''
UNION ALL
SELECT 'dim_product', product_key, 'category is missing'
FROM dim_product
WHERE category IS NULL OR TRIM(category) = '';

-- 4.7 Invalid values in the fact table (null, zero or negative)
SELECT *
FROM fact_sales
WHERE quantity IS NULL OR quantity <= 0
   OR revenue  IS NULL OR revenue  <= 0;

-- 4.8 Data quality summary (one row per check)
SELECT 'Duplicate fact rows' AS check_name, COUNT(*) AS issues_found
FROM (
    SELECT order_id, product_key, date_key
    FROM fact_sales
    GROUP BY order_id, product_key, date_key
    HAVING COUNT(*) > 1
) d
UNION ALL
SELECT 'Orphan customer keys', COUNT(*)
FROM fact_sales f
LEFT JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL
UNION ALL
SELECT 'Orphan product keys', COUNT(*)
FROM fact_sales f
LEFT JOIN dim_product p ON f.product_key = p.product_key
WHERE p.product_key IS NULL
UNION ALL
SELECT 'Missing customer email', COUNT(*)
FROM dim_customer
WHERE email IS NULL OR TRIM(email) = ''
UNION ALL
SELECT 'Missing product category', COUNT(*)
FROM dim_product
WHERE category IS NULL OR TRIM(category) = '';
