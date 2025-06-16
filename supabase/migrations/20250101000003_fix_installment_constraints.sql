-- =====================================================
-- QANTA v2 - Fix Installment Constraints
-- =====================================================
-- Created: 2025-01-01
-- Purpose: Fix installment deletion constraint issues

-- =====================================================
-- 1. FIX INSTALLMENT DETAILS CONSTRAINT
-- =====================================================

-- Drop the problematic constraint
ALTER TABLE installment_details DROP CONSTRAINT IF EXISTS chk_paid_consistency;

-- Create a more flexible constraint that allows proper deletion
ALTER TABLE installment_details 
ADD CONSTRAINT chk_paid_consistency CHECK (
    (is_paid = true AND paid_date IS NOT NULL) OR
    (is_paid = false AND paid_date IS NULL)
);

-- =====================================================
-- 2. UPDATE DELETE TRANSACTION FUNCTION
-- =====================================================

-- Improved delete transaction function that handles installments properly
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
    
    -- Check if this is an installment payment
    IF v_transaction.installment_id IS NOT NULL THEN
        -- Find the installment detail linked to this transaction
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
-- 3. GRANT PERMISSIONS
-- =====================================================

GRANT EXECUTE ON FUNCTION delete_transaction TO authenticated;
ALTER FUNCTION delete_transaction OWNER TO postgres; 