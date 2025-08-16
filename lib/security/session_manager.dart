/// Session management utilities
class SessionManager {
  static const Duration sessionTimeout = Duration(minutes: 30);
  static DateTime? _lastActivity;
  static String? _currentUserId;
  static String? _userMode;
  static String? _companyName;

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
  static void startSession({
    required String userId,
    String? userMode,
    String? companyName,
  }) {
    _currentUserId = userId;
    _userMode = userMode;
    _companyName = companyName;
    updateActivity();
  }

  /// End current session
  static void endSession() {
    _currentUserId = null;
    _userMode = null;
    _companyName = null;
    _lastActivity = null;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _currentUserId;
  }

  /// Get current user mode
  static String? getUserMode() {
    return _userMode;
  }

  /// Get current company name
  static String? getCompanyName() {
    return _companyName;
  }

  /// Check if user has organization access
  static bool hasOrganizationAccess() {
    return _userMode == 'organization';
  }

  /// Get session info
  static Map<String, dynamic> getSessionInfo() {
    return {
      'userId': _currentUserId,
      'userMode': _userMode,
      'companyName': _companyName,
      'lastActivity': _lastActivity?.toIso8601String(),
      'isExpired': isSessionExpired(),
      'remainingTime': _lastActivity != null
          ? sessionTimeout - DateTime.now().difference(_lastActivity!)
          : Duration.zero,
    };
  }

  /// Extend session
  static void extendSession() {
    if (_currentUserId != null) {
      updateActivity();
    }
  }
}
