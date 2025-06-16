-- =====================================================
-- QANTA v2 - Clean, Professional Database Schema
-- =====================================================
-- Created: 2025-01-01
-- Purpose: Complete rewrite for optimal mobile performance

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. USERS (Core Authentication)
-- =====================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. USER_PROFILES (Personalization)
-- =====================================================
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    profile_picture_url TEXT,
    preferred_language VARCHAR(5) DEFAULT 'tr',
    currency_code VARCHAR(3) DEFAULT 'TRY',
    theme_mode VARCHAR(10) DEFAULT 'system', -- 'light', 'dark', 'system'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 3. ACCOUNTS (Polymorphic: Credit/Debit/Cash)
-- =====================================================
CREATE TYPE account_type AS ENUM ('credit', 'debit', 'cash');

CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type account_type NOT NULL,
    name VARCHAR(100) NOT NULL,
    bank_name VARCHAR(100), -- nullable for cash accounts
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    
    -- Credit card specific fields
    credit_limit DECIMAL(15,2), -- nullable, only for credit cards
    statement_day INTEGER CHECK (statement_day >= 1 AND statement_day <= 31),
    due_day INTEGER CHECK (due_day >= 1 AND due_day <= 31),
    
    -- Common fields
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_credit_fields CHECK (
        (type = 'credit' AND credit_limit IS NOT NULL AND credit_limit > 0) OR
        (type != 'credit' AND credit_limit IS NULL AND statement_day IS NULL AND due_day IS NULL)
    ),
    CONSTRAINT chk_balance_positive CHECK (
        (type = 'credit') OR (balance >= 0)
    )
);

-- =====================================================
-- 4. CATEGORIES (Income/Expense Categories)
-- =====================================================
CREATE TYPE category_type AS ENUM ('income', 'expense');

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL for system categories
    type category_type NOT NULL,
    name VARCHAR(50) NOT NULL,
    icon VARCHAR(50) DEFAULT 'category',
    color VARCHAR(7) DEFAULT '#6B7280',
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, type, name) -- Prevent duplicate categories per user
);

-- =====================================================
-- 5. INSTALLMENT_TRANSACTIONS (Master Installment Data)
-- =====================================================
CREATE TABLE installment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    total_amount DECIMAL(15,2) NOT NULL CHECK (total_amount > 0),
    monthly_amount DECIMAL(15,2) NOT NULL CHECK (monthly_amount > 0),
    count INTEGER NOT NULL CHECK (count > 1),
    start_date DATE NOT NULL,
    description TEXT NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_monthly_amount CHECK (monthly_amount * count = total_amount)
);

-- =====================================================
-- 6. TRANSACTIONS (All Financial Transactions)
-- =====================================================
CREATE TYPE transaction_type AS ENUM ('income', 'expense', 'transfer');

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type transaction_type NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- References
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    source_account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    target_account_id UUID REFERENCES accounts(id) ON DELETE RESTRICT, -- for transfers
    installment_id UUID REFERENCES installment_transactions(id) ON DELETE SET NULL,
    
    -- Additional fields
    is_recurring BOOLEAN DEFAULT false,
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT chk_transfer_target CHECK (
        (type = 'transfer' AND target_account_id IS NOT NULL AND target_account_id != source_account_id) OR
        (type != 'transfer' AND target_account_id IS NULL)
    )
);

-- =====================================================
-- 7. INSTALLMENT_DETAILS (Individual Installment Payments)
-- =====================================================
CREATE TABLE installment_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    installment_transaction_id UUID NOT NULL REFERENCES installment_transactions(id) ON DELETE CASCADE,
    installment_number INTEGER NOT NULL CHECK (installment_number > 0),
    due_date DATE NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    is_paid BOOLEAN DEFAULT false,
    paid_date TIMESTAMP WITH TIME ZONE,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(installment_transaction_id, installment_number),
    
    CONSTRAINT chk_paid_consistency CHECK (
        (is_paid = true AND paid_date IS NOT NULL AND transaction_id IS NOT NULL) OR
        (is_paid = false AND paid_date IS NULL AND transaction_id IS NULL)
    )
);

-- =====================================================
-- 8. RECURRING_TRANSACTIONS (Future Feature)
-- =====================================================
CREATE TYPE recurrence_interval AS ENUM ('daily', 'weekly', 'monthly', 'yearly');

