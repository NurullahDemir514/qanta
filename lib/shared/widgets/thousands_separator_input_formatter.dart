import 'package:flutter/services.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If text is empty, allow it
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // If user is deleting everything (selection covers entire text), allow it
    if (newValue.text.isEmpty && oldValue.text.isNotEmpty) {
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
    
    // Optimized cursor position calculation
    int cursorPosition = formattedText.length;
    
    // Quick optimization: if text is empty, cursor at start
    if (formattedText.isEmpty) {
      cursorPosition = 0;
    } else if (newValue.text.length < oldValue.text.length) {
      // Optimized deletion handling - most common case
      int originalCursorPos = newValue.selection.baseOffset;
      
      // Fast path: if deleting from end, cursor stays at end
      if (originalCursorPos >= oldValue.text.length) {
        cursorPosition = formattedText.length;
      } else {
        // Count meaningful characters (digits + decimal) before cursor
        int meaningfulChars = 0;
        for (int i = 0; i < originalCursorPos && i < oldValue.text.length; i++) {
          if (oldValue.text[i].contains(RegExp(r'[\d.]'))) {
            meaningfulChars++;
          }
        }
        
        // Find position in new text
        int currentMeaningfulChars = 0;
        for (int i = 0; i < formattedText.length; i++) {
          if (formattedText[i].contains(RegExp(r'[\d.]'))) {
            currentMeaningfulChars++;
            if (currentMeaningfulChars >= meaningfulChars) {
              cursorPosition = i + 1;
              break;
            }
          }
        }
      }
    } else if (newValue.text.length > oldValue.text.length) {
      // Optimized insertion handling
      int originalCursorPos = newValue.selection.baseOffset;
      int oldCommas = oldValue.text.substring(0, originalCursorPos.clamp(0, oldValue.text.length)).split(',').length - 1;
      int newCommas = formattedText.substring(0, originalCursorPos.clamp(0, formattedText.length)).split(',').length - 1;
      
      cursorPosition = originalCursorPos + (newCommas - oldCommas);
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: cursorPosition.clamp(0, formattedText.length),
      ),
    );
  }
}