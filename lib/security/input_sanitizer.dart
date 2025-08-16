/// Input sanitization and validation utilities
class InputSanitizer {
  /// Email validation with comprehensive regex
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Sanitize input to prevent injection attacks
  static String sanitizeInput(String input) {
    return input
        .replaceAll(
          RegExp(r'[<>"' + "'" + r'`]'),
          '',
        ) // Remove HTML/SQL injection chars
        .replaceAll(RegExp(r'[{}()\[\]]'), '') // Remove script brackets
        .replaceAll(RegExp(r'[\r\n\t]'), ' ') // Replace newlines with spaces
        .trim();
  }

  /// Validate company name
  static String? validateCompanyName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Company name is required';
    }

    final sanitized = sanitizeInput(name);
    if (sanitized.length < 2) {
      return 'Company name must be at least 2 characters';
    }

    if (sanitized.length > 100) {
      return 'Company name must be less than 100 characters';
    }

    // Check for valid characters (letters, numbers, spaces, hyphens, periods, ampersands)
    if (!RegExp(r'^[a-zA-Z0-9\s\-.&]+$').hasMatch(sanitized)) {
      return 'Company name contains invalid characters';
    }

    return null;
  }

  /// Validate product name
  static String? validateProductName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Product name is required';
    }

    final sanitized = sanitizeInput(name);
    if (sanitized.length < 1) {
      return 'Product name cannot be empty';
    }

    if (sanitized.length > 100) {
      return 'Product name must be less than 100 characters';
    }

    return null;
  }

  /// Validate numeric inputs (quantity, price, threshold)
  static String? validateNumber(
    String? value, {
    required String fieldName,
    double? min,
    double? max,
    bool allowDecimals = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final sanitized = sanitizeInput(value);
    final number = allowDecimals
        ? double.tryParse(sanitized)
        : int.tryParse(sanitized)?.toDouble();

    if (number == null) {
      return 'Please enter a valid ${allowDecimals ? 'number' : 'whole number'}';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must not exceed $max';
    }

    return null;
  }

  /// Validate barcode
  static String? validateBarcode(String? barcode) {
    if (barcode == null || barcode.trim().isEmpty) {
      return null; // Barcode is optional
    }

    final sanitized = sanitizeInput(barcode);
    if (sanitized.length < 6 || sanitized.length > 50) {
      return 'Barcode must be between 6 and 50 characters';
    }

    // Allow alphanumeric characters only
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(sanitized)) {
      return 'Barcode can only contain letters and numbers';
    }

    return null;
  }

  /// Validate phone number (basic validation)
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return null; // Phone is optional
    }

    final sanitized = phone.replaceAll(RegExp(r'[^\d+\-\(\)\s]'), '');
    if (sanitized.length < 10) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate description/notes
  static String? validateDescription(
    String? description, {
    int maxLength = 500,
  }) {
    if (description == null || description.trim().isEmpty) {
      return null; // Description is optional
    }

    final sanitized = sanitizeInput(description);
    if (sanitized.length > maxLength) {
      return 'Description must be less than $maxLength characters';
    }

    return null;
  }

  /// Remove potentially dangerous content from strings
  static String sanitizeForDisplay(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(
          RegExp(r'javascript:', caseSensitive: false),
          '',
        ) // Remove javascript:
        .replaceAll(
          RegExp(r'vbscript:', caseSensitive: false),
          '',
        ) // Remove vbscript:
        .replaceAll(
          RegExp(r'data:', caseSensitive: false),
          '',
        ) // Remove data: URLs
        .trim();
  }

  /// Validate file extension for images
  static bool isValidImageExtension(String filename) {
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final extension = filename.toLowerCase().split('.').last;
    return allowedExtensions.contains('.$extension');
  }

  /// Validate file size
  static bool isValidFileSize(int sizeInBytes, {int maxSizeInMB = 5}) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return sizeInBytes <= maxSizeInBytes;
  }
}
