-- Fix duplicate historical installment transactions
-- The previous migration creates transactions for all past installments,
-- but the old logic already creates the first installment transaction.
-- This causes duplicate transactions.

BEGIN;

-- Update create_installment_transaction to avoid duplicates
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
    
    -- Add total debt to credit card (CRITICAL: This was missing!)
    PERFORM update_account_balance(p_source_account_id, p_total_amount, 'add');
    
    -- Now handle past installments (create transactions for ALL past installments)
    v_current_date := p_start_date::DATE;
    FOR i IN 1..p_count LOOP
        -- If this installment is in the past or today, mark as paid and create transaction
        IF v_current_date <= v_today THEN
            -- Create transaction for this installment
            INSERT INTO transactions (
                user_id, type, amount, description, source_account_id, 
                category_id, installment_id, notes, transaction_date
            ) VALUES (
                v_user_id, 'expense', v_monthly_amount, 
                p_description || ' (' || i || '/' || p_count || ')',
                p_source_account_id, p_category_id, v_installment_id,
                'Installment payment', 
                -- Use the due date for the transaction, but preserve time from p_start_date
                v_current_date::timestamp + (p_start_date::time)
            ) RETURNING id INTO v_transaction_id;
            
            -- Mark installment as paid
            UPDATE installment_details 
            SET is_paid = true, 
                paid_date = v_current_date::timestamp + (p_start_date::time),
                transaction_id = v_transaction_id
            WHERE installment_transaction_id = v_installment_id 
            AND installment_number = i;
            
            -- Update account balance (subtract the monthly payment)
            PERFORM update_account_balance(p_source_account_id, v_monthly_amount, 'subtract');
        END IF;
        
        -- Next month
        v_current_date := v_current_date + INTERVAL '1 month';
    END LOOP;
    
    RETURN v_installment_id;
END;
$$;

COMMIT; 