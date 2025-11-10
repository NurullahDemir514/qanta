import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../shared/models/support_request_model.dart';
import 'support_request_detail_page.dart';

/// Combined support requests page with list and form
class SupportRequestsPage extends StatefulWidget {
  final String? prefillCategory;
  final String? prefillSubject;
  final String? prefillMessage;
  
  const SupportRequestsPage({
    super.key,
    this.prefillCategory,
    this.prefillSubject,
    this.prefillMessage,
  });

  @override
  State<SupportRequestsPage> createState() => _SupportRequestsPageState();
}

class _SupportRequestsPageState extends State<SupportRequestsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _requestsSubscription;
  List<SupportRequest> _requests = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'general', 'label': 'Genel Soru'},
    {'value': 'bug', 'label': 'Hata Bildir'},
    {'value': 'feature', 'label': 'Özellik Öner'},
    {'value': 'account', 'label': 'Hesap'},
    {'value': 'payment', 'label': 'Ödeme'},
    {'value': 'other', 'label': 'Diğer'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Pre-fill form if provided
    if (widget.prefillCategory != null) {
      _selectedCategory = widget.prefillCategory!;
    }
    if (widget.prefillSubject != null) {
      _subjectController.text = widget.prefillSubject!;
    }
    if (widget.prefillMessage != null) {
      _messageController.text = widget.prefillMessage!;
    }
    
    // If pre-filled, switch to form tab
    if (widget.prefillSubject != null || widget.prefillMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(1);
        }
      });
    }
    
    _loadRequests();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _loadRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ User is null, cannot load support requests');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    _loadRequestsWithOrderBy(user.uid);
  }

  void _loadRequestsWithOrderBy(String userId) {
    _requestsSubscription?.cancel();

    debugPrint('🔍 Loading support requests for user: $userId (with orderBy)');
    
    _requestsSubscription = _firestore
        .collection('support_requests')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      debugPrint('✅ Received ${snapshot.docs.length} support requests');
      if (mounted) {
        final requests = snapshot.docs
            .map((doc) {
              try {
                final request = SupportRequest.fromFirestore(doc);
                debugPrint('   📋 Request: ${request.subject} (${request.id})');
                return request;
              } catch (e) {
                debugPrint('❌ Error parsing support request ${doc.id}: $e');
                debugPrint('   Document data: ${doc.data()}');
                return null;
              }
            })
            .whereType<SupportRequest>()
            .toList();
        
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
        debugPrint('✅ Loaded ${_requests.length} support requests');
      }
    }, onError: (error) {
      debugPrint('❌ Error loading support requests: $error');
      debugPrint('   Error type: ${error.runtimeType}');
      debugPrint('   Error details: ${error.toString()}');
      debugPrint('   Error code: ${(error as dynamic).code}');
      debugPrint('   Error message: ${(error as dynamic).message}');
      
      // Try without orderBy if index is missing
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('index') || 
          (error as dynamic).code == 'failed-precondition' ||
          (error as dynamic).code == 'unavailable') {
        debugPrint('⚠️ Index error detected, retrying without orderBy...');
        _loadRequestsWithoutOrderBy(userId);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Destek talepleri yüklenirken hata oluştu: ${error.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  void _loadRequestsWithoutOrderBy(String userId) {
    _requestsSubscription?.cancel();
    debugPrint('🔍 Loading support requests for user: $userId (without orderBy)');
    
    _requestsSubscription = _firestore
        .collection('support_requests')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      debugPrint('✅ Received ${snapshot.docs.length} support requests (no orderBy)');
      if (mounted) {
        final requests = snapshot.docs
            .map((doc) {
              try {
                return SupportRequest.fromFirestore(doc);
              } catch (e) {
                debugPrint('❌ Error parsing support request ${doc.id}: $e');
                return null;
              }
            })
            .whereType<SupportRequest>()
            .toList();
        
        // Sort manually by created_at
        requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
        debugPrint('✅ Loaded ${_requests.length} support requests (sorted manually)');
      }
    }, onError: (error) {
      debugPrint('❌ Error loading support requests (without orderBy): $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Destek talepleri yüklenirken hata oluştu: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Lütfen önce giriş yapın');
      }

      // Call Cloud Function (user info will be fetched automatically)
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('submitSupportRequest');

      debugPrint('📤 Submitting support request: subject=${_subjectController.text.trim()}, category=$_selectedCategory');

      final result = await callable.call({
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'category': _selectedCategory,
      });

      debugPrint('📥 Support request result: $result');

      final data = Map<String, dynamic>.from(result.data);

      if (data['success'] == true) {
        if (mounted) {
          HapticFeedback.mediumImpact();
          
          // Show success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mesajınız iletildi. Teşekkürler!',
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
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Reset form
          _subjectController.clear();
          _messageController.clear();
          setState(() {
            _selectedCategory = 'general';
          });

          // Reload requests to show the new one
          _loadRequests();

          // Switch to list tab after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _tabController.animateTo(0);
            }
          });
        }
      } else {
        throw Exception(data['message'] ?? 'Bir şeyler yanlış gitti');
      }
    } catch (e) {
      debugPrint('❌ Error submitting support request: $e');
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
                    'Gönderilemedi. Lütfen tekrar deneyin.',
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
          _isSubmitting = false;
        });
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'general':
        return Icons.help_outline_rounded;
      case 'bug':
        return Icons.bug_report_rounded;
      case 'feature':
        return Icons.lightbulb_rounded;
      case 'account':
        return Icons.person_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'other':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getCategoryIconColor(String category, bool isDark) {
    switch (category) {
      case 'general':
        return isDark ? const Color(0xFF5AC8FA) : const Color(0xFF007AFF);
      case 'bug':
        return isDark ? const Color(0xFFFF3B30) : const Color(0xFFFF3B30);
      case 'feature':
        return isDark ? const Color(0xFFFFD60A) : const Color(0xFFFF9500);
      case 'account':
        return isDark ? const Color(0xFF32D74B) : const Color(0xFF34C759);
      case 'payment':
        return isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);
      case 'other':
        return isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
      default:
        return isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'general':
        return 'Genel';
      case 'bug':
        return 'Hata';
      case 'feature':
        return 'Özellik';
      case 'account':
        return 'Hesap';
      case 'payment':
        return 'Ödeme';
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          'Destek',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF2C2C2E) 
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark 
                    ? const Color(0xFF1C1C1E) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: const Color(0xFF8E8E93),
              labelStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Taleplerim'),
                Tab(text: 'Yeni Talep'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Requests List
          _buildRequestsList(isDark, primaryColor),
          // Tab 2: New Request Form
          _buildRequestForm(isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildRequestsList(bool isDark, Color primaryColor) {
    if (_isLoading) {
      return Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.support_agent_outlined,
                        size: 64,
                        color: const Color(0xFF8E8E93),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz destek talebiniz yok',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yardıma ihtiyacınız olduğunda bizimle iletişime geçin',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF8E8E93),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                _tabController.animateTo(1);
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Yeni Destek Talebi Oluştur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
      );
    }

    return RefreshIndicator(
                  onRefresh: () async {
                    _loadRequests();
                  },
                  color: primaryColor,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      final hasUnread = request.hasUnreadMessages;

          // Category icon
          IconData categoryIcon = _getCategoryIcon(request.category);
          Color categoryIconColor = _getCategoryIconColor(request.category, isDark);
          Color statusColor = _getStatusColor(request.status);
          
          return Container(
                        margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                        ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SupportRequestDetailPage(
                                  requestId: request.id,
                                ),
                              ),
                  ).then((_) {
                    _loadRequests();
                  });
                          },
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // Left border accent
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          // Top Row: Title and Icon
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        request.subject,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                              height: 1.4,
                                        ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasUnread)
                                      Container(
                                        width: 8,
                                        height: 8,
                                            margin: const EdgeInsets.only(left: 8, top: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                    const SizedBox(height: 10),
                                    // Status Badge and Category
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                  children: [
                                        // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: isDark ? 0.25 : 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getStatusLabel(request.status),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: statusColor,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                        // Category Chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF2C2C2E)
                                                : const Color(0xFFF2F2F7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                categoryIcon,
                                                size: 12,
                                                color: categoryIconColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getCategoryLabel(request.category),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? const Color(0xFF8E8E93)
                                                      : const Color(0xFF6D6D70),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Category Icon (Right)
                              Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(left: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      categoryIconColor.withValues(alpha: 0.2),
                                      categoryIconColor.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  categoryIcon,
                                  color: categoryIconColor,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Footer: Message count and Date
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFF5F5F7),
                                  borderRadius: BorderRadius.circular(6),
                                        ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.message_outlined,
                                      size: 12,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${request.messages.length}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatDate(request.createdAt),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF8E8E93),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: const Color(0xFF8E8E93),
                              ),
                            ],
                          ),
                        ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
      ),
    );
  }

  Widget _buildRequestForm(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Nasıl yardımcı olabiliriz?',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sorunuzu veya önerinizi paylaşın, size yardımcı olalım.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            // Category Selection
            Text(
              'Konu',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF6D6D70),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['value'];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedCategory = category['value']!;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: index < _categories.length - 1 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : (isDark
                                ? const Color(0xFF1C1C1E)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : (isDark
                                  ? const Color(0xFF38383A)
                                  : const Color(0xFFE5E5EA)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(category['value']!),
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF6D6D70)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF6D6D70)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Subject Field
            TextFormField(
              controller: _subjectController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: 'Başlık',
                hintText: 'Kısa bir başlık yazın',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF8E8E93),
                ),
                labelStyle: GoogleFonts.inter(
                  color: const Color(0xFF8E8E93),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1C1C1E)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lütfen bir başlık girin';
                }
                if (value.trim().length < 3) {
                  return 'Başlık en az 3 karakter olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Message Field
            TextFormField(
              controller: _messageController,
              enabled: !_isSubmitting,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Mesajınız',
                hintText: 'Detayları paylaşın...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF8E8E93),
                ),
                labelStyle: GoogleFonts.inter(
                  color: const Color(0xFF8E8E93),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1C1C1E)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lütfen mesajınızı yazın';
                }
                if (value.trim().length < 10) {
                  return 'Mesaj en az 10 karakter olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      primaryColor.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Gönder',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
