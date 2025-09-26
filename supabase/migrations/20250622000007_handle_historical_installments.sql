-- Handle historical installments properly
-- When creating installments with past start dates:
-- 1. Add total amount as debt
-- 2. Auto-pay past due installments (they should have been paid already)
-- 3. Keep future installments unpaid for manual payment

BEGIN;

CREATE OR REPLACE FUNCTION create_installment_transaction(
    p_source_account_id UUID,
    p_total_amount DECIMAL(15,2),
    p_count INTEGER,
    p_description TEXT,
    p_category_id UUID DEFAULT NULL,
    p_start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_installment_id UUID;
    v_monthly_amount DECIMAL(15,2);
    v_current_date DATE;
    v_transaction_id UUID;
    v_today DATE;
    i INTEGER;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Validate inputs
    IF p_total_amount <= 0 THEN
        RAISE EXCEPTION 'Total amount must be positive';
    END IF;
    
    IF p_count <= 0 OR p_count > 60 THEN
        RAISE EXCEPTION 'Installment count must be between 1 and 60';
    END IF;
    
    -- Calculate monthly amount
    v_monthly_amount := ROUND(p_total_amount / p_count, 2);
    v_today := CURRENT_DATE;
    
    -- Create installment transaction master record
    INSERT INTO installment_transactions (
        user_id, source_account_id, total_amount, monthly_amount, 
        count, start_date, description, category_id
    ) VALUES (
        v_user_id, p_source_account_id, p_total_amount, v_monthly_amount,
        p_count, p_start_date::DATE, p_description, p_category_id
    ) RETURNING id INTO v_installment_id;
    
    -- Create installment details for all installments
    v_current_date := p_start_date::DATE;
    FOR i IN 1..p_count LOOP
        INSERT INTO installment_details (
            installment_transaction_id, installment_number, 
            due_date, amount
        ) VALUES (
            v_installment_id, i, v_current_date, v_monthly_amount
        );
        
        -- Next month
        v_current_date := v_current_date + INTERVAL '1 month';
    END LOOP;
    
    -- Add total debt to credit card (this is the main transaction)
    UPDATE accounts 
    SET balance = balance + p_total_amount, updated_at = NOW()
    WHERE id = p_source_account_id;
    
    -- Create the main expense transaction for the total amount
    INSERT INTO transactions (
        user_id, type, amount, description, source_account_id, 
        category_id, installment_id, notes, transaction_date
    ) VALUES (
        v_user_id, 'expense', p_total_amount, 
        p_description || ' (Taksitli)',
        p_source_account_id, p_category_id, v_installment_id,
        'Installment purchase', 
        p_start_date
    );
    
    -- Handle historical installments (past due dates)
    -- Only mark as paid if the credit card payment due date for that installment has passed
    DECLARE
        v_account_due_day INTEGER;
    BEGIN
        -- Get the credit card's due day
        SELECT due_day INTO v_account_due_day 
        FROM accounts 
        WHERE id = p_source_account_id AND type = 'credit';
        
        v_current_date := p_start_date::DATE;
        FOR i IN 1..p_count LOOP
            DECLARE
                v_payment_due_date DATE;
            BEGIN
                -- Calculate the payment due date for this installment
                IF v_account_due_day IS NOT NULL THEN
                    -- For credit cards: payment due date is due_day of the installment month
                    -- If installment is on 1st June, payment due is on due_day of June
                    v_payment_due_date := DATE_TRUNC('month', v_current_date) + 
                                        (v_account_due_day - 1 || ' days')::INTERVAL;
                    
                    -- Handle end of month edge cases (e.g., due day 31 in February)
                    IF v_account_due_day > EXTRACT(DAY FROM (DATE_TRUNC('month', v_current_date) + INTERVAL '1 month' - INTERVAL '1 day')) THEN
                        v_payment_due_date := DATE_TRUNC('month', v_current_date) + INTERVAL '1 month' - INTERVAL '1 day';
                    END IF;
                ELSE
                    -- For non-credit accounts, use installment due date
                    v_payment_due_date := v_current_date;
                END IF;
                
                -- Only auto-pay if the payment due date for this installment has passed
                IF v_payment_due_date < v_today THEN
                    -- Create payment transaction for this past installment
                    INSERT INTO transactions (
                        user_id, type, amount, description, source_account_id, 
                        category_id, installment_id, notes, transaction_date
                    ) VALUES (
                        v_user_id, 'expense', v_monthly_amount, 
                        p_description || ' - Taksit ' || i || '/' || p_count,
                        p_source_account_id, p_category_id, v_installment_id,
                        'Historical installment payment', 
                        v_current_date::timestamp + (p_start_date::time)
                    ) RETURNING id INTO v_transaction_id;
                    
                    -- Mark this installment as paid
                    UPDATE installment_details 
                    SET is_paid = true, 
                        paid_date = v_current_date::timestamp + (p_start_date::time),
                        transaction_id = v_transaction_id
                    WHERE installment_transaction_id = v_installment_id 
                    AND installment_number = i;
                    
                    -- Reduce the debt by this installment amount
                    UPDATE accounts 
                    SET balance = balance - v_monthly_amount, updated_at = NOW()
                    WHERE id = p_source_account_id;
                END IF;
            END;
            
            -- Next month
            v_current_date := v_current_date + INTERVAL '1 month';
        END LOOP;
    END;
    
    RETURN v_installment_id;
END;
$$;

COMMIT; 