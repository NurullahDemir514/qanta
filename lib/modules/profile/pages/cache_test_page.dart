import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/cache_cleanup_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/services/unified_cache_manager.dart';

/// Cache Test Page - For testing and monitoring cache sizes
class CacheTestPage extends StatefulWidget {
  const CacheTestPage({super.key});

  @override
  State<CacheTestPage> createState() => _CacheTestPageState();
}

class _CacheTestPageState extends State<CacheTestPage> {
  Map<String, dynamic>? _cacheStats;
  bool _isLoading = false;
  String? _lastCleanupResult;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await CacheCleanupService.instance.getTotalCacheSize();
      setState(() {
        _cacheStats = stats;
      });
    } catch (e) {
      debugPrint('Error loading cache stats: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runCleanup() async {
    setState(() {
      _isLoading = true;
      _lastCleanupResult = null;
    });

    try {
      final beforeStats = await CacheCleanupService.instance.getTotalCacheSize();
      final beforeSize = double.parse(beforeStats['totalSizeMB']?.toString() ?? '0');

      await CacheCleanupService.instance.performStartupCleanup();

      // Wait a bit for cleanup to complete
      await Future.delayed(const Duration(milliseconds: 500));

      final afterStats = await CacheCleanupService.instance.getTotalCacheSize();
      final afterSize = double.parse(afterStats['totalSizeMB']?.toString() ?? '0');
      final freed = beforeSize - afterSize;

      setState(() {
        _lastCleanupResult = '✅ Cleanup completed!\n'
            'Before: ${beforeSize.toStringAsFixed(2)} MB\n'
            'After: ${afterSize.toStringAsFixed(2)} MB\n'
            'Freed: ${freed.toStringAsFixed(2)} MB';
      });

      await _loadCacheStats();
    } catch (e) {
      setState(() {
        _lastCleanupResult = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllCaches() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Caches?'),
        content: const Text(
          'This will clear all cached data including images, unified cache, and temporary files. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _lastCleanupResult = null;
    });

    try {
      final beforeStats = await CacheCleanupService.instance.getTotalCacheSize();
      final beforeSize = double.parse(beforeStats['totalSizeMB']?.toString() ?? '0');

      await CacheCleanupService.instance.clearAllCaches();

      await Future.delayed(const Duration(milliseconds: 500));

      final afterStats = await CacheCleanupService.instance.getTotalCacheSize();
      final afterSize = double.parse(afterStats['totalSizeMB']?.toString() ?? '0');
      final freed = beforeSize - afterSize;

      setState(() {
        _lastCleanupResult = '✅ All caches cleared!\n'
            'Before: ${beforeSize.toStringAsFixed(2)} MB\n'
            'After: ${afterSize.toStringAsFixed(2)} MB\n'
            'Freed: ${freed.toStringAsFixed(2)} MB';
      });

      await _loadCacheStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Freed ${freed.toStringAsFixed(2)} MB'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastCleanupResult = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cache Test & Monitoring',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _loadCacheStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _cacheStats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total Cache Size Card
                  _buildTotalCacheCard(isDark),
                  const SizedBox(height: 16),

                  // Individual Cache Details
                  if (_cacheStats != null && _cacheStats!['details'] != null)
                    _buildCacheDetailsCard(isDark, _cacheStats!['details'] as Map<String, dynamic>),

                  const SizedBox(height: 16),

                  // Actions Card
                  _buildActionsCard(isDark),

                  const SizedBox(height: 16),

                  // Last Cleanup Result
                  if (_lastCleanupResult != null)
                    _buildResultCard(isDark, _lastCleanupResult!),

                  const SizedBox(height: 16),

                  // Info Card
                  _buildInfoCard(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalCacheCard(bool isDark) {
    if (_cacheStats == null) {
      return const SizedBox.shrink();
    }

    final totalSizeMB = double.tryParse(_cacheStats!['totalSizeMB']?.toString() ?? '0') ?? 0;
    final color = totalSizeMB > 100
        ? Colors.red
        : totalSizeMB > 50
            ? Colors.orange
            : Colors.green;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Cache Size',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  totalSizeMB.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'MB',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: totalSizeMB / 105, // Max expected: 105MB (40+5+60)
              backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E7),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 8),
            Text(
              'Target: < 105 MB (40MB Firestore + 5MB Images + 60MB Unified)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheDetailsCard(bool isDark, Map<String, dynamic> details) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Breakdown',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            ...details.entries.map((entry) => _buildCacheDetailItem(
                  isDark,
                  entry.key,
                  entry.value as Map<String, dynamic>? ?? {},
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheDetailItem(bool isDark, String cacheName, Map<String, dynamic> info) {
    final sizeMB = double.tryParse(info['sizeMB']?.toString() ?? '0') ?? 0;
    final count = info['count']?.toString() ?? '0';
    final limitMB = info['limitMB']?.toString() ?? 'N/A';
    final note = info['note']?.toString();

    String displayName = cacheName;
    switch (cacheName) {
      case 'imageCache':
        displayName = '🖼️ Image Cache';
        break;
      case 'unifiedCache':
        displayName = '📦 Unified Cache';
        break;
      case 'firestoreCache':
        displayName = '🔥 Firestore Cache';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
              Text(
                '$sizeMB MB',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: sizeMB > 0 ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),
          if (limitMB != 'N/A')
            Text(
              'Limit: $limitMB MB | Files: $count',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
            ),
          if (note != null)
            Text(
              note,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runCleanup,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Run Cleanup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _clearAllCaches,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Caches'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(bool isDark, String result) {
    return Card(
      elevation: 0,
      color: result.contains('✅')
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: result.contains('✅') ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          result,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: isDark ? Colors.blue : Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Cache Limits',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(isDark, 'Firestore Cache', '40 MB (auto-managed)'),
            _buildInfoRow(isDark, 'Image Cache', '5 MB (1 profile photo)'),
            _buildInfoRow(isDark, 'Unified Cache', '60 MB (max)'),
            _buildInfoRow(isDark, 'Total Target', '< 105 MB'),
            const SizedBox(height: 12),
            Text(
              'Cache cleanup runs automatically on app startup to prevent size growth.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }
}
