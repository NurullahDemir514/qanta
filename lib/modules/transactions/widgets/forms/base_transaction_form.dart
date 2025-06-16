import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';

class BaseTransactionForm extends StatelessWidget {
  final String title;
  final List<String> stepTitles;
  final int currentStep;
  final PageController pageController;
  final List<Widget> steps;
  final VoidCallback? onNext;
  final VoidCallback? onSave;
  final VoidCallback? onBack;
  final String? nextButtonText;
  final String? saveButtonText;
  final bool isLoading;
  final bool isLastStep;

  const BaseTransactionForm({
    super.key,
    required this.title,
    required this.stepTitles,
    required this.currentStep,
    required this.pageController,
    required this.steps,
    this.onNext,
    this.onSave,
    this.onBack,
    this.nextButtonText,
    this.saveButtonText,
    this.isLoading = false,
    this.isLastStep = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: List.generate(
                stepTitles.length,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < stepTitles.length - 1 ? 8 : 0,
                    ),
                    height: 3,
                    decoration: BoxDecoration(
                      color: index <= currentStep
                          ? isDark 
                              ? Colors.white
                              : Colors.black
                          : isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: steps,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: currentStep == 0
              ? _buildSingleButton(context, l10n, isDark)
              : _buildTwoButtons(context, l10n, isDark),
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, AppLocalizations l10n, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          nextButtonText ?? l10n.next,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, AppLocalizations l10n, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: isDark 
            ? const Color(0xFF2C2C2E) 
            : const Color(0xFFE5E5EA),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.black : Colors.white,
                  ),
                ),
              )
            : Text(
                saveButtonText ?? l10n.save,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSingleButton(BuildContext context, AppLocalizations l10n, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          nextButtonText ?? l10n.next,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTwoButtons(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildBackButton(context, l10n, isDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: isLastStep
              ? _buildSaveButton(context, l10n, isDark)
              : _buildNextButton(context, l10n, isDark),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context, AppLocalizations l10n, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onBack,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          l10n.back,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class BaseFormStep extends StatelessWidget {
  final String title;
  final Widget content;
  final EdgeInsets? padding;

  const BaseFormStep({
    super.key,
    required this.title,
    required this.content,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding ?? const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 40, // Padding'i çıkar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),
                content,
              ],
            ),
          ),
        );
      },
    );
  }
} 