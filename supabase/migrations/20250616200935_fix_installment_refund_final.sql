-- =====================================================
-- QANTA v2 - Final Fix for Installment Refund Logic
-- =====================================================
-- Created: 2025-06-16
-- Purpose: Fix installment deletion refund logic for all account types

-- Problem: Current logic has inconsistent refund behavior between account types
-- Solution: Always refund the total amount since that's what was deducted during creation
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
                -- Credit card balance is negative, so subtracting increases available credit
                UPDATE accounts 
                SET balance = balance - v_total_amount, updated_at = NOW()
                WHERE id = v_installment.source_account_id;
                
                RAISE NOTICE 'Credit card refund: Subtracted % from balance for account %', v_total_amount, v_installment.source_account_id;
            ELSE
                -- For all other account types: Add to balance (restores deducted amount)
                -- Regular accounts have positive balance, so adding restores the amount
                UPDATE accounts 
                SET balance = balance + v_total_amount, updated_at = NOW()
                WHERE id = v_installment.source_account_id;
                
                RAISE NOTICE 'Regular account refund: Added % to balance for account %', v_total_amount, v_installment.source_account_id;
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
            
            RAISE NOTICE 'Successfully deleted installment transaction % with total refund of %', v_installment.id, v_total_amount;
            
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

-- Add comprehensive comment for documentation
COMMENT ON FUNCTION delete_installment_transaction(UUID) IS 
'Deletes an installment transaction and properly refunds the TOTAL amount to the source account.

REFUND LOGIC:
- For credit cards: subtracts total_amount from balance (increases available credit limit)
- For other accounts: adds total_amount to balance (restores the deducted amount)

This ensures correct balance restoration regardless of account type, since the total amount 
was deducted from the account balance during installment creation.

IMPORTANT: This function always refunds the TOTAL amount, not just the remaining unpaid amount,
because the entire amount was deducted upfront during installment creation.';

COMMIT;
