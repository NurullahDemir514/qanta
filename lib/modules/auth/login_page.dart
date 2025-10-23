import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/profile_image_service.dart';
import '../../core/services/image_cache_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/qanta_logo.dart';
import '../../core/services/reminder_service.dart';
import '../../core/firebase_client.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../modules/stocks/providers/stock_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/cash_account_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _preloadUserData() async {
    try {
      // 🚀 V2 PROVIDER: Modern unified data loading with cache
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);

      // StockProvider'ı set et (eğer henüz set edilmemişse)
      if (!providerV2.hasStockProvider) {
        final stockProvider = Provider.of<StockProvider>(
          context,
          listen: false,
        );
        providerV2.setStockProvider(stockProvider);
      }

      // Cache'li veri yükleme (10 dakika cache süresi)
      // Kritik verileri paralel yükle
      await Future.wait([
        providerV2.loadAllData(forceRefresh: false),
        // Hisse pozisyonlarını ayrı yükle
        _loadStockPositionsAsync(providerV2),
        // Profil verilerini yükle
        _loadProfileDataAsync(),
      ]);

      // Hisse verilerini yükle ve fiyatları güncelle
      try {
        final stockProvider = Provider.of<StockProvider>(
          context,
          listen: false,
        );
        final userId = FirebaseManager.currentUser?.uid;

        if (userId != null) {
          // Önce kullanıcının hisselerini yükle (daha hızlı)
          await stockProvider
              .loadWatchedStocks(userId)
              .timeout(
                const Duration(seconds: 2),
                onTimeout: () {
                  debugPrint('⚠️ Hisse yükleme timeout');
                },
              );

          // Eğer hisse varsa fiyatları güncelle (daha hızlı)
          if (stockProvider.watchedStocks.isNotEmpty) {
            await stockProvider.updateRealTimePricesSilently().timeout(
              const Duration(seconds: 3), // Daha hızlı
              onTimeout: () {
                // Hisse fiyat güncelleme timeout - sessizce devam et
              },
            );
          } else {
            debugPrint('ℹ️ Kullanıcının takip ettiği hisse yok');
          }
        }
      } catch (e) {
        // Hisse verileri yüklenemezse devam et
        debugPrint('❌ Hisse verileri yüklenemedi: $e');
      }

      // Real-time listeners'ı kur
      providerV2.setupRealTimeListeners();
    } catch (e) {
      // Kritik veri yükleme hatası olsa bile home'a git, orada tekrar denenecek
      debugPrint('❌ Veri ön yükleme hatası: $e');
    }
  }

  /// Hisse pozisyonlarını asenkron yükle
  Future<void> _loadStockPositionsAsync(UnifiedProviderV2 providerV2) async {
    try {
      await providerV2.loadStockPositions();
      debugPrint('✅ Hisse pozisyonları ön yüklendi');
    } catch (e) {
      debugPrint('⚠️ Hisse pozisyonları yüklenemedi: $e');
    }
  }

  /// Profil verilerini asenkron yükle
  Future<void> _loadProfileDataAsync() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.refresh();
      debugPrint('✅ Profil verileri ön yüklendi');
    } catch (e) {
      debugPrint('⚠️ Profil verileri yüklenemedi: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuthService.signInWithGoogle();

      if (credential.user != null && mounted) {
        // Clear all caches and refresh profile data for existing user
        await _clearAllCachesAndRefreshProfile();
        
        await ReminderService.clearAllRemindersForCurrentUser();

        // Kullanıcı verilerini önceden yükle
        await _preloadUserData();

        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        debugPrint('🔴 Google Sign In Error: $e');
        
        final errorString = e.toString().toLowerCase();
        
        // User cancelled, don't show error
        if (errorString.contains('cancelled') || errorString.contains('canceled') ||
            errorString.contains('user_cancelled') || errorString.contains('sign_in_cancelled')) {
          return;
        }
        
        String errorMessage = l10n.googleSignInError;

        // Handle specific errors
        if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = l10n.networkError;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuthService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential.user != null && mounted) {
        // Clear all caches and refresh profile data for existing user
        await _clearAllCachesAndRefreshProfile();
        
        await ReminderService.clearAllRemindersForCurrentUser();

        // Kullanıcı verilerini önceden yükle
        await _preloadUserData();

        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        debugPrint('🔴 Login Error: $e');
        
        String errorMessage = l10n.invalidCredentials; // Default to invalid credentials
        final errorString = e.toString().toLowerCase();

        // Handle specific auth errors
        if (errorString.contains('email_not_confirmed') || 
            errorString.contains('email not confirmed')) {
          errorMessage = l10n.emailNotConfirmed;
        } else if (errorString.contains('invalid_credentials') || 
                   errorString.contains('invalid login credentials') ||
                   errorString.contains('invalid email') ||
                   errorString.contains('invalid password') ||
                   errorString.contains('wrong-password') ||
                   errorString.contains('wrong password') ||
                   errorString.contains('user-not-found') ||
                   errorString.contains('user not found') ||
                   errorString.contains('no user record')) {
          errorMessage = l10n.invalidCredentials;
        } else if (errorString.contains('too_many_requests') || 
                   errorString.contains('too-many-requests') ||
                   errorString.contains('too many')) {
          errorMessage = l10n.tooManyRequests;
        } else if (errorString.contains('network') || 
                   errorString.contains('connection')) {
          errorMessage = l10n.networkError;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Clear all caches and refresh profile data for existing user
  Future<void> _clearAllCachesAndRefreshProfile() async {
    try {
      debugPrint('🧹 Clearing all caches for existing user...');
      
      // 1. Clear all provider data
      final unifiedProvider = Provider.of<UnifiedProviderV2>(context, listen: false);
      await unifiedProvider.clearAllData();
      
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      await stockProvider.clearAllData();
      
      final cashProvider = Provider.of<CashAccountProvider>(context, listen: false);
      cashProvider.clear();
      
      // 2. Clear profile provider and refresh
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.clearProfile();
      await profileProvider.refresh(); // Refresh with new user data
      
      // 3. Clear all caches
      await ProfileImageService.instance.clearAllData();
      await ImageCacheService.instance.clearCache();
      
      // 4. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // 5. Clear Flutter image cache
      imageCache.clear();
      imageCache.clearLiveImages();
      
      // 6. Clear temporary files
      await _clearTemporaryFiles();
      
      debugPrint('✅ All caches cleared for existing user');
    } catch (e) {
      debugPrint('❌ Error clearing caches for existing user: $e');
    }
  }

  /// Clear temporary files
  Future<void> _clearTemporaryFiles() async {
    try {
      // App documents directory'yi temizle
      final appDocDir = await getApplicationDocumentsDirectory();
      if (await appDocDir.exists()) {
        final files = await appDocDir.list().toList();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          } else if (file is Directory) {
            await file.delete(recursive: true);
          }
        }
      }
      
      // Cache directory'yi temizle
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        final files = await cacheDir.list().toList();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          } else if (file is Directory) {
            await file.delete(recursive: true);
          }
        }
      }
      
      debugPrint('✅ Temporary files cleared');
    } catch (e) {
      debugPrint('❌ Error clearing temporary files: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24.w.clamp(20.w, 32.w), 
              vertical: 16.h.clamp(12.h, 24.h),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 24.h),
                const QantaLogo.large(),
                SizedBox(height: 32.h),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    l10n.login,
                    style: GoogleFonts.inter(
                      fontSize: 28.sp.clamp(20.sp, 32.sp),
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    l10n.loginSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp.clamp(12.sp, 16.sp),
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                Container(
                  padding: EdgeInsets.all(20.w.clamp(16.w, 28.w)),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20.r.clamp(16.r, 24.r)),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.08),
                        blurRadius: 20.r.clamp(16.r, 28.r),
                        offset: Offset(0, 6.h.clamp(4.h, 10.h)),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.emailRequired;
                            }
                            if (!value.contains('@')) {
                              return l10n.emailInvalid;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.2,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.passwordRequired;
                            }
                            if (value.length < 6) {
                              return l10n.passwordTooShort;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              textStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp.clamp(14.sp, 18.sp),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isLoading ? null : _signIn,
                            child: _isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.login),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                // Divider with "veya" text
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        l10n.or,
                        style: GoogleFonts.inter(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                // Google Sign-In Button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 20.h,
                      width: 20.w,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.login,
                          size: 20.sp,
                          color: theme.colorScheme.onSurface,
                        );
                      },
                    ),
                    label: Text(
                      l10n.signInWithGoogle,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp.clamp(14.sp, 18.sp),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                      foregroundColor: theme.colorScheme.onSurface,
                      backgroundColor: theme.colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.dontHaveAccount,
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/register');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      child: Text(l10n.signUp),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

