# 🛒 ZeptoLens: Quick Commerce Analytics Using SQL

> An end-to-end SQL analytics case study on Zepto's product inventory — from raw data cleaning to advanced business intelligence.

![MySQL](https://img.shields.io/badge/MySQL--4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=for-the-badge)
![Domain](https://img.shields.io/badge/Domain-Quick%20Commerce-red?style=for-the-badge)

---

## 📌 Project Overview

**ZeptoLens** is a SQL-based retail analytics project built on a real-world Zepto product inventory dataset. Zepto is one of India's fastest-growing quick commerce platforms, promising 10-minute grocery delivery through a dark store model.

This project simulates the work of a **Data Analyst** at a quick commerce company — answering 13 real business questions that span pricing strategy, inventory health, category performance, discount analysis, and revenue estimation — all using pure SQL.

---

## 🎯 Objectives

- Clean and prepare raw inventory data for analysis
- Perform structured Exploratory Data Analysis (EDA)
- Answer business-driven questions using SQL
- Apply advanced SQL techniques including CTEs, Window Functions, JOINs, and HAVING clauses
- Derive actionable retail insights from the data

---

## 📂 Repository Structure

```
ZeptoLens/
│
├── dataset/
│   └── zepto_v2.csv              # Raw dataset
│
├── sql/
│   ├── 01_database_setup.sql     # Database & table creation
│   ├── 02_data_cleaning.sql      # Cleaning: nulls, paise-to-rupees, etc.
│   ├── 03_eda_queries.sql        # Exploratory Data Analysis (Q1–Q8)
│   └── 04_advanced_queries.sql   # Advanced SQL queries (Q9–Q13)
│
├── docs/
│   └── Zepto_Advanced_SQL_Q9_Q13.docx   # Detailed query documentation
│
└── README.md
```

---

## 📊 Dataset Overview![download](https://github.com/user-attachments/assets/d7f41ad3-62f8-47e3-b4f2-05020262e2e5)<svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" fill="none" viewBox="0 0 40 40"><path fill="#ebf212" d="m21.466 5.071.004 10.915c.001 1.725-1.834 2.83-3.358 2.024L7.17 12.223a15.1 15.1 0 0 1 3.1-3.64l8.582 7.932c.455.42 1.172-.036.985-.626L16.509 5.41a15 15 0 0 1 4.956-.338M18.496 34.925l-.005-10.86c0-1.724 1.834-2.83 3.359-2.023l10.946 5.79a15 15 0 0 1-3.116 3.626l-8.57-7.921c-.455-.42-1.172.035-.985.625l3.316 10.441a15 15 0 0 1-4.945.322M23.492 18.898 31.44 10.3a15 15 0 0 0-3.64-3.113l-5.804 10.972c-.806 1.524.3 3.359 2.024 3.358l10.905-.005a15.2 15.2 0 0 0-.324-4.958l-10.484 3.33c-.59.187-1.045-.53-.625-.985M5.07 18.54l10.872-.004c1.725 0 2.83 1.834 2.024 3.358L12.192 32.81a15 15 0 0 1-3.627-3.103l7.906-8.553c.42-.455-.036-1.172-.626-.985L5.408 23.484a15 15 0 0 1-.337-4.943"/></svg>


| Attribute | Details |
|---|---|
| **Source** | Zepto Product Inventory (scraped/public dataset) |
| **Records** | 1,000+ SKUs |
| **Categories** | 8 product categories |
| **Key Columns** | `sku_id`, `name`, `category`, `mrp`, `discountPercent`, `discountedSellingPrice`, `weightInGms`, `availableQuantity`, `outOfStock` |
| **Price Unit** | Originally in paise (converted to ₹ during cleaning) |

---

## 🧹 Data Cleaning

```sql
-- Remove zero-price products
DELETE FROM zepto WHERE mrp = 0;

-- Convert paise to rupees
UPDATE zepto
SET mrp = mrp / 100.0,
    discountedSellingPrice = discountedSellingPrice / 100.0;
```

**Issues addressed:**
- Removed records where `mrp = 0` or `discountedSellingPrice = 0`
- Converted all price columns from paise → rupees
- Verified distinct categories and stock status distribution

---

## 🔍 Analysis — Questions & Queries

### 📁 Part 1: Exploratory Data Analysis (Q1–Q8)

| # | Business Question | SQL Concepts |
|---|---|---|
| Q1 | Top 10 best-value products by discount % | `ORDER BY`, `DISTINCT` |
| Q2 | High MRP products that are out of stock | `WHERE`, `AND` |
| Q3 | Estimated revenue per category | `SUM`, `GROUP BY` |
| Q4 | Products with MRP > ₹500 and discount < 10% | `WHERE` with multiple conditions |
| Q5 | Top 5 categories by average discount | `AVG`, `GROUP BY`, `LIMIT` |
| Q6 | Price per gram for products above 100g | Derived column, `ORDER BY` |
| Q7 | Products grouped by weight (Low/Medium/Bulk) | `CASE WHEN` |
| Q8 | Total inventory weight per category | `SUM`, `GROUP BY` |

---

### 📁 Part 2: Advanced SQL Queries (Q9–Q13)

#### Q9 — Top 3 Priced In-Stock Products per Category
**Concepts:** `CTE` · `RANK() OVER (PARTITION BY)`

```sql
WITH ranked_products AS (
  SELECT
    category, name, discountedSellingPrice,
    RANK() OVER (
      PARTITION BY category
      ORDER BY discountedSellingPrice DESC
    ) AS price_rank
  FROM zepto
  WHERE outOfStock = FALSE
)
SELECT category, name, discountedSellingPrice, price_rank
FROM ranked_products
WHERE price_rank <= 3
ORDER BY category, price_rank;
```

> 💡 **Insight:** Identifies premium SKUs in each category — useful for category-level pricing strategy.

---

#### Q10 — Premium Categories with High Product Variety
**Concepts:** `Self-JOIN` · `GROUP BY` · `HAVING`

```sql
SELECT z1.category,
       COUNT(DISTINCT z1.name)   AS total_products,
       ROUND(AVG(z1.mrp), 2)     AS avg_mrp,
       SUM(z1.availableQuantity) AS total_stock
FROM zepto z1
JOIN zepto z2
  ON z1.category = z2.category
  AND z1.sku_id <> z2.sku_id
GROUP BY z1.category
HAVING AVG(z1.mrp) > 500
   AND COUNT(DISTINCT z1.name) > 5
ORDER BY avg_mrp DESC;
```

> 💡 **Insight:** Surfaces categories that are both premium-priced and product-rich — prime candidates for promotional investment.

---

#### Q11 — Products Priced Above Their Category Average
**Concepts:** `Chained CTEs` · `AVG() OVER (PARTITION BY)`

```sql
WITH category_avg AS (
  SELECT category, name, discountedSellingPrice,
    ROUND(AVG(discountedSellingPrice) OVER (PARTITION BY category), 2) AS cat_avg_price
  FROM zepto
),
above_avg AS (
  SELECT category, name, discountedSellingPrice, cat_avg_price,
         ROUND(discountedSellingPrice - cat_avg_price, 2) AS price_diff
  FROM category_avg
  WHERE discountedSellingPrice > cat_avg_price
)
SELECT * FROM above_avg
ORDER BY price_diff DESC
LIMIT 10;
```

> 💡 **Insight:** Identifies premium outliers within each category — helps detect over-priced or niche products.

---

#### Q12 — Cumulative Revenue Contribution (Pareto Analysis)
**Concepts:** `CTE` · `Running SUM() OVER (ROWS UNBOUNDED)`

```sql
WITH category_revenue AS (
  SELECT category,
    ROUND(SUM(discountedSellingPrice * availableQuantity), 2) AS category_revenue
  FROM zepto GROUP BY category
),
running_total AS (
  SELECT category, category_revenue,
    ROUND(SUM(category_revenue) OVER (
      ORDER BY category_revenue DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS cumulative_revenue,
    ROUND(100.0 * category_revenue / SUM(category_revenue) OVER (), 2) AS pct_contribution
  FROM category_revenue
)
SELECT * FROM running_total ORDER BY category_revenue DESC;
```

> 💡 **Insight:** Shows which categories drive the first 80% of revenue — classic Pareto / 80-20 analysis.

---

#### Q13 — Discount Tier Classification per Category
**Concepts:** `CTE` · `Window MAX/AVG` · `CASE WHEN` · `HAVING`

```sql
WITH discount_comparison AS (
  SELECT category, name, discountPercent,
    MAX(discountPercent) OVER (PARTITION BY category) AS max_cat_discount,
    ROUND(AVG(discountPercent) OVER (PARTITION BY category), 2) AS avg_cat_discount
  FROM zepto
),
flagged AS (
  SELECT *, ROUND(discountPercent - avg_cat_discount, 2) AS vs_avg,
    CASE
      WHEN discountPercent = max_cat_discount THEN 'Top Discounted'
      WHEN discountPercent >= avg_cat_discount THEN 'Above Average'
      ELSE 'Below Average'
    END AS discount_tier
  FROM discount_comparison
)
SELECT * FROM flagged
HAVING discount_tier = 'Top Discounted'
ORDER BY discountPercent DESC
LIMIT 10;
```

> 💡 **Insight:** Classifies every product's discount relative to its category — helps identify loss-leader products and promotional hotspots.

---

## 🧠 Key SQL Concepts Covered

| Concept | Used In |
|---|---|
| `WHERE`, `GROUP BY`, `ORDER BY` | Q1–Q8 |
| `CASE WHEN` | Q7, Q13 |
| `HAVING` | Q10, Q13 |
| `CTE (WITH clause)` | Q9, Q11, Q12, Q13 |
| `Window Functions — RANK()` | Q9 |
| `Window Functions — AVG() OVER` | Q11, Q13 |
| `Window Functions — Running SUM()` | Q12 |
| `Self-JOIN` | Q10 |
| `Chained CTEs` | Q11, Q12, Q13 |

---

## 💡 Business Insights Summary

- 🏆 **Top revenue categories** — Fruits & Vegetables and Dairy contribute ~41% of total estimated revenue
- 📦 **Out-of-stock risk** — Several high-MRP products (>₹300) are out of stock, representing missed revenue
- 💸 **Discount leaders** — Snacks and Beverages consistently offer the highest average discounts
- ⚖️ **Best value** — Products with the best price-per-gram ratio cluster in Staples and Dairy
- 📈 **Pareto pattern** — Top 3 categories account for ~58% of cumulative inventory revenue

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| **MySQL 8.0** | Query execution and database management |
| **MySQL Workbench** | IDE for writing and testing SQL |
| **Microsoft Excel / CSV** | Raw dataset format |
| **Git & GitHub** | Version control and project hosting |

---

## 🚀 How to Run

```bash
# 1. Clone the repository
git clone https://github.com/your-username/ZeptoLens.git

# 2. Open MySQL Workbench and connect to your local server

# 3. Run scripts in order
source sql/01_database_setup.sql
source sql/02_data_cleaning.sql
source sql/03_eda_queries.sql
source sql/04_advanced_queries.sql
```

---

## 👤 Author

**Rakesh**  
Data Analyst | SQL · Python · Power BI · Salesforce CRM
---

## 📃 License

This project is open-source and available under the [MIT License](LICENSE).

---

> ⭐ If you found this project helpful, please consider giving it a star — it helps others discover it!
