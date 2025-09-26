-- Fix statement installment display
-- Show monthly installment amount instead of total amount in statements
-- This ensures statements show only the amount due for that period

BEGIN;

-- Create a view that shows installment transactions with monthly amounts for statements
CREATE OR REPLACE VIEW statement_installment_transactions AS
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
    -- Add installment info for better display
    it.count as installment_count,
    it.monthly_amount as monthly_installment_amount,
    it.total_amount as total_installment_amount
FROM transactions t
LEFT JOIN installment_transactions it ON t.installment_id = it.id
WHERE t.type = 'expense';

-- Add comment explaining the view
COMMENT ON VIEW statement_installment_transactions IS 
'View that shows transactions with correct amounts for statement display.
For installment transactions with count > 1, shows monthly_amount instead of total_amount.
This ensures credit card statements show only the monthly installment amount due for that period.';

COMMIT; 