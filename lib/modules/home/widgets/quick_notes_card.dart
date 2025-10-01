import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/providers/unified_provider_v2.dart';
import '../../../core/services/services_v2.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/models_v2.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ios_dialog.dart';
import '../pages/quick_notes_page.dart';

class QuickNotesCard extends StatefulWidget {
  const QuickNotesCard({super.key});

  @override
  State<QuickNotesCard> createState() => _QuickNotesCardState();
}

class _QuickNotesCardState extends State<QuickNotesCard> {
  List<Map<String, dynamic>> _pendingNotes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingNotes();
  }

  Future<void> _loadPendingNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await QuickNoteService.getPendingNotes();
      for (var note in notes) {
      }
      setState(() => _pendingNotes = notes.cast<Map<String, dynamic>>());
    } catch (e) {
      debugPrint('Hızlı notlar yüklenirken hata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.note_add_rounded,
                        color: Color(0xFF007AFF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.quickNotes,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        if (_pendingNotes.isNotEmpty)
                          Text(
                            l10n.pendingNotes(_pendingNotes.length),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _showAddOptionsDialog,
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF007AFF),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ),

          // Notes List or Empty State
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_pendingNotes.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 32,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.noNotesYet ?? 'No notes yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)?.addExpenseIncomeNotes ?? 'Add your expense or income notes here',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _pendingNotes.length > 3 ? 3 : _pendingNotes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final noteMap = _pendingNotes[index];
                // Convert Map to QuickNote
                final note = QuickNote.fromJson(noteMap);
                debugPrint('QuickNotesCard: Converting Map to QuickNote');
                return _buildNoteItem(note, isDark);
              },
            ),

          // Show All Button
          if (_pendingNotes.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuickNotesPage(notes: _pendingNotes.cast<QuickNote>()),
                    ),
                  );
                },
                child: Text(
                  l10n.viewAllNotes(_pendingNotes.length),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF007AFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(QuickNote note, bool isDark) {
    // Debug: Image path'i yazdır
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Type indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getNoteTypeColor(note.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getNoteTypeIcon(note.type),
              size: 14,
              color: _getNoteTypeColor(note.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content
                Text(
                  note.content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Date
                Text(
                  _formatDate(note.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ),
                // Image preview if exists
                if (note.imagePath != null && note.imagePath!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(note.imagePath!),
                      height: 60,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 60,
                          width: 80,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: Color(0xFF8E8E93),
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteNote(note),
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xFF8E8E93),
            ),
            style: IconButton.styleFrom(
              minimumSize: const Size(24, 24),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Color _getNoteTypeColor(QuickNoteType type) {
    switch (type) {
      case QuickNoteType.text:
        return const Color(0xFF007AFF);
      case QuickNoteType.voice:
        return const Color(0xFF34C759);
      case QuickNoteType.image:
        return const Color(0xFFFF9500);
    }
  }

  IconData _getNoteTypeIcon(QuickNoteType type) {
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

    final l10n = AppLocalizations.of(context)!;
    if (diff.inSeconds < 30) {
      return l10n.justNow;
    } else if (diff.inMinutes < 1) {
      return l10n.secondsAgo(diff.inSeconds);
    } else if (diff.inMinutes < 60) {
      return l10n.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n.hoursAgo(diff.inHours);
    } else if (diff.inDays == 1) {
      return l10n.yesterdayAt('${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}');
    } else if (diff.inDays < 7) {
      final weekdays = [
        AppLocalizations.of(context)?.monday ?? 'Monday',
        AppLocalizations.of(context)?.tuesday ?? 'Tuesday',
        AppLocalizations.of(context)?.wednesday ?? 'Wednesday',
        AppLocalizations.of(context)?.thursday ?? 'Thursday',
        AppLocalizations.of(context)?.friday ?? 'Friday',
        AppLocalizations.of(context)?.saturday ?? 'Saturday',
        AppLocalizations.of(context)?.sunday ?? 'Sunday'
      ];
      return l10n.weekdayAt(weekdays[date.weekday - 1], '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}');
    } else if (diff.inDays < 365) {
      final months = [
        l10n.january,
        l10n.february,
        l10n.march,
        l10n.april,
        l10n.may,
        l10n.june,
        l10n.july,
        l10n.august,
        l10n.september,
        l10n.october,
        l10n.november,
        l10n.december
      ];
      return l10n.dayMonth(date.day, months[date.month - 1]);
    } else {
      return l10n.dayMonthYear(date.day, date.month, date.year);
    }
  }

  Future<void> _showAddOptionsDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF48484A) : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                l10n.addQuickNote,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              
              // Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildOptionTile(
                      icon: Icons.text_fields_rounded,
                      title: l10n.textNote,
                      subtitle: l10n.addQuickTextNote,
                      color: const Color(0xFF007AFF),
                      onTap: () {
                        Navigator.pop(context);
                        _showAddNoteDialog();
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionTile(
                      icon: Icons.camera_alt_rounded,
                      title: l10n.takePhoto,
                      subtitle: l10n.takePhotoFromCamera,
                      color: const Color(0xFFFF9500),
                      onTap: () async {
                        Navigator.pop(context);
                        await Future.delayed(const Duration(milliseconds: 100));
                        _takePicture();
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionTile(
                      icon: Icons.photo_library_rounded,
                      title: l10n.selectFromGallery,
                      subtitle: l10n.selectPhotoFromGallery,
                      color: const Color(0xFF34C759),
                      onTap: () async {
                        Navigator.pop(context);
                        await Future.delayed(const Duration(milliseconds: 100));
                        _pickImageFromGallery();
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
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
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    final l10n = AppLocalizations.of(context)!;
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      
      if (image != null) {
        await _showImageNoteDialog(image.path);
      } else {
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.photoCaptureError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final l10n = AppLocalizations.of(context)!;
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      
      if (image != null) {
        await _showImageNoteDialog(image.path);
      } else {
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.photoSelectionError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageNoteDialog(String imagePath) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => IOSDialog(
        title: l10n.addPhotoNote,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.addPhotoNoteDescription,
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
                hintText: l10n.examplePhotoNote(Provider.of<ThemeProvider>(context, listen: false).currency.symbol),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF007AFF)),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          IOSDialogAction(
            text: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
          IOSDialogAction(
            text: l10n.add,
            isPrimary: true,
            onPressed: () {
              Navigator.of(context).pop(controller.text.trim());
            },
          ),
        ],
      ),
    );

    if (result != null) {
      await _addImageNote(result.isEmpty ? l10n.photoNote : result, imagePath);
    }
  }

  Future<void> _addImageNote(String content, String imagePath) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      
      await QuickNoteService.addQuickNote(
        content: content,
        type: 'image',
        imagePath: imagePath,
      );
      await _loadPendingNotes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.photoNoteAdded),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.photoNoteAddError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddNoteDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => IOSDialog(
        title: l10n.addQuickNote,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.addQuickNoteDescription,
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
                hintText: l10n.exampleExpenseNote(Provider.of<ThemeProvider>(context, listen: false).currency.symbol),
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
            text: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
          IOSDialogAction(
            text: l10n.add,
            isPrimary: true,
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _addNote(result);
    }
  }

  Future<void> _addNote(String content) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await QuickNoteService.addQuickNote(
        content: content,
        type: 'text',
      );
      await _loadPendingNotes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noteAdded),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noteAddError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote(QuickNote note) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await QuickNoteService.deleteQuickNote(note.id);
      await _loadPendingNotes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noteDeleted),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noteDeleteError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 