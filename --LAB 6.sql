--LAB 6

CREATE OR REPLACE TYPE GIFT_TYPE is TABLE OF VARCHAR2(20);

CREATE TABLE GIFT_CATALOG(GIFT_ID NUMBER PRIMARY KEY, MIN_PURCHASE NUMBER, GIFTS GIFT_TYPE) 
NESTED TABLE gifts STORE AS GIFT_STORE_TABLE;
/

INSERT INTO GIFT_CATALOG VALUES(1, 10, GIFT_TYPE('Stickers','Pens'));
INSERT INTO GIFT_CATALOG VALUES(2, 50, GIFT_TYPE('AutoBots','Decepticons','Power Rangers'));
INSERT INTO GIFT_CATALOG VALUES(3, 100, GIFT_TYPE('Computers','Screen','Mouse','Lap Tops'));
INSERT INTO GIFT_CATALOG VALUES(4, 1000, GIFT_TYPE('Water','Coal','Pocket Lint','Rocks'));
/

SELECT * from GIFT_CATALOG;

CREATE TABLE CUSTOMER_REWARDS(REWARD_ID NUMBER GENERATED ALWAYS AS IDENTITY NOT NULL PRIMARY KEY, 
                              CUSTOMER_EMAIL VARCHAR2(100), 
                              GIFT_ID NUMBER,
                              CONSTRAINT FK_GIFT_ID 
                              FOREIGN KEY (GIFT_ID) REFERENCES GIFT_CATALOG(GIFT_ID),
                              REWARD_DATE DATE DEFAULT SYSDATE
                              );
                              /

CREATE OR REPLACE PACKAGE CUSTOMER_MANAGER AS
    FUNCTION GET_TOTAL_PURCHASE(p_customer_id IN CUSTOMERS.CUSTOMER_ID%TYPE) RETURN NUMBER;
    PROCEDURE ASSIGN_GIFTS_TO_ALL;
    PROCEDURE show_customers;
END CUSTOMER_MANAGER;
/

CREATE OR REPLACE PACKAGE BODY CUSTOMER_MANAGER IS

    FUNCTION GET_TOTAL_PURCHASE(
        p_customer_id IN CUSTOMERS.CUSTOMER_ID%TYPE
    ) RETURN NUMBER IS
        v_cost NUMBER;
    BEGIN
        SELECT NVL(SUM(oi.unit_price * oi.quantity), 0)
        INTO v_cost
        FROM orders o
        JOIN order_items oi USING(order_id)
        WHERE o.customer_id = p_customer_id;

        RETURN v_cost;
    END GET_TOTAL_PURCHASE;


FUNCTION CHOOSE_GIFT_PACKAGE(p_total_purchase IN NUMBER)
RETURN NUMBER IS
    v_gift_id GIFT_CATALOG.GIFT_ID%TYPE;
BEGIN
    v_gift_id := CASE
                    WHEN p_total_purchase >= 1000 THEN 4
                    WHEN p_total_purchase >= 100  THEN 3
                    WHEN p_total_purchase >= 50   THEN 2
                    WHEN p_total_purchase >= 10   THEN 1
                    ELSE NULL
                 END;
    RETURN v_gift_id;
END;

    PROCEDURE ASSIGN_GIFTS_TO_ALL IS
        CURSOR c_customers IS
            SELECT customer_id, email_address
            FROM customers;

        v_total    NUMBER;
        v_gift_id  GIFT_CATALOG.GIFT_ID%TYPE;
    BEGIN
        FOR r_cust IN c_customers LOOP
            
            v_total   := CUSTOMER_MANAGER.GET_TOTAL_PURCHASE(r_cust.customer_id);
            v_gift_id := CUSTOMER_MANAGER.CHOOSE_GIFT_PACKAGE(v_total);

            IF v_gift_id IS NOT NULL THEN
                INSERT INTO customer_rewards (customer_email, gift_id, reward_date)
                VALUES (r_cust.email_address, v_gift_id, SYSDATE);
            END IF;
        END LOOP;
    END ASSIGN_GIFTS_TO_ALL;

PROCEDURE show_customers IS
    v_show_amt NUMBER;
BEGIN
    v_show_amt := 5;
    FOR r IN (SELECT cr.customer_email, cr.reward_date, gc.gift_id, gc.min_purchase
              FROM   customer_rewards cr
              JOIN   gift_catalog gc
              ON cr.gift_id = gc.gift_id
              WHERE  ROWNUM <= v_show_amt 
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE(
              'Email: '|| r.customer_email || ', Gift ID: '|| r.gift_id|| ', Min Purchase: ' || r.min_purchase|| ', Reward Date: '  || TO_CHAR(r.reward_date, 'YYYY-MM-DD')
        );
    END LOOP;
END show_customers;


END CUSTOMER_MANAGER;
/

SET SERVEROUTPUT ON; 
EXEC CUSTOMER_MANAGER.ASSIGN_GIFTS_TO_ALL;
EXEC CUSTOMER_MANAGER.SHOW_CUSTOMERS;