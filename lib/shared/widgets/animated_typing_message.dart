import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// ChatGPT-style streaming mesaj widget'ı
/// AI mesajlarını token by token (kelime kelime) gösterir
class AnimatedTypingMessage extends StatefulWidget {
  final String fullMessage;
  final bool isDark;
  final VoidCallback? onComplete;
  final int wordsPerSecond; // Saniyede kaç kelime gösterilsin (varsayılan: 20)

  const AnimatedTypingMessage({
    super.key,
    required this.fullMessage,
    required this.isDark,
    this.onComplete,
    this.wordsPerSecond = 20, // Saniyede ~20 kelime = doğal okuma hızı
  });

  @override
  State<AnimatedTypingMessage> createState() => _AnimatedTypingMessageState();
}

class _AnimatedTypingMessageState extends State<AnimatedTypingMessage> {
  String _displayedMessage = '';
  Timer? _timer;
  int _currentCharIndex = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    
    // Animasyonu başlat
    _startTypingAnimation();
  }

  void _startTypingAnimation() {
    // Ortalama kelime uzunluğu ~5 karakter
    // wordsPerSecond * 5 = karakterPerSecond
    final charsPerSecond = widget.wordsPerSecond * 5;
    final millisecondsPerChar = (1000 / charsPerSecond).round();
    
    // Minimum 15ms (60 FPS), maksimum 100ms (yumuşak geçişler için)
    final optimizedDelay = millisecondsPerChar.clamp(15, 100);
    
    _timer = Timer.periodic(Duration(milliseconds: optimizedDelay), (timer) {
      if (_currentCharIndex < widget.fullMessage.length) {
        setState(() {
          _currentCharIndex++;
          _displayedMessage = widget.fullMessage.substring(0, _currentCharIndex);
        });
      } else {
        // Animasyon tamamlandı
        timer.cancel();
        setState(() {
          _isComplete = true;
        });
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _displayedMessage + (_isComplete ? '' : '▊'), // Cursor efekti
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.inter(
          fontSize: 15,
          height: 1.5,
          color: widget.isDark ? Colors.white : Colors.black87,
        ),
        strong: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500, // Bold yerine medium
          color: widget.isDark ? Colors.white : Colors.black87,
        ),
        em: GoogleFonts.inter(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: widget.isDark ? Colors.white70 : Colors.black54,
        ),
        h1: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: widget.isDark ? Colors.white : Colors.black87,
        ),
        h2: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: widget.isDark ? Colors.white : Colors.black87,
        ),
        h3: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: widget.isDark ? Colors.white : Colors.black87,
        ),
        listBullet: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF6D6D70),
        ),
        code: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          backgroundColor: widget.isDark 
            ? const Color(0xFF1C1C1E) 
            : const Color(0xFFF5F5F5),
          color: widget.isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
        ),
        blockquote: GoogleFonts.inter(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: widget.isDark ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }
}

