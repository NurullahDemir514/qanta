import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme_provider.dart';

/// Hisse fiyat ve miktar hesap makinesi step'i
class StockCalculatorStep extends StatefulWidget {
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final String? quantityError;
  final String? priceError;
  final VoidCallback? onChanged;
  final String currencySymbol;

  const StockCalculatorStep({
    super.key,
    required this.quantityController,
    required this.priceController,
    this.quantityError,
    this.priceError,
    this.onChanged,
    required this.currencySymbol,
  });

  @override
  State<StockCalculatorStep> createState() => _StockCalculatorStepState();
}

class _StockCalculatorStepState extends State<StockCalculatorStep> {
  String _quantityDisplay = '0';
  String _priceDisplay = '0';
  String _quantityOperation = '';
  String _priceOperation = '';
  double _quantityPreviousValue = 0;
  double _pricePreviousValue = 0;
  bool _quantityWaitingForOperand = false;
  bool _priceWaitingForOperand = false;
  bool _isQuantityMode = true; // true = quantity, false = price
  late AppLocalizations l10n;

  @override
  void initState() {
    super.initState();
    if (widget.quantityController.text.isNotEmpty) {
      _quantityDisplay = widget.quantityController.text;
    }
    if (widget.priceController.text.isNotEmpty) {
      _priceDisplay = widget.priceController.text;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context)!;
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_isQuantityMode) {
        if (_quantityWaitingForOperand) {
          _quantityDisplay = number;
          _quantityWaitingForOperand = false;
        } else {
          _quantityDisplay = _quantityDisplay == '0'
              ? number
              : _quantityDisplay + number;
        }
        widget.quantityController.text = _quantityDisplay;
      } else {
        if (_priceWaitingForOperand) {
          _priceDisplay = number;
          _priceWaitingForOperand = false;
        } else {
          _priceDisplay = _priceDisplay == '0'
              ? number
              : _priceDisplay + number;
        }
        widget.priceController.text = _priceDisplay;
      }
      widget.onChanged?.call();
    });
    HapticFeedback.lightImpact();
  }

  void _onOperationPressed(String operation) {
    setState(() {
      if (_isQuantityMode) {
        if (_quantityOperation.isNotEmpty && !_quantityWaitingForOperand) {
          _quantityDisplay = _performOperation(
            _quantityPreviousValue,
            double.parse(_quantityDisplay),
            _quantityOperation,
          ).toString();
          widget.quantityController.text = _quantityDisplay;
        }
        _quantityPreviousValue = double.parse(_quantityDisplay);
        _quantityOperation = operation;
        _quantityWaitingForOperand = true;
      } else {
        if (_priceOperation.isNotEmpty && !_priceWaitingForOperand) {
          _priceDisplay = _performOperation(
            _pricePreviousValue,
            double.parse(_priceDisplay),
            _priceOperation,
          ).toString();
          widget.priceController.text = _priceDisplay;
        }
        _pricePreviousValue = double.parse(_priceDisplay);
        _priceOperation = operation;
        _priceWaitingForOperand = true;
      }
      widget.onChanged?.call();
    });
    HapticFeedback.lightImpact();
  }

  double _performOperation(double first, double second, String operation) {
    switch (operation) {
      case '+':
        return first + second;
      case '-':
        return first - second;
      case '×':
        return first * second;
      case '÷':
        return second != 0 ? first / second : 0;
      default:
        return second;
    }
  }

  void _onEqualsPressed() {
    setState(() {
      if (_isQuantityMode) {
        if (_quantityOperation.isNotEmpty) {
          _quantityDisplay = _performOperation(
            _quantityPreviousValue,
            double.parse(_quantityDisplay),
            _quantityOperation,
          ).toString();
          widget.quantityController.text = _quantityDisplay;
          _quantityOperation = '';
          _quantityWaitingForOperand = true;
        }
      } else {
        if (_priceOperation.isNotEmpty) {
          _priceDisplay = _performOperation(
            _pricePreviousValue,
            double.parse(_priceDisplay),
            _priceOperation,
          ).toString();
          widget.priceController.text = _priceDisplay;
          _priceOperation = '';
          _priceWaitingForOperand = true;
        }
      }
      widget.onChanged?.call();
    });
    HapticFeedback.lightImpact();
  }

  void _onClearPressed() {
    setState(() {
      if (_isQuantityMode) {
        _quantityDisplay = '0';
        _quantityOperation = '';
        _quantityPreviousValue = 0;
        _quantityWaitingForOperand = false;
        widget.quantityController.text = _quantityDisplay;
      } else {
        _priceDisplay = '0';
        _priceOperation = '';
        _pricePreviousValue = 0;
        _priceWaitingForOperand = false;
        widget.priceController.text = _priceDisplay;
      }
      widget.onChanged?.call();
    });
    HapticFeedback.lightImpact();
  }

  void _onBackspacePressed() {
    setState(() {
      if (_isQuantityMode) {
        if (_quantityDisplay.length > 1) {
          _quantityDisplay = _quantityDisplay.substring(
            0,
            _quantityDisplay.length - 1,
          );
        } else {
          _quantityDisplay = '0';
        }
        widget.quantityController.text = _quantityDisplay;
      } else {
        if (_priceDisplay.length > 1) {
          _priceDisplay = _priceDisplay.substring(0, _priceDisplay.length - 1);
        } else {
          _priceDisplay = '0';
        }
        widget.priceController.text = _priceDisplay;
      }
      widget.onChanged?.call();
    });
    HapticFeedback.lightImpact();
  }

  String _formatNumber(double number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(2);
  }

  void _switchMode() {
    setState(() {
      _isQuantityMode = !_isQuantityMode;
    });
    HapticFeedback.lightImpact();
  }

  String _calculateTotal() {
    final quantity = double.tryParse(_quantityDisplay) ?? 0;
    final price = double.tryParse(_priceDisplay) ?? 0;
    final total = quantity * price;

    if (total == 0) {
      return '0 ₺';
    }

    return '${total.toStringAsFixed(2)} ₺';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Column(
      children: [
        // Miktar ve Fiyat Girişleri - Kompakt Tasarım
        Row(
          children: [
            // Miktar Girişi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quantity,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _isQuantityMode = true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _isQuantityMode
                            ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
                            : (isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFF2F2F7)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isQuantityMode
                              ? (widget.quantityError != null
                                    ? const Color(0xFFFF3B30)
                                    : (isDark
                                          ? const Color(0xFF48484A)
                                          : const Color(0xFFD1D1D6)))
                              : (isDark
                                    ? const Color(0xFF48484A)
                                    : const Color(0xFFD1D1D6)),
                          width: _isQuantityMode ? 1.0 : 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_quantityOperation.isNotEmpty) ...[
                            Text(
                              '${_formatNumber(_quantityPreviousValue)} $_quantityOperation',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6D6D70),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            _quantityDisplay,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isQuantityMode
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark
                                        ? Colors.white70
                                        : Colors.grey[600]),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.quantityError != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.quantityError!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFFF3B30),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Fiyat Girişi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.price,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _isQuantityMode = false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: !_isQuantityMode
                            ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
                            : (isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFF2F2F7)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_isQuantityMode
                              ? (widget.priceError != null
                                    ? const Color(0xFFFF3B30)
                                    : (isDark
                                          ? const Color(0xFF48484A)
                                          : const Color(0xFFD1D1D6)))
                              : (isDark
                                    ? const Color(0xFF48484A)
                                    : const Color(0xFFD1D1D6)),
                          width: !_isQuantityMode ? 1.0 : 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_priceOperation.isNotEmpty) ...[
                            Text(
                              '${_formatNumber(_pricePreviousValue)} $_priceOperation',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6D6D70),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            _priceDisplay,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: !_isQuantityMode
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark
                                        ? Colors.white70
                                        : Colors.grey[600]),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.priceError != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.priceError!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFFF3B30),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Toplam Tutar - Kompakt Tasarım
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.total,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                ),
              ),
              Text(
                _calculateTotal(),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Calculator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              // Row 1: C, ⌫, %, ÷
              Row(
                children: [
                  _buildButton('C', _onClearPressed, isOperator: true),
                  _buildButton('⌫', _onBackspacePressed, isOperator: true),
                  _buildButton(
                    '%',
                    () => _onOperationPressed('%'),
                    isOperator: true,
                  ),
                  _buildButton(
                    '÷',
                    () => _onOperationPressed('÷'),
                    isOperator: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: 7, 8, 9, ×
              Row(
                children: [
                  _buildButton('7', () => _onNumberPressed('7')),
                  _buildButton('8', () => _onNumberPressed('8')),
                  _buildButton('9', () => _onNumberPressed('9')),
                  _buildButton(
                    '×',
                    () => _onOperationPressed('×'),
                    isOperator: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 3: 4, 5, 6, -
              Row(
                children: [
                  _buildButton('4', () => _onNumberPressed('4')),
                  _buildButton('5', () => _onNumberPressed('5')),
                  _buildButton('6', () => _onNumberPressed('6')),
                  _buildButton(
                    '-',
                    () => _onOperationPressed('-'),
                    isOperator: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 4: 1, 2, 3, +
              Row(
                children: [
                  _buildButton('1', () => _onNumberPressed('1')),
                  _buildButton('2', () => _onNumberPressed('2')),
                  _buildButton('3', () => _onNumberPressed('3')),
                  _buildButton(
                    '+',
                    () => _onOperationPressed('+'),
                    isOperator: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 5: 0, ., =
              Row(
                children: [
                  _buildButton('0', () => _onNumberPressed('0'), flex: 2),
                  _buildButton(',', () => _onNumberPressed('.')),
                  _buildButton('=', _onEqualsPressed, isOperator: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    bool isOperator = false,
    int flex = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isOperator
              ? isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFE5E5EA)
              : isDark
              ? const Color(0xFF1C1C1E)
              : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isDark
                  ? Border.all(color: const Color(0xFF38383A), width: 0.5)
                  : null,
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 60,
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isOperator
                        ? isDark
                              ? Colors.white
                              : Colors.black
                        : isDark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
