-- Add increment_balance RPC function for credit card balance updates
-- This function safely updates account balance and returns the new balance

BEGIN;

-- Create increment_balance function
CREATE OR REPLACE FUNCTION increment_balance(
    account_id UUID,
    amount DECIMAL(15,2)
)
RETURNS DECIMAL(15,2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_new_balance DECIMAL(15,2);
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Update the account balance and return new balance
    UPDATE accounts 
    SET balance = balance + amount, 
        updated_at = NOW()
    WHERE id = account_id 
    AND user_id = v_user_id  -- Security: only user's own accounts
    RETURNING balance INTO v_new_balance;
    
    -- Check if account was found and updated
    IF v_new_balance IS NULL THEN
        RAISE EXCEPTION 'Account not found or access denied';
    END IF;
    
    RETURN v_new_balance;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION increment_balance TO authenticated;

COMMIT; 