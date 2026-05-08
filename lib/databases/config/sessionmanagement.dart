import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // Single source of truth — pass this same key to MaterialApp
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> handle401(AppwriteException e) async {
    if (e.code == 401) {
      await _forceLogout();
    }
  }

  Future<void> _forceLogout() async {
    try {
      await AppwriteConfig.account.deleteSession(sessionId: 'current');
    } catch (_) {}

    // Bail out silently if the navigator isn't mounted yet
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    nav.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
