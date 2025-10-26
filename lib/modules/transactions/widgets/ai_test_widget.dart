import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/ai/firebase_ai_service.dart';
import '../../../core/services/ai/ai_models.dart';

/// AI Test Widget - Hızlı Test İçin
/// 
/// Bu widget'ı istediğin yere ekleyebilirsin.
/// Örneğin: home_screen.dart'a ekle ve test et!
class AITestWidget extends StatefulWidget {
  const AITestWidget({super.key});

  @override
  State<AITestWidget> createState() => _AITestWidgetState();
}

class _AITestWidgetState extends State<AITestWidget> {
  final FirebaseAIService _aiService = FirebaseAIService();
  final TextEditingController _controller = TextEditingController();
  AICategoryResult? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _testAI() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _aiService.categorizeExpense(_controller.text);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF007AFF).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: Color(0xFF007AFF), size: 24),
              const SizedBox(width: 8),
              Text(
                '🤖 AI Test',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Input Field
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Örnek: Starbucks kahve',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onSubmitted: (_) => _testAI(),
          ),
          const SizedBox(height: 12),
          
          // Test Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAI,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'AI Çalışıyor...' : 'AI ile Test Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Results
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF34D399).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _result!.categoryIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result!.categoryName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '%${(_result!.confidence * 100).toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_result!.reasoning != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _result!.reasoning!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF3B30).withOpacity(0.3),
                ),
              ),
              child: Text(
                '❌ Hata: $_error',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFFF3B30),
                ),
              ),
            ),
          ],
          
          // Test Examples
          const SizedBox(height: 16),
          Text(
            'Test Örnekleri:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildExampleChip('Starbucks kahve'),
              _buildExampleChip('Migros market'),
              _buildExampleChip('Shell benzin'),
              _buildExampleChip('Netflix abonelik'),
              _buildExampleChip('Uber taksi'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return InkWell(
      onTap: () {
        _controller.text = text;
        _testAI();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF007AFF).withOpacity(0.3),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF007AFF),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

