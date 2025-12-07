create database Olist_project;
use Olist_project;
SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
SET SESSION sql_mode='';
SHOW VARIABLES LIKE "secure_file_priv";

CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat REAL,
    geolocation_lng REAL,
    geolocation_city VARCHAR(255),
    geolocation_state VARCHAR(2)
);
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/geolocation.csv"
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE order_items (
    order_id CHAR(32),
    order_item_id INTEGER,
    product_id CHAR(32),
    seller_id CHAR(32),
    shipping_limit_date DATETIME,
    price REAL,
    freight_value REAL
);
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/order_items.csv"
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE order_payments (
    order_id CHAR(32),
    payment_sequential INTEGER,
    payment_type VARCHAR(50),
    payment_installments INTEGER,
    payment_value REAL
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/payments.csv"
INTO TABLE order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE order_reviews (
    review_id CHAR(32),
    order_id CHAR(32),
    review_score INTEGER,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/reviews.csv"
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE orders (
    order_id CHAR(32),
    customer_id CHAR(32),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv"
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE products (
    product_id CHAR(32),
    product_category_name VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv"
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE sellers (
    seller_id CHAR(32),
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(255),
    seller_state VARCHAR(2)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/seller.csv"
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE products_dataset (
    product_id CHAR(32),
    product_category_name VARCHAR(100)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_dataset.csv"
INTO TABLE products_dataset
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE product_name_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_name_translation.csv"
INTO TABLE product_name_translation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

#SQL QUERIES FOR REQUIREMENTS
#1 WEEKEND VS WEEKDAY

WITH valid_orders AS (
    SELECT DISTINCT o.order_id,
           o.order_purchase_timestamp,
           CASE 
               WHEN WEEKDAY(o.order_purchase_timestamp) IN (5,6) THEN 'Weekend'
               ELSE 'Weekday'
           END AS Day_Type
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
)
SELECT 
    Day_Type,
    COUNT(order_id) AS Total_Orders,
    ROUND(
        COUNT(order_id) / (SELECT COUNT(order_id) FROM valid_orders) * 100,
        0
    ) AS Order_Percentage
FROM valid_orders
GROUP BY Day_Type;

#2 NUM OF ORDERS REVIEW WITH REVIEW 5 SCORE

SELECT COUNT(DISTINCT r.order_id) AS total_orders
FROM order_reviews r
JOIN order_payments p ON r.order_id = p.order_id
WHERE r.review_score = 5
AND p.payment_type = 'credit_card';
  
#3 AVG NO DAY TAKEN FOR ORDER DELIVERED CUSTOMER DATE PET SHOP

SELECT 
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 0) 
        AS avg_delivery_days_petshop
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE pr.product_category_name = 'pet_shop'
  AND o.order_delivered_customer_date IS NOT NULL;

#4 AVG PRICE AND PAYMENT values FOR FROM CUSTOMERS OF SAO PAULO CITY
SELECT
    (SELECT AVG(oi.price)
     FROM order_items oi
     JOIN orders o ON oi.order_id = o.order_id
     JOIN customers c ON o.customer_id = c.customer_id
     WHERE c.customer_city = 'sao paulo') AS avg_price_sp,

    (SELECT AVG(p.payment_value)
     FROM order_payments p
     JOIN orders o ON p.order_id = o.order_id
     JOIN customers c ON o.customer_id = c.customer_id
     WHERE c.customer_city = 'sao paulo') AS avg_payment_sp;

#5 RELATIONSHIP BETWEEN REVIEWS SCORE VS SHIPPING DAYS
SELECT
r.review_score,
ROUND(
    AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)),
    0
)AS avg_shipping_days
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score;

#6 Top 5 product categories by total sales value
SELECT 
    pr.product_category_name,
    SUM(oi.price) AS total_sales
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
GROUP BY pr.product_category_name
ORDER BY total_sales DESC
LIMIT 5;

#7  Average review score by product category
SELECT
    pr.product_category_name,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM order_reviews r
JOIN order_items oi ON r.order_id = oi.order_id
JOIN products pr ON oi.product_id = pr.product_id
GROUP BY pr.product_category_name
ORDER BY avg_review_score DESC;


#8 Number of returning customers
SELECT 
    COUNT(*) AS returning_customers
FROM (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
) AS t;

#9 Total freight cost by seller
SELECT 
    s.seller_id,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_cost
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_id
ORDER BY total_freight_cost DESC;

#10 Monthly order trend (orders per month)
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY month;









