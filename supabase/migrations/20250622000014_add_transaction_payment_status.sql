-- Add payment status to transactions for statement tracking
-- This allows showing paid status in transaction cards when statement is paid

BEGIN;

-- Add is_paid column to transactions table
ALTER TABLE transactions 
ADD COLUMN is_paid BOOLEAN DEFAULT FALSE;

-- Add index for better performance on paid status queries
CREATE INDEX idx_transactions_is_paid ON transactions(is_paid);
CREATE INDEX idx_transactions_source_account_paid ON transactions(source_account_id, is_paid);

-- Function to mark statement transactions as paid
CREATE OR REPLACE FUNCTION mark_statement_transactions_paid(
    p_card_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    -- Mark all transactions in the statement period as paid
    UPDATE transactions 
    SET is_paid = TRUE,
        updated_at = NOW()
    WHERE source_account_id = p_card_id
      AND type = 'expense'
      AND transaction_date::DATE >= p_start_date
      AND transaction_date::DATE <= p_end_date
      AND is_paid = FALSE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN v_updated_count;
END;
$$;

-- Function to unmark statement transactions as paid
CREATE OR REPLACE FUNCTION unmark_statement_transactions_paid(
    p_card_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    -- Unmark all transactions in the statement period as paid
    UPDATE transactions 
    SET is_paid = FALSE,
        updated_at = NOW()
    WHERE source_account_id = p_card_id
      AND type = 'expense'
      AND transaction_date::DATE >= p_start_date
      AND transaction_date::DATE <= p_end_date
      AND is_paid = TRUE;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN v_updated_count;
END;
$$;

-- Drop and recreate the statement view to include payment status
DROP VIEW IF EXISTS statement_installment_transactions;

CREATE VIEW statement_installment_transactions AS
SELECT 
    t.id,
    t.user_id,
    t.type,
    -- Use monthly_amount for installment transactions instead of total amount
    CASE 
        WHEN it.id IS NOT NULL AND it.count > 1 THEN it.monthly_amount
        ELSE t.amount
    END as amount,
    t.description,
    t.transaction_date,
    t.category_id,
    t.source_account_id,
    t.target_account_id,
    t.installment_id,
    t.is_recurring,
    t.notes,
    t.created_at,
    t.updated_at,
    t.is_paid,  -- Include payment status
    -- Add installment info for better display
    it.count as installment_count,
    it.monthly_amount as monthly_installment_amount,
    it.total_amount as total_installment_amount
FROM transactions t
LEFT JOIN installment_transactions it ON t.installment_id = it.id
WHERE t.type = 'expense';

-- Add comments
COMMENT ON COLUMN transactions.is_paid IS 'Whether this transaction has been paid (marked when statement is paid)';
COMMENT ON FUNCTION mark_statement_transactions_paid IS 'Marks all transactions in a statement period as paid';
COMMENT ON FUNCTION unmark_statement_transactions_paid IS 'Unmarks all transactions in a statement period as paid';

COMMIT; 