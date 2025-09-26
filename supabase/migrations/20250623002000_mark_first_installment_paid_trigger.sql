-- Migration: Mark first installment as paid if due date is in the past

-- 1. Trigger fonksiyonunu oluştur
CREATE OR REPLACE FUNCTION mark_first_installment_paid()
RETURNS TRIGGER AS $$
BEGIN
  -- Sadece yeni eklenen taksit için çalışır
  IF (NEW.installment_number = 1 AND NEW.due_date < NOW()) THEN
    NEW.is_paid := TRUE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Eski trigger varsa sil
DROP TRIGGER IF EXISTS trg_mark_first_installment_paid ON installment_details;

-- 3. Trigger'ı oluştur
CREATE TRIGGER trg_mark_first_installment_paid
BEFORE INSERT ON installment_details
FOR EACH ROW
EXECUTE FUNCTION mark_first_installment_paid(); 