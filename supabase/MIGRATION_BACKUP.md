# Qanta Database Migration Backup
**Created:** 2025-06-16  
**Purpose:** Backup of all applied migrations to prevent data loss

## Applied Migrations (Production)

### Core Schema & Functions
- `20250101000000_qanta_v2_schema.sql` - Main database schema (tables, constraints)
- `20250101000001_qanta_v2_functions.sql` - Core database functions (CRUD operations)
- `20250101000002_fix_auth_integration.sql` - Authentication integration fixes
- `20250101000003_fix_installment_constraints.sql` - Installment table constraints

### Installment System Fixes (2025-06-16)
- `20250116000000_fix_monthly_amount_constraint.sql` - Monthly amount constraint fix
- `20250116000001_fix_installment_transaction_link.sql` - Transaction-installment linking
- `20250116000002_fix_installment_deletion.sql` - Installment deletion logic
- `20250616155621_fix_installment_deletion_v2.sql` - Enhanced deletion with proper refund
- `20250616160343_fix_monthly_amount_precision.sql` - Decimal precision handling
- `20250616160622_fix_installment_refund_calculation.sql` - Correct refund calculation
- `20250616161721_fix_installment_credit_limit.sql` - Credit card limit deduction fix
- `20250616162020_fix_installment_refund_credit_card.sql` - Credit card refund logic

### Empty/Reverted Migrations
- `20250616134058_revert_installment_first_payment_date.sql` - (Empty - reverted)

## ⚠️ CRITICAL: DO NOT DELETE THESE MIGRATIONS
These migrations are applied to production database. Deleting them will cause:
- Database schema mismatch
- Data corruption
- Application crashes

## Safe Development Practices
1. Always create NEW migrations for changes
2. Never modify existing migration files
3. Test migrations in local environment first
4. Use `supabase db reset` for local development only
5. Keep this backup file updated

## Recovery Instructions
If migrations are accidentally deleted:
1. Restore from this backup
2. Check migration status: `supabase migration list`
3. Apply missing migrations: `supabase db push`
4. Verify database integrity

## Last Updated
- Date: 2025-06-16
- Applied Migrations: 13 total
- Production Status: ✅ All applied successfully 