-- Allow single installment transactions
-- This migration fixes the constraint that prevents count = 1 installments

BEGIN;

-- Drop the problematic constraint if it exists
ALTER TABLE installment_transactions 
DROP CONSTRAINT IF EXISTS installment_transactions_count_check;

-- Also ensure the basic count constraint allows count = 1
ALTER TABLE installment_transactions 
DROP CONSTRAINT IF EXISTS installment_transactions_count_check1;

-- Add a simple constraint that allows count >= 1 (including 1)
ALTER TABLE installment_transactions 
ADD CONSTRAINT installment_transactions_count_check 
CHECK (count >= 1);

COMMIT; 