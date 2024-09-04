-- Create the transactions table (if it doesn't exist)
CREATE TABLE transactions (
    transaction_id NUMBER PRIMARY KEY,
    user_id NUMBER,
    amount NUMBER(20, 2),
    transaction_date DATE,
    status VARCHAR2(20),
    audited CHAR(1) DEFAULT 'N'
);

-- Create the audit_log table (if it doesn't exist)
CREATE TABLE audit_log (
    log_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    log_time TIMESTAMP DEFAULT SYSTIMESTAMP,
    log_message VARCHAR2(4000),
    transaction_id NUMBER
);

-- PL/SQL procedure to audit high-value transactions
CREATE OR REPLACE PROCEDURE audit_high_value_transactions IS
    -- Set a threshold for high-value transactions
    v_threshold NUMBER := 100000;
    -- Variables to hold transaction details
    v_transaction_id NUMBER;
    v_user_id NUMBER;
    v_amount NUMBER(20,2);
    v_transaction_date DATE;
    v_status VARCHAR2(20);
    v_log_message VARCHAR2(4000);
BEGIN
    -- Cursor to fetch transactions above the threshold that haven't been audited yet
    FOR rec IN (
        SELECT transaction_id, user_id, amount, transaction_date, status
        FROM transactions
        WHERE amount > v_threshold AND audited = 'N'
    ) LOOP
        -- Create a log message for the transaction
        v_log_message := 'Auditing high-value transaction: ' ||
                         'Transaction ID: ' || rec.transaction_id ||
                         ', User ID: ' || rec.user_id ||
                         ', Amount: ' || rec.amount ||
                         ', Date: ' || TO_CHAR(rec.transaction_date, 'DD-MON-YYYY') ||
                         ', Status: ' || rec.status;

        -- Insert into audit_log
        INSERT INTO audit_log (log_message, transaction_id)
        VALUES (v_log_message, rec.transaction_id);

        -- Mark the transaction as audited
        UPDATE transactions
        SET audited = 'Y'
        WHERE transaction_id = rec.transaction_id;
    END LOOP;

    -- Commit the transaction to save the changes
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Audit completed successfully.');
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback in case of error
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred during audit: ' || SQLERRM);
END audit_high_value_transactions;
/

-- Test Data Insertion (for illustration purposes)
INSERT INTO transactions (transaction_id, user_id, amount, transaction_date, status) 
VALUES (1, 101, 150000, SYSDATE - 5, 'COMPLETED');
INSERT INTO transactions (transaction_id, user_id, amount, transaction_date, status) 
VALUES (2, 102, 50000, SYSDATE - 3, 'COMPLETED');
INSERT INTO transactions (transaction_id, user_id, amount, transaction_date, status) 
VALUES (3, 103, 200000, SYSDATE - 1, 'COMPLETED');

-- Execute the procedure
BEGIN
    audit_high_value_transactions;
END;
/

-- Query the audit_log to see the result
SELECT * FROM audit_log;