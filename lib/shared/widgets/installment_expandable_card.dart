import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/installment_service_v2.dart';
import '../../core/services/unified_installment_service.dart';
import '../../shared/models/installment_models_v2.dart';
import '../design_system/transaction_design_system.dart';
import '../services/category_icon_service.dart';
import '../../core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

class InstallmentExpandableCard extends StatefulWidget {
  final String? installmentId;
  final String title;
  final String subtitle;
  final String amount;
  final String? time;
  final TransactionType type;
  final String? categoryIcon;
  final String? categoryColor;
  final bool isDark;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onLongPress;
  final int? currentInstallment;
  final int? totalInstallments;
  final double? totalAmount; // Toplam tutar
  final double? monthlyAmount; // Aylık tutar
  final bool isPaid; // Payment status for statement tracking

  const InstallmentExpandableCard({
    super.key,
    this.installmentId,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.time,
    required this.type,
    this.categoryIcon,
    this.categoryColor,
    required this.isDark,
    this.isFirst = false,
    this.isLast = false,
    this.onLongPress,
    this.currentInstallment,
    this.totalInstallments,
    this.totalAmount,
    this.monthlyAmount,
    this.isPaid = false,
  });

  @override
  State<InstallmentExpandableCard> createState() => _InstallmentExpandableCardState();
}

class _InstallmentExpandableCardState extends State<InstallmentExpandableCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<InstallmentDetailModel>? _installmentDetails;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInstallmentDetails() async {
    if (_installmentDetails != null) return;

    setState(() => _isLoading = true);

