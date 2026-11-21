-- 01_create_tables.hql : database, raw table, cleaned ORC table, partitioned table, view
CREATE DATABASE IF NOT EXISTS ecommerce;
USE ecommerce;

-- 1. Raw external table: reads the CSV in place (no copy). Bad values become NULL.
DROP TABLE IF EXISTS orders_raw;
CREATE EXTERNAL TABLE orders_raw (
  order_id       STRING,
  customer_id    STRING,
  order_date     DATE,
  category       STRING,
  product        STRING,
  quantity       INT,
  unit_price     DOUBLE,
  discount_pct   INT,
  payment_method STRING,
  city           STRING,
  status         STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/orders_raw'
TBLPROPERTIES ('skip.header.line.count'='1');

-- 2. Cleaned managed table in ORC format: drops incomplete rows, removes duplicate
--    order_id values and derives order_month and net_amount.
DROP TABLE IF EXISTS orders_clean;
CREATE TABLE orders_clean STORED AS ORC AS
SELECT order_id, customer_id, order_date,
       date_format(order_date, 'yyyy-MM') AS order_month,
       category, product, quantity, unit_price, discount_pct,
       ROUND(quantity * unit_price * (1 - discount_pct / 100.0), 2) AS net_amount,
       payment_method, city, status
FROM (
  SELECT r.*,
         ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date) AS rn
  FROM orders_raw r
  WHERE order_id IS NOT NULL AND customer_id IS NOT NULL AND order_date IS NOT NULL
    AND city IS NOT NULL AND TRIM(city) <> ''
    AND quantity > 0 AND unit_price > 0
) t
WHERE rn = 1;

-- 3. Partitioned copy (one partition per month) using dynamic partitioning.
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
DROP TABLE IF EXISTS orders_by_month;
CREATE TABLE orders_by_month (
  order_id       STRING,
  customer_id    STRING,
  order_date     DATE,
  category       STRING,
  product        STRING,
  quantity       INT,
  unit_price     DOUBLE,
  discount_pct   INT,
  net_amount     DOUBLE,
  payment_method STRING,
  city           STRING,
  status         STRING
)
PARTITIONED BY (order_month STRING)
STORED AS ORC;

INSERT OVERWRITE TABLE orders_by_month PARTITION (order_month)
SELECT order_id, customer_id, order_date, category, product, quantity, unit_price,
       discount_pct, net_amount, payment_method, city, status, order_month
FROM orders_clean;

-- 4. View of completed sales: revenue is counted only for delivered orders.
DROP VIEW IF EXISTS delivered_orders;
CREATE VIEW delivered_orders AS
SELECT * FROM orders_clean WHERE status = 'Delivered';

SHOW TABLES;
SHOW PARTITIONS orders_by_month;
