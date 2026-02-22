import 'package:flutter/services.dart';

/// Custom input formatter for phone numbers with country code pickers
/// This formatter automatically handles phone number formatting
/// It removes non-digit characters and limits length appropriately
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove any non-digit characters
    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to reasonable length (15 digits max for international numbers)
    if (cleaned.length > 15) {
      cleaned = cleaned.substring(0, 15);
    }
    
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}
