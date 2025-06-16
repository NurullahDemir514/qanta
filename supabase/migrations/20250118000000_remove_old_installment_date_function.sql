-- Remove old create_installment_transaction function with DATE parameter
DROP FUNCTION IF EXISTS public.create_installment_transaction(
  p_source_account_id UUID,
  p_total_amount DECIMAL,
  p_count INTEGER,
  p_description TEXT,
  p_category_id UUID,
  p_start_date DATE
); 