/// Password strength validator
class PasswordValidator {
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
    final weakPatterns = [
      'password',
      '123456',
      'qwerty',
      'abc123',
      'admin',
      'letmein',
    ];

    for (String pattern in weakPatterns) {
      if (password.toLowerCase().contains(pattern)) {
        return 'Password contains common weak patterns';
      }
    }

    return null; // Password is valid
  }

  /// Calculate password strength score (0-100)
  static int calculateStrength(String password) {
    int score = 0;

    // Length bonus
    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;

    // Character variety
    if (password.contains(RegExp(r'[a-z]'))) score += 10;
    if (password.contains(RegExp(r'[A-Z]'))) score += 10;
    if (password.contains(RegExp(r'[0-9]'))) score += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 15;

    // Unique character bonus
    final uniqueChars = password.split('').toSet().length;
    if (uniqueChars >= 8) score += 10;
    if (uniqueChars >= 12) score += 5;

    // Penalty for common patterns
    final weakPatterns = ['123', 'abc', 'password', 'qwerty'];
    for (String pattern in weakPatterns) {
      if (password.toLowerCase().contains(pattern)) {
        score -= 10;
      }
    }

    return score.clamp(0, 100);
  }

  /// Get password strength description
  static String getStrengthDescription(int score) {
    if (score < 30) return 'Very Weak';
    if (score < 50) return 'Weak';
    if (score < 70) return 'Fair';
    if (score < 90) return 'Strong';
    return 'Very Strong';
  }
}
