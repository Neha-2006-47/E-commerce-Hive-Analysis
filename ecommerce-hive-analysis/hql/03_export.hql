-- 03_export.hql : write four summaries as CSV files to ./output (inside the container: /output)
USE ecommerce;

INSERT OVERWRITE LOCAL DIRECTORY '/output/category_summary'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT category, COUNT(*), SUM(quantity), ROUND(SUM(net_amount), 2), ROUND(AVG(net_amount), 2)
FROM delivered_orders GROUP BY category;

INSERT OVERWRITE LOCAL DIRECTORY '/output/monthly_summary'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT order_month, COUNT(*), ROUND(SUM(net_amount), 2)
FROM orders_by_month WHERE status = 'Delivered' GROUP BY order_month;

INSERT OVERWRITE LOCAL DIRECTORY '/output/city_summary'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT city, COUNT(*), ROUND(SUM(net_amount), 2)
FROM delivered_orders GROUP BY city;

INSERT OVERWRITE LOCAL DIRECTORY '/output/payment_summary'
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
SELECT payment_method, COUNT(*), ROUND(SUM(net_amount), 2)
FROM delivered_orders GROUP BY payment_method;
