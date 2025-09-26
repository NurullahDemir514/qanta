-- Fix installment constraint to allow auto-paid historical installments
-- The issue: trigger was setting is_paid=true but leaving transaction_id=NULL
-- This violates the original chk_paid_consistency constraint

BEGIN;

-- 1. Drop the problematic trigger first
DROP TRIGGER IF EXISTS trg_mark_first_installment_paid ON installment_details;
DROP FUNCTION IF EXISTS mark_first_installment_paid();

-- 2. Update the constraint to be more flexible
ALTER TABLE installment_details DROP CONSTRAINT IF EXISTS chk_paid_consistency;
ALTER TABLE installment_details DROP CONSTRAINT IF EXISTS chk_paid_consistency_flexible;

-- Create a new flexible constraint that allows auto-paid installments
ALTER TABLE installment_details 
ADD CONSTRAINT chk_paid_consistency_flexible CHECK (
    -- Normal paid installments: must have paid_date and transaction_id
    (is_paid = true AND paid_date IS NOT NULL AND transaction_id IS NOT NULL) OR
    -- Auto-paid historical installments: must have paid_date but transaction_id can be NULL
    (is_paid = true AND paid_date IS NOT NULL AND transaction_id IS NULL) OR
    -- Unpaid installments: both paid_date and transaction_id must be NULL
    (is_paid = false AND paid_date IS NULL AND transaction_id IS NULL)
);

-- 3. Add comment explaining the new logic
COMMENT ON CONSTRAINT chk_paid_consistency_flexible ON installment_details IS 
'Flexible constraint that allows:
1. Normal paid installments: is_paid=true, paid_date NOT NULL, transaction_id NOT NULL
2. Auto-paid historical installments: is_paid=true, paid_date NOT NULL, transaction_id NULL
3. Unpaid installments: is_paid=false, paid_date NULL, transaction_id NULL';

COMMIT;
