create Database Zepto_db;
use Zepto_db;
select * from zepto;

-- different product categories

SELECT DISTINCT category
FROM zepto
ORDER BY category;

-- products in stock vs out of stock
SELECT outOfStock, COUNT(sku_id)
FROM zepto
GROUP BY outOfStock;

-- product names present multiple times
SELECT name, COUNT(sku_id) AS "Number of SKUs"
FROM zepto
GROUP BY name
HAVING count(sku_id) > 1
ORDER BY count(sku_id) DESC;

-- data cleaning

-- products with price = 0
SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;

DELETE FROM zepto
WHERE mrp = 0;

-- convert paise to rupees
UPDATE zepto
SET mrp = mrp / 100.0,
discountedSellingPrice = discountedSellingPrice / 100.0;

SELECT mrp, discountedSellingPrice FROM zepto;

-- data analysis

-- Q1. Find the top 10 best-value products based on the discount percentage.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
ORDER BY discountPercent DESC
LIMIT 10;

-- Q2.What are the Products with High MRP but Out of Stock

SELECT DISTINCT name,mrp
FROM zepto
WHERE outOfStock = TRUE and mrp > 300
ORDER BY mrp DESC;

-- Q3.Calculate Estimated Revenue for each category
SELECT category,
SUM(discountedSellingPrice * availableQuantity) AS total_revenue
FROM zepto
GROUP BY category
ORDER BY total_revenue;

-- Q4. Find all products where MRP is greater than ₹500 and discount is less than 10%.
SELECT DISTINCT name, mrp, discountPercent
FROM zepto
WHERE mrp > 500 AND discountPercent < 10
ORDER BY mrp DESC, discountPercent DESC;

-- Q5. Identify the top 5 categories offering the highest average discount percentage.
SELECT category,
ROUND(AVG(discountPercent),2) AS avg_discount
FROM zepto
GROUP BY category
ORDER BY avg_discount DESC
LIMIT 5;

-- Q6. Find the price per gram for products above 100g and sort by best value.
SELECT DISTINCT name, weightInGms, discountedSellingPrice,
ROUND(discountedSellingPrice/weightInGms,2) AS price_per_gram
FROM zepto
WHERE weightInGms >= 100
ORDER BY price_per_gram;

-- Q7.Group the products into categories like Low, Medium, Bulk.
SELECT DISTINCT name, weightInGms,
CASE WHEN weightInGms < 1000 THEN 'Low'
	WHEN weightInGms < 5000 THEN 'Medium'
	ELSE 'Bulk'
	END AS weight_category
FROM zepto;

-- Q8.What is the Total Inventory Weight Per Category 
SELECT category,
SUM(weightInGms * availableQuantity) AS total_weight
FROM zepto
GROUP BY category
ORDER BY total_weight;


-- Q9. Rank products within each category by discounted price using WINDOW function
-- Concepts: WINDOW (RANK), CTE
 
WITH ranked_products AS (
  SELECT
    category,
    name,
    discountedSellingPrice,
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


-- Q11. Identify products whose discounted price is ABOVE their category average
-- Concepts: CTE, Window AVG, HAVING
 
WITH category_avg AS (
  SELECT
    category,
    name,
    discountedSellingPrice,
    ROUND(AVG(discountedSellingPrice) OVER (PARTITION BY category), 2) AS cat_avg_price
  FROM zepto
),
above_avg AS (
  SELECT category, name, discountedSellingPrice, cat_avg_price,
         ROUND(discountedSellingPrice - cat_avg_price, 2) AS price_diff
  FROM category_avg
  WHERE discountedSellingPrice > cat_avg_price
)
SELECT category, name, discountedSellingPrice, cat_avg_price, price_diff
FROM above_avg
ORDER BY price_diff DESC
LIMIT 10;

-- Q12. Cumulative revenue contribution per category (Running Total)
-- Concepts: CTE, Window SUM (Running Total), ORDER BY
 
WITH category_revenue AS (
  SELECT
    category,
    ROUND(SUM(discountedSellingPrice * availableQuantity), 2) AS category_revenue
  FROM zepto
  GROUP BY category
),
running_total AS (
  SELECT
    category,
    category_revenue,
    ROUND(SUM(category_revenue) OVER (
      ORDER BY category_revenue DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS cumulative_revenue,
    ROUND(100.0 * category_revenue /
      SUM(category_revenue) OVER (), 2)   AS pct_contribution
  FROM category_revenue
)
SELECT category, category_revenue, cumulative_revenue, pct_contribution
FROM running_total
ORDER BY category_revenue DESC;


-- Q13. Compare each product's discount % vs the top discount in its category
-- Concepts: CTE, Window MAX, Self-JOIN logic, HAVING
 
WITH discount_comparison AS (
  SELECT
    category,
    name,
    discountPercent,
    MAX(discountPercent) OVER (PARTITION BY category) AS max_cat_discount,
    ROUND(AVG(discountPercent)  OVER (PARTITION BY category), 2) AS avg_cat_discount
  FROM zepto
),
flagged AS (
  SELECT
    category, name, discountPercent,
    max_cat_discount, avg_cat_discount,
    ROUND(discountPercent - avg_cat_discount, 2) AS vs_avg,
    CASE
      WHEN discountPercent = max_cat_discount THEN 'Top Discounted'
      WHEN discountPercent >= avg_cat_discount THEN 'Above Average'
      ELSE 'Below Average'
    END AS discount_tier
  FROM discount_comparison
)
SELECT *
FROM flagged
HAVING discount_tier = 'Top Discounted'
ORDER BY discountPercent DESC
LIMIT 10;
