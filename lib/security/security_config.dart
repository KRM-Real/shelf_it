/// Security constants and configurations
class SecurityConfig {
  // Password requirements
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireNumbers = true;
  static const bool requireSpecialChars = true;

  // Rate limiting
  static const int maxLoginAttempts = 5;
  static const int maxApiRequestsPerMinute = 100;
  static const Duration loginRateLimitWindow = Duration(minutes: 15);
  static const Duration apiRateLimitWindow = Duration(minutes: 1);
  static const Duration rateLimitBlockDuration = Duration(minutes: 30);

  // Session management
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration sessionWarningTime = Duration(minutes: 25);

  // File upload restrictions
  static const int maxImageSizeInMB = 5;
  static const List<String> allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];

  // Input validation
  static const int maxCompanyNameLength = 100;
  static const int maxProductNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxBarcodeLength = 50;
  static const int minBarcodeLength = 6;

  // Data access limits
  static const int maxProductsPerQuery = 100;
  static const int maxTransactionsPerQuery = 50;

  // Security headers
  static const Map<String, String> securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
  };

  // Sensitive data patterns (for logging redaction)
  static const List<String> sensitivePatterns = [
    'password',
    'email',
    'phone',
    'credit',
    'card',
    'ssn',
    'social',
  ];

  // Allowed domains for redirects (if implementing redirect functionality)
  static const List<String> allowedRedirectDomains = [
    'localhost',
    'shelfit.com',
    // Add your production domains here
  ];

  // Error messages (generic to avoid information disclosure)
  static const String genericErrorMessage =
      'An error occurred. Please try again.';
  static const String rateLimitMessage =
      'Too many attempts. Please try again later.';
  static const String sessionExpiredMessage =
      'Your session has expired. Please log in again.';
  static const String unauthorizedMessage =
      'You are not authorized to access this resource.';
  static const String invalidInputMessage = 'Invalid input provided.';

  // Audit event types
  static const String authEventType = 'authentication';
  static const String dataAccessEventType = 'data_access';
  static const String suspiciousActivityEventType = 'suspicious_activity';
  static const String securityViolationEventType = 'security_violation';
}
