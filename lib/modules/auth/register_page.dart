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
import '../../core/providers/unified_provider_v2.dart';
import '../../core/providers/profile_provider.dart';
import '../../modules/stocks/providers/stock_provider.dart';
import '../../core/providers/cash_account_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/qanta_logo.dart';
import '../../routes/app_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithGoogle() async {
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuthService.signInWithGoogle();

      if (credential.user != null) {
        // Clear caches in background (non-blocking)
        _clearAllCachesAndRefreshProfile().catchError((e) {
          debugPrint('❌ Error clearing caches in background: $e');
        });
        
        // Reset loading state before navigation
        if (mounted) {
          setState(() => _isLoading = false);
        }
        
        // Navigate to home using router directly (no context needed)
        // This prevents context deactivation errors
        AppRouter.router.go('/home');
        return;
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      
      // User cancelled, don't show error
      if (errorString.contains('cancelled') || errorString.contains('canceled') ||
          errorString.contains('user_cancelled') || errorString.contains('sign_in_cancelled')) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      
      // Show error message
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        debugPrint('🔴 Google Sign Up Error: $e');
        
        String errorMessage = l10n.googleSignUpError;

        // Handle specific errors
        if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = l10n.networkError;
        } else if (errorString.contains('email-already-in-use') || 
                   errorString.contains('email already in use') ||
                   errorString.contains('already_registered') ||
                   errorString.contains('already exists')) {
          errorMessage = l10n.userAlreadyRegistered;
        }

        // Show error message safely using post frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
            } catch (e) {
              debugPrint('⚠️ Could not show snackbar: $e');
            }
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuthService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        additionalData: {'displayName': _nameController.text.trim()},
      );

      if (credential.user != null) {
        // Clear caches in background (non-blocking)
        _clearAllCachesAndRefreshProfile().catchError((e) {
          debugPrint('❌ Error clearing caches in background: $e');
        });
        
        // Reset loading state before navigation
        if (mounted) {
          setState(() => _isLoading = false);
        }
        
        // Navigate to home using router directly (no context needed)
        // This prevents context deactivation errors
        AppRouter.router.go('/home');
        return;
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        debugPrint('🔴 Register Error: $e');
        
        String errorMessage = l10n.registerError;
        final errorString = e.toString().toLowerCase();

        // Handle specific auth errors
        if (errorString.contains('email_address_invalid') || 
            errorString.contains('invalid-email') ||
            errorString.contains('invalid email')) {
          errorMessage = l10n.invalidEmailAddress;
        } else if (errorString.contains('password_too_short') || 
                   errorString.contains('weak-password') ||
                   errorString.contains('weak password')) {
          errorMessage = l10n.passwordTooShortError;
        } else if (errorString.contains('user_already_registered') || 
                   errorString.contains('email-already-in-use') ||
                   errorString.contains('email already in use') ||
                   errorString.contains('user already registered') ||
                   errorString.contains('already exists') ||
                   errorString.contains('e-posta adresi zaten kullanımda')) {
          errorMessage = l10n.userAlreadyRegistered;
        } else if (errorString.contains('signup_disabled') ||
                   errorString.contains('signup disabled')) {
          errorMessage = l10n.signupDisabled;
        } else if (errorString.contains('network') || 
                   errorString.contains('connection')) {
          errorMessage = l10n.networkError;
        }

        // Show error message safely using post frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
            } catch (e) {
              debugPrint('⚠️ Could not show snackbar: $e');
            }
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Clear all caches and refresh profile data for new user
  /// This is called in background after navigation to avoid context issues
  Future<void> _clearAllCachesAndRefreshProfile() async {
    try {
      debugPrint('🧹 Clearing caches for new user (background)...');
      
      // Clear image caches (no context needed)
      try {
      await ProfileImageService.instance.clearAllData();
      await ImageCacheService.instance.clearCache();
        imageCache.clear();
        imageCache.clearLiveImages();
      } catch (e) {
        debugPrint('⚠️ Error clearing image caches: $e');
      }
      
      // Clear SharedPreferences (no context needed)
      try {
      final prefs = await SharedPreferences.getInstance();
        // Don't clear all - just clear user-specific data
        // await prefs.clear(); // Commented out to preserve app settings
      } catch (e) {
        debugPrint('⚠️ Error clearing SharedPreferences: $e');
      }
      
      // Clear temporary files (no context needed)
      await _clearTemporaryFiles();
      
      debugPrint('✅ Caches cleared for new user');
    } catch (e) {
      debugPrint('❌ Error clearing caches for new user: $e');
    }
    
    // Note: Provider clearing will happen automatically when home screen loads
    // The home screen will refresh all providers with new user data
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
                    l10n.signUp,
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
                    l10n.registerSubtitle,
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
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.fullName,
                            prefixIcon: const Icon(Icons.person_outlined),
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
                              return l10n.nameRequired;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12.h),
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
                        SizedBox(height: 12.h),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: l10n.confirmPassword,
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
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
                              return l10n.confirmPasswordRequired;
                            }
                            if (value != _passwordController.text) {
                              return l10n.passwordsDoNotMatch;
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
                            onPressed: _isLoading ? null : _signUp,
                            child: _isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.signUp),
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
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signUpWithGoogle,
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
                      l10n.signUpWithGoogle,
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
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.alreadyHaveAccount,
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14.sp.clamp(12.sp, 16.sp),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp.clamp(12.sp, 16.sp),
                        ),
                      ),
                      child: Text(l10n.login),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
