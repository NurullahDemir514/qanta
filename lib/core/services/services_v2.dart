// QANTA v2 Services - Barrel Export File
// This file exports all the new service classes that work with our QANTA v2 database schema

// Core services - Temporarily disabled for Firebase migration
// export 'account_service_v2.dart';
// export 'transaction_service_v2.dart';
// export 'category_service_v2.dart';
// export 'installment_service_v2.dart';
// export 'income_service.dart';
// export 'transfer_service.dart';
// export 'budget_service.dart';

// Firebase services
export 'firebase_auth_service.dart';
export 'firebase_firestore_service.dart';
export 'firebase_transaction_service.dart';
export 'firebase_credit_card_service.dart';
export 'firebase_cash_account_service.dart';
export 'firebase_debit_card_service.dart';
export 'profile_image_service.dart';

// Legacy services (for backward compatibility during migration)
// export 'supabase_service.dart'; // Temporarily disabled for Firebase migration
// export 'profile_image_service.dart'; // Temporarily disabled for Firebase migration

// import 'package:supabase_flutter/supabase_flutter.dart'; // Temporarily disabled for Firebase migration
// import '../supabase_client.dart'; // Temporarily disabled for Firebase migration
