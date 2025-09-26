-- Fix installment deletion to be consistent with creation logic
-- Only refund remaining debt amount, not total amount
-- This ensures mathematical consistency in the system

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
    v_paid_amount DECIMAL(15,2);
    v_remaining_amount DECIMAL(15,2);
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
            
            -- Calculate total amount already paid
            SELECT COALESCE(SUM(amount), 0) INTO v_paid_amount
            FROM installment_details
            WHERE installment_transaction_id = v_installment.id 
            AND is_paid = true;
            
            -- Calculate remaining amount (what's actually owed)
            v_remaining_amount := v_total_amount - v_paid_amount;
            
            -- Get account details
            SELECT * INTO v_account
            FROM accounts
            WHERE id = v_installment.source_account_id AND user_id = v_user_id;
            
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Account not found';
            END IF;
            
            -- CONSISTENT REMAINING DEBT LOGIC: Only refund the remaining debt amount
            -- This matches the creation logic where only remaining debt was added to balance
            IF v_account.type = 'credit' THEN
                -- For credit cards: Subtract remaining amount from balance (increases available credit)
                UPDATE accounts 
                SET balance = balance - v_remaining_amount, updated_at = NOW()
                WHERE id = v_installment.source_account_id;
                
                RAISE NOTICE 'Credit card refund: Subtracted % (remaining debt) from balance for account %', v_remaining_amount, v_installment.source_account_id;
            ELSE
                -- For other account types: Add remaining amount to balance
                UPDATE accounts 
                SET balance = balance + v_remaining_amount, updated_at = NOW()
                WHERE id = v_installment.source_account_id;
                
                RAISE NOTICE 'Regular account refund: Added % (remaining debt) to balance for account %', v_remaining_amount, v_installment.source_account_id;
            END IF;
            
            -- Delete all installment details (paid and unpaid)
            DELETE FROM installment_details 
            WHERE installment_transaction_id = v_installment.id;
            
            -- Delete all related transactions
            DELETE FROM transactions 
            WHERE installment_id = v_installment.id 
            AND user_id = v_user_id;
            
            -- Delete the installment transaction itself
            DELETE FROM installment_transactions 
            WHERE id = v_installment.id 
            AND user_id = v_user_id;
            
            RAISE NOTICE 'Successfully deleted installment transaction % with remaining debt refund of % (total was %, paid was %)', 
                v_installment.id, v_remaining_amount, v_total_amount, v_paid_amount;
            
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

-- Update function documentation
COMMENT ON FUNCTION delete_installment_transaction(UUID) IS 
'Deletes an installment transaction and properly refunds the REMAINING DEBT amount to the source account.

CONSISTENT REMAINING DEBT LOGIC:
- Calculates how much was already paid through installments
- Only refunds the remaining debt amount (total - paid)
- For credit cards: subtracts remaining amount from balance (increases available credit)
- For other accounts: adds remaining amount to balance

This ensures consistency with the creation logic where only the remaining debt 
amount was added to the account balance after deducting paid installments.

MATHEMATICAL CONSISTENCY:
Creation: balance += (total - paid_installments)
Deletion: balance -= (total - paid_installments)
Result: Perfect balance restoration

EXAMPLE:
- Total: 5000 TL, Paid: 1250 TL, Remaining: 3750 TL
- Only 3750 TL is refunded (the actual debt that was added to the account)
- This prevents users from gaining/losing money through installment deletion';

COMMIT; 