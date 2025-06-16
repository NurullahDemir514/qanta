-- =====================================================
-- QANTA v2 - Fix Installment Credit Card Limit Deduction
-- =====================================================
-- Created: 2025-06-16
-- Purpose: Fix installment transaction to deduct total amount from credit limit, not just first installment

-- Problem: Current function only deducts first installment amount from credit card limit
-- This is incorrect - the entire installment amount should be blocked from available credit
-- 
-- Example:
-- - 12,000₺ installment purchase, 12 months
-- - Current: Only 1,000₺ deducted from limit (WRONG)
-- - Correct: Full 12,000₺ should be deducted from limit (CORRECT)

BEGIN;

CREATE OR REPLACE FUNCTION create_installment_transaction(
    p_source_account_id UUID,
    p_total_amount DECIMAL(15,2),
    p_count INTEGER,
    p_description TEXT,
    p_category_id UUID DEFAULT NULL,
    p_start_date DATE DEFAULT CURRENT_DATE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_installment_id UUID;
    v_monthly_amount DECIMAL(15,2);
    v_account RECORD;
    v_current_date DATE;
    v_first_transaction_id UUID;
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
    
    -- Validate account (must be credit card)
    SELECT * INTO v_account 
    FROM accounts 
    WHERE id = p_source_account_id AND user_id = v_user_id AND type = 'credit' AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source account must be an active credit card';
    END IF;
    
    -- Check credit limit (total amount should fit within available limit)
    IF v_account.balance + p_total_amount > v_account.credit_limit THEN
        RAISE EXCEPTION 'Credit limit exceeded. Available: %, Requested: %', 
            v_account.credit_limit - v_account.balance, p_total_amount;
    END IF;
    
    -- Calculate monthly amount with proper rounding
    v_monthly_amount := ROUND(p_total_amount / p_count, 2);
    
    -- Create installment transaction master record
    INSERT INTO installment_transactions (
        user_id, source_account_id, total_amount, monthly_amount, 
        count, start_date, description, category_id
    ) VALUES (
        v_user_id, p_source_account_id, p_total_amount, v_monthly_amount,
        p_count, p_start_date, p_description, p_category_id
    ) RETURNING id INTO v_installment_id;
    
    -- Create installment details for each month
    v_current_date := p_start_date;
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
    
    -- CRITICAL FIX: Add TOTAL amount to credit card balance (blocks entire amount from limit)
    -- This is the correct credit card behavior - entire purchase amount is blocked
    UPDATE accounts 
    SET balance = balance + p_total_amount, updated_at = NOW()
    WHERE id = p_source_account_id;
    
    -- Create first installment transaction WITH installment_id link
    INSERT INTO transactions (
        user_id, type, amount, description, source_account_id, 
        category_id, installment_id, notes
    ) VALUES (
        v_user_id, 'expense', v_monthly_amount, 
        p_description || ' (1/' || p_count || ')',
        p_source_account_id, p_category_id, v_installment_id,
        'First installment payment'
    ) RETURNING id INTO v_first_transaction_id;
    
    -- Link first installment to transaction
    UPDATE installment_details 
    SET is_paid = true, 
        paid_date = NOW(), 
        transaction_id = v_first_transaction_id
    WHERE installment_transaction_id = v_installment_id 
    AND installment_number = 1;
    
    -- NOTE: We don't call update_account_balance here because we already updated the balance above
    -- The total amount is already blocked from the credit limit
    
    RETURN v_installment_id;
END;
$$;

COMMIT;
