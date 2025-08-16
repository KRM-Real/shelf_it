/// Rate limiting utilities to prevent abuse
class RateLimiter {
  static final Map<String, List<DateTime>> _attempts = {};
  static const int maxLoginAttempts = 5;
  static const int maxApiRequests = 100;
  static const Duration loginWindow = Duration(minutes: 15);
  static const Duration apiWindow = Duration(minutes: 1);
  static const Duration blockDuration = Duration(minutes: 30);

  /// Check if login attempts are rate limited
  static bool isLoginRateLimited(String identifier) {
    return _isRateLimited(identifier, 'login', maxLoginAttempts, loginWindow);
  }

  /// Check if API requests are rate limited
  static bool isApiRateLimited(String identifier) {
    return _isRateLimited(identifier, 'api', maxApiRequests, apiWindow);
  }

  /// Record a login attempt
  static void recordLoginAttempt(String identifier) {
    _recordAttempt(identifier, 'login');
  }

  /// Record an API request
  static void recordApiRequest(String identifier) {
    _recordAttempt(identifier, 'api');
  }

  /// Get remaining time for rate limit block
  static Duration? getLoginBlockTimeRemaining(String identifier) {
    return _getBlockTimeRemaining(
      identifier,
      'login',
      maxLoginAttempts,
      blockDuration,
    );
  }

  /// Clear login attempts for successful login
  static void clearLoginAttempts(String identifier) {
    _clearAttempts(identifier, 'login');
  }

  /// Private helper methods
  static bool _isRateLimited(
    String identifier,
    String type,
    int maxAttempts,
    Duration window,
  ) {
    final now = DateTime.now();
    final key = _getKey(identifier, type);

    // Clean old attempts
    _attempts[key]?.removeWhere((attempt) => now.difference(attempt) > window);

    final attempts = _attempts[key] ?? [];
    return attempts.length >= maxAttempts;
  }

  static void _recordAttempt(String identifier, String type) {
    final key = _getKey(identifier, type);
    _attempts[key] ??= [];
    _attempts[key]!.add(DateTime.now());
  }

  static Duration? _getBlockTimeRemaining(
    String identifier,
    String type,
    int maxAttempts,
    Duration blockDuration,
  ) {
    final key = _getKey(identifier, type);
    final attempts = _attempts[key];

    if (attempts == null || attempts.length < maxAttempts) {
      return null;
    }

    final oldestRelevantAttempt = attempts
        .where((attempt) => DateTime.now().difference(attempt) <= blockDuration)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final blockedUntil = oldestRelevantAttempt.add(blockDuration);
    final remaining = blockedUntil.difference(DateTime.now());

    return remaining.isNegative ? null : remaining;
  }

  static void _clearAttempts(String identifier, String type) {
    final key = _getKey(identifier, type);
    _attempts.remove(key);
  }

  static String _getKey(String identifier, String type) {
    return '${type}_${identifier.toLowerCase().trim()}';
  }

  /// Get attempts count for debugging
  static int getAttemptsCount(String identifier, String type) {
    final key = _getKey(identifier, type);
    return _attempts[key]?.length ?? 0;
  }

  /// Clear all rate limit data (for testing)
  static void clearAll() {
    _attempts.clear();
  }
}
