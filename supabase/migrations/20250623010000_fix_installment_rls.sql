-- Enable RLS and set strict user policies for installment tables

-- 1. installment_transactions
ALTER TABLE installment_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own installments" ON installment_transactions;
CREATE POLICY "Users can manage own installments"
    ON installment_transactions
    FOR ALL
    USING (auth.uid() = user_id);

-- 2. installment_details
ALTER TABLE installment_details ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own installment details" ON installment_details;
CREATE POLICY "Users can manage own installment details"
    ON installment_details
    FOR ALL
    USING (
      EXISTS (
        SELECT 1 FROM installment_transactions it
        WHERE it.id = installment_details.installment_transaction_id
        AND it.user_id = auth.uid()
      )
    ); 