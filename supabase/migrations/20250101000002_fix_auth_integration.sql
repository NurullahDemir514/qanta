-- =====================================================
-- QANTA v2 - Fix Authentication Integration
-- =====================================================
-- Created: 2025-01-01
-- Purpose: Fix foreign key references to use auth.users instead of custom users table

-- =====================================================
-- 1. DROP EXISTING CONSTRAINTS AND CUSTOM USERS TABLE
-- =====================================================

-- Drop all foreign key constraints that reference the custom users table
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_user_id_fkey;
ALTER TABLE accounts DROP CONSTRAINT IF EXISTS accounts_user_id_fkey;
ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_user_id_fkey;
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_user_id_fkey;
ALTER TABLE installment_transactions DROP CONSTRAINT IF EXISTS installment_transactions_user_id_fkey;
ALTER TABLE recurring_transactions DROP CONSTRAINT IF EXISTS recurring_transactions_user_id_fkey;

-- Drop the custom users table (we'll use auth.users instead)
DROP TABLE IF EXISTS users CASCADE;

-- =====================================================
-- 2. UPDATE FOREIGN KEY CONSTRAINTS TO USE AUTH.USERS
-- =====================================================

-- User profiles - reference auth.users
ALTER TABLE user_profiles 
ADD CONSTRAINT user_profiles_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Accounts - reference auth.users
ALTER TABLE accounts 
ADD CONSTRAINT accounts_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Categories - reference auth.users (nullable for system categories)
ALTER TABLE categories 
ADD CONSTRAINT categories_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Transactions - reference auth.users
ALTER TABLE transactions 
ADD CONSTRAINT transactions_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Installment transactions - reference auth.users
ALTER TABLE installment_transactions 
ADD CONSTRAINT installment_transactions_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Recurring transactions - reference auth.users
ALTER TABLE recurring_transactions 
ADD CONSTRAINT recurring_transactions_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- =====================================================
-- 3. CREATE TRIGGER TO AUTO-CREATE USER PROFILES
-- =====================================================

-- Function to create user profile when a new user signs up
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_profiles (user_id, preferred_language, currency_code, theme_mode)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'preferred_language', 'tr'),
        COALESCE(NEW.raw_user_meta_data->>'currency_code', 'TRY'),
        COALESCE(NEW.raw_user_meta_data->>'theme_mode', 'system')
    );
    RETURN NEW;
EXCEPTION
    WHEN unique_violation THEN
        -- Profile already exists, ignore
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile on user creation
DROP TRIGGER IF EXISTS create_user_profile_trigger ON auth.users;
CREATE TRIGGER create_user_profile_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_profile();

-- =====================================================
-- 4. CREATE USER PROFILES FOR EXISTING USERS
-- =====================================================

-- Insert user profiles for any existing users who don't have one
INSERT INTO user_profiles (user_id, preferred_language, currency_code, theme_mode)
SELECT 
    id,
    COALESCE(raw_user_meta_data->>'preferred_language', 'tr'),
    COALESCE(raw_user_meta_data->>'currency_code', 'TRY'),
    COALESCE(raw_user_meta_data->>'theme_mode', 'system')
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM user_profiles WHERE user_id IS NOT NULL)
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- 5. UPDATE COMMENTS
-- =====================================================

COMMENT ON TABLE user_profiles IS 'User profiles linked to auth.users for personalization settings';
COMMENT ON COLUMN user_profiles.user_id IS 'References auth.users.id - the authenticated user';

-- =====================================================
-- 6. VERIFY SETUP
-- =====================================================

-- This should now work without foreign key constraint errors
-- Test query: SELECT * FROM accounts WHERE user_id = auth.uid(); 