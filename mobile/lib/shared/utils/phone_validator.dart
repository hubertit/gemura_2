class PhoneValidator {
  // Rwandan phone number validation
  static const List<String> _validPrefixes = ['78', '79', '72', '73'];
  static const int _expectedLength = 9; // Without country code
  static const int _fullLength = 12; // With country code (+250)

  /// Validates a phone number (supports international numbers)
  /// Returns null if valid, error message if invalid
  /// Checks minimum digits only since international numbers have different lengths
  static String? validateRwandanPhone(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove any spaces, dashes, or other separators
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleanNumber)) {
      return 'Phone number must contain only digits';
    }

    // Check minimum length (at least 7 digits for international numbers)
    // Maximum 15 digits as per ITU-T E.164 standard
    if (cleanNumber.length < 7) {
      return 'Phone number must have at least 7 digits';
    }
    
    if (cleanNumber.length > 15) {
      return 'Phone number must not exceed 15 digits';
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

  /// Validates any international phone number (more flexible)
  /// Returns null if valid, error message if invalid
  static String? validateInternationalPhone(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove any spaces, dashes, or other separators
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleanNumber)) {
      return 'Phone number must contain only digits';
    }

    // Check length (should be between 7 and 15 digits for international numbers)
    if (cleanNumber.length < 7 || cleanNumber.length > 15) {
      return 'Phone number must be between 7 and 15 digits';
    }

    return null; // Valid phone number
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
