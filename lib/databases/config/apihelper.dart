import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/databases/config/sessionmanagement.dart';

class ApiHelper {
  /// Wraps an Appwrite call and handles 401 session expiry globally.
  ///
  /// Set [isAuthAction] = true for login / register / verify calls so that
  /// a 401 (wrong password, already exists, etc.) is rethrown to the caller
  /// instead of silently redirecting to /login.
  static Future<T?> guard<T>(
    Future<T> Function() callback, {
    bool isAuthAction = false,
  }) async {
    try {
      return await callback();
    } on AppwriteException catch (e) {
      // ✅ Auth actions (login, register) own their 401 — rethrow so the
      // caller's catch block can show the correct error message to the user.
      if (e.code == 401 && isAuthAction) rethrow;

      // For all other screens a 401 means the session expired — redirect.
      if (e.code == 401) {
        await _handleSessionExpired();
        return null;
      }

      rethrow;
    }
  }

  static Future<void> _handleSessionExpired() async {
    try {
      await AppwriteConfig.account.deleteSession(sessionId: 'current');
    } catch (_) {}

    SessionManager.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}
