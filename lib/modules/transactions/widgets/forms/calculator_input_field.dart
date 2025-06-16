import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
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

  String _formatCurrency(String value) {
    final amount = double.tryParse(value);
    if (amount == null) return CurrencyUtils.formatAmount(0, Currency.TRY);
    
    return CurrencyUtils.formatAmount(amount, Currency.TRY);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? const Color(0xFFFF3B30)
                  : isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
              width: widget.errorText != null ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_operation.isNotEmpty) ...[
                Text(
                  '${_formatNumber(_previousValue)} $_operation',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark 
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6D6D70),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                _displayValue,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              CurrencyUtils.buildCurrencyText(
                _formatCurrency(_displayValue),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark 
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6D6D70),
                ),
                currency: Currency.TRY,
              ),
            ],
          ),
        ),

        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFFF3B30),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Calculator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark 
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              // Row 1: C, ±, %, ÷
              Row(
                children: [
                  _buildButton('C', _onClearPressed, isOperator: true),
                  _buildButton('⌫', _onBackspacePressed, isOperator: true),
                  _buildButton('%', () => _onOperationPressed('%'), isOperator: true),
                  _buildButton('÷', () => _onOperationPressed('÷'), isOperator: true),
                ],
              ),
              const SizedBox(height: 12),
              
              // Row 2: 7, 8, 9, ×
              Row(
                children: [
                  _buildButton('7', () => _onNumberPressed('7')),
                  _buildButton('8', () => _onNumberPressed('8')),
                  _buildButton('9', () => _onNumberPressed('9')),
                  _buildButton('×', () => _onOperationPressed('×'), isOperator: true),
                ],
              ),
              const SizedBox(height: 12),
              
              // Row 3: 4, 5, 6, -
              Row(
                children: [
                  _buildButton('4', () => _onNumberPressed('4')),
                  _buildButton('5', () => _onNumberPressed('5')),
                  _buildButton('6', () => _onNumberPressed('6')),
                  _buildButton('-', () => _onOperationPressed('-'), isOperator: true),
                ],
              ),
              const SizedBox(height: 12),
              
              // Row 4: 1, 2, 3, +
              Row(
                children: [
                  _buildButton('1', () => _onNumberPressed('1')),
                  _buildButton('2', () => _onNumberPressed('2')),
                  _buildButton('3', () => _onNumberPressed('3')),
                  _buildButton('+', () => _onOperationPressed('+'), isOperator: true),
                ],
              ),
              const SizedBox(height: 12),
              
              // Row 5: 0, ., =
              Row(
                children: [
                  _buildButton('0', () => _onNumberPressed('0'), flex: 2),
                  _buildButton(',', _onDecimalPressed),
                  _buildButton('=', _onEqualsPressed, isOperator: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {bool isOperator = false, int flex = 1}) {
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
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isOperator
                      ? isDark ? Colors.white : Colors.black
                      : isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 