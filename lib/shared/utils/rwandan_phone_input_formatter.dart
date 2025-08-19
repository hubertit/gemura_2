import 'package:flutter/services.dart';

/// Custom input formatter to prepend "250" when starting with "0"
/// This formatter is designed to work with country code pickers
/// It automatically handles Rwandan phone number formatting
class RwandanPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove any non-digit characters
    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // If it starts with "0", prepend "250" and keep the rest
    if (cleaned.startsWith('0') && cleaned.length >= 1) {
      cleaned = '250${cleaned.substring(1)}';
    }
    
    // Limit to 12 digits
    if (cleaned.length > 12) {
      cleaned = cleaned.substring(0, 12);
    }
    
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}
