import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../l10n/app_localizations.dart';

// ignore: avoid_web_libraries_in_flutter

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    // Focus'u temizle ve klavyeyi kapat
    FocusScope.of(context).unfocus();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        !_isLoading;
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog(
        AppLocalizations.of(context)?.passwordsDoNotMatch ??
            'Passwords do not match',
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorDialog(
        AppLocalizations.of(context)?.passwordMinLength ??
            'Password must be at least 6 characters',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Önce mevcut şifreyi doğrula
      await FirebaseAuthService.reauthenticateUser(
        _currentPasswordController.text,
      );

      // Şifreyi güncelle
      await FirebaseAuthService.updatePassword(_newPasswordController.text);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.passwordChangedSuccessfully ??
                  'Password changed successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        String errorMessage = _getErrorMessage(e.toString());
        _showErrorDialog(errorMessage);
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('wrong-password')) {
      return AppLocalizations.of(context)?.wrongCurrentPassword ??
          'Current password is incorrect';
    } else if (error.contains('weak-password')) {
      return AppLocalizations.of(context)?.passwordTooWeak ??
          'Password is too weak';
    } else if (error.contains('requires-recent-login')) {
      return AppLocalizations.of(context)?.requiresRecentLogin ??
          'Please log in again to change your password';
    } else {
      return '${AppLocalizations.of(context)?.passwordChangeFailed ?? 'Password change failed'}: $error';
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)?.error ?? 'Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          l10n?.changePassword ?? 'Change Password',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            fontFamily: 'SF Pro Text',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Current Password Section
              _buildSectionTitle('Current Password', isDark),
              const SizedBox(height: 8),
              _buildModernPasswordField(
                controller: _currentPasswordController,
                placeholder: l10n?.currentPassword ?? 'Current Password',
                obscureText: !_showCurrentPassword,
                onVisibilityToggle: () {
                  setState(() => _showCurrentPassword = !_showCurrentPassword);
                },
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // New Password Section
              _buildSectionTitle('New Password', isDark),
              const SizedBox(height: 8),
              _buildModernPasswordField(
                controller: _newPasswordController,
                placeholder: l10n?.newPassword ?? 'New Password',
                obscureText: !_showNewPassword,
                onVisibilityToggle: () {
                  setState(() => _showNewPassword = !_showNewPassword);
                },
                isDark: isDark,
              ),

              const SizedBox(height: 16),

              // Confirm Password Section
              _buildModernPasswordField(
                controller: _confirmPasswordController,
                placeholder: l10n?.confirmNewPassword ?? 'Confirm New Password',
                obscureText: !_showConfirmPassword,
                onVisibilityToggle: () {
                  setState(() => _showConfirmPassword = !_showConfirmPassword);
                },
                isDark: isDark,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSave ? _changePassword : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave
                        ? const Color(0xFF007AFF)
                        : const Color(0xFF8E8E93),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          l10n?.save ?? 'Save',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black,
        fontFamily: 'SF Pro Text',
      ),
    );
  }

  Widget _buildModernPasswordField({
    required TextEditingController controller,
    required String placeholder,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black,
          fontFamily: 'SF Pro Text',
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            fontSize: 16,
            color: const Color(0xFF8E8E93),
            fontFamily: 'SF Pro Text',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: IconButton(
            onPressed: onVisibilityToggle,
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF8E8E93),
              size: 20,
            ),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String placeholder,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
    required bool isDark,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  obscureText: obscureText,
                  decoration: const BoxDecoration(),
                  style: TextStyle(
                    fontSize: 17,
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: 'SF Pro Text',
                  ),
                  placeholderStyle: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF8E8E93),
                    fontFamily: 'SF Pro Text',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onVisibilityToggle,
                child: Icon(
                  obscureText ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  color: const Color(0xFF8E8E93),
                  size: 20,
                ),
                minimumSize: Size(0, 0),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          ),
      ],
    );
  }
}
