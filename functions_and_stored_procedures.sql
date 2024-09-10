--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.3

-- Started on 2024-08-12 01:06:24

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 248 (class 1255 OID 17240)
-- Name: compute_customer_lifetime_value(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.compute_customer_lifetime_value()
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_member_id INT;
    first_order DATE;
    last_order DATE;
    total_revenue NUMERIC(10,2);
    total_orders INT;
    lifetime_years NUMERIC(10,2);
    avg_purchase_value NUMERIC(10,2);
    purchase_frequency NUMERIC(10,2);
    new_clv NUMERIC(10,2);
BEGIN
    FOR v_member_id IN SELECT id FROM member LOOP
        -- Get the first and last order dates for the member
        SELECT MIN(so.order_datetime) INTO first_order
        FROM sale_order so
        WHERE so.member_id = v_member_id AND so.status = 'COMPLETED';

        SELECT MAX(so.order_datetime) INTO last_order
        FROM sale_order so
        WHERE so.member_id = v_member_id AND so.status = 'COMPLETED';

        -- Calculate the total revenue and total number of orders for the member
        SELECT SUM(soi.quantity * p.unit_price), COUNT(DISTINCT so.id) INTO total_revenue, total_orders
        FROM sale_order so
        JOIN sale_order_item soi ON so.id = soi.sale_order_id
        JOIN product p ON soi.product_id = p.id
        WHERE so.member_id = v_member_id AND so.status = 'COMPLETED';

        -- Calculate the customer lifetime in years
        IF first_order IS NOT NULL AND last_order IS NOT NULL AND total_orders > 1 THEN
            lifetime_years := EXTRACT(YEAR FROM age(last_order, first_order));
            -- Ensure lifetime years is not zero to avoid division by zero
            IF lifetime_years = 0 THEN
                lifetime_years := 1;
            END IF;
            -- Calculate average purchase value
            avg_purchase_value := total_revenue / total_orders;
            -- Calculate purchase frequency
            purchase_frequency := total_orders / lifetime_years;
            -- Compute the CLV
            new_clv := avg_purchase_value * purchase_frequency * 2;
        ELSE
            new_clv := NULL;
        END IF;

        -- Update the clv in the member table
        UPDATE member SET clv = new_clv WHERE id = v_member_id;
    END LOOP;
END;
$$;


--
-- TOC entry 249 (class 1255 OID 17415)
-- Name: compute_customer_lifetime_value(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.compute_customer_lifetime_value(IN p_period integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_member_id INT;
    first_order DATE;
    last_order DATE;
    total_revenue NUMERIC(10,2);
    total_orders INT;
    lifetime_years NUMERIC(10,2);
    avg_purchase_value NUMERIC(10,2);
    purchase_frequency NUMERIC(10,2);
    new_clv NUMERIC(10,2);
BEGIN
    FOR v_member_id IN SELECT id FROM member LOOP
        -- Get the first and last order dates for the member
        SELECT MIN(so.order_datetime) INTO first_order
        FROM sale_order so
        WHERE so.member_id = v_member_id AND so.status = 'COMPLETED';

        SELECT MAX(so.order_datetime) INTO last_order
        FROM sale_order so
        WHERE so.member_id = v_member_id AND so.status = 'COMPLETED';

        -- Calculate the total revenue and total number of orders for the member
        SELECT SUM(soi.quantity * p.unit_price), COUNT(DISTINCT so.id) INTO total_revenue, total_orders
        FROM sale_order so
        JOIN sale_order_item soi ON so.id = soi.sale_order_id
        JOIN product p ON soi.product_id = p.id
        WHERE so.member_id = v_member_id AND so.status = 'COMPLETED';

        -- Calculate the customer lifetime in years
        IF first_order IS NOT NULL AND last_order IS NOT NULL AND total_orders > 1 THEN
            lifetime_years := EXTRACT(YEAR FROM age(last_order, first_order));
            -- Ensure lifetime years is not zero to avoid division by zero
            IF lifetime_years = 0 THEN
                lifetime_years := 1;
            END IF;
            -- Calculate average purchase value
            avg_purchase_value := total_revenue / total_orders;
            -- Calculate purchase frequency
            purchase_frequency := total_orders / lifetime_years;
            -- Compute the CLV
            new_clv := avg_purchase_value * purchase_frequency * p_period;
        ELSE
            new_clv := NULL;
        END IF;

        -- Update the clv in the member table
        UPDATE member SET clv = new_clv WHERE id = v_member_id;
    END LOOP;
END;
$$;


--
-- TOC entry 251 (class 1255 OID 17245)
-- Name: compute_running_total_spending(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.compute_running_total_spending() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update running_total_spending for active members
    UPDATE member
    SET running_total_spending = (
        SELECT COALESCE(SUM(soi.quantity * p.unit_price), 0)
        FROM sale_order so
        JOIN sale_order_item soi ON so.id = soi.sale_order_id
        JOIN product p ON soi.product_id = p.id
        WHERE so.member_id = member.id AND so.status = 'COMPLETED'
    )
    WHERE last_login_on >= NOW() - INTERVAL '6 months';

    -- Set running_total_spending to NULL for inactive members
    UPDATE member
    SET running_total_spending = NULL
    WHERE last_login_on < NOW() - INTERVAL '6 months';
END;
$$;


--
-- TOC entry 232 (class 1255 OID 17234)
-- Name: create_review(integer, integer, integer, integer, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.create_review(IN p_memberid integer, IN p_productid integer, IN p_orderid integer, IN p_rating integer, IN p_reviewtext text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if member has a completed order for the product
    IF NOT EXISTS (
        SELECT 1 
        FROM sale_order so
        JOIN sale_order_item soi ON so.id = soi.sale_order_id
        WHERE so.member_id = p_memberId AND soi.product_id = p_productId AND so.status = 'COMPLETED'
    ) THEN
        RAISE EXCEPTION 'Member has no completed order for this product';
    END IF;
 
    -- Insert the new review
    INSERT INTO review (memberId, productId, orderId, rating, reviewText) 
    VALUES (p_memberId, p_productId, p_orderId, p_rating, p_reviewText);
END;
$$;


--
-- TOC entry 236 (class 1255 OID 17238)
-- Name: delete_review(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.delete_review(IN p_reviewid integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NOT EXISTS (SELECT * FROM review WHERE id = p_reviewId) THEN
		RAISE EXCEPTION 'Review does not exist';
	END IF;

	DELETE FROM review
	WHERE id = p_reviewId;
END;
$$;


--
-- TOC entry 252 (class 1255 OID 17241)
-- Name: get_age_group_spending(character, numeric, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_age_group_spending(p_gender character, p_min_total_spending numeric, p_min_member_total_spending numeric) RETURNS TABLE(agegroup text, totalspending numeric, numofmembers bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH memberSpending AS (
        SELECT m.id, EXTRACT(YEAR FROM AGE(current_date, m.dob)) AS age, COALESCE(SUM(soi.quantity * p.unit_price), 0) AS memberTotalSpending
        FROM member m
        LEFT JOIN sale_order so ON m.id = so.member_id AND so.status = 'COMPLETED'
        LEFT JOIN sale_order_item soi ON so.id = soi.sale_order_id
        LEFT JOIN product p ON soi.product_id = p.id
        WHERE (p_gender IS NULL OR m.gender = p_gender) AND m.username != 'user' AND m.username != 'admin'
        GROUP BY m.id, m.dob
        HAVING COALESCE(SUM(soi.quantity * p.unit_price), 0) >= p_min_member_total_spending
    )
    SELECT CASE 
            WHEN age BETWEEN 18 AND 29 THEN '18-29'
            WHEN age BETWEEN 30 AND 39 THEN '30-39'
            WHEN age BETWEEN 40 AND 49 THEN '40-49'
            WHEN age BETWEEN 50 AND 59 THEN '50-59'
            ELSE '60+'
        END AS ageGroup,
        SUM(memberTotalSpending) AS totalSpending, COUNT(*) AS numOfMembers
    FROM memberSpending
    GROUP BY ageGroup
    HAVING SUM(memberTotalSpending) >= p_min_total_spending
    ORDER BY ageGroup;
END;
$$;


--
-- TOC entry 233 (class 1255 OID 17235)
-- Name: get_all_reviews(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_all_reviews(p_memberid integer) RETURNS TABLE(id integer, memberid integer, productid integer, orderid integer, rating integer, reviewtext text, reviewdate date, product_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT r.id, r.memberId, r.productId, r.orderId, r.rating, r.reviewText, r.reviewDate, p.name AS product_name
    FROM review r
    JOIN sale_order_item soi ON r.orderId = soi.sale_order_id AND r.productId = soi.product_id
    JOIN product p ON soi.product_id = p.id 
    WHERE r.memberId = p_memberId;
END;
$$;


--
-- TOC entry 234 (class 1255 OID 17236)
-- Name: get_review(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_review(p_memberid integer, p_reviewid integer) RETURNS TABLE(id integer, memberid integer, productid integer, orderid integer, rating integer, reviewtext text, reviewdate date, product_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT r.id, r.memberId, r.productId, r.orderId, r.rating, r.reviewText, r.reviewDate, p.name AS product_name
    FROM review r
    JOIN sale_order_item soi ON r.orderId = soi.sale_order_id AND r.productId = soi.product_id
    JOIN product p ON soi.product_id = p.id 
    WHERE r.memberId = p_memberId AND r.id = p_reviewId;
END;
$$;


--
-- TOC entry 253 (class 1255 OID 34788)
-- Name: place_orders(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.place_orders(IN p_member_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    r_sale_order_id INT;
    r_product_id INT;
    r_quantity INT;
    r_stock_quantity DECIMAL;
    r_name TEXT;
    out_of_stock_items TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Create a new sale order with status 'PACKING'
    INSERT INTO sale_order (member_id, order_datetime, status)
    VALUES (p_member_id, NOW(), 'PACKING')
    RETURNING id INTO r_sale_order_id;

    -- Process each item in the cart
    FOR r_product_id, r_quantity, r_stock_quantity, r_name IN
        SELECT ci.product_id, ci.quantity, p.stock_quantity, p.name
        FROM cart_item ci
        JOIN product p ON ci.product_id = p.id
        WHERE ci.member_id = p_member_id
    LOOP
        IF r_stock_quantity >= r_quantity THEN
            -- Deduct the stock quantity and create the sale order item
            UPDATE product
            SET stock_quantity = stock_quantity - r_quantity
            WHERE id = r_product_id;

            INSERT INTO sale_order_item (sale_order_id, product_id, quantity)
            VALUES (r_sale_order_id, r_product_id, r_quantity);

            -- Remove the item from the cart
            DELETE FROM cart_item
            WHERE member_id = p_member_id AND product_id = r_product_id;
        ELSE
            -- Add item name to the out_of_stock_items array
            out_of_stock_items := array_append(out_of_stock_items, r_name);
        END IF;
    END LOOP;

    -- Return out_of_stock_items array
    RAISE NOTICE 'Out of stock items: %', out_of_stock_items;
END;
$$;


--
-- TOC entry 250 (class 1255 OID 34792)
-- Name: t1(numeric[]); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.t1(INOUT results numeric[])
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


--
-- TOC entry 235 (class 1255 OID 17237)
-- Name: update_review(integer, integer, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.update_review(IN p_reviewid integer, IN p_rating integer, IN p_reviewtext text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NOT EXISTS (SELECT * FROM review WHERE id = p_reviewId) THEN
		RAISE EXCEPTION 'Review does not exist';
	END IF;

	UPDATE review 
	SET rating = p_rating, reviewText = p_reviewText 
	WHERE id = p_reviewId;
END;
$$;


--
-- TOC entry 229 (class 1259 OID 32206)
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


--
-- TOC entry 231 (class 1259 OID 32619)
-- Name: cart_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cart_item (
    id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    member_id integer NOT NULL
);


--
-- TOC entry 230 (class 1259 OID 32618)
-- Name: cart_item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cart_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4931 (class 0 OID 0)
-- Dependencies: 230
-- Name: cart_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cart_item_id_seq OWNED BY public.cart_item.id;


--
-- TOC entry 215 (class 1259 OID 17143)
-- Name: member; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(50) NOT NULL,
    dob date NOT NULL,
    password character varying(255) NOT NULL,
    role integer NOT NULL,
    gender character(1) NOT NULL,
    last_login_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    clv numeric(10,3),
    running_total_spending numeric(10,3)
);


--
-- TOC entry 216 (class 1259 OID 17147)
-- Name: member_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4932 (class 0 OID 0)
-- Dependencies: 216
-- Name: member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.member_id_seq OWNED BY public.member.id;


--
-- TOC entry 217 (class 1259 OID 17148)
-- Name: member_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_role (
    id integer NOT NULL,
    name character varying(25)
);


--
-- TOC entry 218 (class 1259 OID 17151)
-- Name: member_role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4933 (class 0 OID 0)
-- Dependencies: 218
-- Name: member_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.member_role_id_seq OWNED BY public.member_role.id;


--
-- TOC entry 219 (class 1259 OID 17152)
-- Name: product; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product (
    id integer NOT NULL,
    name character varying(255),
    description text,
    unit_price numeric NOT NULL,
    stock_quantity numeric DEFAULT 0 NOT NULL,
    country character varying(100),
    product_type character varying(50),
    image_url character varying(255) DEFAULT '/images/product.png'::character varying,
    manufactured_on timestamp without time zone
);


--
-- TOC entry 220 (class 1259 OID 17159)
-- Name: product_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4934 (class 0 OID 0)
-- Dependencies: 220
-- Name: product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_id_seq OWNED BY public.product.id;


--
-- TOC entry 226 (class 1259 OID 17210)
-- Name: review; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.review (
    id integer NOT NULL,
    memberid integer NOT NULL,
    productid integer NOT NULL,
    orderid integer NOT NULL,
    rating integer NOT NULL,
    reviewtext text NOT NULL,
    reviewdate date DEFAULT now()
);


--
-- TOC entry 225 (class 1259 OID 17209)
-- Name: review_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.review_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4935 (class 0 OID 0)
-- Dependencies: 225
-- Name: review_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.review_id_seq OWNED BY public.review.id;


--
-- TOC entry 221 (class 1259 OID 17160)
-- Name: sale_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_order (
    id integer NOT NULL,
    member_id integer,
    order_datetime timestamp without time zone NOT NULL,
    status character varying(10)
);


--
-- TOC entry 222 (class 1259 OID 17163)
-- Name: sale_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sale_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4936 (class 0 OID 0)
-- Dependencies: 222
-- Name: sale_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sale_order_id_seq OWNED BY public.sale_order.id;


--
-- TOC entry 223 (class 1259 OID 17164)
-- Name: sale_order_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_order_item (
    id integer NOT NULL,
    sale_order_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity numeric NOT NULL
);


--
-- TOC entry 224 (class 1259 OID 17169)
-- Name: sale_order_item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sale_order_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4937 (class 0 OID 0)
-- Dependencies: 224
-- Name: sale_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sale_order_item_id_seq OWNED BY public.sale_order_item.id;


--
-- TOC entry 228 (class 1259 OID 32195)
-- Name: supplier; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supplier (
    id integer NOT NULL,
    company_name character varying(255) NOT NULL,
    descriptor text,
    address character varying(255),
    country character varying(100) NOT NULL,
    contact_email character varying(50) NOT NULL,
    company_url character varying(255),
    founded_date date,
    staff_size integer,
    specialization character varying(100),
    is_active boolean
);


--
-- TOC entry 227 (class 1259 OID 32194)
-- Name: supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.supplier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4938 (class 0 OID 0)
-- Dependencies: 227
-- Name: supplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.supplier_id_seq OWNED BY public.supplier.id;


--
-- TOC entry 4751 (class 2604 OID 32622)
-- Name: cart_item id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item ALTER COLUMN id SET DEFAULT nextval('public.cart_item_id_seq'::regclass);


--
-- TOC entry 4738 (class 2604 OID 17170)
-- Name: member id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member ALTER COLUMN id SET DEFAULT nextval('public.member_id_seq'::regclass);


--
-- TOC entry 4740 (class 2604 OID 17171)
-- Name: member_role id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_role ALTER COLUMN id SET DEFAULT nextval('public.member_role_id_seq'::regclass);


--
-- TOC entry 4741 (class 2604 OID 17172)
-- Name: product id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product ALTER COLUMN id SET DEFAULT nextval('public.product_id_seq'::regclass);


--
-- TOC entry 4746 (class 2604 OID 17213)
-- Name: review id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review ALTER COLUMN id SET DEFAULT nextval('public.review_id_seq'::regclass);


--
-- TOC entry 4744 (class 2604 OID 17173)
-- Name: sale_order id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order ALTER COLUMN id SET DEFAULT nextval('public.sale_order_id_seq'::regclass);


--
-- TOC entry 4745 (class 2604 OID 17174)
-- Name: sale_order_item id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item ALTER COLUMN id SET DEFAULT nextval('public.sale_order_item_id_seq'::regclass);


--
-- TOC entry 4748 (class 2604 OID 32198)
-- Name: supplier id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier ALTER COLUMN id SET DEFAULT nextval('public.supplier_id_seq'::regclass);


--
-- TOC entry 4771 (class 2606 OID 32214)
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4773 (class 2606 OID 32624)
-- Name: cart_item cart_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item
    ADD CONSTRAINT cart_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4753 (class 2606 OID 17176)
-- Name: member member_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_email_key UNIQUE (email);


--
-- TOC entry 4755 (class 2606 OID 17178)
-- Name: member member_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_pkey PRIMARY KEY (id);


--
-- TOC entry 4759 (class 2606 OID 17180)
-- Name: member_role member_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_role
    ADD CONSTRAINT member_role_pkey PRIMARY KEY (id);


--
-- TOC entry 4757 (class 2606 OID 17182)
-- Name: member member_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_username_key UNIQUE (username);


--
-- TOC entry 4761 (class 2606 OID 17184)
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (id);


--
-- TOC entry 4767 (class 2606 OID 17218)
-- Name: review review_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT review_pkey PRIMARY KEY (id);


--
-- TOC entry 4765 (class 2606 OID 17186)
-- Name: sale_order_item sale_order_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item
    ADD CONSTRAINT sale_order_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4763 (class 2606 OID 17188)
-- Name: sale_order sale_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order
    ADD CONSTRAINT sale_order_pkey PRIMARY KEY (id);


--
-- TOC entry 4769 (class 2606 OID 32202)
-- Name: supplier supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier
    ADD CONSTRAINT supplier_pkey PRIMARY KEY (id);


--
-- TOC entry 4781 (class 2606 OID 34761)
-- Name: cart_item cart_item_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item
    ADD CONSTRAINT cart_item_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.member(id);


--
-- TOC entry 4782 (class 2606 OID 32636)
-- Name: cart_item cart_item_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cart_item
    ADD CONSTRAINT cart_item_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(id);


--
-- TOC entry 4774 (class 2606 OID 17189)
-- Name: member fk_member_role_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT fk_member_role_id FOREIGN KEY (role) REFERENCES public.member_role(id);


--
-- TOC entry 4776 (class 2606 OID 17194)
-- Name: sale_order_item fk_sale_order_item_product; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item
    ADD CONSTRAINT fk_sale_order_item_product FOREIGN KEY (product_id) REFERENCES public.product(id);


--
-- TOC entry 4777 (class 2606 OID 17199)
-- Name: sale_order_item fk_sale_order_item_sale_order; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order_item
    ADD CONSTRAINT fk_sale_order_item_sale_order FOREIGN KEY (sale_order_id) REFERENCES public.sale_order(id);


--
-- TOC entry 4775 (class 2606 OID 17204)
-- Name: sale_order fk_sale_order_member; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_order
    ADD CONSTRAINT fk_sale_order_member FOREIGN KEY (member_id) REFERENCES public.member(id);


--
-- TOC entry 4778 (class 2606 OID 17219)
-- Name: review member_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT member_id_fk FOREIGN KEY (memberid) REFERENCES public.member(id);


--
-- TOC entry 4779 (class 2606 OID 17224)
-- Name: review product_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT product_id_fk FOREIGN KEY (productid) REFERENCES public.product(id);


--
-- TOC entry 4780 (class 2606 OID 17229)
-- Name: review sale_order_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review
    ADD CONSTRAINT sale_order_id_fk FOREIGN KEY (orderid) REFERENCES public.sale_order(id);


-- Completed on 2024-08-12 01:06:24

--
-- PostgreSQL database dump complete
--

