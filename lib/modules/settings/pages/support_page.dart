import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: isDark 
        ? const Color(0xFF000000) 
        : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark 
          ? const Color(0xFF1C1C1E) 
          : Colors.white,
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
          l10n?.supportAndContact ?? 'Support & Contact',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          children: [
            // FAQ Section (background removed, padding reduced)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    l10n?.frequentlyAskedQuestions ?? 'Frequently Asked Questions',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildFAQItem(
                  question: l10n?.isMyDataSecure ?? 'Is my data secure?',
                  answer: l10n?.isMyDataSecureAnswer ?? 'Yes, all your data is stored encrypted and hosted on secure servers.',
                  isDark: isDark,
                ),
                
                _buildFAQItem(
                  question: l10n?.forgotPassword ?? 'I forgot my password, what should I do?',
                  answer: l10n?.forgotPasswordAnswer ?? 'You can reset your password using the "Forgot Password" option on the login screen.',
                  isDark: isDark,
                ),
                
                _buildFAQItem(
                  question: l10n?.howToDeleteAccount ?? 'How can I delete my account?',
                  answer: l10n?.howToDeleteAccountAnswer ?? 'You can use the "Account Settings" > "Delete Account" option from the profile page.',
                  isDark: isDark,
                ),
                
                _buildFAQItem(
                  question: l10n?.isAppFree ?? 'Is the app free?',
                  answer: l10n?.isAppFreeAnswer ?? 'Yes, Qanta can be used completely free. Premium features may be added in the future.',
                  isDark: isDark,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // App Info
            Container(
              decoration: BoxDecoration(
                color: isDark 
                  ? const Color(0xFF1C1C1E) 
                  : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isDark 
                  ? Border.all(
                      color: const Color(0xFF38383A),
                      width: 0.5,
                    )
                  : null,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.appInformation ?? 'App Information',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInfoRow(l10n?.version ?? 'Version', '1.1.5', isDark),
                  _buildInfoRow(l10n?.lastUpdate ?? 'Last Update', '7 Kasım 2025', isDark),
                  _buildInfoRow(l10n?.developer ?? 'Developer', 'Qanta Team', isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1D1D1F),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? const Color(0xFFE5E5EA) : const Color(0xFF6E6E73),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF8E8E93),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

} 