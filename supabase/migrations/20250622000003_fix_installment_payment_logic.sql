-- Fix installment payment logic
-- Current issue: Installment creation doesn't properly handle credit card balance
-- 
-- Correct flow should be:
-- 1. Create installment: Add total amount to debt (decrease available limit)
-- 2. Pay installment: Subtract payment from debt (increase available limit)
-- 3. First installment should be auto-paid but balance already adjusted

BEGIN;

-- Update create_installment_transaction with correct balance logic
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
    
    -- STEP 1: Add total installment amount to credit card debt
    -- This represents the full purchase amount and decreases available limit
    PERFORM update_account_balance(p_source_account_id, p_total_amount, 'add');
    
    -- STEP 2: Handle past installments (auto-pay them)
    v_current_date := p_start_date::DATE;
    FOR i IN 1..p_count LOOP
        -- If this installment is in the past or today, mark as paid
        IF v_current_date <= v_today THEN
            -- Create transaction record for this installment payment
            INSERT INTO transactions (
                user_id, type, amount, description, source_account_id, 
                category_id, installment_id, notes, transaction_date
            ) VALUES (
                v_user_id, 'expense', v_monthly_amount, 
                p_description || ' (' || i || '/' || p_count || ')',
                p_source_account_id, p_category_id, v_installment_id,
                'Installment payment', 
                v_current_date::timestamp + (p_start_date::time)
            ) RETURNING id INTO v_transaction_id;
            
            -- Mark installment as paid
            UPDATE installment_details 
            SET is_paid = true, 
                paid_date = v_current_date::timestamp + (p_start_date::time),
                transaction_id = v_transaction_id
            WHERE installment_transaction_id = v_installment_id 
            AND installment_number = i;
            
            -- STEP 3: Subtract the payment from debt (this increases available limit)
            -- This represents paying off part of the installment debt
            PERFORM update_account_balance(p_source_account_id, v_monthly_amount, 'subtract');
        END IF;
        
        -- Next month
        v_current_date := v_current_date + INTERVAL '1 month';
    END LOOP;
    
    RETURN v_installment_id;
END;
$$;

-- Update pay_installment function to ensure correct balance handling
CREATE OR REPLACE FUNCTION pay_installment(
    p_installment_detail_id UUID,
    p_payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_detail RECORD;
    v_transaction_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Get installment detail with installment info
    SELECT 
        id.*, it.source_account_id, it.description, it.category_id, it.count
    INTO v_detail
    FROM installment_details id
    JOIN installment_transactions it ON it.id = id.installment_transaction_id
    WHERE id.id = p_installment_detail_id AND it.user_id = v_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Installment detail not found or access denied';
    END IF;
    
    IF v_detail.is_paid THEN
        RAISE EXCEPTION 'Installment already paid';
    END IF;
    
    -- Create payment transaction record
    INSERT INTO transactions (
        user_id, type, amount, description, source_account_id, 
        category_id, installment_id, notes, transaction_date
    ) VALUES (
        v_user_id, 'expense', v_detail.amount, 
        v_detail.description || ' (' || v_detail.installment_number || '/' || v_detail.count || ')',
        v_detail.source_account_id, v_detail.category_id, 
        (SELECT installment_transaction_id FROM installment_details WHERE id = p_installment_detail_id),
        'Installment payment', p_payment_date
    ) RETURNING id INTO v_transaction_id;
    
    -- Mark installment as paid
    UPDATE installment_details 
    SET is_paid = true, 
        paid_date = p_payment_date, 
        transaction_id = v_transaction_id,
        updated_at = NOW()
    WHERE id = p_installment_detail_id;
    
    -- Subtract payment from credit card debt (increases available limit)
    PERFORM update_account_balance(v_detail.source_account_id, v_detail.amount, 'subtract');
    
    RETURN v_transaction_id;
END;
$$;

COMMIT; 