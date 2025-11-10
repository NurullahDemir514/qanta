# Referral Codes - Setup and Migration Guide

## Overview

Referral codes are automatically generated for users based on their user ID:
- **Format**: First 8 characters of user ID (uppercase)
- **Example**: User ID `rcyqEbFJHbYzfFsiC4XtQUN7sx92` → Referral Code `RCYQEBFJ`

## Automatic Generation

### New Users
- Referral codes are automatically generated when:
  1. User registers (via `processReferralCode` Cloud Function)
  2. User document is created (via `handleReferralOnUserCreate`)

### Existing Users
- Run migration script to generate referral codes for existing users

## Migration Script

### Generate Referral Codes for All Users

```bash
cd functions
node scripts/generateReferralCodes.js
```

This script:
- ✅ Finds all users without referral codes
- ✅ Generates referral code (first 8 chars of user ID, uppercase)
- ✅ Updates user documents in Firestore
- ✅ Skips users who already have valid referral codes

### Check Referral Codes Status

```bash
cd functions
node scripts/checkReferralCodes.js
```

This script:
- ✅ Checks all users for referral codes
- ✅ Validates referral code format (8 characters)
- ✅ Validates referral code matches user ID prefix
- ✅ Reports users without codes or with invalid codes

## Cloud Functions

### 1. `processReferralCode`
- **Type**: HTTPS Callable Function
- **Purpose**: Process referral code when user enters it
- **Deployed**: ✅ Yes
- **Region**: us-central1

### 2. `handleReferralOnUserCreate`
- **Type**: Handler function (called by Auth trigger or manually)
- **Purpose**: Generate referral code when user is created
- **Status**: ⚠️ Not yet deployed as Auth trigger (requires v1 functions or manual call)

## Verification

### Check if Referral Codes are Generated

1. **Run check script**:
   ```bash
   cd functions
   node scripts/checkReferralCodes.js
   ```

2. **Check Firestore**:
   - Go to Firebase Console → Firestore
   - Check `users/{userId}` documents
   - Verify `referral_code` field exists and is 8 characters

3. **Test in App**:
   - Open app
   - Go to Profile → Referral Widget
   - Verify referral code is displayed

## Troubleshooting

### Users Without Referral Codes

If users don't have referral codes:
1. Run migration script: `node scripts/generateReferralCodes.js`
2. Check script output for errors
3. Verify service account has write permissions

### Invalid Referral Codes

If referral codes are invalid:
1. Run check script: `node scripts/checkReferralCodes.js`
2. Review users with invalid codes
3. Re-run migration script to fix invalid codes

### Referral Code Not Showing in App

1. Check user document in Firestore has `referral_code` field
2. Verify referral code is 8 characters
3. Check app logs for errors
4. Verify `ReferralService.getReferralCode()` is working

## Deployment

### Deploy Cloud Functions

```bash
cd functions
firebase deploy --only functions:processReferralCode
```

### Deploy Auth Trigger (Future)

Auth triggers require Firebase Functions v1. To add Auth trigger:
1. Create separate v1 function file
2. Use `functions.auth.user().onCreate()` trigger
3. Deploy with `firebase deploy --only functions:onUserCreated`

## Security

- ✅ Referral codes are read-only for users
- ✅ Only Cloud Functions can modify referral codes
- ✅ Referral code validation prevents self-referral
- ✅ Max 5 referrals per user
- ✅ Duplicate referral prevention

## Testing

### Test Referral Code Generation

1. Create test user
2. Check user document has `referral_code` field
3. Verify referral code format (8 characters, uppercase)
4. Test referral code lookup

### Test Referral Code Processing

1. Use test referral code
2. Enter code in app
3. Verify points are awarded
4. Check referral stats are updated

