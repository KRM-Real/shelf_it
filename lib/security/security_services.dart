import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Rate limiting service to prevent abuse
class RateLimitService {
  static final Map<String, List<DateTime>> _attempts = {};
  static const int maxAttempts = 5;
  static const Duration windowDuration = Duration(minutes: 15);
  static const Duration blockDuration = Duration(minutes: 30);

  /// Check if an action is rate limited
  static bool isRateLimited(String identifier) {
    final now = DateTime.now();
    final key = _getKey(identifier);

    // Clean old attempts
    _attempts[key]?.removeWhere(
      (attempt) => now.difference(attempt) > windowDuration,
    );

    final attempts = _attempts[key] ?? [];
    return attempts.length >= maxAttempts;
  }

  /// Record an attempt
  static void recordAttempt(String identifier) {
    final key = _getKey(identifier);
    _attempts[key] ??= [];
    _attempts[key]!.add(DateTime.now());
  }

  /// Get remaining time for rate limit
  static Duration? getBlockedTimeRemaining(String identifier) {
    final key = _getKey(identifier);
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

  /// Clear attempts for an identifier
  static void clearAttempts(String identifier) {
    final key = _getKey(identifier);
    _attempts.remove(key);
  }

  static String _getKey(String identifier) {
    return identifier.toLowerCase().trim();
  }
}

/// Session management service
class SessionManager {
  static const Duration sessionTimeout = Duration(minutes: 30);
  static DateTime? _lastActivity;
  static String? _currentUserId;

  /// Update last activity time
  static void updateActivity() {
    _lastActivity = DateTime.now();
  }

  /// Check if session is expired
  static bool isSessionExpired() {
    if (_lastActivity == null) return true;
    return DateTime.now().difference(_lastActivity!) > sessionTimeout;
  }

  /// Start session for user
  static void startSession(String userId) {
    _currentUserId = userId;
    updateActivity();
  }

  /// End current session
  static void endSession() {
    _currentUserId = null;
    _lastActivity = null;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _currentUserId;
  }

  /// Auto-logout if session expired
  static Future<void> checkSessionAndLogout() async {
    if (isSessionExpired()) {
      await FirebaseAuth.instance.signOut();
      endSession();
    }
  }
}

/// Audit logging service for security events
class SecurityAuditLogger {
  static const String _collection = 'security_audit';

  /// Log authentication events
  static Future<void> logAuthEvent({
    required String event,
    required String userId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await FirebaseFirestore.instance.collection(_collection).add({
        'event_type': 'authentication',
        'event': event,
        'user_id': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'ip_address': ipAddress ?? 'unknown',
        'user_agent': userAgent ?? 'unknown',
        'additional_data': additionalData ?? {},
      });
    } catch (e) {
      // Silently fail - don't break app functionality
      print('Failed to log security event: $e');
    }
  }

  /// Log data access events
  static Future<void> logDataAccess({
    required String action,
    required String resource,
    required String userId,
    String? resourceId,
    bool? success,
  }) async {
    try {
      await FirebaseFirestore.instance.collection(_collection).add({
        'event_type': 'data_access',
        'action': action,
        'resource': resource,
        'resource_id': resourceId,
        'user_id': userId,
        'success': success ?? true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail
      print('Failed to log data access: $e');
    }
  }

  /// Log suspicious activities
  static Future<void> logSuspiciousActivity({
    required String activity,
    required String userId,
    String? details,
    String? ipAddress,
  }) async {
    try {
      await FirebaseFirestore.instance.collection(_collection).add({
        'event_type': 'suspicious_activity',
        'activity': activity,
        'user_id': userId,
        'details': details,
        'ip_address': ipAddress,
        'timestamp': FieldValue.serverTimestamp(),
        'severity': 'high',
      });
    } catch (e) {
      // Silently fail
      print('Failed to log suspicious activity: $e');
    }
  }
}
