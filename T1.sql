INSERT INTO sale_order_item (sale_order_id, product_id, quantity)
VALUES (34, 4, 10);

-- For Transaction T1 --
CREATE OR REPLACE PROCEDURE T1(
    INOUT results NUMERIC[]
)
LANGUAGE plpgsql
AS $$
DECLARE
  quantity1 NUMERIC;
  quantity2 NUMERIC;
BEGIN
    -- Initialize the array if it's not already initialized
    results := ARRAY[]::NUMERIC[];

    -- First SELECT
    SELECT quantity INTO quantity1
    FROM sale_order_item
    WHERE id = 58;

    -- Append result to array
    results := array_append(results, quantity1);

    -- Sleep for 10 second
    PERFORM pg_sleep(10);

    -- Second SELECT
    SELECT quantity INTO quantity2
    FROM sale_order_item
    WHERE id = 58;

    -- Append result to array
    results := array_append(results, quantity2);

END;
$$;

DO $$
DECLARE
results NUMERIC[] := '{}';
BEGIN
-- Calling the stored procedure
CALL T1(results);
-- Displaying the result
RAISE NOTICE 'Result: %', results;
END $$;
