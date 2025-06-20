import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/supabase_service.dart';

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
      _showErrorDialog('Yeni şifreler eşleşmiyor');
      return;
    }
    
    if (_newPasswordController.text.length < 6) {
      _showErrorDialog('Yeni şifre en az 6 karakter olmalı');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await SupabaseService.instance.updatePassword(_newPasswordController.text);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre başarıyla değiştirildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorDialog('Şifre değiştirilemedi: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('Tamam'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    return CupertinoPageScaffold(
      backgroundColor: isDark 
        ? const Color(0xFF000000) 
        : const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark 
          ? const Color(0xFF1C1C1E) 
          : const Color(0xFFF8F8F8),
        border: Border(
          bottom: BorderSide(
            color: isDark 
              ? const Color(0xFF38383A)
              : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İptal',
            style: GoogleFonts.inter(
              fontSize: 17,
              color: const Color(0xFF007AFF),
            ),
          ),
        ),
        middle: Text(
          'Şifre Değiştir',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _canSave ? _changePassword : null,
          child: _isLoading
            ? const CupertinoActivityIndicator()
            : Text(
                'Kaydet',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _canSave 
                    ? const Color(0xFF007AFF)
                    : const Color(0xFF8E8E93),
                ),
              ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Current Password Section
              Container(
                decoration: BoxDecoration(
                  color: isDark 
                    ? const Color(0xFF1C1C1E) 
                    : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      placeholder: 'Mevcut Şifre',
                      obscureText: !_showCurrentPassword,
                      onVisibilityToggle: () {
                        setState(() => _showCurrentPassword = !_showCurrentPassword);
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // New Password Section
              Container(
                decoration: BoxDecoration(
                  color: isDark 
                    ? const Color(0xFF1C1C1E) 
                    : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildPasswordField(
                      controller: _newPasswordController,
                      placeholder: 'Yeni Şifre',
                      obscureText: !_showNewPassword,
                      onVisibilityToggle: () {
                        setState(() => _showNewPassword = !_showNewPassword);
                      },
                      isDark: isDark,
                      showDivider: true,
                    ),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      placeholder: 'Yeni Şifre (Tekrar)',
                      obscureText: !_showConfirmPassword,
                      onVisibilityToggle: () {
                        setState(() => _showConfirmPassword = !_showConfirmPassword);
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Şifreniz en az 6 karakter uzunluğunda olmalıdır.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF8E8E93),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
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
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  placeholderStyle: GoogleFonts.inter(
                    fontSize: 17,
                    color: const Color(0xFF8E8E93),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: onVisibilityToggle,
                child: Icon(
                  obscureText ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  color: const Color(0xFF8E8E93),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            color: isDark 
              ? const Color(0xFF38383A)
              : const Color(0xFFE5E5EA),
          ),
      ],
    );
  }
} 