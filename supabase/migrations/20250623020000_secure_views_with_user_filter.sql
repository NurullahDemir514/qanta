-- Secure all summary views with user_id filter for RLS compliance

-- 1. transaction_summary
DROP VIEW IF EXISTS transaction_summary;
CREATE VIEW transaction_summary AS
SELECT 
    t.*,
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
LEFT JOIN categories c ON t.category_id = c.id
WHERE t.user_id = auth.uid();

-- 2. statement_installment_transactions
DROP VIEW IF EXISTS statement_installment_transactions;
CREATE VIEW statement_installment_transactions AS
SELECT 
    t.id,
    t.user_id,
    t.type,
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
    t.is_paid,
    it.count as installment_count,
    it.monthly_amount as monthly_installment_amount,
    it.total_amount as total_installment_amount
FROM transactions t
LEFT JOIN installment_transactions it ON t.installment_id = it.id
WHERE t.type = 'expense' AND t.user_id = auth.uid();

-- 3. installment_summary
DROP VIEW IF EXISTS installment_summary;
CREATE VIEW installment_summary AS
SELECT 
    it.*,
    a.name as account_name,
    COUNT(id_paid.id) as paid_count,
    COUNT(id_total.id) as total_count,
    COALESCE(SUM(CASE WHEN id_paid.is_paid THEN id_paid.amount ELSE 0 END), 0) as paid_amount,
    it.total_amount - COALESCE(SUM(CASE WHEN id_paid.is_paid THEN id_paid.amount ELSE 0 END), 0) as remaining_amount,
    MIN(CASE WHEN NOT id_total.is_paid THEN id_total.due_date END) as next_due_date
FROM installment_transactions it
LEFT JOIN accounts a ON it.source_account_id = a.id
LEFT JOIN installment_details id_total ON it.id = id_total.installment_transaction_id
LEFT JOIN installment_details id_paid ON it.id = id_paid.installment_transaction_id AND id_paid.is_paid = true
WHERE it.user_id = auth.uid()
GROUP BY it.id, a.name;

-- 4. account_summary
DROP VIEW IF EXISTS account_summary;
CREATE VIEW account_summary AS
SELECT 
    a.*,
    CASE 
        WHEN a.type = 'credit' THEN a.credit_limit - a.balance
        ELSE a.balance
    END as available_amount,
    CASE 
        WHEN a.type = 'credit' THEN a.balance
        ELSE 0
    END as debt_amount
FROM accounts a
WHERE a.is_active = true AND a.user_id = auth.uid(); 