/// Security utilities for input validation and sanitization
class SecurityUtils {
  // Email validation with comprehensive regex
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  // Password strength validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }
    return null;
  }

  // Sanitize input to prevent injection attacks
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"' + "']"), '') // Remove HTML/SQL injection chars
        .trim(); // Remove leading/trailing whitespace
  }

  // Validate company name
  static String? validateCompanyName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Company name is required';
    }
    if (name.length < 2) {
      return 'Company name must be at least 2 characters long';
    }
    if (name.length > 50) {
      return 'Company name must be less than 50 characters';
    }
    // Allow letters, numbers, spaces, and common business punctuation
    if (!RegExp(r'^[a-zA-Z0-9\s\.\-&,' + "'" + r']+$').hasMatch(name)) {
      return 'Company name contains invalid characters';
    }
    return null;
  }

  // Validate product names
  static String? validateProductName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Product name is required';
    }
    if (name.length < 1) {
      return 'Product name cannot be empty';
    }
    if (name.length > 100) {
      return 'Product name must be less than 100 characters';
    }
    return null;
  }

  // Validate numeric inputs (quantities, prices)
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    if (number < 0) {
      return '$fieldName must be positive';
    }
    return null;
  }

  // Validate quantity specifically
  static String? validateQuantity(String? quantity) {
    if (quantity == null || quantity.isEmpty) {
      return 'Quantity is required';
    }
    final number = int.tryParse(quantity);
    if (number == null) {
      return 'Quantity must be a whole number';
    }
    if (number < 0) {
      return 'Quantity cannot be negative';
    }
    if (number > 999999) {
      return 'Quantity is too large';
    }
    return null;
  }

  // Validate price
  static String? validatePrice(String? price) {
    if (price == null || price.isEmpty) {
      return 'Price is required';
    }
    final number = double.tryParse(price);
    if (number == null) {
      return 'Price must be a valid number';
    }
    if (number < 0) {
      return 'Price cannot be negative';
    }
    if (number > 999999.99) {
      return 'Price is too large';
    }
    // Check for reasonable decimal places (max 2)
    if (price.contains('.') && price.split('.')[1].length > 2) {
      return 'Price can have at most 2 decimal places';
    }
    return null;
  }

  // Rate limiting for API calls (simple implementation)
  static final Map<String, DateTime> _lastCallTimes = {};
  static final Map<String, int> _callCounts = {};

  static bool isRateLimited(String action, {int maxCalls = 10, Duration window = const Duration(minutes: 1)}) {
    final now = DateTime.now();
    final lastCall = _lastCallTimes[action];
    
    if (lastCall == null || now.difference(lastCall) > window) {
      _lastCallTimes[action] = now;
      _callCounts[action] = 1;
      return false;
    }
    
    final currentCount = _callCounts[action] ?? 0;
    if (currentCount >= maxCalls) {
      return true;
    }
    
    _callCounts[action] = currentCount + 1;
    return false;
  }

  // Validate barcode format
  static String? validateBarcode(String? barcode) {
    if (barcode == null || barcode.isEmpty) {
      return null; // Barcode is optional
    }
    // Common barcode formats: UPC-A (12), EAN-13 (13), Code128 (variable)
    if (!RegExp(r'^[0-9]{8,14}$').hasMatch(barcode)) {
      return 'Barcode must be 8-14 digits';
    }
    return null;
  }
}

/// Error handling utilities
class ErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (errorStr.contains('permission')) {
      return 'Permission denied. Please check your access rights.';
    } else if (errorStr.contains('timeout')) {
      return 'Operation timed out. Please try again.';
    } else if (errorStr.contains('firebase')) {
      return 'Database error. Please try again later.';
    } else if (errorStr.contains('invalid')) {
      return 'Invalid data. Please check your input.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    // In production, this would log to a proper logging service
    // For now, using debug output
    // print('ERROR in $context: $error');
    // if (stackTrace != null) print('Stack trace: $stackTrace');
  }
}
