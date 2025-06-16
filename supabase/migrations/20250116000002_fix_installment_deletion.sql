-- =====================================================
-- QANTA v2 - Fix Installment Transaction Deletion
-- =====================================================
-- Created: 2025-01-16
-- Purpose: Fix installment deletion to refund total amount instead of single installment

-- =====================================================
-- 1. ENHANCED DELETE INSTALLMENT TRANSACTION FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION delete_installment_transaction(
    p_transaction_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_transaction RECORD;
    v_installment RECORD;
    v_total_amount DECIMAL(15,2);
    v_paid_amount DECIMAL(15,2) := 0;
    v_refund_amount DECIMAL(15,2);
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
    
    -- Check if this is an installment transaction
    IF v_transaction.installment_id IS NOT NULL THEN
        -- Get installment transaction details
        SELECT * INTO v_installment
        FROM installment_transactions
        WHERE id = v_transaction.installment_id AND user_id = v_user_id;
        
        IF FOUND THEN
            v_total_amount := v_installment.total_amount;
            
            -- Calculate total amount already paid (excluding current transaction)
            SELECT COALESCE(SUM(amount), 0) INTO v_paid_amount
            FROM transactions
            WHERE installment_id = v_installment.id 
            AND id != p_transaction_id
            AND user_id = v_user_id;
            
            -- Calculate refund amount (total minus already paid)
            v_refund_amount := v_total_amount - v_paid_amount;
            
            -- Refund the total remaining amount instead of just single installment
            PERFORM update_account_balance(
                v_transaction.source_account_id, 
                v_refund_amount, 
                'add'
            );
            
            -- Delete all unpaid installment details
            DELETE FROM installment_details 
            WHERE installment_transaction_id = v_installment.id 
            AND is_paid = false;
            
            -- Delete all related transactions
            DELETE FROM transactions 
            WHERE installment_id = v_installment.id 
            AND user_id = v_user_id;
            
            -- Delete the installment transaction itself
            DELETE FROM installment_transactions 
            WHERE id = v_installment.id 
            AND user_id = v_user_id;
            
            RETURN TRUE;
        END IF;
    ELSE
        -- Regular transaction deletion
        CASE v_transaction.type
            WHEN 'income' THEN
                PERFORM update_account_balance(v_transaction.source_account_id, v_transaction.amount, 'subtract');
            WHEN 'expense' THEN
                PERFORM update_account_balance(v_transaction.source_account_id, v_transaction.amount, 'add');
            WHEN 'transfer' THEN
                PERFORM update_account_balance(v_transaction.source_account_id, v_transaction.amount, 'add');
                PERFORM update_account_balance(v_transaction.target_account_id, v_transaction.amount, 'subtract');
        END CASE;
        
        -- Delete the transaction
        DELETE FROM transactions WHERE id = p_transaction_id;
        
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$;

-- =====================================================
-- 2. UPDATE EXISTING DELETE TRANSACTION FUNCTION
-- =====================================================

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
    v_installment_detail RECORD;
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
    
    -- Check if this is an installment transaction - use enhanced deletion
    IF v_transaction.installment_id IS NOT NULL THEN
        RETURN delete_installment_transaction(p_transaction_id);
    END IF;
    
    -- Check if this is an installment payment
    SELECT * INTO v_installment_detail
    FROM installment_details 
    WHERE transaction_id = p_transaction_id;
    
    IF FOUND THEN
        -- Mark installment as unpaid and clear transaction reference
        UPDATE installment_details 
        SET is_paid = false, 
            paid_date = NULL, 
            transaction_id = NULL,
            updated_at = NOW()
        WHERE id = v_installment_detail.id;
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

COMMIT; 