import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

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
          l10n?.faq ?? 'FAQ',
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
            _buildFAQSection(
              title: l10n?.generalQuestions ?? 'General Questions',
              items: [
                FAQItem(
                  question: l10n?.whatIsQanta ?? 'What is Qanta?',
                  answer: l10n?.whatIsQantaAnswer ?? 'What is Qanta answer',
                ),
                FAQItem(
                  question: l10n?.isAppFree ?? 'Is the app free?',
                  answer: l10n?.isAppFreeAnswer ?? 'Is app free answer',
                ),
                FAQItem(
                  question: l10n?.whichDevicesSupported ?? 'Which devices are supported?',
                  answer: l10n?.whichDevicesSupportedAnswer ?? 'Which devices supported answer',
                ),
              ],
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            _buildFAQSection(
              title: l10n?.accountAndSecurity ?? 'Account and Security',
              items: [
                FAQItem(
                  question: l10n?.isMyDataSecure ?? 'Is my data secure?',
                  answer: l10n?.isMyDataSecureAnswer ?? 'Is my data secure answer',
                ),
                FAQItem(
                  question: l10n?.forgotPassword ?? 'Forgot password',
                  answer: l10n?.forgotPasswordAnswer ?? 'Forgot password answer',
                ),
                FAQItem(
                  question: l10n?.howToDeleteAccount ?? 'How to delete account',
                  answer: l10n?.howToDeleteAccountAnswer ?? 'How to delete account answer',
                ),
                FAQItem(
                  question: l10n?.howToChangePassword ?? 'How to change password',
                  answer: l10n?.howToChangePasswordAnswer ?? 'How to change password answer',
                ),
              ],
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            _buildFAQSection(
              title: l10n?.features ?? 'Features',
              items: [
                FAQItem(
                  question: l10n?.whichCardTypesSupported ?? 'Which card types are supported?',
                  answer: l10n?.whichCardTypesSupportedAnswer ?? 'Which card types supported answer',
                ),
                FAQItem(
                  question: l10n?.howDoesInstallmentTrackingWork ?? 'How does installment tracking work?',
                  answer: l10n?.howDoesInstallmentTrackingWorkAnswer ?? 'How does installment tracking work answer',
                ),
                FAQItem(
                  question: l10n?.howToUseBudgetManagement ?? 'How to use budget management?',
                  answer: l10n?.howToUseBudgetManagementAnswer ?? 'How to use budget management answer',
                ),
              ],
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            _buildFAQSection(
              title: l10n?.technicalIssues ?? 'Technical Issues',
              items: [
                FAQItem(
                  question: l10n?.appCrashingWhatToDo ?? 'App is crashing, what should I do?',
                  answer: l10n?.appCrashingWhatToDoAnswer ?? 'App crashing what to do answer',
                ),
                FAQItem(
                  question: l10n?.dataNotSyncing ?? 'Data not syncing',
                  answer: l10n?.dataNotSyncingAnswer ?? 'Data not syncing answer',
                ),
                FAQItem(
                  question: l10n?.notificationsNotComing ?? 'Notifications not coming',
                  answer: l10n?.notificationsNotComingAnswer ?? 'Notifications not coming answer',
                ),
              ],
              isDark: isDark,
            ),
            
            const SizedBox(height: 20),
            
            _buildFAQSection(
              title: l10n?.contact ?? 'Contact',
              items: [
                FAQItem(
                  question: l10n?.howToContactSupport ?? 'How to contact support',
                  answer: l10n?.howToContactSupportAnswer ?? 'How to contact support answer',
                ),
                FAQItem(
                  question: l10n?.haveSuggestionWhereToSend ?? 'Have suggestion, where to send',
                  answer: l10n?.haveSuggestionWhereToSendAnswer ?? 'Have suggestion where to send answer',
                ),
              ],
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection({
    required String title,
    required List<FAQItem> items,
    required bool isDark,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            
            return _buildFAQItem(item, isDark);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem item, bool isDark) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Text(
        item.question,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      iconColor: isDark ? Colors.white : Colors.black,
      collapsedIconColor: const Color(0xFF8E8E93),
      collapsedShape: Border(),
      shape: Border(),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            item.answer,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
} 