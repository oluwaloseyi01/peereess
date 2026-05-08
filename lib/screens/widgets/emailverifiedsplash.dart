import 'dart:async';
import 'package:flutter/material.dart';

class EmailVerifiedSplash extends StatefulWidget {
  const EmailVerifiedSplash({super.key});

  @override
  State<EmailVerifiedSplash> createState() => _EmailVerifiedSplashState();
}

class _EmailVerifiedSplashState extends State<EmailVerifiedSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/recomendscreen",
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFB0864C);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB0864C), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Stack(
            children: [
              // Bottom-left subtle circle only
              Positioned(
                bottom: -60,
                left: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),

              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: brand,
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        "Email verified",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Your account is ready.\nTaking you to the next step.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0x80000000),
                        ),
                      ),

                      const SizedBox(height: 36),

                      const _DotLoader(color: brand),
                    ],
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

class _DotLoader extends StatefulWidget {
  final Color color;
  const _DotLoader({required this.color});

  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = ((_controller.value - delay) % 1.0 + 1.0) % 1.0;
        final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.25, 1.0);
        final scale = 0.7 + opacity * 0.3;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(opacity),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(0.0),
        const SizedBox(width: 6),
        _dot(0.15),
        const SizedBox(width: 6),
        _dot(0.3),
      ],
    );
  }
}
