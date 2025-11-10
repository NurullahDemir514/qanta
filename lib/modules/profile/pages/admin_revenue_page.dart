import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/services/admin_service.dart';
import '../../../shared/models/amazon_reward_stats_model.dart';

/// Admin Revenue Page
/// Shows ad revenue statistics for all users
class AdminRevenuePage extends StatefulWidget {
  const AdminRevenuePage({super.key});

  @override
  State<AdminRevenuePage> createState() => _AdminRevenuePageState();
}

class _AdminRevenuePageState extends State<AdminRevenuePage> {
  final AdminService _adminService = AdminService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;
  bool _isLoading = true;
  List<UserRevenueData> _userRevenues = [];
  double _totalAdRevenue = 0.0;
  double _totalTransactionRevenue = 0.0;
  int _totalAdCount = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });

    if (isAdmin) {
      _loadUserRevenues();
    }
  }

  Future<void> _loadUserRevenues() async {
    // SECURITY: Double-check admin status before loading sensitive data
    final isAdmin = await _adminService.isAdmin();
    if (!isAdmin) {
      debugPrint('⚠️ AdminRevenuePage: Unauthorized access attempt blocked');
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Collection group query to get all users' stats
      // SECURITY: Only admins can access this data (checked by Firestore rules)
      // Get all documents from amazon_reward_stats collection group
      final statsSnapshot = await _firestore
          .collectionGroup('amazon_reward_stats')
          .get();
      
      // Also get ad watch history for more detailed analytics
      // SECURITY: Only admins can access this data (checked by Firestore rules)
      final adWatchSnapshot = await _firestore
          .collectionGroup('ad_watch_history')
          .get();

      final List<UserRevenueData> revenues = [];
      double totalAdRevenue = 0.0;
      double totalTransactionRevenue = 0.0;
      int totalAdCount = 0;

      // Process ad watch history to calculate actual ad counts per user
      final userAdWatchCounts = <String, int>{};
      final userAdWatchDates = <String, DateTime>{};
      
      for (var doc in adWatchSnapshot.docs) {
        try {
          final pathParts = doc.reference.path.split('/');
          if (pathParts.length >= 2 && pathParts[0] == 'users') {
            final userId = pathParts[1];
            userAdWatchCounts[userId] = (userAdWatchCounts[userId] ?? 0) + 1;
            
            // Track last ad watch date
            final watchedAt = doc.data()['watched_at'] as Timestamp?;
            if (watchedAt != null) {
              final watchDate = watchedAt.toDate();
              final currentLastDate = userAdWatchDates[userId];
              if (currentLastDate == null || watchDate.isAfter(currentLastDate)) {
                userAdWatchDates[userId] = watchDate;
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error processing ad watch history: $e');
        }
      }
      
      // Batch fetch user emails to avoid N+1 queries
      final userIds = <String>{};
      final userDocs = <String, DocumentSnapshot>{};
      
      for (var doc in statsSnapshot.docs) {
        try {
          // Extract user ID from path: users/{userId}/amazon_reward_stats/{statsId}
          final pathParts = doc.reference.path.split('/');
          if (pathParts.length >= 2 && pathParts[0] == 'users') {
            userIds.add(pathParts[1]);
          }
        } catch (e) {
          debugPrint('❌ Error extracting user ID: $e');
        }
      }

      // Batch fetch user documents
      final userFutures = userIds.map((userId) async {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        return MapEntry(userId, userDoc);
      });
      
      final userResults = await Future.wait(userFutures);
      for (var entry in userResults) {
        if (entry.value.exists) {
          userDocs[entry.key] = entry.value;
        }
      }

      // Process stats
      for (var doc in statsSnapshot.docs) {
        try {
          // Extract user ID from path: users/{userId}/amazon_reward_stats/{statsId}
          final pathParts = doc.reference.path.split('/');
          if (pathParts.length >= 2 && pathParts[0] == 'users') {
            final userId = pathParts[1];
            
            // Get user data from batch
            final userDoc = userDocs[userId];
            final userData = userDoc?.data() as Map<String, dynamic>?;
            final userEmail = userData?['email'] ?? 'N/A';
            final userName = userData?['name'] ?? 'N/A';

            final stats = AmazonRewardStats.fromFirestore(doc);
            
            // Use actual ad watch count from ad_watch_history if available
            // Otherwise use stats.rewardedAdCount
            final actualAdCount = userAdWatchCounts[userId] ?? stats.rewardedAdCount;
            
            // Calculate ad revenue: actual_ad_count * 0.20 TL (user reward)
            // Note: This is the reward given to user, not actual AdMob revenue
            final adRevenue = actualAdCount * 0.20;
            
            // Calculate transaction revenue: transaction_count * reward_amount
            // TEST: Geçici olarak 100 TL per transaction (test için)
            // TODO: Production'da 0.03 TL'ye geri döndür
            const transactionRewardAmount = 100.0; // TEST: 100 TL (geçici)
            // const transactionRewardAmount = 0.03; // PRODUCTION: 0.03 TL
            final transactionRevenue = stats.transactionCount * transactionRewardAmount;
            
            totalAdRevenue += adRevenue;
            totalTransactionRevenue += transactionRevenue;
            totalAdCount += actualAdCount;
            
            // Use last ad watch date from history if available
            final lastAdWatchDate = userAdWatchDates[userId] ?? stats.lastEarnedAt;

            revenues.add(UserRevenueData(
              userId: userId,
              userEmail: userEmail,
              userName: userName,
              rewardedAdCount: actualAdCount,
              adRevenue: adRevenue,
              transactionRevenue: transactionRevenue,
              totalEarned: stats.totalEarned,
              transactionCount: stats.transactionCount,
              lastEarnedAt: lastAdWatchDate,
            ));
          }
        } catch (e) {
          debugPrint('❌ Error parsing user revenue: $e');
        }
      }

      // Sort by ad revenue (descending)
      revenues.sort((a, b) => b.adRevenue.compareTo(a.adRevenue));

      setState(() {
        _userRevenues = revenues;
        _totalAdRevenue = totalAdRevenue;
        _totalTransactionRevenue = totalTransactionRevenue;
        _totalAdCount = totalAdCount;
        _totalUsers = revenues.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading user revenues: $e');
      setState(() {
        _isLoading = false;
      });
      
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reklam Gelirleri')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reklam Gelirleri')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reklam Gelirleri'),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserRevenues,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)]
                    : [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: isDark
                  ? Border.all(color: const Color(0xFF38383A), width: 0.5)
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Toplam Kullanıcı',
                      '$_totalUsers',
                      Icons.people,
                    ),
                    _buildSummaryItem(
                      'Toplam Reklam',
                      '$_totalAdCount',
                      Icons.play_circle,
                    ),
                    _buildSummaryItem(
                      'Toplam Gelir',
                      '${_totalAdRevenue.toStringAsFixed(2)} TL',
                      Icons.attach_money,
                      isHighlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Toplam İşlem Ödülü',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.blue.shade800,
                        ),
                      ),
                      Text(
                        '${_totalTransactionRevenue.toStringAsFixed(2)} TL',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: _userRevenues.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz reklam geliri yok',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _userRevenues.length,
                    itemBuilder: (context, index) {
                      return _buildUserRevenueCard(
                        context,
                        _userRevenues[index],
                        index + 1,
                        isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isHighlight ? Colors.green.shade500 : Colors.grey,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isHighlight ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.green.shade500 : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildUserRevenueCard(
    BuildContext context,
    UserRevenueData data,
    int rank,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');
    final lastEarnedDate = data.lastEarnedAt != null
        ? dateFormat.format(data.lastEarnedAt!)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? Colors.green.shade500.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? Colors.green.shade500 : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.userName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.userEmail,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatChip(
                        '${data.rewardedAdCount} reklam',
                        Icons.play_circle,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        '${data.transactionCount} işlem',
                        Icons.receipt,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Revenue
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data.adRevenue.toStringAsFixed(2)} TL',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.transactionRevenue.toStringAsFixed(2)} TL',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'İşlem Ödülü',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.blue.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Son: $lastEarnedDate',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// User Revenue Data Model
class UserRevenueData {
  final String userId;
  final String userEmail;
  final String userName;
  final int rewardedAdCount;
  final double adRevenue;
  final double transactionRevenue;
  final double totalEarned;
  final int transactionCount;
  final DateTime? lastEarnedAt;

  UserRevenueData({
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.rewardedAdCount,
    required this.adRevenue,
    required this.transactionRevenue,
    required this.totalEarned,
    required this.transactionCount,
    this.lastEarnedAt,
  });
}

