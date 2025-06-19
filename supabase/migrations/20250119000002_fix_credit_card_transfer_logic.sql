-- Fix credit card transfer logic
-- Problem: Transfers to credit cards currently ADD to balance (increasing debt)
-- Solution: Transfers to credit cards should SUBTRACT from balance (reducing debt)

-- Create a new transfer-aware balance update function
CREATE OR REPLACE FUNCTION update_account_balance_v2(
    p_account_id UUID,
    p_amount DECIMAL(15,2),
    p_operation VARCHAR(10), -- 'add' or 'subtract'
    p_is_transfer_target BOOLEAN DEFAULT FALSE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_account RECORD;
    v_new_balance DECIMAL(15,2);
    v_effective_operation VARCHAR(10);
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
    
    -- For credit cards receiving transfers, reverse the operation
    -- Transfer TO credit card should reduce debt (subtract from balance)
    v_effective_operation := p_operation;
    IF v_account.type = 'credit' AND p_is_transfer_target = TRUE THEN
        IF p_operation = 'add' THEN
            v_effective_operation := 'subtract';
        ELSIF p_operation = 'subtract' THEN
            v_effective_operation := 'add';
        END IF;
        
        RAISE NOTICE 'Credit card transfer: Operation % changed to % for account %', 
            p_operation, v_effective_operation, p_account_id;
    END IF;
    
    -- Calculate new balance
    IF v_effective_operation = 'add' THEN
        v_new_balance := v_account.balance + p_amount;
    ELSIF v_effective_operation = 'subtract' THEN
        v_new_balance := v_account.balance - p_amount;
    ELSE
        RAISE EXCEPTION 'Invalid operation. Use "add" or "subtract"';
    END IF;
    
    -- Validate balance constraints
    IF v_account.type = 'credit' THEN
        -- Credit cards can have debt up to credit limit
        -- Allow negative balance (overpayment/positive balance on credit card)
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
    
    RAISE NOTICE 'Balance updated: Account %, Old: %, New: %, Operation: %', 
        p_account_id, v_account.balance, v_new_balance, v_effective_operation;
    
    RETURN TRUE;
END;
$$;

-- Update the create_transaction function to use the new balance update logic
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
            PERFORM update_account_balance_v2(p_source_account_id, p_amount, 'add', FALSE);
            
        WHEN 'expense' THEN
            -- Subtract money from source account
            PERFORM update_account_balance_v2(p_source_account_id, p_amount, 'subtract', FALSE);
            
        WHEN 'transfer' THEN
            -- Subtract from source account (normal operation)
            PERFORM update_account_balance_v2(p_source_account_id, p_amount, 'subtract', FALSE);
            
            -- Add to target account (with transfer target flag for credit cards)
            PERFORM update_account_balance_v2(p_target_account_id, p_amount, 'add', TRUE);
    END CASE;
    
    -- Create transaction record
    INSERT INTO transactions (
        user_id, type, amount, description, transaction_date,
        category_id, source_account_id, target_account_id, notes
    ) VALUES (
        v_user_id, p_type, p_amount, p_description, p_transaction_date,
        p_category_id, p_source_account_id, p_target_account_id, p_notes
    ) RETURNING id INTO v_transaction_id;
    
    RAISE NOTICE 'Transaction created successfully: % (Type: %, Amount: %)', 
        v_transaction_id, p_type, p_amount;
    
    RETURN v_transaction_id;
END;
$$;

-- Update the delete_transaction function to use the new balance update logic
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
    v_target_account RECORD;
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
            -- Reverse income: subtract from source account
            PERFORM update_account_balance_v2(v_transaction.source_account_id, v_transaction.amount, 'subtract', FALSE);
            
        WHEN 'expense' THEN
            -- Reverse expense: add back to source account
            PERFORM update_account_balance_v2(v_transaction.source_account_id, v_transaction.amount, 'add', FALSE);
            
        WHEN 'transfer' THEN
            -- Reverse transfer: add back to source account
            PERFORM update_account_balance_v2(v_transaction.source_account_id, v_transaction.amount, 'add', FALSE);
            
            -- Reverse transfer: subtract from target account (with transfer target flag)
            IF v_transaction.target_account_id IS NOT NULL THEN
                PERFORM update_account_balance_v2(v_transaction.target_account_id, v_transaction.amount, 'subtract', TRUE);
            END IF;
    END CASE;
    
    -- Delete the transaction
    DELETE FROM transactions WHERE id = p_transaction_id;
    
    RETURN TRUE;
END;
$$;

-- Add comment explaining the fix
COMMENT ON FUNCTION update_account_balance_v2 IS 'Fixed transfer logic: credit cards receiving transfers have debt reduced (balance decreased). Allows overpayment (negative balance).'; 