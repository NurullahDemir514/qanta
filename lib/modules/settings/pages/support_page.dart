import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Contact Methods
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
              child: Column(
                children: [
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    title: l10n?.email ?? 'Email',
                    subtitle: 'support@qanta.app',
                    onTap: () => _launchEmail('support@qanta.app'),
                    isDark: isDark,
                  ),
                  _buildContactItem(
                    icon: Icons.phone_outlined,
                    title: l10n?.phone ?? 'Phone',
                    subtitle: '+90 (545) 434-1745',
                    onTap: () => _launchPhone('+905454341745'),
                    isDark: isDark,
                  ),
                  _buildContactItem(
                    icon: Icons.chat_bubble_outline,
                    title: l10n?.liveSupport ?? 'Live Support',
                    subtitle: l10n?.liveSupportHours ?? 'Monday-Friday 09:00-18:00',
                    onTap: () => _showLiveChatInfo(context),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // FAQ Section
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.frequentlyAskedQuestions ?? 'Frequently Asked Questions',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
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
            ),
            
            const SizedBox(height: 24),
            
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
              padding: const EdgeInsets.all(24),
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
                  
                  _buildInfoRow(l10n?.version ?? 'Version', '1.0.0', isDark),
                  _buildInfoRow(l10n?.lastUpdate ?? 'Last Update', '20 Ocak 2025', isDark),
                  _buildInfoRow(l10n?.developer ?? 'Developer', 'Nurullah Onur Demir', isDark),
                  _buildInfoRow(l10n?.platform ?? 'Platform', 'Flutter', isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF007AFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF8E8E93),
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

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 76,
      color: isDark 
        ? const Color(0xFF38383A)
        : const Color(0xFFE5E5EA),
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
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
              height: 1.4,
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

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLiveChatInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.liveSupportTitle ?? 'Live Support'),
        content: Text(
          l10n?.liveSupportMessage ?? 'Live support service is currently in development. For urgent matters, please contact us via email or phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.ok ?? 'OK'),
          ),
        ],
      ),
    );
  }
} 