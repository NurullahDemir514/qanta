-- Fix current statement installment logic
-- Problem: Current statement period installments are being marked as paid
-- Solution: Only mark installments as paid if they are from COMPLETELY past statement periods

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
    v_today DATE;
    i INTEGER;
    v_account_due_day INTEGER;
    v_payment_due_date DATE;
    v_current_statement_start DATE;
    v_current_statement_end DATE;
    v_paid_installments INTEGER := 0;
    v_total_paid_amount DECIMAL(15,2) := 0;
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
    
    -- Get credit card due day for payment calculations
    SELECT due_day INTO v_account_due_day 
    FROM accounts 
    WHERE id = p_source_account_id AND type = 'credit';
    
    -- Calculate current statement period
    IF v_account_due_day IS NOT NULL THEN
        -- Current statement ends on due day of current month
        v_current_statement_end := DATE_TRUNC('month', v_today) + (v_account_due_day - 1 || ' days')::INTERVAL;
        
        -- If due day has passed this month, statement period is next month
        IF v_today > v_current_statement_end THEN
            v_current_statement_end := DATE_TRUNC('month', v_today + INTERVAL '1 month') + (v_account_due_day - 1 || ' days')::INTERVAL;
        END IF;
        
        -- Statement period starts from previous month's due day + 1
        v_current_statement_start := v_current_statement_end - INTERVAL '1 month' + INTERVAL '1 day';
    ELSE
        -- If no due day, use month boundaries
        v_current_statement_start := DATE_TRUNC('month', v_today);
        v_current_statement_end := DATE_TRUNC('month', v_today + INTERVAL '1 month') - INTERVAL '1 day';
    END IF;
    
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
        -- Calculate payment due date for this installment
        IF v_account_due_day IS NOT NULL THEN
            v_payment_due_date := DATE_TRUNC('month', v_current_date) + 
                                (v_account_due_day - 1 || ' days')::INTERVAL;
            
            -- Handle end of month edge cases
            IF v_account_due_day > EXTRACT(DAY FROM (DATE_TRUNC('month', v_current_date) + INTERVAL '1 month' - INTERVAL '1 day')) THEN
                v_payment_due_date := DATE_TRUNC('month', v_current_date) + INTERVAL '1 month' - INTERVAL '1 day';
            END IF;
        ELSE
            v_payment_due_date := v_current_date;
        END IF;
        
        -- FIXED LOGIC: Only mark as paid if installment is from COMPLETELY past statement periods
        -- Current statement period installments should remain unpaid
        IF v_current_date < v_current_statement_start AND v_payment_due_date < v_today THEN
            -- Mark as paid with proper paid_date (transaction_id stays NULL for auto-paid)
            INSERT INTO installment_details (
                installment_transaction_id, installment_number, 
                due_date, amount, is_paid, paid_date, transaction_id
            ) VALUES (
                v_installment_id, i, v_current_date, v_monthly_amount,
                true, v_current_date::timestamp + '12:00:00'::time, NULL
            );
            
            v_paid_installments := v_paid_installments + 1;
            v_total_paid_amount := v_total_paid_amount + v_monthly_amount;
        ELSE
            -- Mark as unpaid (for current statement period and future installments)
            INSERT INTO installment_details (
                installment_transaction_id, installment_number, 
                due_date, amount, is_paid, paid_date, transaction_id
            ) VALUES (
                v_installment_id, i, v_current_date, v_monthly_amount,
                false, null, null
            );
        END IF;
        
        -- Next month
        v_current_date := v_current_date + INTERVAL '1 month';
    END LOOP;
    
    -- Add remaining debt to credit card (total - already paid installments)
    UPDATE accounts 
    SET balance = balance + (p_total_amount - v_total_paid_amount), 
        updated_at = NOW()
    WHERE id = p_source_account_id;
    
    -- Create single main transaction for the purchase
    INSERT INTO transactions (
        user_id, type, amount, description, source_account_id, 
        category_id, installment_id, notes, transaction_date
    ) VALUES (
        v_user_id, 'expense', p_total_amount, 
        p_description || ' (' || p_count || ' taksit)',
        p_source_account_id, p_category_id, v_installment_id,
        CASE 
            WHEN v_paid_installments > 0 THEN 
                'Taksitli alışveriş - ' || v_paid_installments || ' taksit otomatik ödenmiş'
            ELSE 
                'Taksitli alışveriş'
        END,
        p_start_date
    );
    
    RETURN v_installment_id;
END;
$$;

-- Add comment explaining the corrected logic
COMMENT ON FUNCTION create_installment_transaction IS 
'Creates an installment transaction with proper statement period logic.

FIXED PAYMENT LOGIC:
- Only marks installments as paid if they are from COMPLETELY past statement periods
- Current statement period installments remain unpaid (even if due date has passed)
- Future installments remain unpaid

EXAMPLES (Card due day: 25):
- Today: 24 June, Current statement: 26 May - 25 June
- Installment on 1 May → Paid (from past statement period)
- Installment on 1 June → NOT paid (from current statement period)
- Installment on 1 July → NOT paid (future installment)

This ensures current statement installments are not auto-marked as paid.';

COMMIT;
