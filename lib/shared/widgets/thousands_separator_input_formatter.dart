import 'package:flutter/services.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final String locale;
  final String thousandsSeparator;
  final String decimalSeparator;

  ThousandsSeparatorInputFormatter({this.locale = 'tr_TR'})
      : thousandsSeparator = _getThousandsSeparator(locale),
        decimalSeparator = _getDecimalSeparator(locale);

  static String _getThousandsSeparator(String locale) {
    // Turkish and most European locales use dot for thousands
    if (locale.startsWith('tr') || 
        locale.startsWith('de') || 
        locale.startsWith('es') || 
        locale.startsWith('it') ||
        locale.startsWith('fr')) {
      return '.';
    }
    // US and UK use comma
    return ',';
  }

  static String _getDecimalSeparator(String locale) {
    // Turkish and most European locales use comma for decimals
    if (locale.startsWith('tr') || 
        locale.startsWith('de') || 
        locale.startsWith('es') || 
        locale.startsWith('it') ||
        locale.startsWith('fr')) {
      return ',';
    }
    // US and UK use dot
    return '.';
  }

  // Public getter for decimal separator (for use in calculator)
  static String getDecimalSeparator(String locale) {
    return _getDecimalSeparator(locale);
  }

  /// Parses a locale-formatted string to double
  /// Example: "277.050,47" (Turkish) -> 277050.47
  ///          "277,050.47" (US) -> 277050.47
  static double parseLocaleDouble(String text, String locale) {
    if (text.isEmpty) return 0.0;
    
    final thousandsSep = _getThousandsSeparator(locale);
    final decimalSep = _getDecimalSeparator(locale);
    
    // Remove thousands separators
    String cleaned = text.replaceAll(thousandsSep, '');
    
    // Replace locale decimal separator with standard dot
    if (decimalSep != '.') {
      cleaned = cleaned.replaceAll(decimalSep, '.');
    }
    
    return double.tryParse(cleaned) ?? 0.0;
  }

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

    // Remove all non-digit characters except decimal separator
    String digitsOnly = newValue.text.replaceAll(
      RegExp('[^\\d${RegExp.escape(decimalSeparator)}]'),
      '',
    );
    
    // Handle decimal separator
    List<String> parts = digitsOnly.split(decimalSeparator);
    if (parts.length > 2) {
      // More than one decimal separator, keep only the first one
      digitsOnly = '${parts[0]}$decimalSeparator${parts.sublist(1).join('')}';
      parts = digitsOnly.split(decimalSeparator);
    }
    
    // Limit decimal places to 2
    if (parts.length == 2 && parts[1].length > 2) {
      parts[1] = parts[1].substring(0, 2);
      digitsOnly = '${parts[0]}$decimalSeparator${parts[1]}';
    }
    
    // Add thousands separators to the integer part
    String integerPart = parts[0];
    if (integerPart.isNotEmpty) {
      // Add separators every 3 digits from right to left
      String reversed = integerPart.split('').reversed.join('');
      String withSeparators = '';
      for (int i = 0; i < reversed.length; i++) {
        if (i > 0 && i % 3 == 0) {
          withSeparators += thousandsSeparator;
        }
        withSeparators += reversed[i];
      }
      integerPart = withSeparators.split('').reversed.join('');
    }
    
    // Reconstruct the formatted text
    String formattedText = integerPart;
    if (parts.length == 2) {
      formattedText += '$decimalSeparator${parts[1]}';
    } else if (digitsOnly.endsWith(decimalSeparator)) {
      formattedText += decimalSeparator;
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
          if (oldValue.text[i].contains(RegExp('[\\d${RegExp.escape(decimalSeparator)}]'))) {
            meaningfulChars++;
          }
        }
        
        // Find position in new text
        int currentMeaningfulChars = 0;
        for (int i = 0; i < formattedText.length; i++) {
          if (formattedText[i].contains(RegExp('[\\d${RegExp.escape(decimalSeparator)}]'))) {
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
      int oldSeparators = oldValue.text.substring(0, originalCursorPos.clamp(0, oldValue.text.length)).split(thousandsSeparator).length - 1;
      int newSeparators = formattedText.substring(0, originalCursorPos.clamp(0, formattedText.length)).split(thousandsSeparator).length - 1;
      
      cursorPosition = originalCursorPos + (newSeparators - oldSeparators);
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: cursorPosition.clamp(0, formattedText.length),
      ),
    );
  }
}