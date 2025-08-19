class PhoneValidator {
  // Rwandan phone number validation
  static const List<String> _validPrefixes = ['78', '79', '72', '73'];
  static const int _expectedLength = 9; // Without country code
  static const int _fullLength = 12; // With country code (+250)

  /// Validates a Rwandan phone number
  /// Returns null if valid, error message if invalid
  static String? validateRwandanPhone(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove any spaces, dashes, or other separators
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it starts with +250
    if (cleanNumber.startsWith('+250')) {
      cleanNumber = cleanNumber.substring(4); // Remove +250
    } else if (cleanNumber.startsWith('250')) {
      cleanNumber = cleanNumber.substring(3); // Remove 250
    }

    // Check length (should be 9 digits after removing country code)
    if (cleanNumber.length != _expectedLength) {
      return 'Phone number must be 9 digits (e.g., 788606765)';
    }

    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleanNumber)) {
      return 'Phone number must contain only digits';
    }

    // Check if it starts with valid Rwandan prefixes
    bool hasValidPrefix = _validPrefixes.any((prefix) => cleanNumber.startsWith(prefix));
    if (!hasValidPrefix) {
      return 'Phone number must start with 78, 79, 72, or 73';
    }

    return null; // Valid phone number
  }

  /// Formats a phone number for display (adds +250 if not present)
  static String formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleanNumber.startsWith('+250')) {
      return cleanNumber;
    } else if (cleanNumber.startsWith('250')) {
      return '+$cleanNumber';
    } else {
      return '+250$cleanNumber';
    }
  }

  /// Extracts the phone number without country code
  static String extractPhoneWithoutCode(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleanNumber.startsWith('+250')) {
      return cleanNumber.substring(4);
    } else if (cleanNumber.startsWith('250')) {
      return cleanNumber.substring(3);
    }
    
    return cleanNumber;
  }

  /// Gets the full phone number with country code
  static String getFullPhoneNumber(String phoneNumber) {
    return formatPhoneNumber(phoneNumber);
  }

  /// Validates phone number for API submission
  static String? validateForAPI(String? phoneNumber) {
    return validateRwandanPhone(phoneNumber);
  }

  /// Gets valid Rwandan phone prefixes
  static List<String> getValidPrefixes() {
    return List.from(_validPrefixes);
  }

  /// Gets expected phone number length (without country code)
  static int getExpectedLength() {
    return _expectedLength;
  }

  /// Gets full phone number length (with country code)
  static int getFullLength() {
    return _fullLength;
  }
}
