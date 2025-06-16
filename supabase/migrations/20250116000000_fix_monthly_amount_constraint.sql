-- Fix monthly amount constraint to handle decimal precision issues
-- 
-- The current constraint is too strict:
-- CONSTRAINT chk_monthly_amount CHECK (monthly_amount * count = total_amount)
-- 
-- This fails for cases like:
-- 520.00 ÷ 3 = 173.333... (stored as 173.33)
-- 173.33 × 3 = 519.99 ≠ 520.00
--
-- We need to allow for small rounding differences due to decimal precision

BEGIN;

-- Drop the existing strict constraint
ALTER TABLE installment_transactions 
DROP CONSTRAINT IF EXISTS chk_monthly_amount;

-- Add a more flexible constraint that allows for small rounding differences
-- Allow up to 0.02 difference (2 cents) to accommodate decimal precision
ALTER TABLE installment_transactions 
ADD CONSTRAINT chk_monthly_amount 
CHECK (ABS((monthly_amount * count) - total_amount) <= 0.02);

COMMIT; 