    try {
      if (widget.installmentId != null) {
        // Load real installment details from Firebase
        debugPrint('Loading installment details for: ${widget.installmentId}');
        final details = await UnifiedInstallmentService.getInstallmentDetails(widget.installmentId!);
        
        if (details.isEmpty) {
          debugPrint('⚠️ No installment details found for ID: ${widget.installmentId}');
          setState(() {
            _installmentDetails = [];
            _isLoading = false;
          });
          return;
        }
        
        // Convert to InstallmentDetailModel
        final installmentDetails = details.map((detail) => InstallmentDetailModel(
          id: detail['id'] as String,
          installmentTransactionId: detail['installment_transaction_id'] as String,
          installmentNumber: detail['installment_number'] as int,
          amount: (detail['amount'] as num).toDouble(),
          dueDate: detail['due_date'] as DateTime,
          isPaid: detail['is_paid'] as bool,
          paidDate: detail['paid_date'] as DateTime?,
          transactionId: detail['transaction_id'] as String?,
          createdAt: detail['created_at'] as DateTime,
          updatedAt: detail['updated_at'] as DateTime,
        )).toList();
        
        debugPrint('✅ Loaded ${installmentDetails.length} installment details for ID: ${widget.installmentId}');
        setState(() {
          _installmentDetails = installmentDetails;
          _isLoading = false;
        });
        
      } else if (widget.currentInstallment != null && widget.totalInstallments != null) {
        // Create fallback installment details from pattern info
        _installmentDetails = _createFallbackInstallmentDetails();
        setState(() => _isLoading = false);
      } else {
        // No data available
        setState(() {
          _installmentDetails = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      
      // If real data fails and we have pattern info, use fallback
      if (widget.currentInstallment != null && widget.totalInstallments != null) {
        _installmentDetails = _createFallbackInstallmentDetails();
      } else {
        _installmentDetails = [];
      }
      
      setState(() => _isLoading = false);
    }
  }

  List<InstallmentDetailModel> _createFallbackInstallmentDetails() {
    if (widget.currentInstallment == null || widget.totalInstallments == null) {
      return [];
    }

    final details = <InstallmentDetailModel>[];
    final baseDate = DateTime.now();
    
    // Extract amount (remove currency and signs)
    final amountStr = widget.amount.replaceAll(RegExp(r'[^\d.,]'), '');
    final monthlyAmount = double.tryParse(amountStr.replaceAll(',', '.')) ?? 0.0;
    
    for (int i = 1; i <= widget.totalInstallments!; i++) {
      final dueDate = DateTime(baseDate.year, baseDate.month + i - widget.currentInstallment!, baseDate.day);
      final isPaid = i < widget.currentInstallment!;
      
      details.add(InstallmentDetailModel(
        id: 'fallback_$i',
        installmentTransactionId: widget.installmentId ?? 'fallback',
        installmentNumber: i,
        amount: monthlyAmount,
        dueDate: dueDate,
        isPaid: isPaid,
        paidDate: isPaid ? dueDate.subtract(const Duration(days: 1)) : null,
        transactionId: isPaid ? 'paid_$i' : null,
        createdAt: baseDate,
        updatedAt: baseDate,
      ));
    }
    
    return details;
  }

  void _toggleExpanded() async {
    if (!_isExpanded) {
      await _loadInstallmentDetails();
    }

    setState(() => _isExpanded = !_isExpanded);

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get category icon using CategoryIconService - prioritize category name over icon field
    IconData? categoryIconData;
    
    // First try to extract category name from title (more reliable)
    String? categoryName;
    if (widget.title.contains('(') && widget.title.contains('Taksit)')) {
      // Extract category name from title like "Benzin (6 Taksit)" -> "benzin"
      categoryName = widget.title.split('(')[0].trim().toLowerCase();
    } else {
      // If no taksit pattern, use the title directly
      categoryName = widget.title.toLowerCase();
    }
    
    // Try category name first (e.g., "benzin", "market", etc.)
    if (categoryName != null) {
      categoryIconData = CategoryIconService.getIcon(categoryName);
    }
    
    // Only fallback to category.icon if category name lookup failed
    if (categoryIconData == null || categoryIconData == Icons.tag) {
      if (widget.categoryIcon != null && widget.categoryIcon != 'category') {
        categoryIconData = CategoryIconService.getIcon(widget.categoryIcon!);
      }
    }

    // Get category color using CategoryIconService - prioritize centralized colors
    Color? categoryColorData;
    
    // First try to get color from centralized map using category name
    if (categoryName != null) {
      categoryColorData = CategoryIconService.getColorFromMap(
        categoryName,
        categoryType: widget.type == TransactionType.income ? 'income' : 'expense',
      );
    } else if (widget.categoryIcon != null) {
      // Try icon name (e.g., "restaurant", "car", etc.)
      categoryColorData = CategoryIconService.getColorFromMap(
        widget.categoryIcon!,
        categoryType: widget.type == TransactionType.income ? 'income' : 'expense',
      );
    }
    
    // If no centralized color found, fall back to hex color from database
    if (categoryColorData == null || categoryColorData == CategoryIconService.getColorFromMap('default')) {
      if (widget.categoryColor != null) {
        categoryColorData = CategoryIconService.getColor(widget.categoryColor!);
      } else if (widget.categoryIcon != null) {
        // Use predefined colors based on category type and icon
        final isIncomeCategory = widget.type == TransactionType.income;
        categoryColorData = CategoryIconService.getCategoryColor(
          iconName: widget.categoryIcon!,
          colorHex: widget.categoryColor,
          isIncomeCategory: isIncomeCategory,
        );
      }
    }

    final iconData = TransactionDesignSystem.getTransactionIconData(
      type: widget.type,
      categoryIconData: categoryIconData,
      categoryColorData: categoryColorData,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: widget.isFirst ? TransactionDesignSystem.verticalPadding + 4 : TransactionDesignSystem.verticalPadding,
        bottom: widget.isLast ? TransactionDesignSystem.verticalPadding + 4 : TransactionDesignSystem.verticalPadding,
        left: TransactionDesignSystem.horizontalPadding,
        right: TransactionDesignSystem.horizontalPadding,
      ),
      child: Column(
        children: [
          // Main transaction row
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleExpanded,
            onLongPress: widget.onLongPress,
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: TransactionDesignSystem.iconContainerSize,
                  height: TransactionDesignSystem.iconContainerSize,
                  decoration: BoxDecoration(
                    color: iconData.backgroundColor,
                    borderRadius: BorderRadius.circular(TransactionDesignSystem.iconBorderRadius),
                  ),
                  child: Center(
                  child: Icon(
                    iconData.icon,
                    color: iconData.iconColor,
                    size: TransactionDesignSystem.iconSize,
                    ),
                  ),
                ),
                
                SizedBox(width: TransactionDesignSystem.iconContentSpacing),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title text (flexible to take available space)
                          Flexible(
                            child: Text(
                              widget.title,
                              style: GoogleFonts.inter(
                                fontSize: TransactionDesignSystem.titleFontSize,
                                fontWeight: TransactionDesignSystem.titleFontWeight,
                                color: TransactionDesignSystem.getTitleColor(widget.isDark),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6),
                          // Taksitli chip
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.isDark ? Colors.orange.shade800 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: widget.isDark ? Colors.orange.shade600 : Colors.orange.shade300,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)?.installment ?? 'Taksitli',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: widget.isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: TransactionDesignSystem.titleSubtitleSpacing),
                      Text(
                        widget.time != null ? '${widget.subtitle} • ${widget.time}' : widget.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: TransactionDesignSystem.subtitleFontSize,
                          fontWeight: TransactionDesignSystem.subtitleFontWeight,
                          color: TransactionDesignSystem.getSubtitleColor(widget.isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount and expand arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Toplam tutar (ana tutar)
                    Text(
                          _getDisplayAmount(),
                      style: GoogleFonts.inter(
                        fontSize: TransactionDesignSystem.amountFontSize,
                        fontWeight: TransactionDesignSystem.amountFontWeight,
                        color: TransactionDesignSystem.getAmountColor(widget.type, widget.isDark),
                      ),
                    ),
                        // Aylık tutar (küçük)
                        if (widget.totalAmount != null && widget.monthlyAmount != null && widget.totalInstallments != null && widget.totalInstallments! > 1)
                          Text(
                            '${TransactionDesignSystem.formatAmount(widget.monthlyAmount!, widget.type, currencySymbol: Provider.of<ThemeProvider>(context, listen: false).currency.symbol)}${AppLocalizations.of(context)?.perMonth ?? '/month'}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: TransactionDesignSystem.getSubtitleColor(widget.isDark),
                            ),
                          ),
                      ],
                    ),

                  ],
                ),
              ],
            ),
          ),
          
          // Expandable installment details
          SizeTransition(
            sizeFactor: _animation,
            child: _buildInstallmentDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentDetails() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _buildLoadingSkeleton(),
      );
    }

    if (_installmentDetails == null || _installmentDetails!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          AppLocalizations.of(context)?.installmentDetailsLoadError ?? 'Installment details could not be loaded',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: TransactionDesignSystem.getSubtitleColor(widget.isDark),
          ),
        ),
      );
    }

    // Sort installments by installment number (ascending order: 1, 2, 3, 4...)
    final sortedDetails = List<InstallmentDetailModel>.from(_installmentDetails!)
      ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 52), // Align with content
      child: Column(
        children: sortedDetails.asMap().entries.map((entry) {
          final index = entry.key;
          final detail = entry.value;
          final isLast = index == sortedDetails.length - 1;
          
          return _buildInstallmentDetailRow(detail, isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildInstallmentDetailRow(InstallmentDetailModel detail, bool isLast) {
    // Hiçbir taksit için ikon göstermeyeceğimiz için status kontrollerini kaldırdık

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Çizgi karakteri ekle - son taksit için farklı
          Text(
            isLast ? '└─ ' : '├─ ', // Son taksit için └─, diğerleri için ├─
            style: GoogleFonts.inter(
              fontSize: 13,
              color: TransactionDesignSystem.getSubtitleColor(widget.isDark),
            ),
          ),
          
          // Installment info
          Expanded(
            child: Text(
              '${detail.installmentNumber}. ${AppLocalizations.of(context)?.installment ?? 'Installment'} - ${_formatDate(detail.dueDate, context)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: TransactionDesignSystem.getSubtitleColor(widget.isDark),
              ),
            ),
          ),
          
          // Amount
          Text(
            TransactionDesignSystem.formatAmount(detail.amount, widget.type, currencySymbol: Provider.of<ThemeProvider>(context, listen: false).currency.symbol),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: TransactionDesignSystem.getAmountColor(widget.type, widget.isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(3, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: TransactionDesignSystem.getTitleColor(widget.isDark).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: TransactionDesignSystem.getTitleColor(widget.isDark).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 60,
              height: 14,
              decoration: BoxDecoration(
                color: TransactionDesignSystem.getTitleColor(widget.isDark).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      )),
    );
  }

  /// Görüntülenecek tutarı belirler (toplam tutar varsa onu, yoksa mevcut amount'u)
  String _getDisplayAmount() {
    if (widget.totalAmount != null) {
      return TransactionDesignSystem.formatAmount(widget.totalAmount!, widget.type, currencySymbol: Provider.of<ThemeProvider>(context, listen: false).currency.symbol);
    }
    return widget.amount;
  }

  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return AppLocalizations.of(context)?.today ?? 'Today';
    } else if (difference == 1) {
      return AppLocalizations.of(context)?.tomorrow ?? 'Tomorrow';
    } else {
      // Çok dilli ay isimleri (kısaltılmış)
      final monthNames = [
        '', 
        AppLocalizations.of(context)?.january?.substring(0, 3) ?? 'Jan',
        AppLocalizations.of(context)?.february?.substring(0, 3) ?? 'Feb',
        AppLocalizations.of(context)?.march?.substring(0, 3) ?? 'Mar',
        AppLocalizations.of(context)?.april?.substring(0, 3) ?? 'Apr',
        AppLocalizations.of(context)?.may?.substring(0, 3) ?? 'May',
        AppLocalizations.of(context)?.june?.substring(0, 3) ?? 'Jun',
        AppLocalizations.of(context)?.july?.substring(0, 3) ?? 'Jul',
        AppLocalizations.of(context)?.august?.substring(0, 3) ?? 'Aug',
        AppLocalizations.of(context)?.september?.substring(0, 3) ?? 'Sep',
        AppLocalizations.of(context)?.october?.substring(0, 3) ?? 'Oct',
        AppLocalizations.of(context)?.november?.substring(0, 3) ?? 'Nov',
        AppLocalizations.of(context)?.december?.substring(0, 3) ?? 'Dec'
      ];
      return '${date.day} ${monthNames[date.month]}';
    }
  }
} 