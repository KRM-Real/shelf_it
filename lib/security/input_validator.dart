import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Input validation and sanitization utilities
class InputValidator {
  // Email validation with comprehensive regex
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // Enhanced password strength validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (password.length > 128) {
      return 'Password must be less than 128 characters';
    }

    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    // Check for common weak patterns
    final weakPatterns = ['password', '123456', 'qwerty', 'abc123', 'admin'];

    for (String pattern in weakPatterns) {
      if (password.toLowerCase().contains(pattern)) {
        return 'Password contains common weak patterns';
      }
    }

    return null; // Password is valid
  }

  // Sanitize input to prevent injection attacks
  static String sanitizeInput(String input) {
    return input
        .replaceAll(
          RegExp(r'[<>"' + r"'" + r'`]'),
          '',
        ) // Remove HTML/SQL injection chars
        .replaceAll(RegExp(r'[{}()\[\]]'), '') // Remove script brackets
        .replaceAll(RegExp(r'[\r\n\t]'), ' ') // Replace newlines with spaces
        .trim();
  }

  // Validate company name
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

    // Check for valid characters (letters, numbers, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z0-9\s\-'.&]+$").hasMatch(sanitized)) {
      return 'Company name contains invalid characters';
    }

    return null;
  }

  // Validate product name
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

  // Validate numeric inputs (quantity, price, threshold)
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

  // Validate barcode
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

  // Hash sensitive data (for logging purposes)
  static String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(
      0,
      8,
    ); // Return first 8 chars for logging
  }

  // Validate phone number (basic validation)
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

  // Validate description/notes
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
}
