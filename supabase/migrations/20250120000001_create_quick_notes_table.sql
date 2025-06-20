-- Create quick_notes table for storing user's quick financial notes
CREATE TABLE IF NOT EXISTS quick_notes (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'voice', 'image')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_processed BOOLEAN DEFAULT FALSE,
    processed_transaction_id TEXT NULL,
    
    CONSTRAINT quick_notes_content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_quick_notes_user_id ON quick_notes(user_id);
CREATE INDEX IF NOT EXISTS idx_quick_notes_created_at ON quick_notes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_quick_notes_is_processed ON quick_notes(is_processed);
CREATE INDEX IF NOT EXISTS idx_quick_notes_user_processed ON quick_notes(user_id, is_processed);

-- Enable RLS (Row Level Security)
ALTER TABLE quick_notes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can only see their own quick notes"
    ON quick_notes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can only insert their own quick notes"
    ON quick_notes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can only update their own quick notes"
    ON quick_notes FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can only delete their own quick notes"
    ON quick_notes FOR DELETE
    USING (auth.uid() = user_id);

-- Add helpful comments
COMMENT ON TABLE quick_notes IS 'Stores quick financial notes that users can later convert to transactions';
COMMENT ON COLUMN quick_notes.id IS 'Unique identifier for the quick note';
COMMENT ON COLUMN quick_notes.user_id IS 'Reference to the user who created the note';
COMMENT ON COLUMN quick_notes.content IS 'The content of the note (text, voice transcript, or image description)';
COMMENT ON COLUMN quick_notes.type IS 'Type of note: text, voice, or image';
COMMENT ON COLUMN quick_notes.is_processed IS 'Whether this note has been converted to a transaction';
COMMENT ON COLUMN quick_notes.processed_transaction_id IS 'ID of the transaction this note was converted to'; 