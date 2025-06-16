-- =====================================================
-- QANTA v2 - Essential RPC Functions
-- =====================================================
-- Created: 2025-01-01
-- Purpose: Core business logic functions for mobile app

-- =====================================================
-- 1. ACCOUNT MANAGEMENT FUNCTIONS
-- =====================================================

-- Create account with validation
CREATE OR REPLACE FUNCTION create_account(
    p_type account_type,
    p_name VARCHAR(100),
    p_bank_name VARCHAR(100) DEFAULT NULL,
    p_balance DECIMAL(15,2) DEFAULT 0.00,
    p_credit_limit DECIMAL(15,2) DEFAULT NULL,
    p_statement_day INTEGER DEFAULT NULL,
    p_due_day INTEGER DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_account_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Validate credit card fields
    IF p_type = 'credit' THEN
        IF p_credit_limit IS NULL OR p_credit_limit <= 0 THEN
            RAISE EXCEPTION 'Credit limit is required for credit cards';
        END IF;
        IF p_statement_day IS NULL OR p_due_day IS NULL THEN
            RAISE EXCEPTION 'Statement and due days are required for credit cards';
        END IF;
    END IF;
    
    -- Insert account
    INSERT INTO accounts (
        user_id, type, name, bank_name, balance, 
        credit_limit, statement_day, due_day
    ) VALUES (
        v_user_id, p_type, p_name, p_bank_name, p_balance,
        p_credit_limit, p_statement_day, p_due_day
    ) RETURNING id INTO v_account_id;
    
    RETURN v_account_id;
END;
$$;

-- Update account balance (with validation)
CREATE OR REPLACE FUNCTION update_account_balance(
    p_account_id UUID,
    p_amount DECIMAL(15,2),
    p_operation VARCHAR(10) -- 'add' or 'subtract'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_account RECORD;
    v_new_balance DECIMAL(15,2);
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Get account details
    SELECT * INTO v_account 
    FROM accounts 
    WHERE id = p_account_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account not found or access denied';
    END IF;
    
    -- Calculate new balance
    IF p_operation = 'add' THEN
        v_new_balance := v_account.balance + p_amount;
    ELSIF p_operation = 'subtract' THEN
        v_new_balance := v_account.balance - p_amount;
    ELSE
        RAISE EXCEPTION 'Invalid operation. Use "add" or "subtract"';
    END IF;
    
    -- Validate balance constraints
    IF v_account.type = 'credit' THEN
        -- Credit cards can have debt up to credit limit
        IF v_new_balance > v_account.credit_limit THEN
            RAISE EXCEPTION 'Credit limit exceeded. Available: %, Requested: %', 
                v_account.credit_limit - v_account.balance, p_amount;
        END IF;
    ELSE
        -- Debit and cash accounts cannot go negative
        IF v_new_balance < 0 THEN
            RAISE EXCEPTION 'Insufficient funds. Available: %, Requested: %', 
                v_account.balance, p_amount;
        END IF;
    END IF;
    
    -- Update balance
    UPDATE accounts 
    SET balance = v_new_balance, updated_at = NOW()
    WHERE id = p_account_id;
    
    RETURN TRUE;
END;
$$;

-- =====================================================
-- 2. TRANSACTION FUNCTIONS
-- =====================================================

-- Create transaction with automatic balance updates
CREATE OR REPLACE FUNCTION create_transaction(
    p_type transaction_type,
    p_amount DECIMAL(15,2),
    p_description TEXT,
    p_source_account_id UUID,
    p_target_account_id UUID DEFAULT NULL,
    p_category_id UUID DEFAULT NULL,
    p_transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_transaction_id UUID;
    v_source_account RECORD;
    v_target_account RECORD;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Validate source account
    SELECT * INTO v_source_account 
    FROM accounts 
    WHERE id = p_source_account_id AND user_id = v_user_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source account not found or inactive';
    END IF;
    
    -- Validate target account for transfers
    IF p_type = 'transfer' THEN
        IF p_target_account_id IS NULL THEN
            RAISE EXCEPTION 'Target account is required for transfers';
        END IF;
        
        SELECT * INTO v_target_account 
        FROM accounts 
        WHERE id = p_target_account_id AND user_id = v_user_id AND is_active = true;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Target account not found or inactive';
        END IF;
        
        IF p_source_account_id = p_target_account_id THEN
            RAISE EXCEPTION 'Source and target accounts cannot be the same';
        END IF;
    END IF;
    
    -- Update balances based on transaction type
    CASE p_type
        WHEN 'income' THEN
            -- Add money to source account
            PERFORM update_account_balance(p_source_account_id, p_amount, 'add');
            
        WHEN 'expense' THEN
            -- Subtract money from source account
            PERFORM update_account_balance(p_source_account_id, p_amount, 'subtract');
            
        WHEN 'transfer' THEN
            -- Subtract from source, add to target
            PERFORM update_account_balance(p_source_account_id, p_amount, 'subtract');
            PERFORM update_account_balance(p_target_account_id, p_amount, 'add');
    END CASE;
    
    -- Create transaction record
    INSERT INTO transactions (
        user_id, type, amount, description, transaction_date,
        category_id, source_account_id, target_account_id, notes
    ) VALUES (
        v_user_id, p_type, p_amount, p_description, p_transaction_date,
        p_category_id, p_source_account_id, p_target_account_id, p_notes
    ) RETURNING id INTO v_transaction_id;
    
    RETURN v_transaction_id;
END;
$$;

-- Delete transaction with balance rollback
CREATE OR REPLACE FUNCTION delete_transaction(
    p_transaction_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_transaction RECORD;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Get transaction details
    SELECT * INTO v_transaction 
    FROM transactions 
    WHERE id = p_transaction_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction not found or access denied';
    END IF;
    
    -- Rollback balance changes (reverse the original operation)
    CASE v_transaction.type
        WHEN 'income' THEN
            -- Subtract the income amount
            PERFORM update_account_balance(v_transaction.source_account_id, v_transaction.amount, 'subtract');
            
        WHEN 'expense' THEN
            -- Add back the expense amount
            PERFORM update_account_balance(v_transaction.source_account_id, v_transaction.amount, 'add');
            
        WHEN 'transfer' THEN
            -- Reverse the transfer
            PERFORM update_account_balance(v_transaction.source_account_id, v_transaction.amount, 'add');
            PERFORM update_account_balance(v_transaction.target_account_id, v_transaction.amount, 'subtract');
    END CASE;
    
    -- Delete the transaction
    DELETE FROM transactions WHERE id = p_transaction_id;
    
    RETURN TRUE;
END;
$$;

-- =====================================================
-- 3. INSTALLMENT FUNCTIONS
-- =====================================================

-- Create installment transaction
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
    i INTEGER;
    v_due_date DATE;
    v_first_transaction_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Validate inputs
    IF p_count <= 1 THEN
        RAISE EXCEPTION 'Installment count must be greater than 1';
    END IF;
    
    IF p_total_amount <= 0 THEN
        RAISE EXCEPTION 'Total amount must be positive';
    END IF;
    
    -- Validate account (must be credit card)
    SELECT * INTO v_account 
    FROM accounts 
    WHERE id = p_source_account_id AND user_id = v_user_id AND type = 'credit' AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source account must be an active credit card';
    END IF;
    
    -- Check credit limit
    IF v_account.balance + p_total_amount > v_account.credit_limit THEN
        RAISE EXCEPTION 'Credit limit exceeded. Available: %, Requested: %', 
            v_account.credit_limit - v_account.balance, p_total_amount;
    END IF;
    
    -- Calculate monthly amount
    v_monthly_amount := p_total_amount / p_count;
    
    -- Create installment transaction
    INSERT INTO installment_transactions (
        user_id, source_account_id, total_amount, monthly_amount, 
        count, start_date, description, category_id
    ) VALUES (
        v_user_id, p_source_account_id, p_total_amount, v_monthly_amount,
        p_count, p_start_date, p_description, p_category_id
    ) RETURNING id INTO v_installment_id;
    
    -- Create installment details
    FOR i IN 1..p_count LOOP
        v_due_date := p_start_date + (i || ' month')::INTERVAL;
        
        INSERT INTO installment_details (
            installment_transaction_id, installment_number, 
            due_date, amount
        ) VALUES (
            v_installment_id, i, v_due_date, v_monthly_amount
        );
    END LOOP;
    
    -- Add total debt to credit card
    UPDATE accounts 
    SET balance = balance + p_total_amount, updated_at = NOW()
    WHERE id = p_source_account_id;
    
    -- Create first installment transaction
    v_first_transaction_id := create_transaction(
        'expense',
        v_monthly_amount,
        p_description || ' (1/' || p_count || ')',
        p_source_account_id,
        NULL,
        p_category_id,
        NOW(),
        'First installment payment'
    );
    
    -- Link first installment to transaction
    UPDATE installment_details 
    SET is_paid = true, 
        paid_date = NOW(), 
        transaction_id = v_first_transaction_id
    WHERE installment_transaction_id = v_installment_id 
    AND installment_number = 1;
    
    RETURN v_installment_id;
END;
$$;

-- Pay installment
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
    v_installment RECORD;
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
    
    -- Create payment transaction
    v_transaction_id := create_transaction(
        'expense',
        v_detail.amount,
        v_detail.description || ' (' || v_detail.installment_number || '/' || v_detail.count || ')',
        v_detail.source_account_id,
        NULL,
        v_detail.category_id,
        p_payment_date,
        'Installment payment'
    );
    
    -- Mark installment as paid
    UPDATE installment_details 
    SET is_paid = true, 
        paid_date = p_payment_date, 
        transaction_id = v_transaction_id,
        updated_at = NOW()
    WHERE id = p_installment_detail_id;
    
    RETURN v_transaction_id;
END;
$$;

-- =====================================================
-- 4. ANALYTICS FUNCTIONS
-- =====================================================

-- Get account balance summary
CREATE OR REPLACE FUNCTION get_account_balance_summary(
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    total_assets DECIMAL(15,2),
    total_debts DECIMAL(15,2),
    net_worth DECIMAL(15,2),
    available_credit DECIMAL(15,2)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get current user
    v_user_id := COALESCE(p_user_id, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    RETURN QUERY
    SELECT 
        COALESCE(SUM(CASE WHEN type != 'credit' THEN balance ELSE 0 END), 0) as total_assets,
        COALESCE(SUM(CASE WHEN type = 'credit' THEN balance ELSE 0 END), 0) as total_debts,
        COALESCE(SUM(CASE WHEN type != 'credit' THEN balance ELSE -balance END), 0) as net_worth,
        COALESCE(SUM(CASE WHEN type = 'credit' THEN credit_limit - balance ELSE 0 END), 0) as available_credit
    FROM accounts
    WHERE user_id = v_user_id AND is_active = true;
END;
$$;

-- Get monthly transaction summary
CREATE OR REPLACE FUNCTION get_monthly_transaction_summary(
    p_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    p_month INTEGER DEFAULT EXTRACT(MONTH FROM CURRENT_DATE)
)
RETURNS TABLE (
    total_income DECIMAL(15,2),
    total_expenses DECIMAL(15,2),
    net_amount DECIMAL(15,2),
    transaction_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Calculate date range
    v_start_date := DATE(p_year || '-' || p_month || '-01');
    v_end_date := (v_start_date + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
    
    RETURN QUERY
    SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expenses,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount WHEN type = 'expense' THEN -amount ELSE 0 END), 0) as net_amount,
        COUNT(*)::INTEGER as transaction_count
    FROM transactions
    WHERE user_id = v_user_id 
    AND transaction_date::DATE BETWEEN v_start_date AND v_end_date;
END;
$$;

-- =====================================================
-- 5. UTILITY FUNCTIONS
-- =====================================================

-- Get upcoming installments
CREATE OR REPLACE FUNCTION get_upcoming_installments(
    p_days_ahead INTEGER DEFAULT 30
)
RETURNS TABLE (
    installment_detail_id UUID,
    installment_transaction_id UUID,
    account_name VARCHAR(100),
    description TEXT,
    amount DECIMAL(15,2),
    due_date DATE,
    installment_number INTEGER,
    total_count INTEGER,
    days_until_due INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    RETURN QUERY
    SELECT 
        id.id,
        id.installment_transaction_id,
        a.name,
        it.description,
        id.amount,
        id.due_date,
        id.installment_number,
        it.count,
        (id.due_date - CURRENT_DATE)::INTEGER
    FROM installment_details id
    JOIN installment_transactions it ON it.id = id.installment_transaction_id
    JOIN accounts a ON a.id = it.source_account_id
    WHERE it.user_id = v_user_id
    AND id.is_paid = false
    AND id.due_date <= CURRENT_DATE + (p_days_ahead || ' days')::INTERVAL
    ORDER BY id.due_date ASC;
END;
$$;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION create_account TO authenticated;
GRANT EXECUTE ON FUNCTION update_account_balance TO authenticated;
GRANT EXECUTE ON FUNCTION create_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION delete_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION create_installment_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION pay_installment TO authenticated;
GRANT EXECUTE ON FUNCTION get_account_balance_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_monthly_transaction_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_upcoming_installments TO authenticated;

-- Set function owners
ALTER FUNCTION create_account OWNER TO postgres;
ALTER FUNCTION update_account_balance OWNER TO postgres;
ALTER FUNCTION create_transaction OWNER TO postgres;
ALTER FUNCTION delete_transaction OWNER TO postgres;
ALTER FUNCTION create_installment_transaction OWNER TO postgres;
ALTER FUNCTION pay_installment OWNER TO postgres;
ALTER FUNCTION get_account_balance_summary OWNER TO postgres;
ALTER FUNCTION get_monthly_transaction_summary OWNER TO postgres;
ALTER FUNCTION get_upcoming_installments OWNER TO postgres; 