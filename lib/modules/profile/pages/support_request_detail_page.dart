import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/support_request_model.dart';

/// Support request detail page with chat interface
class SupportRequestDetailPage extends StatefulWidget {
  final String requestId;

  const SupportRequestDetailPage({
    super.key,
    required this.requestId,
  });

  @override
  State<SupportRequestDetailPage> createState() => _SupportRequestDetailPageState();
}

class _SupportRequestDetailPageState extends State<SupportRequestDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<DocumentSnapshot>? _requestSubscription;
  SupportRequest? _request;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  void _loadRequest() {
    _requestSubscription = _firestore
        .collection('support_requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.exists) {
        setState(() {
          _request = SupportRequest.fromFirestore(snapshot);
          _isLoading = false;
        });
        // Scroll to bottom when new message arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint('❌ Error loading support request: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('addSupportMessage');

      debugPrint('📤 Sending message to support request: ${widget.requestId}');

      final result = await callable.call({
        'requestId': widget.requestId,
        'message': _messageController.text.trim(),
        'senderType': 'user',
      });

      final data = Map<String, dynamic>.from(result.data);

      if (data['success'] == true) {
        _messageController.clear();
        HapticFeedback.mediumImpact();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mesajınız gönderildi',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade500,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Mesaj gönderilemedi');
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mesaj gönderilemedi. Lütfen tekrar deneyin.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'general':
        return 'Genel Soru';
      case 'bug':
        return 'Hata Bildirimi';
      case 'feature':
        return 'Özellik Önerisi';
      case 'account':
        return 'Hesap Sorunu';
      case 'payment':
        return 'Ödeme Sorunu';
      case 'other':
        return 'Diğer';
      default:
        return category;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Beklemede';
      case 'in_progress':
        return 'İnceleniyor';
      case 'resolved':
        return 'Çözüldü';
      case 'closed':
        return 'Kapatıldı';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
          _request?.subject ?? 'Destek Talebi',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : _request == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: const Color(0xFF8E8E93),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Destek talebi bulunamadı',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _request!.subject,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_request!.status)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getStatusLabel(_request!.status),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _getStatusColor(_request!.status),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getCategoryLabel(_request!.category),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Messages List
                    Expanded(
                      child: Container(
                        color: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _request!.messages.length,
                          itemBuilder: (context, index) {
                            final message = _request!.messages[index];
                            final isAdmin = message.senderType == 'admin';
                            final isLast = index == _request!.messages.length - 1;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLast ? 0 : 16,
                              ),
                              child: Row(
                                mainAxisAlignment: isAdmin
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isAdmin) ...[
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1C1C1E)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: isDark
                                              ? Border.all(
                                                  color: const Color(0xFF38383A),
                                                  width: 1,
                                                )
                                              : null,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.message,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                color: isDark ? Colors.white : Colors.black,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatTime(message.createdAt),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: const Color(0xFF8E8E93),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 48),
                                  ] else ...[
                                    const SizedBox(width: 48),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.support_agent,
                                                  size: 14,
                                                  color: Colors.white.withValues(alpha: 0.8),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Destek Ekibi',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white.withValues(alpha: 0.8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              message.message,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                color: Colors.white,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatTime(message.createdAt),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Message Input (only if not resolved/closed)
                    if (_request!.status != 'resolved' && _request!.status != 'closed')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? const Color(0xFF38383A)
                                  : const Color(0xFFE5E5EA),
                              width: 1,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  enabled: !_isSending,
                                  maxLines: null,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                  decoration: InputDecoration(
                                    hintText: 'Mesajınızı yazın...',
                                    hintStyle: GoogleFonts.inter(
                                      color: const Color(0xFF8E8E93),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF000000)
                                        : const Color(0xFFF5F5F7),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: _isSending ? null : _sendMessage,
                                  icon: _isSending
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

