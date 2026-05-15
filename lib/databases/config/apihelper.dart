import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/databases/config/sessionmanagement.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:provider/provider.dart';

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

      if (e.code == 401) {
        // ✅ Only redirect to /login if the user was actually supposed to
        // have a session. If they are a guest browsing /home (isLoggedIn=false),
        // a 401 is expected — just return null silently, no redirect.
        final context = SessionManager.navigatorKey.currentContext;
        final isLoggedIn =
            context != null ? context.read<AuthProvider>().isLoggedIn : false;

        if (isLoggedIn) {
          await _handleSessionExpired();
        }

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
