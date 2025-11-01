import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/bank_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/utils/currency_utils.dart';

class BankAutocompleteField extends StatefulWidget {
  final String? selectedBankCode;
  final Function(String bankCode) onBankSelected;
  final String? errorText;
  final String hintText;

  const BankAutocompleteField({
    super.key,
    this.selectedBankCode,
    required this.onBankSelected,
    this.errorText,
    this.hintText = 'Banka seçin',
  });

  @override
  State<BankAutocompleteField> createState() => _BankAutocompleteFieldState();
}

class _BankAutocompleteFieldState extends State<BankAutocompleteField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  List<String> _filteredBanks = [];
  List<BankModel> _availableBanks = [];
  bool _isDropdownOpen = false;
  bool _isLoadingBanks = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _loadBanks();
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showDropdown();
      } else {
        _hideDropdown();
      }
    });
  }

  /// Bankaları yükle (dinamik)
  Future<void> _loadBanks() async {
    setState(() {
      _isLoadingBanks = true;
    });

    try {
      final bankService = BankService();
      await bankService.loadBanks();
      // Kullanıcının para birimine göre bankaları önceliklendir
      Currency? currency;
      try {
        currency = Provider.of<ThemeProvider>(context, listen: false).currency;
      } catch (e) {
        debugPrint('⚠️ BankAutocompleteField: Could not get currency, using default');
      }
      _availableBanks = bankService.getAvailableBanks(currency: currency);
      
      // Fallback: Eğer hiç banka yoksa static listeyi kullan
      if (_availableBanks.isEmpty) {
        final staticBanks = AppConstants.getAvailableBanks();
        _availableBanks = staticBanks.map((code) {
          return BankModel(
            code: code,
            name: AppConstants.getBankName(code),
            gradientColors: AppConstants.getBankGradientColors(code)
                .map((c) => c.value)
                .toList(),
            accentColor: AppConstants.getBankAccentColor(code).value,
            isActive: true,
          );
        }).toList();
      }

      _filteredBanks = _availableBanks.map((b) => b.code).toList();

      // Başlangıçta seçili banka varsa göster
      if (widget.selectedBankCode != null) {
        final selectedBank = _availableBanks.firstWhere(
          (b) => b.code == widget.selectedBankCode,
          orElse: () => BankModel(
            code: widget.selectedBankCode!,
            name: AppConstants.getBankName(widget.selectedBankCode!),
            gradientColors: [],
            accentColor: 0xFF1976D2,
          ),
        );
        _controller.text = selectedBank.name;
      }
    } catch (e) {
      debugPrint('❌ Error loading banks: $e');
      // Fallback: Static banks
      _filteredBanks = AppConstants.getAvailableBanks();
      _availableBanks = _filteredBanks.map((code) {
        return BankModel(
          code: code,
          name: AppConstants.getBankName(code),
          gradientColors: AppConstants.getBankGradientColors(code)
              .map((c) => c.value)
              .toList(),
          accentColor: AppConstants.getBankAccentColor(code).value,
          isActive: true,
        );
      }).toList();

      // Başlangıçta seçili banka varsa göster
      if (widget.selectedBankCode != null) {
        _controller.text = AppConstants.getBankName(widget.selectedBankCode!);
      }
    } finally {
      setState(() {
        _isLoadingBanks = false;
      });
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _hideDropdown();
    super.dispose();
  }

  void _filterBanks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = _availableBanks.map((b) => b.code).toList();
      } else {
        _filteredBanks = _availableBanks
            .where((bank) {
              return bank.name.toLowerCase().contains(query.toLowerCase()) ||
                  bank.code.toLowerCase().contains(query.toLowerCase());
            })
            .map((b) => b.code)
            .toList();
      }
    });
    _updateDropdown();
  }

  void _showDropdown() {
    if (_isDropdownOpen) return;
    
    _isDropdownOpen = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    if (!_isDropdownOpen) return;
    
    _isDropdownOpen = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateDropdown() {
    if (_isDropdownOpen) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: _filteredBanks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Banka bulunamadı',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : _isLoadingBanks
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: _filteredBanks.length,
                        itemBuilder: (context, index) {
                          final bankCode = _filteredBanks[index];
                          final bank = _availableBanks.firstWhere(
                            (b) => b.code == bankCode,
                            orElse: () => BankModel(
                              code: bankCode,
                              name: AppConstants.getBankName(bankCode),
                              gradientColors: [],
                              accentColor: 0xFF1976D2,
                            ),
                          );
                          final bankName = bank.name;
                          final accentColor = bank.accentColorValue;
                          
                          return InkWell(
                            onTap: () {
                              _selectBank(bankCode, bankName);
                            },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.account_balance,
                                  color: accentColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  bankName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  void _selectBank(String bankCode, String bankName) {
    _controller.text = bankName;
    widget.onBankSelected(bankCode);
    _hideDropdown();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? const Color(0xFFFF3B30)
                  : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _filterBanks,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                Icons.account_balance,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              suffixIcon: Icon(
                _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFFF3B30),
            ),
          ),
        ],
      ],
    );
  }
} 