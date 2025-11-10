import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

/// Email input dialog for Amazon gift card request
class AmazonEmailInputDialog extends StatefulWidget {
  final double balance;
  final Function(String email) onConfirm;

  const AmazonEmailInputDialog({
    super.key,
    required this.balance,
    required this.onConfirm,
  });

  static Future<String?> show(
    BuildContext context, {
    required double balance,
  }) async {
    String? result;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AmazonEmailInputDialog(
        balance: balance,
        onConfirm: (email) {
          result = email;
          Navigator.of(context).pop();
        },
      ),
    );
    
    return result;
  }

  @override
  State<AmazonEmailInputDialog> createState() => _AmazonEmailInputDialogState();
}

class _AmazonEmailInputDialogState extends State<AmazonEmailInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email adresi gerekli';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir email adresi girin';
    }
    
    return null;
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();
    widget.onConfirm(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3A3A3C)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.card_giftcard,
                        color: Colors.green.shade500,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Amazon Hediye Kartı',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.balance.toStringAsFixed(2)} TL birikiminiz var!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amazon hesabınızın email adresini girin',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Email input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'ornek@amazon.com.tr',
                    hintStyle: GoogleFonts.inter(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1C1C1E)
                        : const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  validator: _validateEmail,
                  onFieldSubmitted: (_) => _handleConfirm(),
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF3A3A3C)
                          : const Color(0xFFD1D1D6),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: InkWell(
                        onTap: _isLoading
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                        ),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: Text(
                            'İptal',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: _isLoading
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3)
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      width: 0.5,
                      height: 50,
                      color: isDark
                          ? const Color(0xFF3A3A3C)
                          : const Color(0xFFD1D1D6),
                    ),
                    // Confirm button
                    Expanded(
                      child: InkWell(
                        onTap: _isLoading ? null : _handleConfirm,
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(14),
                        ),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF007AFF),
                                    ),
                                  ),
                                )
                              : Text(
                                  'Gönder',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF007AFF),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

