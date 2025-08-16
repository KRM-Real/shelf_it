/// Authentication Guard Service
/// Handles route protection and user session management
class AuthGuard {
  /// List of routes that require authentication
  static const List<String> _protectedRoutes = [
    '/dashboard',
    '/product',
    '/add',
    '/stocklevels',
    '/orders',
  ];

  /// List of routes accessible only to unauthenticated users
  static const List<String> _guestOnlyRoutes = ['/', '/signup'];

  /// Check if route requires authentication
  static bool isProtectedRoute(String route) {
    return _protectedRoutes.contains(route);
  }

  /// Check if route is for guests only
  static bool isGuestOnlyRoute(String route) {
    return _guestOnlyRoutes.contains(route);
  }

  /// Auto-logout timer (30 minutes of inactivity)
  static const Duration sessionTimeout = Duration(minutes: 30);

  /// Check user permissions for organization features
  static bool hasOrganizationAccess(String? userMode) {
    return userMode == 'organization';
  }

  /// Check if user can access company data
  static bool canAccessCompanyData(
    String? userMode,
    String? userCompany,
    String? dataCompany,
  ) {
    if (userMode != 'organization') return false;
    return userCompany == dataCompany;
  }

  /// Check if user owns the data (for personal mode)
  static bool canAccessUserData(
    String? userMode,
    String? dataUserId,
    String? currentUserId,
  ) {
    if (userMode == 'organization') return false;
    return dataUserId == currentUserId;
  }
}
