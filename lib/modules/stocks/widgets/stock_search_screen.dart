import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_search_item.dart';
import '../../../shared/models/stock_models.dart';
import '../../../core/services/firebase_auth_service.dart';

/// Hisse arama ekranı
class StockSearchScreen extends StatefulWidget {
  const StockSearchScreen({super.key});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Stock> _searchResults = [];
  bool _isSearching = false;
  String _currentQuery = '';
  Timer? _debounceTimer;
  final Map<String, List<Stock>> _searchCache = {};
  late AppLocalizations l10n;

  // BIST 100 hisseleri (en popüler olanlar)
  static const List<String> _bist100Symbols = [
    'THYAO',
    'AKBNK',
    'EREGL',
    'SAHOL',
    'BIMAS',
    'SISE',
    'TUPRS',
    'KCHOL',
    'ASELS',
    'SASA',
    'DOHOL',
    'KOZAL',
    'FROTO',
    'PETKM',
    'VAKBN',
    'TTKOM',
    'ARCLK',
    'EKGYO',
    'KOZAA',
    'PGSUS',
    'KRDMD',
    'TCELL',
    'GARAN',
    'ISCTR',
    'HALKB',
    'YKBNK',
    'AKSEN',
    'TAVHL',
    'TOASO',
    'ENKAI',
    'EREGL',
    'ENJSA',
  ];

  @override
  void initState() {
    super.initState();
    _loadPopularStocks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPopularStocks() async {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final results = await stockProvider.getPopularStocks();
    if (mounted) {
      setState(() {
        _searchResults = _sortStocksByBist100(results);
      });
    }
  }

  /// BIST 100 hisselerini üstte göster
  List<Stock> _sortStocksByBist100(List<Stock> stocks) {
    final sortedStocks = List<Stock>.from(stocks);
    sortedStocks.sort((a, b) {
      final aIsBist100 = _bist100Symbols.contains(a.symbol);
      final bIsBist100 = _bist100Symbols.contains(b.symbol);

      // BIST 100 hisseleri önce
      if (aIsBist100 && !bIsBist100) return -1;
      if (!aIsBist100 && bIsBist100) return 1;

      // İkisi de BIST 100 ise veya ikisi de değilse alfabetik sıra
      return a.symbol.compareTo(b.symbol);
    });
    return sortedStocks;
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchStocks(query);
    });
  }

  Future<void> _searchStocks(String query) async {
    if (query.trim().isEmpty) {
      await _loadPopularStocks();
      return;
    }

    // Cache kontrolü
    if (_searchCache.containsKey(query)) {
      setState(() {
        _searchResults = _searchCache[query]!;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    try {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final results = await stockProvider.searchStocks(query);

      if (mounted) {
        // Sonuçları BIST 100'e göre sırala
        final sortedResults = _sortStocksByBist100(results);

        // Cache'e kaydet
        _searchCache[query] = sortedResults;

        setState(() {
          _searchResults = sortedResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _addStock(Stock stock) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    // Optimistic UI update - anında UI'yi güncelle
    stockProvider.addWatchedStockOptimistically(stock);

    try {
      await stockProvider.addWatchedStock(userId, stock);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${stock.symbol} hissesi takip listesine eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Hata durumunda optimistic update'i geri al
      stockProvider.removeWatchedStockOptimistically(stock.symbol);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hisse eklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _getCurrentUserId() {
    try {
      return FirebaseAuthService.currentUserId;
    } catch (e) {
      // Debug log kaldırıldı
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          l10n.searchStocks ?? 'Hisse Ara',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark
            ? const Color(0xFF000000)
            : const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Arama kutusu
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n.searchStocks ?? 'Hisse ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchStocks('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF007AFF),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Sonuçlar
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF007AFF)),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDark ? Colors.white54 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _currentQuery.isEmpty
                  ? l10n.loadingPopularStocks
                  : l10n.noStocksFound,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            if (_currentQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.tryDifferentSearchTerm,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final stock = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StockSearchItem(stock: stock, onTap: () => _addStock(stock)),
        );
      },
    );
  }
}
