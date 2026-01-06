-- DANGEROUS: This will delete ALL sales history.
-- Use this to reset sales statistics.

DELETE FROM order_items;
DELETE FROM orders;

-- If you have a separate analytics table, clear it too. 
-- But based on the code, it computes on the fly from orders.
