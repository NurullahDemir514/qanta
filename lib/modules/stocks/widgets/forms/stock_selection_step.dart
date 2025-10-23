import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/models/stock_models.dart';
import '../../providers/stock_provider.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme_provider.dart';

/// Hisse seçim step'i
class StockSelectionStep extends StatefulWidget {
  final Stock? selectedStock;
  final Function(Stock) onStockSelected;
  final StockTransactionType? transactionType;

  const StockSelectionStep({
    super.key,
    this.selectedStock,
    required this.onStockSelected,
    this.transactionType,
  });

  @override
  State<StockSelectionStep> createState() => _StockSelectionStepState();
}

class _StockSelectionStepState extends State<StockSelectionStep> {
  final _searchController = TextEditingController();
  List<Stock> _filteredStocks = [];
  List<Stock> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _debounceTimer;
  late AppLocalizations l10n;
  final Map<String, List<Stock>> _searchCache = {};

  @override
  void initState() {
    super.initState();
    // Async işlemi build tamamlandıktan sonra çalıştır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStocks();
    });
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

  Future<void> _loadStocks() async {
    if (_isLoading) return; // Zaten yükleniyorsa tekrar başlatma

    setState(() {
      _isLoading = true;
    });

    try {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      // User ID'yi Firebase Auth'dan al
      final userId = FirebaseAuthService.currentUserId;
      if (userId != null) {
        await stockProvider.loadWatchedStocks(userId);

        if (mounted) {
          setState(() {
            _filteredStocks = stockProvider.watchedStocks;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 15), () {
      _searchStocks(query);
    });
  }

  Future<void> _searchStocks(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
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
    });

    try {
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final searchResults = await stockProvider.searchStocks(query);

      if (mounted && searchResults.isNotEmpty) {
        // Arama sonuçları için gerçek fiyat verilerini çek
        final symbols = searchResults.map((stock) {
          // Türk hisseleri için .IS uzantısı ekle
          if ((stock.exchange == 'BIST' ||
                  stock.exchange == 'IST' ||
                  stock.currency == 'TRY') &&
              !stock.symbol.endsWith('.IS')) {
            return '${stock.symbol}.IS';
          }
          return stock.symbol;
        }).toList();

        final realTimePrices = await stockProvider.getRealTimePrices(symbols);

        // Arama sonuçlarını gerçek fiyat verileri ile güncelle
        final updatedResults = searchResults.map((searchStock) {
          final realTimeStock = realTimePrices.firstWhere(
            (rt) =>
                rt.symbol == searchStock.symbol ||
                (rt.symbol.endsWith('.IS') &&
                    rt.symbol.replaceAll('.IS', '') == searchStock.symbol),
            orElse: () => searchStock,
          );

          return realTimeStock;
        }).toList();

        // Cache'e kaydet
        _searchCache[query] = updatedResults;

        setState(() {
          _searchResults = updatedResults;
          _isSearching = false;
        });
      } else if (mounted) {
        setState(() {
          _searchResults = searchResults;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Arama çubuğu
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: l10n.searchStocks,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
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
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF6D6D70)
                    : const Color(0xFF8E8E93),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          ),
        ),

        const SizedBox(height: 16),

        // Hisse listesi
        SizedBox(
          height: 600, // Sabit yükseklik ver
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildStockList(isDark),
        ),
      ],
    );
  }

  Widget _buildStockList(bool isDark) {
    // Arama yapılıyorsa arama sonuçlarını göster
    if (_searchController.text.isNotEmpty) {
      if (_isSearching) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Hisse aranıyor ve fiyat verileri çekiliyor...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      if (_searchResults.isEmpty) {
        return _buildNoResultsState(isDark);
      }

      return ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final stock = _searchResults[index];
          final isSelected = widget.selectedStock?.symbol == stock.symbol;

          return _buildSearchResultItem(stock, isSelected, isDark);
        },
      );
    }

    // Arama yapılmıyorsa mevcut hisseleri göster
    if (_filteredStocks.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return ListView.builder(
      itemCount: _filteredStocks.length,
      itemBuilder: (context, index) {
        final stock = _filteredStocks[index];
        final isSelected = widget.selectedStock?.symbol == stock.symbol;

        return _buildStockItem(stock, isSelected, isDark);
      },
    );
  }

  Widget _buildNoResultsState(bool isDark) {
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
            l10n.noStocksFound,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tryDifferentSearchTerm,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: isDark ? Colors.white54 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noStocksAddedYet,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addFirstStockInstruction,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _addStockAndSelect(Stock stock) async {
    final userId = FirebaseAuthService.currentUserId;
    if (userId == null) return;

    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    try {
      await stockProvider.addWatchedStock(userId, stock);

      if (mounted) {
        // Hisse eklendikten sonra seç
        widget.onStockSelected(stock);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hisse eklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildSearchResultItem(Stock stock, bool isSelected, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected
            ? (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8F4FD))
            : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _addStockAndSelect(stock),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? (isDark ? Colors.white54 : const Color(0xFF007AFF))
                    : (isDark
                          ? const Color(0xFF38383A)
                          : const Color(0xFFE5E5EA)),
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Hisse bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            stock.symbol,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.newBadge,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cleanStockName(stock.name),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Fiyat bilgileri
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stock.displayPrice,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stock.isPositive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stock.displayChangePercent,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: stock.isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockItem(Stock stock, bool isSelected, bool isDark) {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        // Satış işlemi için pozisyon bilgisini al
        final userId = FirebaseAuthService.currentUserId;
        StockPosition? position;
        if (widget.transactionType == StockTransactionType.sell && userId != null) {
          try {
            position = stockProvider.stockPositions.firstWhere(
              (pos) => pos.stockSymbol == stock.symbol,
            );
          } catch (e) {
            position = null;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected
                ? (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8F4FD))
                : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => widget.onStockSelected(stock),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? Colors.white54 : const Color(0xFF007AFF))
                        : (isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFE5E5EA)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Hisse bilgileri
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                stock.symbol,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _cleanStockName(stock.name),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Fiyat bilgileri
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  stock.displayPrice,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: stock.isPositive
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    stock.displayChangePercent,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: stock.isPositive ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            // Pozisyon bilgisi (sadece satış işlemi için)
                            if (widget.transactionType == StockTransactionType.sell && position != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.grey[800]!.withOpacity(0.3)
                                      : Colors.grey[200]!.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark 
                                        ? Colors.grey[600]!.withOpacity(0.3)
                                        : Colors.grey[400]!.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${position.totalQuantity.toStringAsFixed(0)} lot',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _cleanStockName(String name) {
    // .IS, .COM, .NET gibi ekleri kaldır
    return name
        .replaceAll(RegExp(r'\.IS$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.COM$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.NET$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.ORG$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.CO$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.TR$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.US$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.L$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.TO$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.PA$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.DE$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.HK$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.T$', caseSensitive: false), '')
        .trim();
  }
}
