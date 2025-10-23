import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/theme_provider.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/profile_image_service.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../core/providers/profile_provider.dart';
import '../../modules/stocks/providers/stock_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/profile_section.dart';
import '../../shared/widgets/profile_item.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../settings/pages/privacy_policy_page.dart';
import '../settings/pages/terms_of_service_page.dart';
import '../settings/pages/support_page.dart';
import '../settings/pages/change_password_page.dart';
import '../settings/pages/faq_page.dart';
import '../../core/services/reminder_service.dart';
import '../../core/services/analytics_consent_service.dart';
import '../../core/services/premium_service.dart';
import 'pages/premium_test_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  bool _analyticsConsent = false;
  bool _isLoadingConsent = true;

  @override
  void initState() {
    super.initState();
    // Bucket'ın var olduğundan emin ol
    _ensureBucketExists();
    // Analytics consent'i yükle
    _loadAnalyticsConsent();
    // Focus'u temizle ve klavyeyi kapat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _loadAnalyticsConsent() async {
    try {
      final consent = await AnalyticsConsentService.isConsentGiven();
      if (mounted) {
        setState(() {
          _analyticsConsent = consent;
          _isLoadingConsent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyticsConsent = false;
          _isLoadingConsent = false;
        });
      }
    }
  }

  Future<void> _ensureBucketExists() async {
    try {
      await ProfileImageService.instance.ensureBucketExists();
    } catch (e) {}
  }

  Future<void> _showImageSourceActionSheet() async {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: Text(
              AppLocalizations.of(context)!.camera,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: Text(
              AppLocalizations.of(context)!.gallery,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
              ),
            ),
          ),
          if (ProfileImageService.instance.getProfileImageUrl() != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _deleteProfileImage();
              },
              child: Text(
                AppLocalizations.of(context)!.deletePhoto,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: GoogleFonts.inter(
              fontSize: 20, 
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      debugPrint('📸 ProfileScreen._pickImage() - Starting image picker');
      debugPrint('📸 Source: $source');

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      debugPrint('📸 Image picker result: ${image?.path}');

      if (image != null) {
        debugPrint('📸 Image selected, starting upload...');
        setState(() {
          _isUploadingImage = true;
        });

        final imageFile = File(image.path);
        debugPrint('📸 File created: ${imageFile.path}');

        final newImageUrl = await ProfileImageService.instance
            .uploadProfileImage(imageFile.path);

        debugPrint('📸 Upload result: $newImageUrl');

        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });

          // ProfileProvider'ı güncelle
          final profileProvider = Provider.of<ProfileProvider>(
            context,
            listen: false,
          );
          await profileProvider.updateProfileImage(newImageUrl);

          debugPrint('📸 ProfileProvider updated successfully');
        }
      } else {
        debugPrint('📸 No image selected');
      }
    } catch (e) {
      debugPrint('❌ ProfileScreen._pickImage() error: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.photoUploadError(e.toString()),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      await ProfileImageService.instance.deleteProfileImage();

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        // ProfileProvider'ı güncelle
        final profileProvider = Provider.of<ProfileProvider>(
          context,
          listen: false,
        );
        await profileProvider.updateProfileImage(null);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.photoDeleteError(e.toString()),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Focus'u temizle ve klavyeyi kapat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final userName = profileProvider.userName ?? l10n.defaultUserName;
        final userEmail = profileProvider.userEmail ?? '';
        final profileImageUrl = profileProvider.profileImageUrl;

        return AppPageScaffold(
          title: l10n.profile,
          onRefresh: () async {
            await profileProvider.refresh();
          },
          body: SliverToBoxAdapter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double containerWidth = constraints.maxWidth * 1;
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      width: containerWidth,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF000000)
                            : const Color(0xFFFAFAFA),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(
                            context,
                            l10n,
                            userName,
                            userEmail,
                            profileImageUrl,
                          ),

                          const SizedBox(height: 24),
                          // Preferences Section
                          ProfileSection(
                            title: l10n.preferences,
                            children: [
                              Consumer<ThemeProvider>(
                                builder: (context, themeProvider, child) {
                                  return ProfileItem(
                                    icon: themeProvider.isDarkMode
                                        ? Icons.dark_mode_outlined
                                        : Icons.light_mode_outlined,
                                    title: l10n.theme,
                                    subtitle: themeProvider.isDarkMode
                                        ? l10n.darkMode
                                        : l10n.lightMode,
                                    onTap: null, // Switch ile kontrol edilecek
                                    trailing: _buildCustomToggle(
                                      value: themeProvider.isDarkMode,
                                      onChanged: (value) {
                                        themeProvider.toggleTheme();
                                      },
                                      isDark: Theme.of(context).brightness == Brightness.dark,
                                      onText: l10n.dark,
                                      offText: l10n.light,
                                    ),
                                  );
                                },
                              ),
                              Consumer<ThemeProvider>(
                                builder: (context, themeProvider, child) {
                                  return ProfileItem(
                                    icon: Icons.language_outlined,
                                    title: l10n.language,
                                    subtitle: themeProvider.isTurkish
                                        ? l10n.turkish
                                        : l10n.english,
                                    onTap: () => _showLanguagePicker(
                                      context,
                                      themeProvider,
                                      l10n,
                                    ),
                                  );
                                },
                              ),
                              Consumer<ThemeProvider>(
                                builder: (context, themeProvider, child) {
                                  return ProfileItem(
                                    icon: Icons.monetization_on_outlined,
                                    title: l10n.currency,
                                    subtitle: CurrencyUtils.getDisplayName(
                                      themeProvider.currency,
                                      themeProvider.locale.languageCode,
                                    ),
                                    onTap: () => _showCurrencyPicker(
                                      context,
                                      themeProvider,
                                      l10n,
                                    ),
                                  );
                                },
                              ),
                              // Analytics Consent Toggle
                              ProfileItem(
                                icon: Icons.analytics_outlined,
                                title: l10n.anonymousDataCollection,
                                subtitle: l10n.anonymousDataCollectionSubtitle,
                                onTap: null, // Switch ile kontrol edilecek
                                trailing: _isLoadingConsent
                                    ? const SizedBox(
                                        width: 80,
                                        height: 36,
                                        child: Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      )
                                    : _buildCustomToggle(
                                        value: _analyticsConsent,
                                        onChanged: (value) async {
                                          setState(() {
                                            _analyticsConsent = value;
                                          });
                                          await AnalyticsConsentService.saveConsent(value);
                                          
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  value
                                                      ? l10n.analyticsEnabled
                                                      : l10n.analyticsDisabled,
                                                  style: GoogleFonts.inter(),
                                                ),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        isDark: Theme.of(context).brightness == Brightness.dark,
                                        onText: l10n.on,
                                        offText: l10n.off,
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Premium Management Section
                          Consumer<PremiumService>(
                            builder: (context, premiumService, child) {
                              return ProfileSection(
                                title: l10n.premiumStatus,
                                children: [
                                  if (premiumService.isPremium) ...[
                                    // Premium Aktif Durumu
                                    ProfileItem(
                                      icon: Icons.workspace_premium_rounded,
                                      title: l10n.premiumActive,
                                      subtitle: l10n.premiumActiveDescription,
                                      onTap: null, // Tıklanamaz, sadece durum gösterisi
                                    ),
                                    // Aboneliği Yönet Butonu
                                    ProfileItem(
                                      icon: Icons.manage_accounts_outlined,
                                      title: l10n.manageSubscription,
                                      subtitle: l10n.manageSubscriptionDescription,
                                      onTap: () async {
                                        final url = Uri.parse(
                                          'https://play.google.com/store/account/subscriptions',
                                        );
                                        try {
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(
                                              url,
                                              mode: LaunchMode.externalApplication,
                                            );
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    l10n.playStoreError,
                                                    style: GoogleFonts.inter(),
                                                  ),
                                                  backgroundColor: const Color(0xFFFF4C4C),
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${l10n.error}: $e',
                                                  style: GoogleFonts.inter(),
                                                ),
                                                backgroundColor: const Color(0xFFFF4C4C),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ] else ...[
                                    // Premium Değil - Satın Almaları Geri Yükle
                                    ProfileItem(
                                      icon: Icons.restore_outlined,
                                      title: l10n.restorePurchases,
                                      subtitle: l10n.restorePurchasesDescription,
                                      onTap: () async {
                                        // Loading göster
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? const Color(0xFF1C1C1E)
                                                    : Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const CircularProgressIndicator(
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Color(0xFFFFD700),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    l10n.checkingPurchases,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      color: Theme.of(context).brightness == Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                      decoration: TextDecoration.none,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );

                                        try {
                                          await premiumService.restorePurchases();
                                          
                                          // 2 saniye bekle (Google Play yanıt vermesi için)
                                          await Future.delayed(const Duration(seconds: 2));
                                          
                                          if (context.mounted) {
                                            Navigator.pop(context); // Close loading
                                            
                                            if (premiumService.isPremium) {
                                              // Başarılı
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '✅ ${l10n.premiumRestored}',
                                                    style: GoogleFonts.inter(),
                                                  ),
                                                  backgroundColor: const Color(0xFF4CAF50),
                                                  duration: const Duration(seconds: 3),
                                                ),
                                              );
                                            } else {
                                              // Aktif abonelik bulunamadı
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'ℹ️ ${l10n.noActivePremium}',
                                                    style: GoogleFonts.inter(),
                                                  ),
                                                  backgroundColor: const Color(0xFF007AFF),
                                                  duration: const Duration(seconds: 3),
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            Navigator.pop(context); // Close loading
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '❌ ${l10n.error}: $e',
                                                  style: GoogleFonts.inter(),
                                                ),
                                                backgroundColor: const Color(0xFFFF4C4C),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Security Section
                          ProfileSection(
                            title: l10n.security,
                            children: [
                              ProfileItem(
                                icon: Icons.lock_outline,
                                title: l10n.changePassword,
                                onTap: () => _showChangePasswordDialog(context),
                              ),
                              ProfileItem(
                                icon: Icons.policy_outlined,
                                title: l10n.privacyPolicy,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PrivacyPolicyPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Support Section
                          ProfileSection(
                            title: l10n.support,
                            children: [
                              ProfileItem(
                                icon: Icons.help_outline,
                                title: l10n.contactSupport,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SupportPage(),
                                    ),
                                  );
                                },
                              ),
                              ProfileItem(
                                icon: Icons.description_outlined,
                                title: l10n.termsOfService,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TermsOfServicePage(),
                                    ),
                                  );
                                },
                              ),
                              ProfileItem(
                                icon: Icons.help_outline,
                                title: AppLocalizations.of(
                                  context,
                                )!.frequentlyAskedQuestions,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FAQPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          
                          // Debug Section (sadece debug modda görünür)
                          if (kDebugMode) ...[
                            const SizedBox(height: 24),
                            ProfileSection(
                              title: '🧪 Debug Tools',
                              children: [
                                ProfileItem(
                                  icon: Icons.science_outlined,
                                  title: 'Premium Test',
                                  subtitle: 'Reklamsız sürümü test et',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PremiumTestPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          _buildLogoutButton(context, l10n),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AppLocalizations l10n,
    String userName,
    String userEmail,
    String? profileImageUrl,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: isDark
            ? Border.all(color: const Color(0xFF38383A), width: 0.5)
            : null,
      ),
      child: Row(
        children: [
          // Profile Avatar with loading state
          Stack(
            children: [
              ProfileAvatar(
                imageUrl: profileImageUrl,
                userName: userName,
                size: 56,
                showBorder: false,
                onTap: _isUploadingImage ? null : _showImageSourceActionSheet,
              ),
              if (_isUploadingImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: isDark
            ? Border.all(color: const Color(0xFF38383A), width: 0.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // ProfileProvider'ı temizle
            final profileProvider = Provider.of<ProfileProvider>(
              context,
              listen: false,
            );
            await profileProvider.clearProfile();
            // Reminderları temizle
            await ReminderService.clearAllRemindersForCurrentUser();
            await FirebaseAuthService.signOut();
            if (context.mounted) {
              context.go('/login');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.logout,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    ThemeProvider themeProvider,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.selectCurrency,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...Currency.values.map(
              (currency) => ListTile(
                leading: Text(
                  currency.symbol,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(
                  CurrencyUtils.getDisplayName(
                    currency,
                    themeProvider.locale.languageCode,
                  ),
                  style: GoogleFonts.inter(fontSize: 16),
                ),
                trailing: themeProvider.currency == currency
                    ? const Icon(Icons.check, color: Color(0xFF6D6D70))
                    : null,
                onTap: () {
                  themeProvider.setCurrency(currency);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    ThemeProvider themeProvider,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.language,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
              title: Text(l10n.turkish, style: GoogleFonts.inter(fontSize: 16)),
              trailing: themeProvider.isTurkish
                  ? const Icon(Icons.check, color: Color(0xFF6D6D70))
                  : null,
              onTap: () {
                if (!themeProvider.isTurkish) {
                  themeProvider.toggleLanguage();
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text(l10n.english, style: GoogleFonts.inter(fontSize: 16)),
              trailing: !themeProvider.isTurkish
                  ? const Icon(Icons.check, color: Color(0xFF6D6D70))
                  : null,
              onTap: () {
                if (themeProvider.isTurkish) {
                  themeProvider.toggleLanguage();
                }
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const ChangePasswordPage()),
    );
  }

  Widget _buildCustomToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    String? onText,
    String? offText,
  }) {
    final onLabel = onText ?? 'ON';
    final offLabel = offText ?? 'OFF';
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF2F2F7),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3A3A3C)
              : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // OFF Button
          GestureDetector(
            onTap: () {
              if (value) {
                HapticFeedback.lightImpact();
                onChanged(false);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: !value
                    ? const Color(0xFF6D6D70) // Gri
                    : Colors.transparent,
                boxShadow: !value
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6D6D70).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: !value
                      ? Colors.white
                      : isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : const Color(0xFF6D6D70),
                  letterSpacing: 0.2,
                ),
                child: Text(offLabel),
              ),
            ),
          ),
          // ON Button
          GestureDetector(
            onTap: () {
              if (!value) {
                HapticFeedback.lightImpact();
                onChanged(true);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: value
                    ? const Color(0xFF2E7D32) // Rich Green (same as stocks toggle)
                    : Colors.transparent,
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: value
                      ? Colors.white
                      : isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : const Color(0xFF6D6D70),
                  letterSpacing: 0.2,
                ),
                child: Text(onLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }

}


