-- Update transaction_summary view to include is_paid field
-- This fixes the issue where payment status wasn't being returned by the view

-- Drop the existing view
DROP VIEW IF EXISTS transaction_summary;

-- Recreate the view with is_paid field included
CREATE VIEW transaction_summary AS
SELECT 
    t.id,
    t.user_id,
    t.type,
    t.amount,
    t.description,
    t.transaction_date,
    t.category_id,
    t.source_account_id,
    t.target_account_id,
    t.installment_id,
    t.is_recurring,
    t.notes,
    t.is_paid,  -- This field was missing in the original view
    t.created_at,
    t.updated_at,
    sa.name as source_account_name,
    sa.type as source_account_type,
    ta.name as target_account_name,
    ta.type as target_account_type,
    c.name as category_name,
    c.icon as category_icon,
    c.color as category_color
FROM transactions t
LEFT JOIN accounts sa ON t.source_account_id = sa.id
LEFT JOIN accounts ta ON t.target_account_id = ta.id
LEFT JOIN categories c ON t.category_id = c.id;

-- Add comment for documentation
COMMENT ON VIEW transaction_summary IS 'Transactions with joined account and category information, including payment status'; 