import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../core/services/quick_note_service.dart';
import '../../../core/services/quick_note_notification_service.dart';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/models_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ios_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class QuickNotesPage extends StatefulWidget {
  final List<QuickNote>? notes;

  const QuickNotesPage({super.key, this.notes});

  @override
  State<QuickNotesPage> createState() => _QuickNotesPageState();
}

class _QuickNotesPageState extends State<QuickNotesPage> {
  List<QuickNote> _allNotes = [];
  List<QuickNote> _pendingNotes = [];
  List<QuickNote> _processedNotes = [];
  bool _isLoading = false;
  bool _showProcessed = false;
  final TextEditingController _quickAddController = TextEditingController();
  final FocusNode _quickAddFocus = FocusNode();

  // Localization
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;
  double _soundLevel = 0.0;

  // Image Picker
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  // Responsive breakpoints
  static const double _breakpointSmallMobile = 320; // iPhone SE, small phones
  static const double _breakpointMobile = 375; // iPhone 12/13/14
  static const double _breakpointLargeMobile = 414; // iPhone 12/13/14 Pro Max
  static const double _breakpointSmallTablet = 768; // iPad Mini
  static const double _breakpointTablet = 834; // iPad Air
  static const double _breakpointLargeTablet = 1024; // iPad Pro 11"
  static const double _breakpointDesktop = 1440; // Desktop

  @override
  void initState() {
    super.initState();
    if (widget.notes != null) {
      // Eğer notes parametresi varsa, onları kullan
      _pendingNotes = widget.notes!.where((note) => !note.isProcessed).toList();
      _processedNotes = widget.notes!
          .where((note) => note.isProcessed)
          .toList();
      _allNotes = widget.notes!;
    } else {
      _loadNotes();
    }
    _initSpeech();
  }

