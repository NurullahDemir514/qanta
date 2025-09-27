import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/quick_note_notification_service.dart';
import '../../l10n/app_localizations.dart';

/// Hızlı not girişi için dialog
class QuickNoteDialog extends StatefulWidget {
  const QuickNoteDialog({super.key});

  @override
  State<QuickNoteDialog> createState() => _QuickNoteDialogState();
}

class _QuickNoteDialogState extends State<QuickNoteDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadCurrentNote();
  }

  Future<void> _loadCurrentNote() async {
    final currentNote = await QuickNoteNotificationService.getNoteContent();
    _controller.text = currentNote;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await QuickNoteNotificationService.updateNote(_controller.text.trim());
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hızlı not güncellendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Hızlı Not',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Notunuzu buraya yazın...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF007AFF),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            ),
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)?.cancel ?? 'Cancel',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _saveNote,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                  ),
                )
              : Text(
                  'Kaydet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007AFF),
                  ),
                ),
        ),
      ],
    );
  }
} 