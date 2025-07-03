import 'package:flutter/services.dart';

class MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    String formatted = '';
    if (digits.length >= 4) {
      formatted += digits.substring(0, 4);
      if (digits.length >= 5) {
        formatted += ' ' + digits.substring(4, digits.length >= 7 ? 7 : digits.length);
        if (digits.length >= 8) {
          formatted += ' ' + digits.substring(7, digits.length);
        }
      }
    } else {
      formatted = digits;
    }
    int selectionIndex = formatted.length;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
} 