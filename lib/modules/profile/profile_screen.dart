import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/theme_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/profile_image_service.dart';
import '../../core/providers/unified_provider_v2.dart';
import '../../shared/models/account_model.dart';
import '../../shared/models/transaction_model_v2.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/profile_section.dart';
import '../../shared/widgets/profile_item.dart';
import '../../shared/widgets/profile_avatar.dart';

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
      debugPrint('❌ Error ensuring bucket exists: $e');
    }
  }

  Future<void> _showImageSourceActionSheet() async {
    final l10n = AppLocalizations.of(context)!;
    
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Profil Fotoğrafı',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        message: Text(
          'Profil fotoğrafınızı nasıl eklemek istiyorsunuz?',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
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
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
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
        await ProfileImageService.instance.uploadProfileImage(imageFile);

        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı güncellendi! ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil fotoğrafı silindi! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
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
    final user = SupabaseService.instance.currentUser;
    final userName = user?.userMetadata?['full_name'] as String? ?? l10n.defaultUserName;
    final userEmail = user?.email ?? '';

    return AppPageScaffold(
      title: l10n.profile,
        onRefresh: () async {
          // TODO: Refresh profile data
          await Future.delayed(const Duration(seconds: 1));
        },
      body: SliverList(
        delegate: SliverChildListDelegate([
              // Profile Header
              _buildProfileHeader(context, l10n, userName, userEmail),
              const SizedBox(height: 32),
              
              // Personal Information Section
              ProfileSection(
                title: l10n.personalInfo,
                children: [
                  ProfileItem(
                    icon: Icons.person_outline,
                    title: l10n.editProfile,
                    onTap: () {
                      // TODO: Navigate to edit profile
                    },
                  ),
                ],
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
                        subtitle: themeProvider.isDarkMode ? l10n.darkMode : l10n.lightMode,
                        onTap: () => _showThemePicker(context, themeProvider, l10n),
                      );
                    },
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return ProfileItem(
                        icon: Icons.language_outlined,
                        title: l10n.language,
                        subtitle: themeProvider.isTurkish ? l10n.turkish : l10n.english,
                        onTap: () => _showLanguagePicker(context, themeProvider, l10n),
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
                          themeProvider.locale.languageCode
                        ),
                        onTap: () => _showCurrencyPicker(context, themeProvider, l10n),
                      );
                    },
                  ),
                  ProfileItem(
                    icon: Icons.notifications_outlined,
                    title: l10n.notifications,
                    onTap: () {
                      // TODO: Navigate to notifications settings
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
                    onTap: () {
                      // TODO: Navigate to change password
                    },
                  ),
                  ProfileItem(
                    icon: Icons.fingerprint_outlined,
                    title: l10n.biometricAuth,
                    onTap: () {
                      // TODO: Navigate to biometric settings
                    },
                  ),
                  ProfileItem(
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacy,
                    onTap: () {
                      // TODO: Navigate to privacy settings
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
                      // TODO: Navigate to support
                    },
                  ),
                  ProfileItem(
                    icon: Icons.description_outlined,
                    title: l10n.termsOfService,
                    onTap: () {
                      // TODO: Navigate to terms
                    },
                  ),
                  ProfileItem(
                    icon: Icons.policy_outlined,
                    title: l10n.privacyPolicy,
                    onTap: () {
                      // TODO: Navigate to privacy policy
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // About Section
              ProfileSection(
                title: l10n.about,
                children: [
                  ProfileItem(
                    icon: Icons.info_outline,
                    title: l10n.version,
                    subtitle: '1.0.0',
                    onTap: null, // Non-interactive
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Test Data Section (Development only)
              ProfileSection(
                title: 'Test Verisi (Geliştirme)',
                children: [
                  ProfileItem(
                    icon: Icons.science_outlined,
                    title: 'Test Verisi Oluştur',
                    subtitle: 'V2 provider için örnek hesap ve işlemler',
                    onTap: () => _createTestData(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Logout Button
              _buildLogoutButton(context, l10n),
              const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations l10n, String userName, String userEmail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileImageUrl = ProfileImageService.instance.getProfileImageUrl();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
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
          ? Border.all(
              color: const Color(0xFF38383A),
              width: 0.5,
            )
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Edit Button
          IconButton(
            onPressed: _isUploadingImage ? null : _showImageSourceActionSheet,
            icon: Icon(_isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt_outlined),
            style: IconButton.styleFrom(
              backgroundColor: isDark 
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF2F2F7),
              foregroundColor: isDark 
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6D6D70),
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
        color: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
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
          ? Border.all(
              color: const Color(0xFF38383A),
              width: 0.5,
            )
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await SupabaseService.instance.signOut();
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

  void _showCurrencyPicker(BuildContext context, ThemeProvider themeProvider, AppLocalizations l10n) {
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
            ...Currency.values.map((currency) => ListTile(
              leading: Text(
                currency.symbol,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              title: Text(
                CurrencyUtils.getDisplayName(currency, themeProvider.locale.languageCode),
                style: GoogleFonts.inter(fontSize: 16),
              ),
              trailing: themeProvider.currency == currency
                ? const Icon(Icons.check, color: Color(0xFF10B981))
                : null,
              onTap: () {
                themeProvider.setCurrency(currency);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, ThemeProvider themeProvider, AppLocalizations l10n) {
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
                ? const Icon(Icons.check, color: Color(0xFF10B981))
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
                ? const Icon(Icons.check, color: Color(0xFF10B981))
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

  void _showLanguagePicker(BuildContext context, ThemeProvider themeProvider, AppLocalizations l10n) {
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
              leading: const Text(
                '🇹🇷',
                style: TextStyle(fontSize: 24),
              ),
              title: Text(
                l10n.turkish,
                style: GoogleFonts.inter(fontSize: 16),
              ),
              trailing: themeProvider.isTurkish
                ? const Icon(Icons.check, color: Color(0xFF10B981))
                : null,
              onTap: () {
                if (!themeProvider.isTurkish) {
                  themeProvider.toggleLanguage();
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text(
                '🇺🇸',
                style: TextStyle(fontSize: 24),
              ),
              title: Text(
                l10n.english,
                style: GoogleFonts.inter(fontSize: 16),
              ),
              trailing: !themeProvider.isTurkish
                ? const Icon(Icons.check, color: Color(0xFF10B981))
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

  Future<void> _createTestData(BuildContext context) async {
    try {
      final providerV2 = Provider.of<UnifiedProviderV2>(context, listen: false);
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Create test accounts
      debugPrint('🧪 Creating test accounts...');
      
      // 1. Create a credit card
      final creditCardId = await providerV2.createAccount(
        type: AccountType.credit,
        name: 'Akbank Kredi Kartı',
        bankName: 'Akbank',
        balance: -2500.0, // Negative for credit card debt
        creditLimit: 10000.0,
        statementDay: 15,
        dueDay: 5,
      );
      
      // 2. Create a debit card
      final debitCardId = await providerV2.createAccount(
        type: AccountType.debit,
        name: 'İş Bankası Vadesiz',
        bankName: 'İş Bankası',
        balance: 5000.0,
      );
      
      // 3. Create a cash account
      final cashAccountId = await providerV2.createAccount(
        type: AccountType.cash,
        name: 'Nakit',
        balance: 500.0,
      );
      
      debugPrint('✅ Test accounts created');
      
      // Create test transactions
      debugPrint('🧪 Creating test transactions...');
      
      // Income transaction
      await providerV2.createTransaction(
        type: TransactionType.income,
        amount: 8000.0,
        description: 'Maaş',
        sourceAccountId: debitCardId,
        transactionDate: DateTime.now().subtract(const Duration(days: 5)),
      );
      
      // Expense transactions
      await providerV2.createTransaction(
        type: TransactionType.expense,
        amount: 150.0,
        description: 'Market alışverişi',
        sourceAccountId: creditCardId,
        transactionDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      
      await providerV2.createTransaction(
        type: TransactionType.expense,
        amount: 50.0,
        description: 'Kahve',
        sourceAccountId: cashAccountId,
        transactionDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      
      await providerV2.createTransaction(
        type: TransactionType.expense,
        amount: 300.0,
        description: 'Benzin',
        sourceAccountId: debitCardId,
        transactionDate: DateTime.now(),
      );
      
      // Transfer transaction
      await providerV2.createTransaction(
        type: TransactionType.transfer,
        amount: 200.0,
        description: 'Nakit çekme',
        sourceAccountId: debitCardId,
        targetAccountId: cashAccountId,
        transactionDate: DateTime.now().subtract(const Duration(days: 3)),
      );
      
      // Create an installment transaction
      await providerV2.createInstallmentTransaction(
        sourceAccountId: creditCardId,
        totalAmount: 1200.0,
        count: 6,
        description: 'Telefon',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      
      debugPrint('✅ Test transactions created');
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test verisi başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('❌ Error creating test data: $e');
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test verisi oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
} 