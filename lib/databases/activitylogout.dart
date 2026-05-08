import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/databases/config/sessionmanagement.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;
  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _inactivityTimer;
  Timer? _authCheckTimer;

  bool _isLoggingOut = false;

  static const Duration timeout = Duration(minutes: 900);
  static const Duration authCheckInterval = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
    _startAuthCheckTimer();
    // ✅ Do NOT call _checkAuth() on startup — let Splash handle initial auth.
    // Calling it here causes a 401 → /login redirect that stomps over onboarding.
  }

  // ===============================
  // SESSION CHECK
  // ===============================
  Future<void> _checkAuth() async {
    if (_isLoggingOut) return;

    // ✅ Only check session if the user is actually supposed to be logged in.
    // During onboarding / login / signup the auth provider says isLoggedIn=false
    // so there is no session to check — skip entirely.
    final auth =
        SessionManager.navigatorKey.currentContext?.read<AuthProvider>();
    if (auth == null || !auth.isLoggedIn) return;

    try {
      await AppwriteConfig.account.get();
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        debugPrint('Session expired (401). Logging out...');
        await _logoutUser();
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }
  }

  void _startAuthCheckTimer() {
    _authCheckTimer?.cancel();
    _authCheckTimer = Timer.periodic(authCheckInterval, (_) => _checkAuth());
  }

  // ===============================
  // INACTIVITY TIMER
  // ===============================
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(timeout, _logoutUser);
  }

  void _resetInactivityTimer() {
    if (_isLoggingOut) return;
    _startInactivityTimer();
  }

  // ===============================
  // LOGOUT
  // ===============================
  Future<void> _logoutUser() async {
    if (_isLoggingOut) return;

    // ✅ Don't log out if the user isn't logged in (e.g. sitting on onboarding)
    final auth =
        SessionManager.navigatorKey.currentContext?.read<AuthProvider>();
    if (auth == null || !auth.isLoggedIn) return;

    _isLoggingOut = true;
    _inactivityTimer?.cancel();
    _authCheckTimer?.cancel();

    try {
      await AppwriteConfig.account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      if (e.code != 401) debugPrint('Logout error: $e');
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    SessionManager.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      onPointerSignal: (_) => _resetInactivityTimer(),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _authCheckTimer?.cancel();
    super.dispose();
  }
}
