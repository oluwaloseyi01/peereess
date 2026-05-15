import 'package:flutter/material.dart';

/// Shows a bottom sheet prompting the user to sign in or create an account.
///
/// Usage:
/// ```dart
/// AuthPromptSheet.show(context);
/// ```
///
/// Or with custom text:
/// ```dart
/// AuthPromptSheet.show(
///   context,
///   title: 'Save items',
///   subtitle: 'Sign in to save your favourite products.',
/// );
/// ```
class AuthPromptSheet extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthPromptSheet({
    super.key,
    this.title = 'Sign in required',
    this.subtitle = 'Please sign in or create an account to continue.',
  });

  /// Convenience method — call this instead of manually invoking showModalBottomSheet.
  static void show(
    BuildContext context, {
    String title = 'Sign in required',
    String subtitle = 'Please sign in or create an account to continue.',
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AuthPromptSheet(title: title, subtitle: subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false, // only pad the bottom (home bar / nav bar area)
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ────────────────────────────────────
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // ── Icon ───────────────────────────────────────────
              const Icon(
                Icons.lock_outline,
                size: 48,
                color: Color(0xff9D6E2D),
              ),
              const SizedBox(height: 12),

              // ── Title ──────────────────────────────────────────
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'poppins',
                ),
              ),
              const SizedBox(height: 8),

              // ── Subtitle ───────────────────────────────────────
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xff6A7686),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // ── Login button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff9D6E2D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Sign up button ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xff9D6E2D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Color(0xff9D6E2D),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
