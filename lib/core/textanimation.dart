import 'package:flutter/material.dart';

class AnimatedGradientText extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;
  final List<Color> gradientColors;
  final Duration duration;
  final Offset slideBeginOffset;

  const AnimatedGradientText({
    super.key,
    required this.text,
    this.fontSize = 28,
    this.fontWeight = FontWeight.w600,
    this.fontFamily = 'Caros',
    this.gradientColors = const [
      Color.fromARGB(255, 96, 69, 32),
      Color.fromARGB(255, 221, 115, 148),
    ],
    this.duration = const Duration(seconds: 1),
    this.slideBeginOffset = const Offset(0, 1),
  });

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _slideAnimation = Tween<Offset>(
      begin: widget.slideBeginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: widget.fontFamily,
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
              color: Colors.white, // required for ShaderMask
            ),
          ),
        ),
      ),
    );
  }
}
