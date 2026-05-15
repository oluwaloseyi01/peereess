import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:peereess/core/app_images.dart';
import 'package:peereess/databases/config/appwrite.dart';

import 'package:peereess/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderRadiusAnim;
  late Animation<double> _scaleAnim;

  bool _hasInternet = true;
  bool _checkingInternet = true;
  bool _navigated = false;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInternetAndNavigate();
    });
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _borderRadiusAnim = Tween<double>(
      begin: 0,
      end: 75,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('🔔 Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('⚠️ Firebase Messaging setup failed: $e');
    }
  }

  Future<void> _checkInternetAndNavigate() async {
    // ── 1. Wait for internet ────────────────────────────────────
    while (true) {
      if (!mounted || _navigated) return;

      if (mounted) setState(() => _checkingInternet = true);

      final connected = await _checkInternet();

      if (!mounted || _navigated) return;

      if (!connected) {
        _failedAttempts++;
        setState(() {
          _hasInternet = false;
          _checkingInternet = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }

      if (mounted) {
        setState(() {
          _hasInternet = true;
          _checkingInternet = false;
        });
      }

      break;
    }

    if (!mounted || _navigated) return;

    // ── 2. Request notification permission ─────────────────────
    await _setupFirebaseMessaging();

    if (!mounted || _navigated) return;

    // ── 3. Restore session (if any) ─────────────────────────────
    final auth = context.read<AuthProvider>();
    await auth.initAuth();

    if (!mounted || _navigated) return;

    // ── 4. Register device push token if logged in ──────────────
    if (auth.isLoggedIn) {
      await AppwriteConfig.registerDevice();
    }

    if (!mounted || _navigated) return;

    // ── 5. Check onboarding flag ────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    if (!mounted || _navigated) return;

    _navigated = true;

    // ── 6. Navigate ─────────────────────────────────────────────

    // First-time user: show onboarding regardless of auth state
    if (!seenOnboarding) {
      Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
      return;
    }

    // Logged-in user: route by role
    if (auth.isLoggedIn) {
      final role = auth.userType.toLowerCase().replaceAll('/', '');
      switch (role) {
        case 'admin':
          Navigator.pushNamedAndRemoveUntil(
              context, '/adminhome', (_) => false);
          break;
        case 'seller':
          Navigator.pushNamedAndRemoveUntil(
              context, '/sellerhome', (_) => false);
          break;
        default:
          // Normal user — go to home feed
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
      return;
    }

    // ✅ Not logged in — land on /home (public browse), NOT /login.
    // Users can explore products freely; login is prompted only when
    // they try to do something that requires an account (cart, chat, etc.).
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showNoBanner =
        !_hasInternet && !_checkingInternet && _failedAttempts > 0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          _borderRadiusAnim.value,
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Image.asset(AppImages.peereesslogo),
                    ),
                  );
                },
              ),
            ),
          ),
          if (showNoBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.red,
                child: const SafeArea(
                  child: Center(
                    child: Text(
                      "No internet connection. Retrying...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_checkingInternet || !_hasInternet)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 1,
              ),
            ),
        ],
      ),
    );
  }
}
