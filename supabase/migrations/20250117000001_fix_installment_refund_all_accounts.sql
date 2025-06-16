-- =====================================================
-- QANTA v2 - Fix Installment Refund for All Account Types
-- =====================================================
-- Created: 2025-01-17
-- Purpose: Fix installment deletion refund logic for all account types

-- Problem: Current logic only refunds remaining amount for non-credit accounts,
-- but should refund the total amount since the entire amount was deducted during creation
-- 
-- Correct Logic for ALL account types:
-- - Creation: Deduct total_amount from account balance
-- - Deletion: Refund total_amount to account balance
-- - This ensures proper balance restoration regardless of account type

BEGIN;

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
    v_account RECORD;
    v_total_amount DECIMAL(15,2);
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
            
            -- Get account details
            SELECT * INTO v_account
            FROM accounts
            WHERE id = v_installment.source_account_id AND user_id = v_user_id;
            
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Account not found';
            END IF;
            
            -- UNIFIED REFUND LOGIC: Always refund the total amount
            -- This is correct because the total amount was deducted during creation
            IF v_account.type = 'credit' THEN
                -- For credit cards: Subtract from balance (increases available credit)
                UPDATE accounts 
                SET balance = balance - v_total_amount, updated_at = NOW()
                WHERE id = v_installment.source_account_id;
            ELSE
                -- For all other account types: Add to balance (restores deducted amount)
                UPDATE accounts 
                SET balance = balance + v_total_amount, updated_at = NOW()
                WHERE id = v_installment.source_account_id;
            END IF;
            
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

-- Add comment for documentation
COMMENT ON FUNCTION delete_installment_transaction(UUID) IS 
'Deletes an installment transaction and properly refunds the total amount to the source account. 
For credit cards: subtracts from balance (increases available credit).
For other accounts: adds to balance (restores deducted amount).
This ensures correct balance restoration regardless of account type.';

COMMIT; 