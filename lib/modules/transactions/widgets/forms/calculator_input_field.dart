import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/utils/currency_utils.dart';

class CalculatorInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final VoidCallback? onChanged;

  const CalculatorInputField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  State<CalculatorInputField> createState() => _CalculatorInputFieldState();
}

class _CalculatorInputFieldState extends State<CalculatorInputField> {
  String _displayValue = '0';
  String _operation = '';
  double _previousValue = 0;
  bool _waitingForOperand = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isNotEmpty) {
      _displayValue = widget.controller.text;
    }
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_waitingForOperand) {
        _displayValue = number;
        _waitingForOperand = false;
      } else {
        _displayValue = _displayValue == '0' ? number : _displayValue + number;
      }
      widget.controller.text = _displayValue;
      widget.onChanged?.call();
    });
    HapticFeedback.lightImpact();
  }

  void _onOperationPressed(String operation) {
    setState(() {
      if (_operation.isNotEmpty && !_waitingForOperand) {
        _calculate();
      }
      _previousValue = double.tryParse(_displayValue) ?? 0;
      _operation = operation;
      _waitingForOperand = true;
    });
    HapticFeedback.lightImpact();
  }

  void _onEqualsPressed() {
    if (_operation.isNotEmpty && !_waitingForOperand) {
      _calculate();
      setState(() {
        _operation = '';
        _waitingForOperand = true;
      });
    }
    HapticFeedback.lightImpact();
  }

  void _calculate() {
    final currentValue = double.tryParse(_displayValue) ?? 0;
    double result = _previousValue;

    switch (_operation) {
      case '+':
        result = _previousValue + currentValue;
        break;
      case '-':
        result = _previousValue - currentValue;
        break;
      case '×':
        result = _previousValue * currentValue;
        break;
      case '÷':
        if (currentValue != 0) {
          result = _previousValue / currentValue;
        }
        break;
    }

    setState(() {
      _displayValue = _formatNumber(result);
      widget.controller.text = _displayValue;
      widget.onChanged?.call();
    });
  }

  String _formatNumber(double number) {
    if (number == number.toInt()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _onClearPressed() {
    setState(() {
      _displayValue = '0';
      _operation = '';
      _previousValue = 0;
      _waitingForOperand = false;
      widget.controller.text = '';
      widget.onChanged?.call();
    });
    HapticFeedback.lightImpact();
  }

  void _onBackspacePressed() {
    setState(() {
      if (_displayValue.length > 1) {
        _displayValue = _displayValue.substring(0, _displayValue.length - 1);
      } else {
        _displayValue = '0';
      }
      widget.controller.text = _displayValue == '0' ? '' : _displayValue;
      widget.onChanged?.call();
    });
    HapticFeedback.lightImpact();
  }

  void _onDecimalPressed() {
    if (!_displayValue.contains('.')) {
      setState(() {
        if (_waitingForOperand) {
          _displayValue = '0.';
          _waitingForOperand = false;
        } else {
          _displayValue += '.';
        }
        widget.controller.text = _displayValue;
        widget.onChanged?.call();
      });
    }
    HapticFeedback.lightImpact();
  }

  String _formatCurrency(String value, BuildContext context) {
    final amount = double.tryParse(value);
    if (amount == null)
      return Provider.of<ThemeProvider>(context, listen: false).formatAmount(0);

    return Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).formatAmount(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360; // iPhone SE, küçük telefonlar
    final isMobile =
        screenWidth > 360 && screenWidth <= 480; // Standart telefonlar
    final isLargeMobile =
        screenWidth > 480 && screenWidth <= 600; // Büyük telefonlar
    final isSmallTablet =
        screenWidth > 600 && screenWidth <= 768; // Küçük tabletler
    final isTablet =
        screenWidth > 768 && screenWidth <= 1024; // Standart tabletler
    final isLargeTablet =
        screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200; // Desktop/laptop
    final isLandscape = screenHeight < screenWidth;

    // Responsive değerler - Ekran boyutuna göre optimize
    final displayPadding = isSmallMobile
        ? 16.0
        : isMobile
        ? 18.0
        : isLargeMobile
        ? 20.0
        : isSmallTablet
        ? 24.0
        : isTablet
        ? 28.0
        : 32.0;

    final displayFontSize = isSmallMobile
        ? 24.0
        : isMobile
        ? 28.0
        : isLargeMobile
        ? 32.0
        : isSmallTablet
        ? 36.0
        : isTablet
        ? 40.0
        : 44.0;

    final operationFontSize = isSmallMobile
        ? 12.0
        : isMobile
        ? 14.0
        : isLargeMobile
        ? 16.0
        : isSmallTablet
        ? 18.0
        : isTablet
        ? 20.0
        : 22.0;

    final currencyFontSize = isSmallMobile
        ? 12.0
        : isMobile
        ? 14.0
        : isLargeMobile
        ? 16.0
        : isSmallTablet
        ? 17.0
        : isTablet
        ? 18.0
        : 20.0;

    final buttonHeight = isSmallMobile
        ? 48.0
        : isMobile
        ? 52.0
        : isLargeMobile
        ? 56.0
        : isSmallTablet
        ? 60.0
        : isTablet
        ? 64.0
        : 68.0;

    final buttonFontSize = isSmallMobile
        ? 14.0
        : isMobile
        ? 16.0
        : isLargeMobile
        ? 18.0
        : isSmallTablet
        ? 19.0
        : isTablet
        ? 20.0
        : 22.0;

    final buttonSpacing = isSmallMobile
        ? 10.0
        : isMobile
        ? 12.0
        : isLargeMobile
        ? 14.0
        : isSmallTablet
        ? 16.0
        : isTablet
        ? 18.0
        : 20.0;

    final calculatorPadding = isSmallMobile
        ? 14.0
        : isMobile
        ? 16.0
        : isLargeMobile
        ? 18.0
        : isSmallTablet
        ? 20.0
        : isTablet
        ? 22.0
        : 26.0;

    final containerSpacing = isSmallMobile
        ? 16.0
        : isMobile
        ? 18.0
        : isLargeMobile
        ? 20.0
        : isSmallTablet
        ? 22.0
        : isTablet
        ? 24.0
        : 28.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Mevcut alanı hesapla
        final availableHeight = constraints.maxHeight;

        // Landscape modda daha kompakt boyutlar kullan
        final adjustedDisplayPadding = isLandscape
            ? displayPadding * 0.8
            : displayPadding;
        final adjustedDisplayFontSize = isLandscape
            ? displayFontSize * 0.9
            : displayFontSize;
        final adjustedButtonHeight = isLandscape
            ? buttonHeight * 0.9
            : buttonHeight;
        final adjustedButtonSpacing = isLandscape
            ? buttonSpacing * 0.8
            : buttonSpacing;
        final adjustedCalculatorPadding = isLandscape
            ? calculatorPadding * 0.8
            : calculatorPadding;
        final adjustedContainerSpacing = isLandscape
            ? containerSpacing * 0.8
            : containerSpacing;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(adjustedDisplayPadding),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(
                  isSmallMobile ? 12.0 : 16.0,
                ),
                border: Border.all(
                  color: widget.errorText != null
                      ? const Color(0xFFFF3B30)
                      : isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
                  width: widget.errorText != null ? 1.5 : 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_operation.isNotEmpty) ...[
                    Text(
                      '${_formatNumber(_previousValue)} $_operation',
                      style: GoogleFonts.inter(
                        fontSize: operationFontSize,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6D6D70),
                      ),
                    ),
                    SizedBox(height: isSmallMobile ? 3.0 : 4.0),
                  ],
                  Text(
                    _displayValue,
                    style: GoogleFonts.inter(
                      fontSize: adjustedDisplayFontSize,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: isSmallMobile ? 6.0 : 8.0),
                  CurrencyUtils.buildCurrencyText(
                    _formatCurrency(_displayValue, context),
                    style: GoogleFonts.inter(
                      fontSize: currencyFontSize,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                    ),
                    currency: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).currency,
                  ),
                ],
              ),
            ),

            if (widget.errorText != null) ...[
              SizedBox(height: isSmallMobile ? 6.0 : 8.0),
              Text(
                widget.errorText!,
                style: GoogleFonts.inter(
                  fontSize: isSmallMobile ? 12.0 : 14.0,
                  color: const Color(0xFFFF3B30),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            SizedBox(height: adjustedContainerSpacing),

            // Calculator
            Container(
              padding: EdgeInsets.all(adjustedCalculatorPadding),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(
                  isSmallMobile ? 12.0 : 16.0,
                ),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: C, ±, %, ÷
                  Row(
                    children: [
                      _buildButton(
                        'C',
                        _onClearPressed,
                        isOperator: true,
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '⌫',
                        _onBackspacePressed,
                        isOperator: true,
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '%',
                        () => _onOperationPressed('%'),
                        isOperator: true,
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '÷',
                        () => _onOperationPressed('÷'),
                        isOperator: true,
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                    ],
                  ),
                  SizedBox(height: adjustedButtonSpacing),

                  // Row 2: 7, 8, 9, ×
                  Row(
                    children: [
                      _buildButton(
                        '7',
                        () => _onNumberPressed('7'),
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '8',
                        () => _onNumberPressed('8'),
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '9',
                        () => _onNumberPressed('9'),
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '×',
                        () => _onOperationPressed('×'),
                        isOperator: true,
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                    ],
                  ),
                  SizedBox(height: adjustedButtonSpacing),

                  // Row 3: 4, 5, 6, -
                  Row(
                    children: [
                      _buildButton(
                        '4',
                        () => _onNumberPressed('4'),
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '5',
                        () => _onNumberPressed('5'),
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '6',
                        () => _onNumberPressed('6'),
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '-',
                        () => _onOperationPressed('-'),
                        isOperator: true,
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                    ],
                  ),
                  SizedBox(height: adjustedButtonSpacing),

                  // Row 4: 1, 2, 3, +
                  Row(
                    children: [
                      _buildButton(
                        '1',
                        () => _onNumberPressed('1'),
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '2',
                        () => _onNumberPressed('2'),
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '3',
                        () => _onNumberPressed('3'),
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '+',
                        () => _onOperationPressed('+'),
                        isOperator: true,
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                    ],
                  ),
                  SizedBox(height: adjustedButtonSpacing),

                  // Row 5: 0, ., =
                  Row(
                    children: [
                      _buildButton(
                        '0',
                        () => _onNumberPressed('0'),
                        flex: 2,
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        ',',
                        _onDecimalPressed,
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                      _buildButton(
                        '=',
                        _onEqualsPressed,
                        isOperator: true,
                        buttonHeight: adjustedButtonHeight,
                        buttonFontSize: buttonFontSize,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    bool isOperator = false,
    int flex = 1,
    required double buttonHeight,
    required double buttonFontSize,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Detaylı Responsive Breakpoints
    final isSmallMobile = screenWidth <= 360; // iPhone SE, küçük telefonlar
    final isMobile =
        screenWidth > 360 && screenWidth <= 480; // Standart telefonlar
    final isLargeMobile =
        screenWidth > 480 && screenWidth <= 600; // Büyük telefonlar
    final isSmallTablet =
        screenWidth > 600 && screenWidth <= 768; // Küçük tabletler
    final isTablet =
        screenWidth > 768 && screenWidth <= 1024; // Standart tabletler
    final isLargeTablet =
        screenWidth > 1024 && screenWidth <= 1200; // Büyük tabletler
    final isDesktop = screenWidth > 1200; // Desktop/laptop

    // Responsive değerler
    final buttonMargin = isSmallMobile
        ? 2.0
        : isMobile
        ? 3.0
        : isLargeMobile
        ? 4.0
        : isSmallTablet
        ? 5.0
        : isTablet
        ? 6.0
        : 8.0;

    final buttonBorderRadius = isSmallMobile
        ? 6.0
        : isMobile
        ? 7.0
        : isLargeMobile
        ? 8.0
        : isSmallTablet
        ? 10.0
        : isTablet
        ? 12.0
        : 14.0;

    return Expanded(
      flex: flex,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: buttonMargin),
        child: Material(
          color: isOperator
              ? isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFE5E5EA)
              : isDark
              ? const Color(0xFF1C1C1E)
              : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(buttonBorderRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(buttonBorderRadius),
              border: isDark
                  ? Border.all(color: const Color(0xFF38383A), width: 0.5)
                  : null,
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(buttonBorderRadius),
              child: Container(
                height: buttonHeight,
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: buttonFontSize,
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
