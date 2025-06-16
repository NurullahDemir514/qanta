-- =====================================================
-- QANTA v2 - Fix Installment Refund Calculation
-- =====================================================
-- Created: 2025-06-16
-- Purpose: Fix installment deletion refund calculation - include current transaction in paid amount

-- Problem: Current logic excludes the transaction being deleted from paid amount calculation
-- This causes one extra installment to be refunded
-- 
-- Example:
-- - Total: 12,000₺, 12 installments of 1,000₺ each
-- - 3 installments paid (including current one being deleted)
-- - Current logic: Refund = 12,000₺ - 2,000₺ = 10,000₺ (WRONG - 1 extra installment)
-- - Correct logic: Refund = 12,000₺ - 3,000₺ = 9,000₺ (CORRECT)

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
            
            -- Calculate total amount already paid (INCLUDING current transaction)
            -- This is the key fix - we need to include ALL paid installments
            SELECT COALESCE(SUM(amount), 0) INTO v_paid_amount
            FROM transactions
            WHERE installment_id = v_installment.id 
            AND user_id = v_user_id;
            
            -- Calculate refund amount (total minus ALL paid installments)
            v_refund_amount := v_total_amount - v_paid_amount;
            
            -- Refund the remaining amount (should be 0 or negative if all paid)
            IF v_refund_amount > 0 THEN
                PERFORM update_account_balance(
                    v_transaction.source_account_id, 
                    v_refund_amount, 
                    'add'
                );
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
