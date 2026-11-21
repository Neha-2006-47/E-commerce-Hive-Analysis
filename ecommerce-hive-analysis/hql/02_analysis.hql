-- 02_analysis.hql : all analysis queries
USE ecommerce;

SELECT '--- Records read and kept ---' AS section;
SELECT COUNT(*) AS raw_records FROM orders_raw;
SELECT COUNT(*) AS valid_records FROM orders_clean;

SELECT '--- Overall KPIs ---' AS section;
SELECT COUNT(*)                                                           AS total_orders,
       SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END)              AS delivered,
       SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END)              AS cancelled,
       SUM(CASE WHEN status = 'Returned'  THEN 1 ELSE 0 END)              AS returned,
       ROUND(SUM(CASE WHEN status = 'Delivered' THEN quantity * unit_price ELSE 0 END), 2) AS gross_value,
       ROUND(SUM(CASE WHEN status = 'Delivered' THEN net_amount ELSE 0 END), 2)            AS net_revenue,
       ROUND(AVG(CASE WHEN status = 'Delivered' THEN net_amount END), 2)  AS avg_order_value
FROM orders_clean;

SELECT '--- Revenue by category (delivered orders) ---' AS section;
SELECT category,
       COUNT(*)                     AS orders,
       SUM(quantity)                AS units,
       ROUND(SUM(net_amount), 2)    AS revenue,
       ROUND(AVG(net_amount), 2)    AS avg_order_value,
       ROUND(AVG(discount_pct), 1)  AS avg_discount_pct
FROM delivered_orders
GROUP BY category
ORDER BY revenue DESC;

SELECT '--- Monthly sales (reads the partitioned table) ---' AS section;
SELECT order_month,
       COUNT(*)                                              AS orders,
       ROUND(SUM(net_amount), 2)                             AS revenue,
       ROUND(AVG(net_amount), 2)                             AS avg_order_value,
       COUNT(DISTINCT order_date)                            AS active_days,
       ROUND(SUM(net_amount) / COUNT(DISTINCT order_date), 2) AS revenue_per_active_day
FROM orders_by_month
WHERE status = 'Delivered'
GROUP BY order_month
ORDER BY order_month;

SELECT '--- November revenue by category (partition pruning) ---' AS section;
SELECT category, COUNT(*) AS orders, ROUND(SUM(net_amount), 2) AS revenue
FROM orders_by_month
WHERE order_month = '2026-11' AND status = 'Delivered'
GROUP BY category
ORDER BY revenue DESC;

SELECT '--- Sales by city ---' AS section;
SELECT city, COUNT(*) AS orders, ROUND(SUM(net_amount), 2) AS revenue,
       ROUND(AVG(net_amount), 2) AS avg_order_value
FROM delivered_orders
GROUP BY city
ORDER BY revenue DESC;

SELECT '--- Sales by payment method ---' AS section;
SELECT payment_method,
       COUNT(*)                  AS orders,
       ROUND(SUM(net_amount), 2) AS revenue,
       ROUND(100 * SUM(net_amount) / SUM(SUM(net_amount)) OVER (), 1) AS revenue_share_pct
FROM delivered_orders
GROUP BY payment_method
ORDER BY revenue DESC;

SELECT '--- Order status (all valid orders) ---' AS section;
SELECT status, COUNT(*) AS orders,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_pct
FROM orders_clean
GROUP BY status
ORDER BY orders DESC;

SELECT '--- Top 5 products by revenue (window RANK) ---' AS section;
SELECT product, category, revenue, rnk
FROM (
  SELECT product, category,
         ROUND(SUM(net_amount), 2)              AS revenue,
         RANK() OVER (ORDER BY SUM(net_amount) DESC) AS rnk
  FROM delivered_orders
  GROUP BY product, category
) ranked
WHERE rnk <= 5
ORDER BY rnk;

SELECT '--- Category x payment method (delivered orders) ---' AS section;
SELECT category,
       SUM(CASE WHEN payment_method = 'UPI'              THEN 1 ELSE 0 END) AS upi,
       SUM(CASE WHEN payment_method = 'Credit Card'      THEN 1 ELSE 0 END) AS credit_card,
       SUM(CASE WHEN payment_method = 'Debit Card'       THEN 1 ELSE 0 END) AS debit_card,
       SUM(CASE WHEN payment_method = 'Cash on Delivery' THEN 1 ELSE 0 END) AS cash_on_delivery,
       SUM(CASE WHEN payment_method = 'Net Banking'      THEN 1 ELSE 0 END) AS net_banking
FROM delivered_orders
GROUP BY category
ORDER BY category;

SELECT '--- Customers ---' AS section;
SELECT COUNT(*) AS customers,
       SUM(CASE WHEN n > 1 THEN 1 ELSE 0 END) AS repeat_customers
FROM (SELECT customer_id, COUNT(*) AS n FROM delivered_orders GROUP BY customer_id) c;

SELECT customer_id, COUNT(*) AS orders, ROUND(SUM(net_amount), 2) AS total_spend
FROM delivered_orders
GROUP BY customer_id
ORDER BY total_spend DESC
LIMIT 5;

SELECT '--- Total check (each dimension should equal the delivered-order count) ---' AS section;
SELECT 'delivered_orders' AS dimension, COUNT(*) AS total FROM delivered_orders
UNION ALL
SELECT 'category', SUM(c) FROM (SELECT COUNT(*) AS c FROM delivered_orders GROUP BY category) a
UNION ALL
SELECT 'month', SUM(c) FROM (SELECT COUNT(*) AS c FROM orders_by_month WHERE status = 'Delivered' GROUP BY order_month) b
UNION ALL
SELECT 'city', SUM(c) FROM (SELECT COUNT(*) AS c FROM delivered_orders GROUP BY city) d
UNION ALL
SELECT 'payment_method', SUM(c) FROM (SELECT COUNT(*) AS c FROM delivered_orders GROUP BY payment_method) e;
