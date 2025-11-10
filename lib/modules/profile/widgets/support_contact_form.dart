import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Elegant and minimal support contact form
class SupportContactForm extends StatefulWidget {
  const SupportContactForm({super.key});

  @override
  State<SupportContactForm> createState() => _SupportContactFormState();
}

class _SupportContactFormState extends State<SupportContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'general', 'label': 'Genel Soru'},
    {'value': 'bug', 'label': 'Hata Bildir'},
    {'value': 'feature', 'label': 'Özellik Öner'},
    {'value': 'account', 'label': 'Hesap'},
    {'value': 'payment', 'label': 'Ödeme'},
    {'value': 'other', 'label': 'Diğer'},
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'general':
        return Icons.help_outline;
      case 'bug':
        return Icons.bug_report_outlined;
      case 'feature':
        return Icons.lightbulb_outline;
      case 'account':
        return Icons.person_outline;
      case 'payment':
        return Icons.payment_outlined;
      case 'other':
        return Icons.chat_bubble_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Lütfen önce giriş yapın');
      }

      // Call Cloud Function (user info will be fetched automatically)
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('submitSupportRequest');

      debugPrint('📤 Submitting support request: subject=${_subjectController.text.trim()}, category=$_selectedCategory');

      final result = await callable.call({
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'category': _selectedCategory,
      });

      debugPrint('📥 Support request result: $result');

      final data = Map<String, dynamic>.from(result.data);

      if (data['success'] == true) {
        if (mounted) {
          HapticFeedback.mediumImpact();
          
          // Show success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mesajınız iletildi. Teşekkürler!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade500,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Reset form
          _subjectController.clear();
          _messageController.clear();
          setState(() {
            _selectedCategory = 'general';
          });

          // Close after delay
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      } else {
        throw Exception(data['message'] ?? 'Bir şeyler yanlış gitti');
      }
    } catch (e) {
      debugPrint('❌ Error submitting support request: $e');
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gönderilemedi. Lütfen tekrar deneyin.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          'Yardım',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Simple header
                Text(
                  'Nasıl yardımcı olabiliriz?',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sorunuzu veya önerinizi paylaşın, size yardımcı olalım.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF8E8E93),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // Category Selection - Minimal design
                Text(
                  'Konu',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF6D6D70),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category['value'];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCategory = category['value']!;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: index < _categories.length - 1 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                    ? const Color(0xFF1C1C1E)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? const Color(0xFF38383A)
                                      : const Color(0xFFE5E5EA)),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(category['value']!),
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF6D6D70)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category['label']!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF6D6D70)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Subject Field
                TextFormField(
                  controller: _subjectController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Kısa bir başlık yazın',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF8E8E93),
                    ),
                    labelStyle: GoogleFonts.inter(
                      color: const Color(0xFF8E8E93),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1C1C1E)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen bir başlık girin';
                    }
                    if (value.trim().length < 3) {
                      return 'Başlık en az 3 karakter olmalı';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Message Field
                TextFormField(
                  controller: _messageController,
                  enabled: !_isSubmitting,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Mesajınız',
                    hintText: 'Detayları paylaşın...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF8E8E93),
                    ),
                    labelStyle: GoogleFonts.inter(
                      color: const Color(0xFF8E8E93),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1C1C1E)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen mesajınızı yazın';
                    }
                    if (value.trim().length < 10) {
                      return 'Mesaj en az 10 karakter olmalı';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          primaryColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Gönder',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
