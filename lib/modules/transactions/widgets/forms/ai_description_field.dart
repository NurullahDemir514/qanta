import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/ai/gemini_ai_service.dart';
import '../../../../core/services/ai/ai_models.dart';
import 'dart:async';

/// AI-powered Description Field
/// 
/// Kullanıcı açıklama girdiğinde otomatik olarak AI ile kategori önerisi yapar.
class AIDescriptionField extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(AICategoryResult?)? onCategorySuggested;
  final String? hintText;

  const AIDescriptionField({
    super.key,
    required this.controller,
    this.errorText,
    this.onCategorySuggested,
    this.hintText,
  });

  @override
  State<AIDescriptionField> createState() => _AIDescriptionFieldState();
}

class _AIDescriptionFieldState extends State<AIDescriptionField> 
    with SingleTickerProviderStateMixin {
  final GeminiAIService _aiService = GeminiAIService();
  Timer? _debounceTimer;
  AICategoryResult? _suggestedCategory;
  bool _isLoadingAI = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pulseController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Kullanıcı yazmayı bıraktıktan 1 saniye sonra AI'dan öneri al
    _debounceTimer?.cancel();
    
    if (widget.controller.text.trim().length >= 3) {
      _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
        _getCategorySuggestion(widget.controller.text);
      });
    } else {
      setState(() {
        _suggestedCategory = null;
        _isLoadingAI = false;
      });
      widget.onCategorySuggested?.call(null);
    }
  }

  Future<void> _getCategorySuggestion(String description) async {
    if (!mounted) return;

    setState(() {
      _isLoadingAI = true;
      _suggestedCategory = null;
    });

    try {
      final result = await _aiService.categorizeExpense(description);
      
      if (!mounted) return;
      
      // Sadece güven skoru %50'den yüksekse göster
      if (result.confidence >= 0.5) {
        setState(() {
          _suggestedCategory = result;
          _isLoadingAI = false;
        });
        widget.onCategorySuggested?.call(result);
      } else {
        setState(() {
          _suggestedCategory = null;
          _isLoadingAI = false;
        });
        widget.onCategorySuggested?.call(null);
      }
    } catch (e) {
      debugPrint('AI categorization error: $e');
      if (mounted) {
        setState(() {
          _isLoadingAI = false;
          _suggestedCategory = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.description,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.2,
              ),
            ),
            if (_isLoadingAI) ...[
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Color(0xFF007AFF),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              Text(
                'AI analiz ediyor...',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF007AFF),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark 
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.errorText != null
                ? const Color(0xFFFF3B30)
                : (_suggestedCategory != null
                    ? const Color(0xFF007AFF) // AI önerisi varsa mavi border
                    : (isDark 
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE8E8E8))),
              width: _suggestedCategory != null ? 1.5 : 0.5,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? l10n.exampleMarketShopping,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark 
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
                letterSpacing: -0.2,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: _suggestedCategory != null
                ? const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF007AFF),
                    size: 20,
                  )
                : null,
            ),
          ),
        ),
        
        // AI Önerisi Kartı
        if (_suggestedCategory != null) ...[
          const SizedBox(height: 8),
          _buildAISuggestionCard(_suggestedCategory!, isDark),
        ],
        
        // Error mesajı
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFFF3B30),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAISuggestionCard(AICategoryResult category, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF007AFF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // AI İkonu
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF007AFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Kategori Bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      category.categoryIcon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.categoryName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade500.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '%${(category.confidence * 100).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade500,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
                if (category.reasoning != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    category.reasoning!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6D6D70),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Checkmark (otomatik seçildiğini göster)
          Icon(
            Icons.check_circle,
            color: Colors.green.shade500.withOpacity(0.8),
            size: 20,
          ),
        ],
      ),
    );
  }
}

