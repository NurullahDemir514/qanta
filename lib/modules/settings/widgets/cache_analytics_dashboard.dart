import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/unified_cache_manager.dart';
import '../../../core/services/cache_strategy_config.dart';

/// Cache Analytics Dashboard - Shows cache performance metrics
class CacheAnalyticsDashboard extends StatefulWidget {
  const CacheAnalyticsDashboard({super.key});

  @override
  State<CacheAnalyticsDashboard> createState() => _CacheAnalyticsDashboardState();
}

class _CacheAnalyticsDashboardState extends State<CacheAnalyticsDashboard> {
  CacheStats? _stats;
  Map<String, CachePolicy> _policies = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      _stats = UnifiedCacheManager.instance.getStats();
      _policies = CacheStrategyConfig.allPolicies;
    } catch (e) {
      debugPrint('Error loading cache analytics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cache Analytics',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _clearAllCache,
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(isDark),
                  const SizedBox(height: 16),
                  _buildPoliciesCard(isDark),
                  const SizedBox(height: 16),
                  _buildActionsCard(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    if (_stats == null) return const SizedBox.shrink();
    
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
              'Cache Performance',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Hit Rate',
                    '${_stats!.hitRate.toStringAsFixed(1)}%',
                    _getHitRateColor(_stats!.hitRate),
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Hits',
                    _stats!.hits.toString(),
                    Colors.green,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Misses',
                    _stats!.misses.toString(),
                    Colors.orange,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Evictions',
                    _stats!.evictions.toString(),
                    Colors.red,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Writes',
                    _stats!.writes.toString(),
                    Colors.blue,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Reads',
                    _stats!.reads.toString(),
                    Colors.purple,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Memory Items',
              _stats!.memoryItems.toString(),
              Colors.indigo,
              isDark,
            ),
            if (_stats!.lastWarmUpTime != null) ...[
              const SizedBox(height: 12),
              _buildStatItem(
                'Last Warm Up',
                _formatDateTime(_stats!.lastWarmUpTime!),
                Colors.teal,
                isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPoliciesCard(bool isDark) {
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
              'Cache Policies',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            ..._policies.entries.map((entry) => _buildPolicyItem(entry, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem(MapEntry<String, CachePolicy> entry, bool isDark) {
    final policy = entry.value;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              entry.key,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatDuration(policy.ttl),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
            ),
          ),
          Expanded(
            child: Text(
              policy.type.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
              ),
            ),
          ),
          Expanded(
            child: Text(
              policy.priority.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _getPriorityColor(policy.priority),
              ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Actions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearAllCache,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _warmUpCache,
                    icon: const Icon(Icons.whatshot, size: 18),
                    label: const Text('Warm Up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getHitRateColor(double hitRate) {
    if (hitRate >= 80) return Colors.green;
    if (hitRate >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getPriorityColor(CachePriority priority) {
    switch (priority) {
      case CachePriority.high:
        return Colors.red;
      case CachePriority.medium:
        return Colors.orange;
      case CachePriority.low:
        return Colors.green;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _clearAllCache() async {
    try {
      await UnifiedCacheManager.instance.clearAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All cache cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAnalytics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing cache: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _warmUpCache() async {
    try {
      await UnifiedCacheManager.instance.warmUpCache();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache warmed up successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error warming up cache: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
