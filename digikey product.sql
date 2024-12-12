USE FTN2;
#1
-- Identify manufacturers whose products are priced higher than the average price within their respective product categories. For each manufacturer and category, calculate the count of products that exceed the category’s average price and rank the results in descending order based on the number of high-priced products.
WITH CategoryAveragePrice AS (
    SELECT
        product_category,
        AVG(price) AS avg_price
    FROM 
        product_metadata
    GROUP BY 
        product_category
),
HighPriceManufacturers AS (
    SELECT 
        pm.manufacturer,
        pm.product_category,
        pm.price,
        cap.avg_price
    FROM 
        product_metadata pm
    JOIN 
        CategoryAveragePrice cap
    ON 
        pm.product_category = cap.product_category
    WHERE 
        pm.price > cap.avg_price
)
SELECT 
    manufacturer, 
    product_category, 
    COUNT(*) AS high_price_count
FROM 
    HighPriceManufacturers
GROUP BY
    manufacturer, product_category
ORDER BY 
    high_price_count DESC;
    
 #2   
-- Identify products at high risk of stockouts based on inventory levels and lead times. Specifically, focus on products with stock quantities below 30 and lead times exceeding 20 days. Highlight the top 5 high-risk products sorted by lead time in descending order, prioritizing those with the longest replenishment times.
WITH Riskproduct AS(
	SELECT 
		part_number,
        product_category,
        manufacturer,
        stock_numeric,
        stock_numeric2,
        lead_time
	FROM 
		product_metadata
	WHERE 
		stock_numeric<30 AND lead_time>20
)
SELECT 
	part_number,
    product_category,
    stock_numeric,
    stock_numeric2,
    lead_time,
    manufacturer
FROM 
	Riskproduct
ORDER BY
	lead_time DESC LIMIT 5;-- product category TVS Siodes have high risk 

#3
-- Analyze the average lead times of manufacturers to identify those whose lead times exceed the overall industry average. Specifically, determine the manufacturers with above-average lead times, rank them in descending order, and highlight those with the longest lead times. 
WITH Avgleadtime  AS (
	SELECT 
		AVG(lead_time) AS avg_lead_time 
	FROM
		product_metadata
),
Longleadtime AS (
	SELECT
		AVG(lead_time) AS manufacurer_avg_lead_time,
        manufacturer
	FROM 
		product_metadata
	GROUP BY 
		manufacturer
	HAVING
		AVG(lead_time)>(SELECT avg_lead_time FROM Avgleadtime)
)
SELECT
	manufacturer,
    manufacurer_avg_lead_time
FROM 
	Longleadtime
ORDER BY 
	manufacurer_avg_lead_time DESC;
    
    
#4
--  Identify the most common features for each product category to understand which attributes are most frequently associated with products in the dataset. 
WITH Featurecounts AS(
	SELECT
		product_category,
        features,
        COUNT(*) AS feature_count
	FROM
		product_metadata
	GROUP BY 
		product_category,features
),
Topfeatures AS(
	SELECT 
		product_category,
        features,
        feature_count,
        RANK() OVER(PARTITION BY product_category ORDER BY feature_count DESC) AS  renk
	FROM Featurecounts
)
SELECT 
    product_category, 
    features, 
    feature_count
FROM 
    TopFeatures
WHERE 
    renk =1;
    
#5
    -- Analyze product pricing across manufacturers and series to identify the average price for each combination.
SELECT 
	manufacturer,
    series,
    AVG(price) AS avg_price 
FROM 
	product_metadata
GROUP BY 
	manufacturer,series
ORDER BY 
	avg_price DESC ;
    
#6
    -- Determine the most top 5 popular manufacturers in each product category based on the number of products they offer.
WITH Manufacturerpopularity AS (
	SELECT 
		product_category,
        manufacturer,
        COUNT(*) AS  product_count
	FROM 
		product_metadata
	GROUP BY 
		product_category,manufacturer
),
Topmanufacturer AS (
	SELECT 
		product_category,
        manufacturer,
        product_count,
        RANK() OVER(PARTITION BY product_category ORDER BY product_count DESC ) renk
	FROM 
		Manufacturerpopularity
)
SELECT 
	product_category,
    manufacturer,
    product_count
FROM 
	Topmanufacturer
WHERE 
	renk=1 ORDER BY product_count DESC LIMIT 5;
	
