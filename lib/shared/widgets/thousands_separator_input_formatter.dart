import 'package:flutter/services.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters except decimal point
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Handle decimal point
    List<String> parts = digitsOnly.split('.');
    if (parts.length > 2) {
      // More than one decimal point, keep only the first one
      digitsOnly = '${parts[0]}.${parts.sublist(1).join('')}';
      parts = digitsOnly.split('.');
    }
    
    // Limit decimal places to 2
    if (parts.length == 2 && parts[1].length > 2) {
      parts[1] = parts[1].substring(0, 2);
      digitsOnly = '${parts[0]}.${parts[1]}';
    }
    
    // Add thousands separators to the integer part
    String integerPart = parts[0];
    if (integerPart.isNotEmpty) {
      // Add commas every 3 digits from right to left
      String reversed = integerPart.split('').reversed.join('');
      String withCommas = '';
      for (int i = 0; i < reversed.length; i++) {
        if (i > 0 && i % 3 == 0) {
          withCommas += ',';
        }
        withCommas += reversed[i];
      }
      integerPart = withCommas.split('').reversed.join('');
    }
    
    // Reconstruct the formatted text
    String formattedText = integerPart;
    if (parts.length == 2) {
      formattedText += '.${parts[1]}';
    } else if (digitsOnly.endsWith('.')) {
      formattedText += '.';
    }
    
    // Calculate cursor position
    int cursorPosition = formattedText.length;
    if (newValue.selection.baseOffset < newValue.text.length) {
      // Try to maintain relative cursor position
      int originalCursorPos = newValue.selection.baseOffset;
      int commasBeforeCursor = 0;
      
      // Count commas before the original cursor position
      for (int i = 0; i < originalCursorPos && i < newValue.text.length; i++) {
        if (newValue.text[i] == ',') {
          commasBeforeCursor++;
        }
      }
      
      // Adjust cursor position based on new comma count
      int newCommasBeforeCursor = 0;
      int adjustedPos = originalCursorPos - commasBeforeCursor;
      
      for (int i = 0; i < formattedText.length && newCommasBeforeCursor + adjustedPos >= 0; i++) {
        if (formattedText[i] == ',') {
          newCommasBeforeCursor++;
        } else {
          adjustedPos--;
          if (adjustedPos < 0) {
            cursorPosition = i + 1;
            break;
          }
        }
      }
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: cursorPosition.clamp(0, formattedText.length),
      ),
    );
  }
} 