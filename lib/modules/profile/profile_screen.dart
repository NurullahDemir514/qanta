import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/theme_provider.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/profile_image_service.dart';
import '../../core/services/quick_note_notification_service.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../core/providers/profile_provider.dart';
import '../../shared/models/account_model.dart';
import '../../shared/models/transaction_model_v2.dart';
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Bucket'ın var olduğundan emin ol
    _ensureBucketExists();
  }

  Future<void> _ensureBucketExists() async {
    try {
      await ProfileImageService.instance.ensureBucketExists();
    } catch (e) {
    }
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
              'Kamera',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: Text(
              'Galeri',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w400,
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
                'Fotoğrafı Sil',
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
            'İptal',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final imageFile = File(image.path);
        final newImageUrl = await ProfileImageService.instance
            .uploadProfileImage(imageFile.path);

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
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf yüklenirken hata oluştu: $e'),
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
            content: Text('Fotoğraf silinirken hata oluştu: $e'),
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
                    return Container(
                      width: containerWidth,
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
                                        ? Icons.light_mode_outlined
                                        : Icons.dark_mode_outlined,
                                    title: l10n.theme,
                                    subtitle: themeProvider.isDarkMode
                                        ? l10n.darkMode
                                        : l10n.lightMode,
                                    onTap: () => _showThemePicker(
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
                              FutureBuilder<bool>(
                                future:
                                    QuickNoteNotificationService.isEnabled(),
                                builder: (context, snapshot) {
                                  final isEnabled = snapshot.data ?? false;
                                  return ProfileItem(
                                    icon: Icons.edit_note_outlined,
                                    title: 'Hızlı Notlar',
                                    subtitle:
                                        'Anında not alma için kalıcı bildirim',
                                    trailing: Switch(
                                      value: isEnabled,
                                      onChanged: (value) async {
                                        final success =
                                            await QuickNoteNotificationService.setEnabled(
                                              value,
                                            );
                                        if (success) {
                                          setState(() {});
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                value
                                                    ? 'Hızlı notlar bildirimi açıldı'
                                                    : 'Hızlı notlar bildirimi kapatıldı',
                                              ),
                                              backgroundColor: value
                                                  ? Colors.green
                                                  : Colors.orange,
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Bildirim izni gerekli! Lütfen ayarlardan açın.',
                                              ),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
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
                                title: 'Sık Sorulan Sorular',
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
      padding: const EdgeInsets.all(20),
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
                size: 64,
                showBorder: false,
                onTap: _isUploadingImage ? null : _showImageSourceActionSheet,
              ),
              if (_isUploadingImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(32),
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
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
            profileProvider.clearProfile();
            // Reminderları temizle
            await ReminderService.clearAllRemindersForCurrentUser();
            await FirebaseAuthService.signOut();
            if (context.mounted) {
              context.go('/onboarding');
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

  void _showThemePicker(
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
              l10n.theme,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: Text(
                l10n.lightMode,
                style: GoogleFonts.inter(fontSize: 16),
              ),
              trailing: !themeProvider.isDarkMode
                  ? const Icon(Icons.check, color: Color(0xFF6D6D70))
                  : null,
              onTap: () {
                if (themeProvider.isDarkMode) {
                  themeProvider.toggleTheme();
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: Text(
                l10n.darkMode,
                style: GoogleFonts.inter(fontSize: 16),
              ),
              trailing: themeProvider.isDarkMode
                  ? const Icon(Icons.check, color: Color(0xFF6D6D70))
                  : null,
              onTap: () {
                if (!themeProvider.isDarkMode) {
                  themeProvider.toggleTheme();
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
}
