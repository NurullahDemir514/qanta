-- =====================================================
-- QANTA v2 - Fix Installment Refund for Credit Cards
-- =====================================================
-- Created: 2025-06-16
-- Purpose: Fix installment deletion refund logic for credit cards

-- Problem: After fixing credit card limit deduction to use total amount,
-- the refund logic needs to be updated to properly restore credit card balance
-- 
-- Credit Card Logic:
-- - Creation: balance += total_amount (blocks entire amount from limit)
-- - Deletion: balance -= total_amount (restores entire amount to limit)
-- - This is different from regular transactions that use update_account_balance

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
            
            -- Get account details to check if it's a credit card
            SELECT * INTO v_account
            FROM accounts
            WHERE id = v_installment.source_account_id AND user_id = v_user_id;
            
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Account not found';
            END IF;
            
            -- CRITICAL FIX: For credit cards, directly subtract total amount from balance
            -- This restores the entire blocked amount back to available credit limit
            IF v_account.type = 'credit' THEN
                UPDATE accounts 
                SET balance = balance - v_total_amount, updated_at = NOW()
                WHERE id = v_installment.source_account_id;
            ELSE
                -- For non-credit accounts, use the standard refund logic
                -- Calculate paid amount and refund remaining
                DECLARE
                    v_paid_amount DECIMAL(15,2) := 0;
                    v_refund_amount DECIMAL(15,2);
                BEGIN
                    SELECT COALESCE(SUM(amount), 0) INTO v_paid_amount
                    FROM transactions
                    WHERE installment_id = v_installment.id 
                    AND user_id = v_user_id;
                    
                    v_refund_amount := v_total_amount - v_paid_amount;
                    
                    IF v_refund_amount > 0 THEN
                        PERFORM update_account_balance(
                            v_installment.source_account_id, 
                            v_refund_amount, 
                            'add'
                        );
                    END IF;
                END;
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

COMMIT;
