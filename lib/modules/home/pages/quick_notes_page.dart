import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/services/quick_note_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/models_v2.dart';
import '../../../shared/models/unified_category_model.dart' as unified;
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/unified_provider_v2.dart';

class QuickNotesPageNew extends StatefulWidget {
  final List<QuickNote>? notes;

  const QuickNotesPageNew({super.key, this.notes});

  @override
  State<QuickNotesPageNew> createState() => _QuickNotesPageNewState();
}

class _QuickNotesPageNewState extends State<QuickNotesPageNew>
    with TickerProviderStateMixin {
  List<QuickNote> _allNotes = [];
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;

  // Image Picker
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedImagePath;

  // Quick capture state
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final FocusNode _itemFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _accountFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _initSpeech();
    _initAnimations();
  }

  void _initAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _itemController.dispose();
    _amountController.dispose();
    _accountController.dispose();
    _descriptionController.dispose();
    _itemFocus.dispose();
    _amountFocus.dispose();
    _accountFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      // Önce mikrofon iznini kontrol et
      final permission = await Permission.microphone.status;
      if (permission != PermissionStatus.granted) {
        debugPrint('Microphone permission not granted');
        _speechEnabled = false;
        setState(() {});
        return;
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          setState(() {
            _isListening = false;
          });
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
        debugLogging: true,
      );

      if (_speechEnabled) {
        debugPrint('Speech recognition initialized successfully');
      } else {
        debugPrint('Speech recognition initialization failed');
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      _speechEnabled = false;
      setState(() {});
    }
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await QuickNoteService.getUserQuickNotes();
      setState(() {
        _allNotes = notes;
      });
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startQuickCapture() {
    _showAddNoteBottomSheet();
  }

  void _showAddNoteBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddNoteBottomSheet(),
    ).then((_) {
      // Bottom sheet kapandığında focus'u kaldır
      _itemFocus.unfocus();
      _amountFocus.unfocus();
      _accountFocus.unfocus();
      _descriptionFocus.unfocus();
    });
  }

  Future<void> _saveQuickCapture() async {
    if (_itemController.text.trim().isEmpty &&
        _amountController.text.trim().isEmpty &&
        _selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir alan doldurulmalı'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      // Form verilerini birleştir
      final content = _buildNoteContent();
      String noteType = 'text';
      if (_selectedImagePath != null) {
        noteType = 'image';
      }

      await QuickNoteService.addQuickNote(
        content: content,
        type: noteType,
        imagePath: _selectedImagePath,
      );

      // Clear form
      _clearForm();

      // Close bottom sheet
      Navigator.pop(context);

      // Reload notes
      _loadNotes();

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not başarıyla eklendi!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not eklenirken hata oluştu'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _buildNoteContent() {
    final parts = <String>[];

    if (_itemController.text.trim().isNotEmpty) {
      parts.add('İşlem Adı: ${_itemController.text.trim()}');
    }

    if (_amountController.text.trim().isNotEmpty) {
      parts.add('Tutar: ${_amountController.text.trim()}');
    }

    if (_accountController.text.trim().isNotEmpty) {
      parts.add('Hesap: ${_accountController.text.trim()}');
    }

    if (_descriptionController.text.trim().isNotEmpty) {
      parts.add('Açıklama: ${_descriptionController.text.trim()}');
    }

    return parts.join('\n');
  }

  void _clearForm() {
    _itemController.clear();
    _amountController.clear();
    _accountController.clear();
    _descriptionController.clear();
    _selectedImagePath = null;
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ses tanıma servisi kullanılamıyor'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Mikrofon izni kontrol et
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon izni gerekli'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Eğer zaten dinliyorsa, önce durdur
      if (_speechToText.isListening) {
        await _speechToText.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() => _isListening = true);

      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _itemController.text = result.recognizedWords;
            });
          }
        },
        listenFor: const Duration(seconds: 10), // Daha kısa süre
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation, // Daha basit mod
        localeId: 'tr_TR', // Türkçe dil desteği
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses tanıma başlatılamadı'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      if (mounted) {
        setState(() => _isListening = false);
      }
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  void _convertToTransaction(QuickNote note, String transactionType) {
    try {
      print('=== CONVERTING TO TRANSACTION ===');
      print('Note content: ${note.content}');
      print('Transaction type: $transactionType');

      // Hızlı not içeriğini parse et
      final parsedData = _parseQuickNoteContent(note.content);

      // Amount'u double'a çevir
      double? amount;
      if (parsedData['amount'] != null &&
          parsedData['amount'].toString().isNotEmpty) {
        final amountStr = parsedData['amount'].toString().replaceAll(',', '.');
        print('Amount string before parsing: "$amountStr"');
        amount = double.tryParse(amountStr);
        print('Converted amount: $amount');
      } else {
        print('No amount found in parsed data');
      }

      // Hesap ID'sini bul
      String? accountId;
      if (parsedData['account'] != null &&
          parsedData['account'].toString().isNotEmpty) {
        final provider = Provider.of<UnifiedProviderV2>(context, listen: false);
        final accounts = provider.accounts;
        print('Available accounts: ${accounts.map((a) => a.name).toList()}');
        print('Looking for account: ${parsedData['account']}');

        final account = accounts.firstWhere(
          (acc) => acc.name == parsedData['account'],
          orElse: () => accounts.isNotEmpty
              ? accounts.first
              : AccountModel(
                  id: '',
                  name: '',
                  type: AccountType.cash,
                  balance: 0.0,
                  userId: '',
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
        );
        accountId = account.id;
        print('Found account ID: $accountId');
      }

      final formData = {
        'initialAmount': amount,
        'initialDescription': parsedData['description'] ?? '',
        'initialCategoryId': parsedData['item'] ?? '',
        'initialPaymentMethodId': accountId,
        'initialStep': 3, // Direkt detay adımına git (4. adım, 0-indexed)
      };

      print('Form data: $formData');

      if (transactionType == 'expense') {
        print('Navigating to expense form...');
        context.push('/expense-form', extra: formData);
      } else {
        print('Navigating to income form...');
        context.push('/income-form', extra: formData);
      }

      print('=== END CONVERSION ===');
    } catch (e) {
      print('Error navigating to transaction form: $e');
      debugPrint('Error navigating to transaction form: $e');
    }
  }

  Map<String, dynamic> _parseQuickNoteContent(String content) {
    final parsedData = <String, dynamic>{};

    print('=== PARSING QUICK NOTE CONTENT ===');
    print('Content: $content');

    // Hızlı not içeriğini satırlara böl
    final lines = content.split('\n');
    print('Lines: $lines');

    for (final line in lines) {
      print('Processing line: $line');
      if (line.contains('İşlem Adı:')) {
        parsedData['item'] = line.replaceFirst('İşlem Adı:', '').trim();
        print('Found item (new format): ${parsedData['item']}');
      } else if (line.contains('Ne:')) {
        parsedData['item'] = line.replaceFirst('Ne:', '').trim();
        print('Found item (old format): ${parsedData['item']}');
      } else if (line.contains('Tutar:')) {
        final amountText = line
            .replaceFirst('Tutar:', '')
            .replaceAll('TL', '')
            .replaceAll('₺', '')
            .replaceAll(',', '.')
            .trim();
        parsedData['amount'] = amountText;
        print('Found amount: ${parsedData['amount']}');
      } else if (line.contains('Hesap:')) {
        parsedData['account'] = line.replaceFirst('Hesap:', '').trim();
        print('Found account: ${parsedData['account']}');
      } else if (line.contains('Açıklama:')) {
        parsedData['description'] = line.replaceFirst('Açıklama:', '').trim();
        print('Found description: ${parsedData['description']}');
      }
    }

    print('Parsed data: $parsedData');
    print('=== END PARSING ===');

    return parsedData;
  }

  Map<String, dynamic> _analyzeNoteContent(
    String content,
    String transactionType,
  ) {
    final formData = <String, dynamic>{};
    final lowerContent = content.toLowerCase();

    // Tutar analizi
    final amountPattern = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:tl|₺|lira|türk lirası)?',
      caseSensitive: false,
    );
    final amountMatch = amountPattern.firstMatch(lowerContent);
    if (amountMatch != null) {
      String amountStr = amountMatch.group(1)!.replaceAll(',', '.');
      final amount = double.tryParse(amountStr);
      if (amount != null) {
        formData['amount'] = amount;
      }
    }

    // Kategori analizi
    final category = _extractCategory(lowerContent, transactionType);
    if (category != null) {
      formData['category'] = category;
    }

    // Açıklama analizi
    final description = _extractDescription(content);
    if (description != null) {
      formData['description'] = description;
    }

    // Ödeme yöntemi analizi
    final paymentMethod = _extractPaymentMethod(lowerContent);
    if (paymentMethod != null) {
      formData['paymentMethod'] = paymentMethod;
    }

    return formData;
  }

  String? _extractCategory(String content, String transactionType) {
    if (transactionType == 'expense') {
      if (content.contains('yemek') ||
          content.contains('restoran') ||
          content.contains('kahve')) {
        return 'Yemek';
      }
      if (content.contains('benzin') ||
          content.contains('yakıt') ||
          content.contains('ulaşım')) {
        return 'Ulaşım';
      }
      if (content.contains('market') || content.contains('alışveriş')) {
        return 'Alışveriş';
      }
      if (content.contains('fatura') ||
          content.contains('elektrik') ||
          content.contains('su')) {
        return 'Faturalar';
      }
    } else {
      if (content.contains('maaş') || content.contains('ücret')) {
        return 'Maaş';
      }
      if (content.contains('freelance') || content.contains('proje')) {
        return 'Freelance';
      }
      if (content.contains('yatırım') || content.contains('hisse')) {
        return 'Yatırım';
      }
    }
    return null;
  }

  String? _extractDescription(String content) {
    final sentences = content.split(RegExp(r'[.!?]'));
    if (sentences.isNotEmpty && sentences.first.trim().isNotEmpty) {
      return sentences.first.trim();
    }
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  String? _extractPaymentMethod(String content) {
    if (content.contains('nakit') || content.contains('para')) {
      return 'Nakit';
    }
    if (content.contains('kredi kartı') || content.contains('kredi')) {
      return AppLocalizations.of(context)!.creditCard;
    }
    if (content.contains('banka kartı') || content.contains('debit')) {
      return AppLocalizations.of(context)!.debitCard;
    }
    return null;
  }

  Future<void> _deleteNote(String id) async {
    try {
      await QuickNoteService.deleteQuickNote(id);
      _loadNotes();
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppPageScaffold(
      title: 'Hızlı Notlar',
      subtitle: 'Düşüncelerini kaydet',
      onRefresh: _loadNotes,
      body: SliverToBoxAdapter(
        child: Column(
          children: [
            // Notes List
            _buildNotesList(isDark),

            // Bottom padding for FAB
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(isDark),
    );
  }

  Widget _buildNotesList(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_allNotes.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allNotes.length,
      itemBuilder: (context, index) {
        final note = _allNotes[index];
        return _buildNoteCard(note, isDark);
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz not yok',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk notunuzu eklemek için + butonuna dokunun',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(QuickNote note, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showNoteDetails(note, isDark),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    _buildNoteTypeIcon(note.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hızlı Not',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getNoteTypeColor(note.type),
                            ),
                          ),
                          Text(
                            DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(note.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _deleteNote(note.id),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Content
                if (note.content.isNotEmpty) ...[
                  Text(
                    note.content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],

                // Image Preview
                if (note.imagePath != null) ...[
                  GestureDetector(
                    onTap: () => _showImagePreview(note.imagePath!),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF48484A)
                              : const Color(0xFFE5E5EA),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.file(
                              File(note.imagePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.zoom_in_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Buttons
                if (!note.isProcessed) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.trending_down_rounded,
                          label: 'Gider',
                          color: AppColors.error,
                          onTap: () => _convertToTransaction(note, 'expense'),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.trending_up_rounded,
                          label: 'Gelir',
                          color: AppColors.success,
                          onTap: () => _convertToTransaction(note, 'income'),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'İşleme Dönüştürüldü',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTypeIcon(QuickNoteType type) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getNoteTypeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getNoteTypeIcon(type),
        color: _getNoteTypeColor(type),
        size: 16,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: _startQuickCapture,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: Text(
        'Hızlı Not',
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAddNoteBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Yeni Not Ekle',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // İşlem Adı
                    _buildFormFieldWithChips(
                      controller: _itemController,
                      focusNode: _itemFocus,
                      label: 'İşlem Adı',
                      hint: 'Örn: Kahve, Benzin, Market...',
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      isDark: isDark,
                      chipType: 'category',
                    ),

                    const SizedBox(height: 16),

                    // Ne kadar?
                    _buildFormFieldWithChips(
                      controller: _amountController,
                      focusNode: _amountFocus,
                      label: 'Ne kadar?',
                      hint: 'Örn: 25.50',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      isDark: isDark,
                      chipType: 'amount',
                    ),

                    const SizedBox(height: 16),

                    // Hangi hesaptan? - Kart Seçimi
                    _buildAccountSelector(isDark),

                    const SizedBox(height: 16),

                    // Açıklama
                    _buildFormField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocus,
                      label: 'Açıklama (Opsiyonel)',
                      hint: 'Ek detaylar...',
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.done,
                      maxLines: 2,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 20),

                    // Media Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildMediaButton(
                            icon: Icons.photo_library_rounded,
                            label: 'Galeri',
                            color: AppColors.info,
                            onTap: _pickImage,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMediaButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Kamera',
                            color: AppColors.warning,
                            onTap: _takePhoto,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Selected Image Preview
                    if (_selectedImagePath != null) ...[
                      GestureDetector(
                        onTap: () => _showImagePreview(_selectedImagePath!),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF48484A)
                                  : const Color(0xFFE5E5EA),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Image.file(
                                  File(_selectedImagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedImagePath = null,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _saveQuickCapture,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          'Notu Kaydet',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldWithChips({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    required bool isDark,
    required String chipType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: (value) {
            // Klavye geçişleri
            if (textInputAction == TextInputAction.next) {
              _handleNextField(focusNode);
            } else if (textInputAction == TextInputAction.done) {
              focusNode.unfocus();
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        _buildChipsRow(chipType, isDark),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: (value) {
            // Klavye geçişleri
            if (textInputAction == TextInputAction.next) {
              _handleNextField(focusNode);
            } else if (textInputAction == TextInputAction.done) {
              focusNode.unfocus();
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildChipsRow(String chipType, bool isDark) {
    final chips = chipType == 'category'
        ? _getCategoryChips()
        : _getAmountChips();

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chip = chips[index];
          return GestureDetector(
            onTap: () {
              if (chipType == 'category') {
                _itemController.text = chip;
              } else {
                _amountController.text = chip;
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: index < chips.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF48484A)
                    : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                chip,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getCategoryChips() {
    // Kullanıcının en çok kullandığı kategorileri al
    final mostUsedCategories = Provider.of<UnifiedProviderV2>(
      context,
      listen: false,
    ).getMostUsedCategories(type: unified.CategoryType.expense, topN: 8);

    // Eğer kullanıcının kategorisi yoksa varsayılan kategoriler
    if (mostUsedCategories.isEmpty) {
      return [
        'Kahve',
        'Benzin',
        'Market',
        'Yemek',
        'Ulaşım',
        'Eğlence',
        'Sağlık',
        'Giyim',
      ];
    }

    // Kullanıcının kategorilerini döndür
    return mostUsedCategories.map((entry) => entry.key).toList();
  }

  List<String> _getAmountChips() {
    // Kullanıcının en çok kullandığı fiyat aralıklarını al
    final transactions = Provider.of<UnifiedProviderV2>(
      context,
      listen: false,
    ).transactions.where((tx) => tx.type == TransactionType.expense).toList();

    if (transactions.isEmpty) {
      // Varsayılan fiyat aralıkları
      return ['5₺', '10₺', '25₺', '50₺', '100₺', '200₺', '500₺', '1000₺'];
    }

    // Son 30 günün işlemlerini al
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentTransactions = transactions
        .where((tx) => tx.transactionDate.isAfter(thirtyDaysAgo))
        .toList();

    if (recentTransactions.isEmpty) {
      // Son 30 günde işlem yoksa tüm işlemlerden al
      return _getCommonAmounts(transactions);
    }

    return _getCommonAmounts(recentTransactions);
  }

  List<String> _getCommonAmounts(List<dynamic> transactions) {
    // Fiyat aralıklarını hesapla
    final amounts = transactions.map((tx) => tx.amount).toList();
    amounts.sort();

    // Yaygın fiyat aralıklarını bul
    final commonAmounts = <String>[];

    // En küçük, orta ve en büyük değerler
    if (amounts.isNotEmpty) {
      final minAmount = amounts.first;
      final maxAmount = amounts.last;
      final medianAmount = amounts[amounts.length ~/ 2];

      // Yuvarlanmış değerler
      final roundedMin = _roundToNearestCommon(minAmount);
      final roundedMax = _roundToNearestCommon(maxAmount);
      final roundedMedian = _roundToNearestCommon(medianAmount);

      // Benzersiz değerleri ekle
      final uniqueAmounts = <double>{};
      uniqueAmounts.addAll([roundedMin, roundedMedian, roundedMax]);

      // Yaygın fiyat aralıklarını ekle
      final commonRanges = [5.0, 10.0, 25.0, 50.0, 100.0, 200.0, 500.0, 1000.0];
      for (final range in commonRanges) {
        if (range >= minAmount && range <= maxAmount) {
          uniqueAmounts.add(range);
        }
      }

      // Sırala ve string'e çevir
      final sortedAmounts = uniqueAmounts.toList()..sort();
      commonAmounts.addAll(
        sortedAmounts.take(8).map((amount) => '${amount.toInt()}₺'),
      );
    }

    // Eğer yeterli veri yoksa varsayılan değerler
    if (commonAmounts.length < 4) {
      return ['5₺', '10₺', '25₺', '50₺', '100₺', '200₺', '500₺', '1000₺'];
    }

    return commonAmounts;
  }

  double _roundToNearestCommon(double amount) {
    // Yaygın fiyat aralıklarına yuvarla
    final commonAmounts = [5.0, 10.0, 25.0, 50.0, 100.0, 200.0, 500.0, 1000.0];

    for (final common in commonAmounts) {
      if (amount <= common) {
        return common;
      }
    }

    // Eğer 1000'den büyükse 1000'in katlarına yuvarla
    return ((amount / 1000).ceil() * 1000).toDouble();
  }

  void _handleNextField(FocusNode currentFocus) {
    if (currentFocus == _itemFocus) {
      _amountFocus.requestFocus();
    } else if (currentFocus == _amountFocus) {
      _descriptionFocus.requestFocus();
    }
  }

  Widget _buildAccountSelector(bool isDark) {
    return Selector<UnifiedProviderV2, List<AccountModel>>(
      selector: (context, provider) => provider.accounts,
      builder: (context, accounts, child) {
        if (accounts.isEmpty) {
          return _buildEmptyAccountState(isDark);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hangi hesaptan?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildOptimizedAccountChips(accounts, isDark),
          ],
        );
      },
    );
  }

  Widget _buildOptimizedAccountChips(List<AccountModel> accounts, bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];

          return _buildAccountChip(
            account,
            isDark,
            index < accounts.length - 1,
          );
        },
      ),
    );
  }

  Widget _buildAccountChip(AccountModel account, bool isDark, bool hasMargin) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _accountController,
      builder: (context, value, child) {
        final isSelected = value.text == account.name;

        return InkWell(
          onTap: () {
            print('Account tapped: ${account.name}');
            _selectAccount(account.name);
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 70,
            height: 50,
            margin: EdgeInsets.only(right: hasMargin ? 6 : 0),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                    ? const Color(0xFF48484A)
                    : const Color(0xFFE5E5EA),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Center(
              child: Text(
                account.name,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : isDark
                      ? Colors.white70
                      : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectAccount(String accountName) {
    print('Selecting account: $accountName');
    _accountController.text = accountName;
    print('Account controller updated: ${_accountController.text}');
  }

  Widget _buildEmptyAccountState(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hangi hesaptan?',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA),
            ),
          ),
          child: Center(
            child: Text(
              'Henüz hesap eklenmemiş',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDetails(QuickNote note, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNoteDetailsModal(note, isDark),
    );
  }

  Widget _buildNoteDetailsModal(QuickNote note, bool isDark) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        _buildNoteTypeIcon(note.type),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hızlı Not',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _getNoteTypeColor(note.type),
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'dd MMMM yyyy, HH:mm',
                                ).format(note.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Content
                    if (note.content.isNotEmpty) ...[
                      Text(
                        note.content,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Image
                    if (note.imagePath != null) ...[
                      GestureDetector(
                        onTap: () => _showImagePreview(note.imagePath!),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF48484A)
                                  : const Color(0xFFE5E5EA),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(note.imagePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Action Buttons
                    if (!note.isProcessed) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _convertToTransaction(note, 'expense');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.trending_down_rounded),
                              label: const Text('Gider Olarak Kaydet'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _convertToTransaction(note, 'income');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.trending_up_rounded),
                              label: const Text('Gelir Olarak Kaydet'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(imagePath), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNoteTypeColor(QuickNoteType type) {
    switch (type) {
      case QuickNoteType.text:
        return AppColors.primary;
      case QuickNoteType.voice:
        return AppColors.info;
      case QuickNoteType.image:
        return AppColors.warning;
    }
  }

  IconData _getNoteTypeIcon(QuickNoteType type) {
    switch (type) {
      case QuickNoteType.text:
        return Icons.receipt_long_rounded;
      case QuickNoteType.voice:
        return Icons.mic_rounded;
      case QuickNoteType.image:
        return Icons.image_rounded;
    }
  }

  String _getNoteTypeLabel(QuickNoteType type) {
    switch (type) {
      case QuickNoteType.text:
        return 'Metin Notu';
      case QuickNoteType.voice:
        return 'Sesli Not';
      case QuickNoteType.image:
        return 'Görsel Not';
    }
  }
}
