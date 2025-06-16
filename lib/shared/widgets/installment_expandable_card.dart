import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/installment_service_v2.dart';
import '../../shared/models/installment_models_v2.dart';
import '../design_system/transaction_design_system.dart';

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
    final iconData = TransactionDesignSystem.getTransactionIconData(
      type: widget.type,
      categoryIcon: widget.categoryIcon,
      categoryColor: widget.categoryColor,
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
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: TransactionDesignSystem.getSubtitleColor(widget.isDark),
                        size: 20,
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

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 52), // Align with content
      child: Column(
        children: _installmentDetails!.asMap().entries.map((entry) {
          final index = entry.key;
          final detail = entry.value;
          final isLast = index == _installmentDetails!.length - 1;
          
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
    String statusText;
    
    if (isPaid) {
      statusColor = const Color(0xFF34C759); // Green
      statusIcon = Icons.check_circle;
      statusText = 'Ödendi';
    } else if (isOverdue) {
      statusColor = const Color(0xFFFF3B30); // Red
      statusIcon = Icons.error;
      statusText = 'Gecikmiş';
    } else if (isDueSoon) {
      statusColor = const Color(0xFFFF9500); // Orange
      statusIcon = Icons.warning;
      statusText = 'Yaklaşıyor';
    } else {
      statusColor = TransactionDesignSystem.getSubtitleColor(widget.isDark);
      statusIcon = Icons.schedule;
      statusText = 'Bekliyor';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Tree line indicator
          Container(
            width: 2,
            height: 24,
            color: isLast 
                ? Colors.transparent 
                : TransactionDesignSystem.getBorderColor(widget.isDark),
          ),
          
          Container(
            width: 8,
            height: 2,
            color: TransactionDesignSystem.getBorderColor(widget.isDark),
          ),
          
          const SizedBox(width: 8),
          
          // Status icon
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          
          const SizedBox(width: 8),
          
          // Installment info
          Expanded(
            child: Text(
              '${detail.installmentNumber}. Taksit (${_formatDate(detail.dueDate)}) • $statusText',
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
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Yarın';
    } else if (difference < 7) {
      return '${difference} gün';
    } else {
      return '${date.day}/${date.month}';
    }
  }
} 