CREATE TABLE recurring_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type transaction_type NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    
    -- Recurrence settings
    interval_type recurrence_interval NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE, -- nullable for indefinite recurrence
    next_run_date DATE NOT NULL,
    
    -- References
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    source_account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    target_account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_recurring_transfer_target CHECK (
        (type = 'transfer' AND target_account_id IS NOT NULL) OR
        (type != 'transfer' AND target_account_id IS NULL)
    ),
    CONSTRAINT chk_end_date CHECK (end_date IS NULL OR end_date >= start_date)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Users
CREATE INDEX idx_users_email ON users(email);

-- Accounts
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE INDEX idx_accounts_type ON accounts(type);
CREATE INDEX idx_accounts_user_type ON accounts(user_id, type);

-- Categories
CREATE INDEX idx_categories_user_type ON categories(user_id, type);
CREATE INDEX idx_categories_type_active ON categories(type, is_active);

-- Transactions (most important for performance)
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_transactions_user_type ON transactions(user_id, type);
CREATE INDEX idx_transactions_source_account ON transactions(source_account_id);
CREATE INDEX idx_transactions_target_account ON transactions(target_account_id);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_installment ON transactions(installment_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date DESC);

-- Installment transactions
CREATE INDEX idx_installment_transactions_user ON installment_transactions(user_id);
CREATE INDEX idx_installment_transactions_account ON installment_transactions(source_account_id);

-- Installment details
CREATE INDEX idx_installment_details_transaction ON installment_details(installment_transaction_id);
CREATE INDEX idx_installment_details_due_date ON installment_details(due_date);
CREATE INDEX idx_installment_details_unpaid ON installment_details(is_paid, due_date) WHERE is_paid = false;

-- Recurring transactions
CREATE INDEX idx_recurring_transactions_user ON recurring_transactions(user_id);
CREATE INDEX idx_recurring_transactions_next_run ON recurring_transactions(next_run_date) WHERE is_active = true;

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE installment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE installment_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_transactions ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- User profiles policies
CREATE POLICY "Users can manage own profile" ON user_profiles FOR ALL USING (auth.uid() = user_id);

-- Accounts policies
CREATE POLICY "Users can manage own accounts" ON accounts FOR ALL USING (auth.uid() = user_id);

-- Categories policies
CREATE POLICY "Users can view system categories" ON categories FOR SELECT USING (user_id IS NULL);
CREATE POLICY "Users can manage own categories" ON categories FOR ALL USING (auth.uid() = user_id);

-- Transactions policies
CREATE POLICY "Users can manage own transactions" ON transactions FOR ALL USING (auth.uid() = user_id);

-- Installment transactions policies
CREATE POLICY "Users can manage own installments" ON installment_transactions FOR ALL USING (auth.uid() = user_id);

-- Installment details policies
CREATE POLICY "Users can manage own installment details" ON installment_details FOR ALL USING (
    EXISTS (
        SELECT 1 FROM installment_transactions it 
        WHERE it.id = installment_details.installment_transaction_id 
        AND it.user_id = auth.uid()
    )
);

-- Recurring transactions policies
CREATE POLICY "Users can manage own recurring transactions" ON recurring_transactions FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_installment_transactions_updated_at BEFORE UPDATE ON installment_transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_installment_details_updated_at BEFORE UPDATE ON installment_details FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_recurring_transactions_updated_at BEFORE UPDATE ON recurring_transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMPUTED COLUMNS TRIGGER (for credit cards)
-- =====================================================

CREATE OR REPLACE FUNCTION update_credit_card_available_limit()
RETURNS TRIGGER AS $$
BEGIN
    -- Only for credit cards, calculate available limit
    IF NEW.type = 'credit' THEN
        -- Available limit = credit_limit - current_balance
        -- Note: balance for credit cards represents debt
        NEW.balance = LEAST(NEW.balance, NEW.credit_limit);
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_credit_card_limits 
    BEFORE INSERT OR UPDATE ON accounts 
    FOR EACH ROW 
    WHEN (NEW.type = 'credit')
    EXECUTE FUNCTION update_credit_card_available_limit();

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- Account summary with computed fields
CREATE VIEW account_summary AS
SELECT 
    a.*,
    CASE 
        WHEN a.type = 'credit' THEN a.credit_limit - a.balance
        ELSE a.balance
    END as available_amount,
    CASE 
        WHEN a.type = 'credit' THEN a.balance
        ELSE 0
    END as debt_amount
FROM accounts a
WHERE a.is_active = true;

