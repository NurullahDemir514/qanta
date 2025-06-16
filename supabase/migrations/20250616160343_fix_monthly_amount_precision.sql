-- =====================================================
-- QANTA v2 - Fix Monthly Amount Precision Constraint
-- =====================================================
-- Created: 2025-06-16
-- Purpose: Fix monthly amount constraint to handle decimal precision issues

-- The current constraint is too strict:
-- CONSTRAINT chk_monthly_amount CHECK (monthly_amount * count = total_amount)
-- 
-- This fails for cases like:
-- 20000.00 ÷ 12 = 1666.666... (stored as 1666.67)
-- 1666.67 × 12 = 20000.04 ≠ 20000.00
--
-- We need to allow for small rounding differences due to decimal precision

BEGIN;

-- Drop the existing strict constraint
ALTER TABLE installment_transactions 
DROP CONSTRAINT IF EXISTS chk_monthly_amount;

-- Add a more flexible constraint that allows for small rounding differences
-- Allow up to 0.05 difference (5 cents) to accommodate decimal precision
ALTER TABLE installment_transactions 
ADD CONSTRAINT chk_monthly_amount 
CHECK (ABS((monthly_amount * count) - total_amount) <= 0.05);

COMMIT;
