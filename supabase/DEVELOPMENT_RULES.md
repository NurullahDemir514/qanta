# Qanta Database Development Rules
**🚨 CRITICAL: Read before making any database changes**

## ❌ NEVER DO THESE
1. **Delete migration files** - They're applied to production
2. **Modify existing migrations** - Will cause schema mismatch
3. **Run `supabase db reset` on production** - Will destroy all data
4. **Push untested migrations** - Test locally first
5. **Ignore migration errors** - Fix immediately

## ✅ SAFE PRACTICES

### For New Features
```bash
# 1. Create new migration
supabase migration new feature_name

# 2. Write SQL changes in the new file
# 3. Test locally (if Docker available)
supabase db reset
supabase db push

# 4. Push to production only after testing
supabase db push
```

### For Bug Fixes
```bash
# 1. Create new migration (don't modify existing)
supabase migration new fix_bug_name

# 2. Write corrective SQL
# 3. Test thoroughly
# 4. Push to production
```

### For Schema Changes
```bash
# 1. Always create new migration
supabase migration new alter_table_name

# 2. Use safe SQL practices:
#    - Add columns with DEFAULT values
#    - Use IF EXISTS for drops
#    - Add constraints carefully
```

## 🔒 PRODUCTION SAFETY

### Before Any Database Change
- [ ] Create backup documentation
- [ ] Test migration locally
- [ ] Review SQL for destructive operations
- [ ] Ensure rollback plan exists
- [ ] Commit code changes first

### Emergency Rollback
If something goes wrong:
1. **DON'T PANIC**
2. Check `supabase/MIGRATION_BACKUP.md`
3. Restore missing migrations from backup
4. Contact team if data corruption suspected

## 📝 MIGRATION NAMING CONVENTION
```
YYYYMMDDHHMMSS_descriptive_name.sql

Examples:
20250616163000_add_user_preferences.sql
20250616163100_fix_transaction_constraint.sql
20250616163200_update_installment_logic.sql
```

## 🧪 LOCAL DEVELOPMENT
```bash
# Safe local reset (only affects local Docker)
supabase stop
supabase start
supabase db reset

# This will:
# - Destroy local database
# - Recreate from migrations
# - Safe for development
```

## 📞 EMERGENCY CONTACTS
- Database issues: Check GitHub issues
- Migration problems: Restore from backup
- Data corruption: **STOP ALL OPERATIONS**

## Last Updated: 2025-06-16 