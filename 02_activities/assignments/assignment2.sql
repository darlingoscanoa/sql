/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product
-- COALESCE(product_size, '') --  we are telling in case of null replace with a blank ''
-- COALESCE(product_qty_type, 'unit') -- we are telling in case of null replace with a 'unit'


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 


You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT
  customer_id,
  market_date,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date) AS visit_number_to_mkt
FROM customer_purchases
ORDER BY customer_id, market_date;

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT
  customer_id,
  market_date,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS reversed_visit_number_to_mkt
FROM customer_purchases
ORDER BY customer_id, market_date DESC;

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT *,
  COUNT() OVER (PARTITION BY customer_id ORDER BY product_id) AS many_times_customer_bought_that_product
FROM customer_purchases
ORDER BY customer_id, product_id, market_date;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT *,  
  CASE	WHEN INSTR(product_name, '-') > 0 --first we need to find the hyphen position
	THEN
      TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1)) -- then we subtract everything after the hyphen (+1), and after that we remove all leading/trail whitespcces
    ELSE
      NULL
  END AS description
FROM product;

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT *
FROM product
WHERE product_size REGEXP '[0-9]';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

-- The approach, as suggest, will be in 3 steps
-- First I Calculate total sales per market date WITH cte.
WITH sales_by_date AS (
  SELECT
    market_date,
    SUM(quantity * cost_to_customer_per_qty) AS total_sales
  FROM customer_purchases
  GROUP BY market_date
),

-- Second, I need to rank the date by total sales WITH another cte
ranked_sales_by_date AS (
  SELECT
    market_date,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank_desc,
    RANK() OVER (ORDER BY total_sales ASC) AS sales_rank_asc
  FROM sales_by_date
)

--Finally (3rd) I will calculate the highest and lowest and then will union both tables 
SELECT market_date, total_sales, 'highest_day' AS type
FROM ranked_sales_by_date
WHERE sales_rank_desc = 1

UNION
--Here I union and put those 2 tables one below the other
SELECT market_date, total_sales, 'lowest_day' AS type
FROM ranked_sales_by_date
WHERE sales_rank_asc = 1;


/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

--Again I will make this in steps:
-- First: I will get all vendor-product pairs with their prices and names
WITH vendor_products AS (
  SELECT
    vi.vendor_id,
    v.vendor_name,
    vi.product_id,
    p.product_name,
    vi.original_price
  FROM vendor_inventory vi
  JOIN vendor v 
	ON vi.vendor_id = v.vendor_id
  JOIN product p 
	ON vi.product_id = p.product_id
),

-- Second: I will get all customers
all_customers AS (
  SELECT customer_id
  FROM customer
)

-- Finally: I will CROSS JOIN vendor-products with all customers
SELECT
  vp.vendor_name,
  vp.product_name,
  SUM(5 * vp.original_price) AS total_revenue
FROM vendor_products vp
CROSS JOIN all_customers ac
GROUP BY vp.vendor_name, vp.product_name
ORDER BY vp.vendor_name, vp.product_name;



-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

--I chose create the table as temporary so doesnt meant any changes to the "farmersmarket.db" file from the github repo
CREATE TEMPORARY TABLE product_units AS
SELECT
    *,
    CURRENT_TIMESTAMP AS snapshot_timestamp
FROM
    product
WHERE
    product_qty_type = 'unit';

--to check the values
SELECT * FROM product_units;

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units (product_id, product_name, product_size, product_category_id, product_qty_type, snapshot_timestamp)
	VALUES (100,'Apple Pie', '10"',3,'unit',CURRENT_TIMESTAMP);

--to check the values
SELECT * FROM product_units;	
	
-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units
WHERE product_id=100;

--to check the values
SELECT * FROM product_units;	


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

--Adding the new column,
ALTER TABLE product_units
ADD current_quantity INT;

UPDATE product_units
SET current_quantity = (
  SELECT final_qty
  FROM (
    SELECT  
      pu2.product_id, 
      COALESCE(inv_latest.quantity, 0) AS final_qty
    FROM product_units pu2
    LEFT JOIN (
      SELECT 
        vi2.*,
        ROW_NUMBER() OVER (PARTITION BY vi2.product_id ORDER BY vi2.market_date DESC) AS row_num
      FROM vendor_inventory vi2
    ) inv_latest
      ON pu2.product_id = inv_latest.product_id
    WHERE inv_latest.row_num = 1 OR inv_latest.row_num IS NULL
  ) qty_sub
  WHERE product_units.product_id = qty_sub.product_id
);

--to check the values
SELECT * FROM product_units;	

/*
Finally to comment I am doing with all the knowledge gained here a real life project by consolidated 3 
open data source for Toronto healthcare facilities and neighborhoods for "Identifying Healthcare Access Disparities" 

Problem: Not all Toronto neighborhoods have equal access to healthcare facilities like pharmacies, clinics, 
or hospitals. Vulnerable populations-such as older adults, children, and low-income households-are especially 
affected by these disparities.

Goal: Analyze the geographic distribution of facilities and overlaying demographic data, this project 
could pinpoint under-served neighborhoods. This supports targeted resource allocation and policy 
interventions to improve access for those who need it most.

I hope to post the results on a linked newsletter on my profile by this week:

https://www.linkedin.com/in/darling-oscanoa-1ab2425/

*/