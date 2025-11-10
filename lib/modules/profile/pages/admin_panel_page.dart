import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../core/services/admin_service.dart';
import '../../../shared/models/amazon_gift_card_model.dart';
import '../../../shared/utils/date_utils.dart' as date_utils;
import '../../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_revenue_page.dart';

/// Admin Panel Page
/// Shows pending gift card requests and allows admin to process them
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final AdminService _adminService = AdminService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingRequests = [];
  StreamSubscription<QuerySnapshot>? _requestsSubscription;
  String? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });

    if (isAdmin) {
      _setupListener();
    }
  }

  void _setupListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('🔍 AdminPanel: Setting up listener for admin_requests...');
    debugPrint('🔍 AdminPanel: Current user ID: $userId');
    debugPrint('🔍 AdminPanel: Expected admin ID: obwsYff7JuNBEis9ENvX2pIdIKE2');
    debugPrint('🔍 AdminPanel: Is admin? ${userId == 'obwsYff7JuNBEis9ENvX2pIdIKE2'}');
    
    _requestsSubscription = _firestore
        .collection('admin_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        debugPrint('✅ AdminPanel: Received ${snapshot.docs.length} pending requests');
        setState(() {
          _pendingRequests = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
        });
      },
      onError: (error) {
        debugPrint('❌ AdminPanel: Error listening to requests: $error');
        debugPrint('❌ AdminPanel: Error details: ${error.toString()}');
        // Try without orderBy if composite index is missing
        _setupListenerWithoutOrderBy();
      },
    );
  }
  
  void _setupListenerWithoutOrderBy() {
    debugPrint('⚠️ AdminPanel: Retrying without orderBy (fallback mode)...');
    _requestsSubscription?.cancel();
    _requestsSubscription = _firestore
        .collection('admin_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
      (snapshot) {
        debugPrint('✅ AdminPanel: Received ${snapshot.docs.length} pending requests (fallback)');
        setState(() {
          _pendingRequests = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          // Sort manually by created_at
          _pendingRequests.sort((a, b) {
            final aTime = (a['created_at'] as Timestamp?)?.toDate() ?? DateTime(1970);
            final bTime = (b['created_at'] as Timestamp?)?.toDate() ?? DateTime(1970);
            return bTime.compareTo(aTime); // Descending
          });
        });
      },
      onError: (error) {
        debugPrint('❌ AdminPanel: Error listening to requests (fallback): $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Future<void> _processGiftCard(String requestId, String userId, String giftCardId, String amazonEmail, double amount) async {
    try {
      // Show dialog to enter Amazon code
      final code = await _showCodeInputDialog(amount);
      if (code == null || code.isEmpty) return;

      // Update gift card status
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('amazon_gift_cards')
          .doc(giftCardId)
          .update({
        'status': 'sent',
        'purchased_at': date_utils.DateUtils.toFirebase(DateTime.now()),
        'sent_at': date_utils.DateUtils.toFirebase(DateTime.now()),
        'amazon_code': code,
        'amazon_claim_code': 'AMZN-GC-$code',
        'updated_at': date_utils.DateUtils.toFirebase(DateTime.now()),
      });

      // Update admin request status
      await _firestore
          .collection('admin_requests')
          .doc(requestId)
          .update({
        'status': 'completed',
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Send push notification
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
        final callable = functions.httpsCallable('notifyGiftCardSent');
        await callable.call({
          'userId': userId,
          'giftCardId': giftCardId,
          'amount': amount,
        });
      } catch (e) {
        debugPrint('⚠️ Failed to send notification: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Hediye kartı başarıyla işlendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error processing gift card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showCodeInputDialog(double amount) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Amazon Hediye Kartı Kodu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${amount.toStringAsFixed(0)} TL için Amazon\'dan aldığınız kodu girin:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Kod',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Bu sayfaya erişim yetkiniz yok',
                style: GoogleFonts.inter(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.card_giftcard), text: 'Hediye Kartları'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Reklam Gelirleri'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Gift Card Requests Tab
            Column(
              children: [
                // Provider Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String>(
                    value: _selectedProvider,
                    decoration: InputDecoration(
                      labelText: 'Kart Tipi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tümü'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'amazon',
                        child: Text('Amazon'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'paribu',
                        child: Text('Paribu Cineverse'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'dnr',
                        child: Text('D&R'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'gratis',
                        child: Text('Gratis'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProvider = value;
                      });
                    },
                  ),
                ),
                // Requests List
                Expanded(
                  child: _getFilteredRequests().isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inbox, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Bekleyen talep yok',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _getFilteredRequests().length,
                          itemBuilder: (context, index) {
                            final request = _getFilteredRequests()[index];
                            return _buildRequestCard(context, request, isDark);
                          },
                        ),
                ),
              ],
            ),
            // Revenue Tab
            const AdminRevenuePage(),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredRequests() {
    if (_selectedProvider == null) {
      return _pendingRequests;
    }
    return _pendingRequests.where((request) {
      final provider = request['provider'] as String?;
      return provider == _selectedProvider;
    }).toList();
  }

  String _getProviderName(String? provider) {
    switch (provider) {
      case 'amazon':
        return 'Amazon';
      case 'paribu':
        return 'Paribu Cineverse';
      case 'dnr':
        return 'D&R';
      case 'gratis':
        return 'Gratis';
      default:
        return 'Bilinmeyen';
    }
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'tr_TR');
    final createdAt = request['created_at'] as Timestamp?;
    final date = createdAt != null ? createdAt.toDate() : DateTime.now();
    final provider = request['provider'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${request['amount']} TL',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF9900),
                  ),
                ),
                Row(
                  children: [
                    if (provider != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getProviderName(provider),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bekliyor',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Kullanıcı Email', request['user_email'] ?? 'N/A'),
            _buildInfoRow('Email', request['amazon_email'] ?? request['email'] ?? 'N/A'),
            if (provider == 'paribu' && request['phone_number'] != null)
              _buildInfoRow('Telefon', request['phone_number'] ?? 'N/A'),
            _buildInfoRow('User ID', request['user_id'] ?? 'N/A'),
            _buildInfoRow('Gift Card ID', request['gift_card_id'] ?? 'N/A'),
            _buildInfoRow('Tarih', dateFormat.format(date)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _processGiftCard(
                  request['id'],
                  request['user_id'],
                  request['gift_card_id'],
                  request['amazon_email'],
                  (request['amount'] as num).toDouble(),
                ),
                icon: const Icon(Icons.check),
                label: const Text('İşle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