-- Transaction summary with account and category names
CREATE VIEW transaction_summary AS
SELECT 
    t.*,
    sa.name as source_account_name,
    sa.type as source_account_type,
    ta.name as target_account_name,
    ta.type as target_account_type,
    c.name as category_name,
    c.icon as category_icon,
    c.color as category_color
FROM transactions t
LEFT JOIN accounts sa ON t.source_account_id = sa.id
LEFT JOIN accounts ta ON t.target_account_id = ta.id
LEFT JOIN categories c ON t.category_id = c.id;

-- Installment summary with progress
CREATE VIEW installment_summary AS
SELECT 
    it.*,
    a.name as account_name,
    COUNT(id_paid.id) as paid_count,
    COUNT(id_total.id) as total_count,
    COALESCE(SUM(CASE WHEN id_paid.is_paid THEN id_paid.amount ELSE 0 END), 0) as paid_amount,
    it.total_amount - COALESCE(SUM(CASE WHEN id_paid.is_paid THEN id_paid.amount ELSE 0 END), 0) as remaining_amount,
    MIN(CASE WHEN NOT id_total.is_paid THEN id_total.due_date END) as next_due_date
FROM installment_transactions it
LEFT JOIN accounts a ON it.source_account_id = a.id
LEFT JOIN installment_details id_total ON it.id = id_total.installment_transaction_id
LEFT JOIN installment_details id_paid ON it.id = id_paid.installment_transaction_id AND id_paid.is_paid = true
GROUP BY it.id, a.name;

-- =====================================================
-- INITIAL DATA SEEDING
-- =====================================================

-- Default income categories
INSERT INTO categories (id, user_id, type, name, icon, color, sort_order) VALUES
(uuid_generate_v4(), NULL, 'income', 'Maaş', 'work', '#00FFB3', 1),
(uuid_generate_v4(), NULL, 'income', 'Freelance', 'laptop', '#00FFB3', 2),
(uuid_generate_v4(), NULL, 'income', 'Yatırım', 'trending_up', '#00FFB3', 3),
(uuid_generate_v4(), NULL, 'income', 'Kira Geliri', 'home', '#00FFB3', 4),
(uuid_generate_v4(), NULL, 'income', 'Hediye', 'card_giftcard', '#00FFB3', 5),
(uuid_generate_v4(), NULL, 'income', 'Diğer', 'category', '#00FFB3', 99);

-- Default expense categories
INSERT INTO categories (id, user_id, type, name, icon, color, sort_order) VALUES
(uuid_generate_v4(), NULL, 'expense', 'Yemek', 'restaurant', '#FF6B6B', 1),
(uuid_generate_v4(), NULL, 'expense', 'Ulaşım', 'directions_car', '#FF6B6B', 2),
(uuid_generate_v4(), NULL, 'expense', 'Alışveriş', 'shopping_bag', '#FF6B6B', 3),
(uuid_generate_v4(), NULL, 'expense', 'Faturalar', 'receipt_long', '#FF6B6B', 4),
(uuid_generate_v4(), NULL, 'expense', 'Eğlence', 'movie', '#FF6B6B', 5),
(uuid_generate_v4(), NULL, 'expense', 'Sağlık', 'local_hospital', '#FF6B6B', 6),
(uuid_generate_v4(), NULL, 'expense', 'Eğitim', 'school', '#FF6B6B', 7),
(uuid_generate_v4(), NULL, 'expense', 'Seyahat', 'flight', '#FF6B6B', 8),
(uuid_generate_v4(), NULL, 'expense', 'Diğer', 'category', '#FF6B6B', 99);

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE accounts IS 'Polymorphic table for credit cards, debit cards, and cash accounts';
COMMENT ON COLUMN accounts.balance IS 'For credit cards: current debt. For debit/cash: available balance';
COMMENT ON COLUMN accounts.credit_limit IS 'Only for credit cards: maximum credit limit';

COMMENT ON TABLE transactions IS 'All financial transactions: income, expense, and transfers';
COMMENT ON COLUMN transactions.target_account_id IS 'Only used for transfer transactions';
COMMENT ON COLUMN transactions.installment_id IS 'Links to installment_transactions for installment payments';

COMMENT ON TABLE installment_transactions IS 'Master record for installment purchases';
COMMENT ON TABLE installment_details IS 'Individual installment payments, linked to transactions when paid';

COMMENT ON VIEW account_summary IS 'Accounts with computed available amounts and debt';
COMMENT ON VIEW transaction_summary IS 'Transactions with joined account and category information';
COMMENT ON VIEW installment_summary IS 'Installment transactions with payment progress'; 