import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';

class WelcomeNotePage extends StatefulWidget {
  const WelcomeNotePage({super.key});

  @override
  State<WelcomeNotePage> createState() => _WelcomeNotePageState();
}

class _WelcomeNotePageState extends State<WelcomeNotePage>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _buttonController;

  late Animation<double> _iconScale;
  late Animation<double> _iconRotation;
  late Animation<double> _buttonSlide;
  late Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();

    // Icon: continuous pulse + slow spin
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _iconScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _iconRotation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    // Button: slide up + fade in on load
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _buttonSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    _buttonOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    // Delay button entrance slightly
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated Celebration Icon ──
                AnimatedBuilder(
                  animation: _iconController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _iconRotation.value,
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: const Icon(
                      Icons.celebration_rounded,
                      size: 64,
                      color: Color(0xff9D6E2D),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Main Message ──
                const Text(
                  'You’re all set!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff9D6E2D),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Start exploring amazing products and discover new favorites now!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "poppins",
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Animated Explore Button ──
                AnimatedBuilder(
                  animation: _buttonController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _buttonOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _buttonSlide.value),
                        child: child,
                      ),
                    );
                  },
                  child: AppButtons(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    text: "Explore now",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