  // Responsive helper methods
  bool _isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < _breakpointMobile;
  }

  bool _isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _breakpointMobile && width < _breakpointLargeMobile;
  }

  bool _isLargeMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _breakpointLargeMobile && width < _breakpointSmallTablet;
  }

  bool _isSmallTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _breakpointSmallTablet && width < _breakpointTablet;
  }

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _breakpointTablet && width < _breakpointLargeTablet;
  }

  bool _isLargeTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _breakpointLargeTablet && width < _breakpointDesktop;
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= _breakpointDesktop;
  }

  // Get responsive values
  double _getResponsiveValue(
    BuildContext context, {
    required double smallMobile,
    required double mobile,
    required double largeMobile,
    required double smallTablet,
    required double tablet,
    required double largeTablet,
    required double desktop,
  }) {
    if (_isSmallMobile(context)) return smallMobile;
    if (_isMobile(context)) return mobile;
    if (_isLargeMobile(context)) return largeMobile;
    if (_isSmallTablet(context)) return smallTablet;
    if (_isTablet(context)) return tablet;
    if (_isLargeTablet(context)) return largeTablet;
    return desktop;
  }

  @override
  void dispose() {
    _quickAddController.dispose();
    _quickAddFocus.dispose();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      // Load from Firebase
      final allNotes = await QuickNoteService.getUserQuickNotes();
      final pendingNotes = await QuickNoteService.getPendingNotes();
      final processedNotes = await QuickNoteService.getProcessedNotes();

      setState(() {
        _allNotes = allNotes;
        _pendingNotes = pendingNotes;
        _processedNotes = processedNotes;
      });
    } catch (e) {
      debugPrint('Error loading notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notlar yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF000000)
            : const Color(0xFFF2F2F7),
        appBar: _buildModernAppBar(isDark),
        body: RefreshIndicator(
          onRefresh: _loadNotes,
          color: const Color(0xFF007AFF),
          child: Column(
            children: [
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Toggle Buttons
                      _buildModernToggleButtons(isDark),
                      const SizedBox(height: 20),

                      // Notes List
                      if (_showProcessed)
                        _buildModernNotesSection(
                          title: l10n.processedNotesTitle,
                          notes: _processedNotes.cast<QuickNote>(),
                          isDark: isDark,
                          emptyMessage: l10n.noProcessedNotes,
                        )
                      else
                        _buildModernNotesSection(
                          title: l10n.pendingNotesTitle,
                          notes: _pendingNotes.cast<QuickNote>(),
                          isDark: isDark,
                          emptyMessage: l10n.noPendingNotes,
                        ),

                      const SizedBox(
                        height: 100,
                      ), // Bottom padding for quick add
                    ],
                  ),
                ),
              ),

              // Quick Add Section - Bottom
              _buildSimpleQuickAddSection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // Modern AppBar
  PreferredSizeWidget _buildModernAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.note_add_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.quickNotesTitle,
                style: GoogleFonts.inter(
                  fontSize: _getResponsiveValue(
                    context,
                    smallMobile: 18,
                    mobile: 20,
                    largeMobile: 22,
                    smallTablet: 24,
                    tablet: 26,
                    largeTablet: 28,
                    desktop: 30,
                  ),
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                l10n.pendingNotesCount(_pendingNotes.length),
                style: GoogleFonts.inter(
                  fontSize: _getResponsiveValue(
                    context,
                    smallMobile: 10,
                    mobile: 12,
                    largeMobile: 13,
                    smallTablet: 14,
                    tablet: 15,
                    largeTablet: 16,
                    desktop: 17,
                  ),
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                ),
              ),
            ],
          ),
        ],
      ),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : Colors.black,
            size: 16,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _loadNotes,
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF38383A)
                    : const Color(0xFFE5E5EA),
              ),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : Colors.black,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Modern Quick Add Section
  Widget _buildSimpleQuickAddSection(bool isDark) {
    return Container(
      padding: EdgeInsets.all(
        _getResponsiveValue(
          context,
          smallMobile: 16,
          mobile: 20,
          largeMobile: 22,
          smallTablet: 24,
          tablet: 26,
          largeTablet: 28,
          desktop: 30,
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)]
              : [Colors.white, const Color(0xFFF8F9FA)],
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Quick Actions Row
            Row(
              children: [
                // Voice Button
                _buildQuickActionButton(
                  icon: _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _isListening
                      ? const Color(0xFFFF6B35)
                      : const Color(0xFF007AFF),
                  onTap: _isListening ? _stopListening : _startListening,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),

                // Photo Button
                _buildQuickActionButton(
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFF34C759),
                  onTap: _pickImage,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),

                // Spacer
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),

            // Input Row
            Row(
              children: [
                // Input Field
                Expanded(child: _buildSimpleInputField(isDark)),
                const SizedBox(width: 12),

                // Add Button
                _buildSimpleAddButton(isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Quick Action Button
  Widget _buildQuickActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _getResponsiveValue(
          context,
          smallMobile: 36,
          mobile: 40,
          largeMobile: 42,
          smallTablet: 44,
          tablet: 46,
          largeTablet: 48,
          desktop: 50,
        ),
        height: _getResponsiveValue(
          context,
          smallMobile: 36,
          mobile: 40,
          largeMobile: 42,
          smallTablet: 44,
          tablet: 46,
          largeTablet: 48,
          desktop: 50,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Icon(
          icon,
          color: color,
          size: _getResponsiveValue(
            context,
            smallMobile: 16,
            mobile: 18,
            largeMobile: 19,
            smallTablet: 20,
            tablet: 21,
            largeTablet: 22,
            desktop: 23,
          ),
        ),
      ),
    );
  }

  // Simple Input Field
  Widget _buildSimpleInputField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
              : [const Color(0xFFF2F2F7), Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isListening
              ? const Color(0xFFFF6B35)
              : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
          width: _isListening ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _quickAddController,
        focusNode: _quickAddFocus,
        decoration: InputDecoration(
          hintText: l10n.addNoteHint,
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF8E8E93),
            fontSize: _getResponsiveValue(
              context,
              smallMobile: 14,
              mobile: 16,
              largeMobile: 17,
              smallTablet: 18,
              tablet: 19,
              largeTablet: 20,
              desktop: 21,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: _getResponsiveValue(
              context,
              smallMobile: 12,
              mobile: 16,
              largeMobile: 18,
              smallTablet: 20,
              tablet: 22,
              largeTablet: 24,
              desktop: 26,
            ),
            vertical: _getResponsiveValue(
              context,
              smallMobile: 12,
              mobile: 14,
              largeMobile: 15,
              smallTablet: 16,
              tablet: 17,
              largeTablet: 18,
              desktop: 19,
            ),
          ),
          prefixIcon: Icon(
            _isListening ? Icons.mic : Icons.edit_note_rounded,
            color: _isListening
                ? const Color(0xFFFF6B35)
                : const Color(0xFF007AFF),
            size: _getResponsiveValue(
              context,
              smallMobile: 18,
              mobile: 20,
              largeMobile: 21,
              smallTablet: 22,
              tablet: 23,
              largeTablet: 24,
              desktop: 25,
            ),
          ),
        ),
        maxLines: 1,
        style: GoogleFonts.inter(
          fontSize: _getResponsiveValue(
            context,
            smallMobile: 14,
            mobile: 16,
            largeMobile: 17,
            smallTablet: 18,
            tablet: 19,
            largeTablet: 20,
            desktop: 21,
          ),
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  // Simple Add Button
  Widget _buildSimpleAddButton(bool isDark) {
    return GestureDetector(
      onTap: _quickAddNote,
      child: Container(
        width: _getResponsiveValue(
          context,
          smallMobile: 44,
          mobile: 48,
          largeMobile: 50,
          smallTablet: 52,
          tablet: 54,
          largeTablet: 56,
          desktop: 58,
        ),
        height: _getResponsiveValue(
          context,
          smallMobile: 44,
          mobile: 48,
          largeMobile: 50,
          smallTablet: 52,
          tablet: 54,
          largeTablet: 56,
          desktop: 58,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: _getResponsiveValue(
            context,
            smallMobile: 18,
            mobile: 20,
            largeMobile: 21,
            smallTablet: 22,
            tablet: 23,
            largeTablet: 24,
            desktop: 25,
          ),
        ),
      ),
    );
  }

  // Modern Input Field
  Widget _buildModernInputField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isListening
              ? const Color(0xFFFF6B35)
              : Colors.white.withOpacity(0.3),
          width: _isListening ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _quickAddController,
        focusNode: _quickAddFocus,
        decoration: InputDecoration(
          hintText: l10n.addNoteHint,
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF8E8E93),
            fontSize: _getResponsiveValue(
              context,
              smallMobile: 14,
              mobile: 16,
              largeMobile: 17,
              smallTablet: 18,
              tablet: 19,
              largeTablet: 20,
              desktop: 21,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(
            _isListening ? Icons.mic : Icons.edit_note_rounded,
            color: _isListening
                ? const Color(0xFFFF6B35)
                : const Color(0xFF007AFF),
          ),
        ),
        maxLines: 3,
        minLines: 1,
        style: GoogleFonts.inter(
          fontSize: _getResponsiveValue(
            context,
            smallMobile: 14,
            mobile: 16,
            largeMobile: 17,
            smallTablet: 18,
            tablet: 19,
            largeTablet: 20,
            desktop: 21,
          ),
          color: Colors.black,
        ),
      ),
    );
  }

  // Action Buttons
  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        // Voice Button
        Expanded(
          child: _buildActionButton(
            icon: _isListening ? Icons.stop_rounded : Icons.mic_rounded,
            label: _isListening ? l10n.stopButton : l10n.voiceButton,
            color: _isListening ? const Color(0xFFFF6B35) : Colors.white,
            textColor: _isListening ? Colors.white : const Color(0xFF007AFF),
            onTap: _isListening ? _stopListening : _startListening,
          ),
        ),
        const SizedBox(width: 8),

        // Camera Button
        Expanded(
          child: _buildActionButton(
            icon: Icons.camera_alt_rounded,
            label: l10n.photoButton,
            color: Colors.white,
            textColor: const Color(0xFF007AFF),
            onTap: _pickImage,
          ),
        ),
        const SizedBox(width: 8),

        // Add Button
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_rounded,
            label: l10n.addButton,
            color: Colors.white,
            textColor: const Color(0xFF007AFF),
            onTap: _quickAddNote,
          ),
        ),
      ],
    );
  }

  // Action Button Widget
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: _getResponsiveValue(
            context,
            smallMobile: 10,
            mobile: 12,
            largeMobile: 13,
            smallTablet: 14,
            tablet: 15,
            largeTablet: 16,
            desktop: 17,
          ),
          horizontal: _getResponsiveValue(
            context,
            smallMobile: 12,
            mobile: 16,
            largeMobile: 18,
            smallTablet: 20,
            tablet: 22,
            largeTablet: 24,
            desktop: 26,
          ),
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: textColor,
              size: _getResponsiveValue(
                context,
                smallMobile: 16,
                mobile: 18,
                largeMobile: 19,
                smallTablet: 20,
                tablet: 21,
                largeTablet: 22,
                desktop: 23,
              ),
            ),
            SizedBox(
              width: _getResponsiveValue(
                context,
                smallMobile: 4,
                mobile: 6,
                largeMobile: 7,
                smallTablet: 8,
                tablet: 9,
                largeTablet: 10,
                desktop: 11,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: _getResponsiveValue(
                  context,
                  smallMobile: 12,
                  mobile: 14,
                  largeMobile: 15,
                  smallTablet: 16,
                  tablet: 17,
                  largeTablet: 18,
                  desktop: 19,
                ),
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Floating Action Button
  Widget _buildFloatingActionButton(bool isDark) {
    return FloatingActionButton(
      onPressed: () {
        _quickAddFocus.requestFocus();
      },
      backgroundColor: const Color(0xFF007AFF),
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }

  // Modern Toggle Buttons
  Widget _buildModernToggleButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: l10n.pendingNotes,
              isSelected: !_showProcessed,
              isDark: isDark,
              onTap: () => setState(() => _showProcessed = false),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: l10n.processedNotes,
              isSelected: _showProcessed,
              isDark: isDark,
              onTap: () => setState(() => _showProcessed = true),
            ),
          ),
        ],
      ),
    );
  }

  // Toggle Button Widget
  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70)),
          ),
        ),
      ),
    );
  }

  // Modern Notes Section
  Widget _buildModernNotesSection({
    required String title,
    required List<QuickNote> notes,
    required bool isDark,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notes.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Notes List
        if (notes.isEmpty)
          _buildEmptyState(emptyMessage, isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildModernNoteCard(notes[index], isDark),
          ),
      ],
    );
  }

  // Modern Note Card
  Widget _buildModernNoteCard(QuickNote note, bool isDark) {
    return Container(
      padding: EdgeInsets.all(
        _getResponsiveValue(
          context,
          smallMobile: 12,
          mobile: 16,
          largeMobile: 18,
          smallTablet: 20,
          tablet: 22,
          largeTablet: 24,
          desktop: 26,
        ),
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: note.isProcessed
              ? const Color(0xFF34C759).withOpacity(0.3)
              : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getNoteTypeColor(note.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNoteTypeIcon(note.type),
                  color: _getNoteTypeColor(note.type),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.content,
                      style: GoogleFonts.inter(
                        fontSize: _getResponsiveValue(
                          context,
                          smallMobile: 14,
                          mobile: 16,
                          largeMobile: 17,
                          smallTablet: 18,
                          tablet: 19,
                          largeTablet: 20,
                          desktop: 21,
                        ),
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(
                      height: _getResponsiveValue(
                        context,
                        smallMobile: 3,
                        mobile: 4,
                        largeMobile: 5,
                        smallTablet: 6,
                        tablet: 7,
                        largeTablet: 8,
                        desktop: 9,
                      ),
                    ),
                    Text(
                      _formatNoteDate(note.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: _getResponsiveValue(
                          context,
                          smallMobile: 10,
                          mobile: 12,
                          largeMobile: 13,
                          smallTablet: 14,
                          tablet: 15,
                          largeTablet: 16,
                          desktop: 17,
                        ),
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Indicator
              _buildStatusIndicator(note, isDark),
            ],
          ),

          // Image Preview
          if (note.imagePath != null) ...[
            const SizedBox(height: 12),
            _buildImagePreview(note.imagePath!, isDark),
          ],

          // Actions
          if (!note.isProcessed) ...[
            const SizedBox(height: 16),
            _buildNoteActions(note, isDark),
          ],
        ],
      ),
    );
  }

  // Status Indicator
  Widget _buildStatusIndicator(QuickNote note, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: note.isProcessed
            ? const Color(0xFF34C759).withOpacity(0.1)
            : const Color(0xFF007AFF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            note.isProcessed ? Icons.check_circle : Icons.schedule,
            size: 14,
            color: note.isProcessed
                ? const Color(0xFF34C759)
                : const Color(0xFF007AFF),
          ),
          const SizedBox(width: 4),
          Text(
            note.isProcessed
                ? l10n.noteStatusProcessed
                : l10n.noteStatusPending,
            style: GoogleFonts.inter(
              fontSize: _getResponsiveValue(
                context,
                smallMobile: 10,
                mobile: 12,
                largeMobile: 13,
                smallTablet: 14,
                tablet: 15,
                largeTablet: 16,
                desktop: 17,
              ),
              fontWeight: FontWeight.w600,
              color: note.isProcessed
                  ? const Color(0xFF34C759)
                  : const Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    );
  }

  // Note Actions
  Widget _buildNoteActions(QuickNote note, bool isDark) {
    return Row(
      children: [
        // Convert to Expense
        Expanded(
          child: _buildActionButton(
            icon: Icons.shopping_cart_rounded,
            label: l10n.convertToExpense,
            color: const Color(0xFFFF3B30).withOpacity(0.1),
            textColor: const Color(0xFFFF3B30),
            onTap: () => _quickConvertToExpense(note),
          ),
        ),
        const SizedBox(width: 8),

        // Convert to Income
        Expanded(
          child: _buildActionButton(
            icon: Icons.trending_up_rounded,
            label: l10n.convertToIncome,
            color: const Color(0xFF34C759).withOpacity(0.1),
            textColor: const Color(0xFF34C759),
            onTap: () => _quickConvertToIncome(note),
          ),
        ),
        const SizedBox(width: 8),

        // Delete Button
        GestureDetector(
          onTap: () => _confirmDeleteNote(note),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.delete_rounded,
              color: Color(0xFFFF3B30),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // Empty State
  Widget _buildEmptyState(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.note_add_rounded,
            size: 64,
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getNoteTypeColor(QuickNoteType type) {
    switch (type) {
      case QuickNoteType.text:
        return const Color(0xFF007AFF);
      case QuickNoteType.voice:
        return const Color(0xFFFF6B35);
      case QuickNoteType.image:
        return const Color(0xFF34C759);
    }
  }

  IconData _getNoteTypeIcon(QuickNoteType type) {
    switch (type) {
      case QuickNoteType.text:
        return Icons.edit_note_rounded;
      case QuickNoteType.voice:
        return Icons.mic_rounded;
      case QuickNoteType.image:
        return Icons.camera_alt_rounded;
    }
  }

  String _formatNoteDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return l10n.timeNow;
    } else if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.timeDaysAgo(difference.inDays);
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  // Image Preview
  Widget _buildImagePreview(String imagePath, bool isDark) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              child: Icon(
                Icons.broken_image_rounded,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
                size: 32,
              ),
            );
          },
        ),
      ),
    );
  }

  // Quick Convert Methods
  Future<void> _quickConvertToExpense(QuickNote note) async {
    // TODO: Implement quick expense conversion
    debugPrint('Converting to expense: ${note.content}');
  }

  Future<void> _quickConvertToIncome(QuickNote note) async {
    // TODO: Implement quick income conversion
    debugPrint('Converting to income: ${note.content}');
  }

  Widget _buildQuickAddField(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isListening
            ? (isDark ? const Color(0xFF2C1810) : const Color(0xFFFFF4E6))
            : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isListening
              ? const Color(0xFFFF6B35)
              : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
          width: _isListening ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isListening
                ? const Color(0xFFFF6B35).withOpacity(0.2)
                : (isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1)),
            blurRadius: _isListening ? 12 : 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dynamic Icon based on state
          if (_isListening) ...[
            // Recording Animation
            _buildRecordingAnimation(isDark),
            const SizedBox(width: 8),

            // Recording Text with Wave Animation
            Expanded(child: _buildRecordingText(isDark)),
          ] else if (_selectedImage != null) ...[
            // Image Preview
            _buildImagePreview(_selectedImage!.path, isDark),
            const SizedBox(width: 8),

            // Text Field
            Expanded(child: _buildTextField(isDark)),
          ] else ...[
            // Text Field - no icon
            Expanded(child: _buildTextField(isDark)),
          ],

          const SizedBox(width: 6),

          // Action Buttons
          if (_isListening) ...[
            // Stop Recording Button
            _buildStopRecordingButton(),
          ] else ...[
            // Image Button
            _buildImageButton(isDark),
            const SizedBox(width: 2),

            // Voice Button
            _buildVoiceButton(isDark),
            const SizedBox(width: 2),

            // Send Button
            _buildSendButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingAnimation(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF6B35), width: 2),
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: Color(0xFFFF6B35),
              size: 18,
            ),
          ),
        );
      },
      onEnd: () {
        if (_isListening) {
          setState(() {}); // Trigger rebuild to restart animation
        }
      },
    );
  }

  Widget _buildRecordingText(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Dinleniyor...',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(height: 4),
        // Sound Level Indicator
        Row(
          children: List.generate(20, (index) {
            final isActive = index < (_soundLevel * 20).round();
            return Container(
              margin: const EdgeInsets.only(right: 2),
              width: 3,
              height: isActive ? 12 : 4,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFFF6B35)
                    : (isDark
                          ? const Color(0xFF48484A)
                          : const Color(0xFFE5E5EA)),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTextField(isDark) {
    return TextField(
      controller: _quickAddController,
      focusNode: _quickAddFocus,
      decoration: InputDecoration(
        hintText: _selectedImage != null
            ? 'Fotoğraf için açıklama ekle...'
            : 'Market 150${Provider.of<ThemeProvider>(context, listen: false).currency.symbol}, Kahve 25${Provider.of<ThemeProvider>(context, listen: false).currency.symbol}...',
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: 1,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _quickAddNote(),
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildImageButton(bool isDark) {
    return IconButton(
      onPressed: _pickImage,
      icon: const Icon(
        Icons.photo_camera_rounded,
        color: Color(0xFF007AFF),
        size: 18,
      ),
      tooltip: 'Fotoğraf Ekle',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildVoiceButton(bool isDark) {
    return IconButton(
      onPressed: _startListening,
      icon: const Icon(
        Icons.keyboard_voice_rounded,
        color: Color(0xFFFF6B35),
        size: 18,
      ),
      tooltip: 'Sesli Not',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildStopRecordingButton() {
    return IconButton(
      onPressed: () {
        _stopListening(); // Sadece durdur, gönderme
      },
      icon: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      tooltip: AppLocalizations.of(context)?.stop ?? 'Stop',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildSendButton() {
    return IconButton(
      onPressed: _quickAddNote,
      icon: const Icon(Icons.send_rounded, color: Color(0xFF34C759), size: 18),
      tooltip: AppLocalizations.of(context)?.send ?? 'Send',
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Color _getTypeColor(QuickNoteType type) {
    switch (type) {
      case QuickNoteType.text:
        return const Color(0xFF007AFF);
      case QuickNoteType.voice:
        return const Color(0xFF34C759);
      case QuickNoteType.image:
        return const Color(0xFFFF9500);
    }
  }

  IconData _getTypeIcon(QuickNoteType type) {
    switch (type) {
      case QuickNoteType.text:
        return Icons.text_fields_rounded;
      case QuickNoteType.voice:
        return Icons.mic_rounded;
      case QuickNoteType.image:
        return Icons.image_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 30) {
      return AppLocalizations.of(context)?.justNow ?? 'Just now';
    } else if (diff.inMinutes < 1) {
      return '${diff.inSeconds} saniye önce';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dakika önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays == 1) {
      return 'Dün ${DateFormat('HH:mm', 'tr_TR').format(date)}';
    } else if (diff.inDays < 7) {
      final weekdays = [
        'Pazartesi',
        'Salı',
        'Çarşamba',
        'Perşembe',
        'Cuma',
        'Cumartesi',
        'Pazar',
      ];
      return '${weekdays[date.weekday - 1]} ${DateFormat('HH:mm', 'tr_TR').format(date)}';
    } else if (diff.inDays < 365) {
      return DateFormat('dd MMM HH:mm', 'tr_TR').format(date);
    } else {
      return DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
    }
  }

  Future<void> _showAddNoteDialog() async {
    final controller = TextEditingController();

    final result = await IOSDialog.show<String>(
      context,
      title: 'Hızlı Not Ekle',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Harcama veya gelir notunuzu yazın. Daha sonra işlem olarak ekleyebilirsiniz.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText:
                  'Örn: Market alışverişi 150${Provider.of<ThemeProvider>(context, listen: false).currency.symbol}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF007AFF)),
              ),
            ),
            maxLines: 3,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        IOSDialogAction(
          text: AppLocalizations.of(context)?.cancel ?? 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        IOSDialogAction(
          text: 'Ekle',
          isPrimary: true,
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop(controller.text.trim());
            }
          },
        ),
      ],
    );

    if (result != null && result.isNotEmpty) {
      await _addNote(result);
    }
  }

  Future<void> _addNote(String content) async {
    try {
      await QuickNoteService.addQuickNote(content: content, type: 'text');

      // Bildirim güncelle
      await QuickNoteNotificationService.updateNotificationWithNewNote(content);

      await _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not eklenirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showNoteOptions(QuickNote note) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF48484A)
                        : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Note preview
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getTypeIcon(note.type),
                        size: 16,
                        color: _getTypeColor(note.type),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          note.content,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                if (!note.isProcessed) ...[
                  ListTile(
                    title: Text(
                      'İşleme Dönüştür',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                    subtitle: Text(
                      'Harcama veya gelir işlemi olarak ekle',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _convertToTransaction(note);
                    },
                  ),
                ],

                ListTile(
                  title: Text(
                    AppLocalizations.of(context)?.delete ?? 'Delete',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  subtitle: Text(
                    'Bu notu kalıcı olarak sil',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteNote(note);
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteNote(QuickNote note) async {
    final result = await IOSDialog.show<bool>(
      context,
      title: 'Notu Sil',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bu notu kalıcı olarak silmek istiyor musunuz?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              note.content,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IOSDialogAction(
          text: AppLocalizations.of(context)?.cancel ?? 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        IOSDialogAction(
          text: AppLocalizations.of(context)?.delete ?? 'Delete',
          isDestructive: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (result == true) {
      await _deleteNote(note);
    }
  }

  Future<void> _deleteNote(QuickNote note) async {
    try {
      await QuickNoteService.deleteQuickNote(note.id);
      await _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Not silindi',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Not silinirken hata oluştu',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _convertToTransaction(QuickNote note) async {
    try {
      // İşlem türünü belirlemek için dialog göster
      final transactionType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'İşlem Türü Seçin',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bu notu hangi türde işleme dönüştürmek istiyorsunuz?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, 'expense'),
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Gider',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, 'income'),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Gelir',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

      if (transactionType != null) {
        // İşlem türüne göre form sayfasına yönlendir
        final route = transactionType == 'income'
            ? '/income-form'
            : '/expense-form';

        // Not içeriğinden tutar ve kategori çıkar
        final extractedAmount = _extractAmountFromNote(note.content);
        final extractedCategory = _extractCategoryFromNote(note.content);

        debugPrint('  - Extracted amount: $extractedAmount');
        debugPrint('  - Extracted category: "$extractedCategory"');

        if (extractedCategory != null) {
          // Kategori türünü belirle
          final mainCategories = [
            'yemek',
            'ulaşım',
            'alışveriş',
            'faturalar',
            'eğlence',
            'sağlık',
            'eğitim',
            'market',
            'süpermarket',
            'restoran',
            'cafe',
            'taksi',
            'otobüs',
            'metro',
            'sinema',
            'tiyatro',
            'hastane',
            'eczane',
            'okul',
            'kurs',
          ];
          final isMainCategory = mainCategories.contains(
            extractedCategory.toLowerCase(),
          );
          debugPrint(
            '  - Category type: ${isMainCategory ? "Ana kategori" : "Kullanıcı kategorisi"}',
          );
        }

        // URL parametrelerini oluştur
        final params = <String, String>{};
        params['description'] = Uri.encodeComponent(note.content);
        // Türkiye saati için local time kullan (UTC+3 sorunu çözümü)
        final localDate = DateTime.now(); // Şu anki local time
        params['date'] = localDate.millisecondsSinceEpoch.toString();

        if (extractedAmount != null) {
          params['amount'] = extractedAmount.toString();
        }

        if (extractedCategory != null && extractedCategory.isNotEmpty) {
          params['category'] = Uri.encodeComponent(extractedCategory);
        }

        // URL'yi oluştur
        final queryString = params.entries
            .map((e) => '${e.key}=${e.value}')
            .join('&');
        final fullUrl = '$route?$queryString';

        // Form sayfasına git ve not içeriğini description olarak gönder
        if (mounted) {
          final result = await context.push(fullUrl);

          // Eğer transaction başarıyla kaydedildiyse (transaction ID döndüyse)
          if (result != null && result is String) {
            // Notu işlenmiş olarak işaretle ve transaction ID'sini kaydet
            await QuickNoteService.markNoteAsProcessed(note.id);

            // Notları yenile
            await _loadNotes();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text('Not başarıyla işleme dönüştürüldü'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            // Transaction kaydedilmedi, sadece notları yenile
            await _loadNotes();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Not dönüştürülürken hata oluştu'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(QuickNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Notu Sil',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        content: Text(
          'Bu notu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6D6D70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF007AFF),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)?.delete ?? 'Delete',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await QuickNoteService.deleteQuickNote(note.id);
        await _loadNotes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text('Not silindi'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Not silinirken hata oluştu'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _showFullScreenImage(QuickNote note) async {
    if (note.imagePath == null || note.imagePath!.isEmpty) return;

    await showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Full screen image
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  File(note.imagePath!),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Fotoğraf yüklenemedi',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note.imagePath!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Note info overlay
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.image_rounded,
                          color: Color(0xFFFF9500),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note.content,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(note.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAddNote() async {
    final content = _quickAddController.text.trim();
    if (content.isEmpty && _selectedImage == null) return;

    try {
      // Loading indicator göster
      setState(() => _isLoading = true);

      // Eğer fotoğraf varsa image note, yoksa text note
      final noteType = _selectedImage != null
          ? QuickNoteType.image
          : QuickNoteType.text;
      final noteContent = content.isEmpty ? 'Fotoğraf notu' : content;

      await QuickNoteService.addQuickNote(
        content: noteContent,
        type: noteType.toString().split('.').last,
        imagePath: _selectedImage?.path,
      );

      // Bildirim güncelle
      await QuickNoteNotificationService.updateNotificationWithNewNote(
        noteContent,
      );

      // Text field'ı temizle
      _quickAddController.clear();

      // Seçili fotoğrafı temizle
      setState(() {
        _selectedImage = null;
      });

      // Focus'ı kaldır
      _quickAddFocus.unfocus();

      // Notları yenile
      await _loadNotes();

      // Bekleyen notlar sekmesine geç
      setState(() => _showProcessed = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Not eklendi: ${content.length > 30 ? '${content.substring(0, 30)}...' : content}',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Not eklenirken hata oluştu'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Speech to Text Functions
  Future<void> _initSpeech() async {
    try {
      // Mikrofon izni iste
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return;
      }

      // Speech to Text'i başlat
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          setState(() {
            _isListening = false;
          });
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Sesli not özelliği kullanılamıyor'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isListening = true;
      });

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _quickAddController.text = result.recognizedWords;
          });
        },
        onSoundLevelChange: (level) {
          setState(() {
            _soundLevel = level;
          });
        },
        localeId: 'tr_TR', // Türkçe
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      setState(() {
        _isListening = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Sesli not başlatılırken hata oluştu'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });

      // Eğer metin varsa focus'u text field'a ver
      if (_quickAddController.text.trim().isNotEmpty) {
        _quickAddFocus.requestFocus();
        _quickAddController.selection = TextSelection.fromPosition(
          TextPosition(offset: _quickAddController.text.length),
        );
      }
    } catch (e) {
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _pickImage() async {
    // Show bottom sheet with camera/gallery options
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF8E8E93),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF007AFF),
              ),
              title: Text(
                'Kamera',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),

            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFF34C759),
              ),
              title: Text(
                'Galeri',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: result,
        imageQuality: 70,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // Focus text field for description
        _quickAddFocus.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Fotoğraf seçilirken hata oluştu'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _getTransactionDetails(String transactionId) async {
    try {
      final provider = Provider.of<UnifiedProviderV2>(context, listen: false);

      // Transaction'ı ID ile bul
      final transaction = provider.transactions.firstWhere(
        (t) => t.id == transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );

      // Account bilgisini al - TransactionWithDetailsV2'de sourceAccountName zaten var
      final accountName = transaction.sourceAccountName ?? 'Bilinmeyen hesap';

      // Category bilgisini al - TransactionWithDetailsV2'de categoryName zaten var
      final categoryName = transaction.categoryName ?? 'Bilinmeyen kategori';

      // Tutar formatla
      final amount = NumberFormat(
        '#,##0.00',
        'tr_TR',
      ).format(transaction.amount);

      // Tarih formatla - transactionDate property'sini kullan
      final date = DateFormat(
        'dd.MM.yyyy HH:mm',
        'tr_TR',
      ).format(transaction.transactionDate);

      // Format: "45,00 ₺ • Çay • Kuveyt Türk Banka Kartı • 20.01.2025 14:30"
      return '$amount ₺ • $categoryName • $accountName • $date';
    } catch (e) {
      return null;
    }
  }

  /// Not içeriğinden tutar çıkarır
  /// Örnek: "25 lira çay" -> 25.0
  /// Örnek: "100₺ market" -> 100.0
  /// Örnek: "çay 35" -> 35.0
  double? _extractAmountFromNote(String content) {
    try {
      // Türkçe sayı formatları için regex
      final regexPatterns = [
        r'(\d+(?:[.,]\d+)?)\s*(?:lira|tl|₺)', // "25 lira", "100₺", "15.5₺"
        r'(\d+(?:[.,]\d+)?)\s+\w+', // "25 çay", "100 market"
        r'\w+\s+(\d+(?:[.,]\d+)?)', // "çay 25", "market 100"
        r'^(\d+(?:[.,]\d+)?)', // Başta sayı "25 lira çay"
        r'(\d+(?:[.,]\d+)?)$', // Sonda sayı "çay 25"
      ];

      for (final pattern in regexPatterns) {
        final regex = RegExp(pattern, caseSensitive: false);
        final match = regex.firstMatch(content.toLowerCase());

        if (match != null) {
          final amountStr = match.group(1)!.replaceAll(',', '.');
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0) {
            return amount;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Not içeriğinden kategori tahmin eder
  /// %100 eşleşme varsa kategori adını, yoksa kullanıcının yazdığı kelimeyi döndürür
  /// Örnek: "25 lira yemek" -> "yemek" (tam eşleşme)
  /// Örnek: "25 lira çay" -> "çay" (kullanıcının yazdığı kelime)
  String? _extractCategoryFromNote(String content) {
    try {
      final lowercaseContent = content.toLowerCase();

      // Ana kategori isimleri (tam eşleşme için)
      final mainCategories = [
        'yemek',
        'ulaşım',
        'alışveriş',
        'faturalar',
        'eğlence',
        'sağlık',
        'eğitim',
        'market',
        'süpermarket',
        'restoran',
        'cafe',
        'taksi',
        'otobüs',
        'metro',
        'sinema',
        'tiyatro',
        'hastane',
        'eczane',
        'okul',
        'kurs',
      ];

      // Önce tam kategori eşleşmesi ara
      for (final category in mainCategories) {
        if (lowercaseContent.contains(category)) {
          return category;
        }
      }

      // Tam eşleşme yoksa, tutar kısmını çıkarıp kalan kelimeyi al
      String cleanContent = content;

      // Tutar ve para birimi ifadelerini çıkar
      final amountPatterns = [
        r'\d+(?:[.,]\d+)?\s*(?:lira|tl|₺)', // "25 lira", "100₺", "15.5₺"
        r'\d+(?:[.,]\d+)?', // Sadece sayı "25"
      ];

      for (final pattern in amountPatterns) {
        final regex = RegExp(pattern, caseSensitive: false);
        cleanContent = cleanContent.replaceAll(regex, '').trim();
      }

      // Gereksiz kelimeleri çıkar
      final stopWords = [
        'için',
        'aldım',
        'yaptım',
        'gittim',
        'ile',
        've',
        'bir',
        'bu',
        'şu',
        'o',
      ];
      for (final stopWord in stopWords) {
        cleanContent = cleanContent
            .replaceAll(RegExp('\\b$stopWord\\b', caseSensitive: false), '')
            .trim();
      }

      // Birden fazla boşluğu tek boşluğa çevir
      cleanContent = cleanContent.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Eğer temizlenmiş içerik makul uzunluktaysa, onu kategori olarak kullan
      if (cleanContent.isNotEmpty &&
          cleanContent.length <= 20 &&
          !cleanContent.contains(' ')) {
        return cleanContent;
      }

      // Eğer birden fazla kelime varsa, ilk kelimeyi al
      final words = cleanContent.split(' ');
      if (words.isNotEmpty && words.first.length > 2) {
        return words.first;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