#7
    -- GET STOCK TRENDS
    -- Analyze the stock levels of products across different categories to assess inventory health. Calculate the average, maximum, and minimum stock for each product category, and categorize them as “Overstocked,” “Understocked,” or “Optimal Stock” based on the overall average stock in the system.
WITH Stockanalysis AS(
	SELECT 
		product_category,
        AVG(stock_numeric) AS avg_stock,
        MAX(stock_numeric) AS max_stock,
        MIN(stock_numeric )AS min_stock
	FROM 
		product_metadata 
	GROUP BY 
		product_category
)
SELECT 
	product_category,
    avg_stock,max_stock,min_stock,
	CASE
        WHEN avg_stock > (SELECT AVG(stock_numeric) FROM product_metadata) THEN 'Overstocked'
        WHEN avg_stock < (SELECT AVG(stock_numeric) FROM product_metadata) THEN 'Understocked'
        ELSE 'Optimal Stock'
    END AS stock_status
    FROM 
    Stockanalysis
ORDER BY 
    avg_stock DESC LIMIT 10;
    
#8
    -- Analyze the revenue generated by each manufacturer by calculating the total revenue (price multiplied by stock quantity), average product price, and average stock for each manufacturer. 
    SELECT 
    manufacturer,
    SUM(price * stock_numeric) AS total_revenue,
    AVG(price) AS avg_price,
    AVG(stock_numeric) AS avg_stock
FROM 
    product_metadata
GROUP BY 
    manufacturer
HAVING 
    total_revenue > (SELECT AVG(price * stock_numeric) FROM product_metadata)
ORDER BY 
    total_revenue DESC;
    
    
#9
-- Evaluate the financial performance of manufacturers by calculating their total revenue (the product of price and stock quantity), average product price, and average stock.
SELECT 
    manufacturer,
    SUM(price * stock_numeric) AS total_revenue,
    ROUND(AVG(price),2) AS avg_price,
    ROUND(AVG(stock_numeric),2) AS avg_stock
FROM 
    product_metadata
GROUP BY 
    manufacturer
HAVING 
    total_revenue > (SELECT AVG(price * stock_numeric) FROM product_metadata)
ORDER BY 
    total_revenue DESC;
    
#10
  -- Analyze the revenue generated by each product category by calculating the total revenue (price multiplied by stock quantity), average stock levels, and the total number of products within each category. 
SELECT 
	product_category,
    SUM(price*stock_numeric) As revenue,
    AVG(stock_numeric) AS avg_stock,
    COUNT(*) AS total_products
FROM
	product_metadata
GROUP BY 
	product_category
ORDER BY revenue DESC;

SET SQL_SAFE_UPDATES = 0;

#11
-- Identify and compare products within the same category that have similar pricing, with a price difference of less than $50. This analysis involves pairing products with similar features (same product category) and calculating the price difference between them. 
SELECT 
    p1.part_number AS product_1,
    p2.part_number AS product_2,
    p1.product_category,
    p1.manufacturer,
    p1.price AS price_1,
    p2.price AS price_2,
    ABS(p1.price - p2.price) AS price_difference
FROM 
    product_metadata p1
JOIN 
    product_metadata p2 
    ON p1.product_category = p2.product_category 
    AND p1.part_number != p2.part_number
WHERE 
    ABS(p1.price - p2.price) < 50
ORDER BY 
    price_difference DESC;
   

#12
-- Identify the Least profitable category accross dataset.
SELECT categories, 
       SUM(price * stock_numeric) AS total_value
FROM product_metadata
GROUP BY categories
ORDER BY total_value ASC;

#13
-- Determine the top 3 most expensive products within each product_category.
SELECT price,digikey_part_number,product_category FROM product_metadata WHERE price IS NOT NULL ORDER BY product_category,price DESC LIMIT 3 ;

#14
-- Find the average lead time for products grouped by manufacturer to identify slow suppliers.
SELECT manufacturer , AVG(lead_time) AS avg_lead FROM product_metadata GROUP BY manufacturer ORDER BY avg_lead DESC LIMIT 15; 

#15
-- This query calculates the average price of products in each category over time.
SELECT EXTRACT(MONTH FROM date_added ) AS monthh ,product_category,AVG(price) AS avg_prc FROM product_metadata GROUP BY product_category,monthh ORDER BY product_category,avg_prc  LIMIT 5;
    
