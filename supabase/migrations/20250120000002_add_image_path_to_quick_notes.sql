-- Add image_path column to quick_notes table
ALTER TABLE quick_notes ADD COLUMN IF NOT EXISTS image_path TEXT;

-- Add comment for the new column
COMMENT ON COLUMN quick_notes.image_path IS 'Path to the image file for image type notes'; 