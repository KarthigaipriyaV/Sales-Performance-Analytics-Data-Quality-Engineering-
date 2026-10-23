# Sales Performance Analytics & Data Quality Engineering

A SQL-based analytics framework built on a dimensional data warehouse (star schema) to report on sales performance, customer value and product revenue, with automated data quality checks to keep the reporting data trustworthy.

**Tools:** Snowflake, SQL Server, SQL (CTEs, joins, window functions)

---

## Project Overview

Reliable sales reporting depends on two things: a well-designed data model, and clean data. This project covers both:

1. **Analytics:** a set of SQL queries on a fact and dimension model that answer common business questions about customers, products and revenue.
2. **Data quality:** automated checks that catch duplicate records, orphan keys and missing attributes before they distort the reports.

## Data Model (Star Schema)

| Table | Type | Description |
|---|---|---|
| `fact_sales` | Fact | One row per sale line: order, customer, product, date, quantity, revenue |
| `dim_customer` | Dimension | Customer name, city, email |
| `dim_product` | Dimension | Product name, category, unit price |
| `dim_date` | Dimension | Calendar date, year, month |

```
dim_customer ─┐
dim_product  ─┼──> fact_sales
dim_date     ─┘
```

## Analytics Performed

- **Revenue metrics:** total revenue, number of orders
- **Average order value (AOV):** revenue divided by distinct orders
- **Customer lifetime value (CLV):** total revenue per customer, with orders placed and average order value
- **Product performance:** units sold and revenue by product
- **Revenue contribution:** each product's share of total revenue, using a window function
- **Sales trends:** monthly revenue and order counts
- **Customer ranking:** customers ranked by revenue

## Data Quality Checks

Each check returns zero rows when the data is clean.

| Check | What it finds |
|---|---|
| Duplicate records | Same order, product and date appearing more than once; repeated sale IDs |
| Orphan keys | Fact rows pointing to a customer, product or date that does not exist in the dimension |
| Missing attributes | Null or blank values in dimension fields such as email and category |
| Invalid values | Null, zero or negative quantity and revenue |
| Summary | One row per check with the number of issues found |

> Snowflake does not enforce primary or foreign keys, so these checks are what protect the warehouse from broken relationships.

The sample data deliberately includes a duplicate sale, an orphan customer key, an orphan product key, a missing email and a missing category, so the checks have issues to find.

## Repository Structure

```
├── README.md
└── sql/
    └── sales_analytics_data_quality.sql
```

## How to Use

1. Open `sales_analytics_data_quality.sql` in Snowflake or SQL Server.
2. Run section 1 to create the tables and section 2 to load the sample data.
3. Run section 3 for the sales analytics queries.
4. Run section 4 to see the data quality checks flag the sample issues.

## Skills Demonstrated

Dimensional modelling (fact and dimension tables) · Analytical SQL (CTEs, joins, aggregations, window functions) · KPI design (AOV, CLV, revenue contribution) · Data profiling and data quality validation · Snowflake and SQL Server

## Author

**Karthigaipriya**
Data Analyst | SQL | Power BI | Excel
priyaselvi788@gmail.com
