-- =====================================================
-- QANTA v2 - FORCE FIX Installment Credit Logic
-- =====================================================
-- Created: 2025-06-16
-- Purpose: Force fix installment transaction to deduct TOTAL amount from credit limit

-- CRITICAL ISSUE: User reports only first installment (1,000₺) is deducted instead of total (4,000₺)
-- This migration ensures the correct behavior is enforced

BEGIN;

-- Drop existing function to ensure clean recreation
DROP FUNCTION IF EXISTS create_installment_transaction(UUID, DECIMAL, INTEGER, TEXT, UUID, DATE);
DROP FUNCTION IF EXISTS create_installment_transaction(UUID, DECIMAL, INTEGER, TEXT, UUID, TIMESTAMP WITH TIME ZONE);

-- Recreate with EXPLICIT total amount deduction logic
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
        p_count, p_start_date::DATE, p_description, p_category_id
    ) RETURNING id INTO v_installment_id;
    
    -- Create installment details for each month
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
    
    -- *** CRITICAL FIX: DEDUCT TOTAL AMOUNT FROM CREDIT LIMIT ***
    -- This is the key fix - we MUST deduct the ENTIRE purchase amount
    -- Example: 4,000₺ purchase → deduct 4,000₺ from available credit
    UPDATE accounts 
    SET balance = balance + p_total_amount, updated_at = NOW()
    WHERE id = p_source_account_id;
    
    RAISE NOTICE 'INSTALLMENT CREATED: Deducted TOTAL amount % from credit limit for account %', p_total_amount, p_source_account_id;
    
    -- Create first installment transaction WITH installment_id link
    INSERT INTO transactions (
        user_id, type, amount, description, source_account_id, 
        category_id, installment_id, notes, transaction_date
    ) VALUES (
        v_user_id, 'expense', v_monthly_amount, 
        p_description || ' (1/' || p_count || ')',
        p_source_account_id, p_category_id, v_installment_id,
        'First installment payment - TOTAL amount already deducted from credit limit',
        p_start_date
    ) RETURNING id INTO v_first_transaction_id;
    
    -- Link first installment to transaction
    UPDATE installment_details 
    SET is_paid = true, 
        paid_date = NOW(), 
        transaction_id = v_first_transaction_id
    WHERE installment_transaction_id = v_installment_id 
    AND installment_number = 1;
    
    -- IMPORTANT: We do NOT call update_account_balance here because:
    -- 1. We already updated the balance above with the TOTAL amount
    -- 2. The total amount is already blocked from the credit limit
    -- 3. Individual installment payments don't affect the credit limit further
    
    RAISE NOTICE 'INSTALLMENT SUCCESS: Created installment % with total amount % deducted from credit limit', v_installment_id, p_total_amount;
    
    RETURN v_installment_id;
END;
$$;

-- Add explicit comment
COMMENT ON FUNCTION create_installment_transaction(UUID, DECIMAL, INTEGER, TEXT, UUID, TIMESTAMP WITH TIME ZONE) IS 
'Creates an installment transaction and deducts the TOTAL amount from credit card limit.

CRITICAL BEHAVIOR:
- For 4,000₺ total in 4 installments: Deducts 4,000₺ from available credit limit
- NOT just the first 1,000₺ installment
- This blocks the entire purchase amount from the credit limit upfront

EXAMPLE:
- Credit limit: 50,000₺, Current balance: 0₺
- Create 4,000₺ installment → New balance: 4,000₺ (46,000₺ available)
- Delete installment → Balance returns to 0₺ (50,000₺ available)';

COMMIT;
