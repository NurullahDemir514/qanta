import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/stock_models.dart';
import '../providers/stock_provider.dart';
import '../../../core/services/firebase_auth_service.dart';
import 'stock_transaction_form_screen.dart';

/// Hisse seçim ekranı - Alım/Satım için hisse seçimi
class StockSelectionScreen extends StatefulWidget {
  final StockTransactionType transactionType;
  
  const StockSelectionScreen({
    super.key,
    required this.transactionType,
  });

  @override
  State<StockSelectionScreen> createState() => _StockSelectionScreenState();
}

class _StockSelectionScreenState extends State<StockSelectionScreen> {
  final _searchController = TextEditingController();
  List<Stock> _filteredStocks = [];
  bool _isLoading = false;
  String? _error;
  late AppLocalizations l10n;

  @override
  void initState() {
    super.initState();
    _loadWatchedStocks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWatchedStocks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) {
        throw Exception(l10n.userSessionNotFound);
      }

      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      await stockProvider.loadWatchedStocks(userId);
      
      setState(() {
        _filteredStocks = stockProvider.watchedStocks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterStocks(String query) {
    setState(() {
      if (query.isEmpty) {
        final stockProvider = Provider.of<StockProvider>(context, listen: false);
        _filteredStocks = stockProvider.watchedStocks;
      } else {
        _filteredStocks = Provider.of<StockProvider>(context, listen: false)
            .watchedStocks
            .where((stock) =>
                stock.symbol.toLowerCase().contains(query.toLowerCase()) ||
                stock.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onStockSelected(Stock stock) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockTransactionFormScreen(
          transactionType: widget.transactionType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          widget.transactionType == StockTransactionType.buy 
              ? l10n.stockPurchase 
              : l10n.stockSale,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
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
          // Arama çubuğu
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterStocks,
              decoration: InputDecoration(
                hintText: l10n.searchStocks,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterStocks('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
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
              ),
            ),
          ),
          
          // Hisse listesi
          Expanded(
            child: _buildStockList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.white54 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Hata: $_error',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWatchedStocks,
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      );
    }

    if (_filteredStocks.isEmpty) {
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Hisse ekleme ekranına yönlendir
              },
              child: Text(l10n.addStock),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredStocks.length,
      itemBuilder: (context, index) {
        final stock = _filteredStocks[index];
        return _buildStockItem(stock, isDark);
      },
    );
  }

  Widget _buildStockItem(Stock stock, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _onStockSelected(stock),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Hisse bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.symbol,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stock.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stock.exchange,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey[500],
                        ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                
                const SizedBox(width: 12),
                
                // Ok ikonu
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
