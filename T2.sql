-- Transaction 2
BEGIN;

UPDATE sale_order_item SET quantity = quantity+2 WHERE id = 58;

COMMIT;