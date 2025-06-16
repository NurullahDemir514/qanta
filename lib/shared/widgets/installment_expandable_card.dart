import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/installment_service_v2.dart';
import '../../shared/models/installment_models_v2.dart';
import '../design_system/transaction_design_system.dart';
import '../services/category_icon_service.dart';

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
        // Try to load real installment details
        final details = await InstallmentServiceV2.getInstallmentDetails(widget.installmentId!);
        setState(() {
          _installmentDetails = details;
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
      debugPrint('❌ Error loading installment details: $e');
      
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
    // Get category icon using CategoryIconService
    IconData? categoryIconData;
    if (widget.categoryIcon != null) {
      categoryIconData = CategoryIconService.getIcon(widget.categoryIcon!);
    }

    // Get category color using CategoryIconService
    Color? categoryColorData;
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
                  child: Icon(
                    iconData.icon,
                    color: iconData.iconColor,
                    size: TransactionDesignSystem.iconSize,
                  ),
                ),
                
                SizedBox(width: TransactionDesignSystem.iconContentSpacing),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: TransactionDesignSystem.titleFontSize,
                          fontWeight: TransactionDesignSystem.titleFontWeight,
                          color: TransactionDesignSystem.getTitleColor(widget.isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    Text(
                      widget.amount,
                      style: GoogleFonts.inter(
                        fontSize: TransactionDesignSystem.amountFontSize,
                        fontWeight: TransactionDesignSystem.amountFontWeight,
                        color: TransactionDesignSystem.getAmountColor(widget.type, widget.isDark),
                      ),
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
          'Taksit detayları yüklenemedi',
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
    final isPaid = detail.isPaid;
    final isOverdue = detail.isOverdue;
    final isDueSoon = detail.isDueSoon;
    
    Color statusColor;
    IconData statusIcon;
    
    if (isPaid) {
      statusColor = const Color(0xFF34C759); // Green
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = const Color(0xFFFF3B30); // Red
      statusIcon = Icons.error;
    } else if (isDueSoon) {
      statusColor = const Color(0xFFFF9500); // Orange
      statusIcon = Icons.warning;
    } else {
      statusColor = TransactionDesignSystem.getSubtitleColor(widget.isDark);
      statusIcon = Icons.schedule;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Status icon
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          
          const SizedBox(width: 12),
          
          // Installment info - removed status text
          Expanded(
            child: Text(
              '${detail.installmentNumber}. Taksit - ${_formatDate(detail.dueDate)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: TransactionDesignSystem.getSubtitleColor(widget.isDark),
              ),
            ),
          ),
          
          // Amount
          Text(
            TransactionDesignSystem.formatAmount(detail.amount, widget.type),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isPaid 
                  ? statusColor 
                  : TransactionDesignSystem.getAmountColor(widget.type, widget.isDark),
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

  String _formatDate(DateTime date) {
    const monthNames = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Yarın';
    } else {
      return '${date.day} ${monthNames[date.month - 1]}';
    }
  }
} 