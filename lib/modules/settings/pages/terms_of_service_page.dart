import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          l10n?.termsOfService ?? 'Terms of Service',
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
        child: Container(
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
              _buildSection(
                title: '1. ${l10n?.serviceDescription ?? 'Service Description'}',
                content: l10n?.serviceDescriptionContent ?? 'Service Description Content',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '2. ${l10n?.usageTerms ?? 'Usage Terms'}',
                content: l10n?.usageTermsContent ?? 'Usage Terms Content',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '3. ${l10n?.userResponsibilities ?? 'User Responsibilities'}',
                content: l10n?.userResponsibilitiesContent ?? 'User Responsibilities Content',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '4. ${l10n?.serviceLimitations ?? 'Service Limitations'}',
                content: l10n?.serviceLimitationsContent ?? 'Service Limitations Content',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '5. ${l10n?.intellectualProperty ?? 'Intellectual Property'}',
                content: l10n?.intellectualPropertyContent ?? 'Intellectual Property Content',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '6. ${l10n?.serviceChanges ?? 'Service Changes'}',
                content: l10n?.serviceChangesContent ?? 'Service Changes Content',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '7. ${l10n?.disclaimer ?? 'Disclaimer'}',
                content: l10n?.disclaimerContent ?? 'Disclaimer Content',
                isDark: isDark,
              ),
              
              _buildSection(
                title: '8. ${l10n?.termsContact ?? 'Contact'}',
                content: l10n?.termsContactContent ?? 'Terms Contact Content',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark 
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
} 