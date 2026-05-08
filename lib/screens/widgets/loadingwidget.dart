import 'dart:math';
import 'package:flutter/material.dart';

class LogoLoadingIndicator extends StatefulWidget {
  final double size;

  const LogoLoadingIndicator({super.key, this.size = 100});

  @override
  State<LogoLoadingIndicator> createState() => _LogoLoadingIndicatorState();
}

class _LogoLoadingIndicatorState extends State<LogoLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const Color _colorA = Color(0xff9D6E2D);
  static const Color _colorB = Color(0xffC4893E);
  static const Color _colorC = Color(0xffD4A05A);

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

  @override
  Widget build(BuildContext context) {
    final double dotSize = widget.size * 0.08;
    final double gap = dotSize * 1.2;
    final double totalTrack = gap * 2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;

        double ease(double x) {
          x = x.clamp(0.0, 1.0);
          return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2;
        }

        double dotOffset(double phase) {
          final double p = ((t + phase) % 1.0);
          if (p < 0.5) {
            return ease(p * 2) * totalTrack;
          } else {
            return (1.0 - ease((p - 0.5) * 2)) * totalTrack;
          }
        }

        double dotScale(double phase) {
          final double p = ((t + phase) % 1.0);
          if (p < 0.5) {
            final double e = ease(p * 2);
            return 1.0 - (0.35 * sin(e * pi));
          } else {
            final double e = ease((p - 0.5) * 2);
            return 1.0 - (0.35 * sin(e * pi));
          }
        }

        final double posA = dotOffset(0.0);
        final double posB = dotOffset(1 / 3);
        final double posC = dotOffset(2 / 3);

        final double scaleA = dotScale(0.0);
        final double scaleB = dotScale(1 / 3);
        final double scaleC = dotScale(2 / 3);

        final double centerPos = totalTrack / 2;
        final dots = [
          (pos: posA, scale: scaleA, color: _colorA, id: 0),
          (pos: posB, scale: scaleB, color: _colorB, id: 1),
          (pos: posC, scale: scaleC, color: _colorC, id: 2),
        ];

        final sorted = [...dots]..sort(
            (a, b) =>
                (b.pos - centerPos).abs().compareTo((a.pos - centerPos).abs()),
          );

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: SizedBox(
              width: totalTrack + dotSize,
              height: dotSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: sorted.map((d) {
                  return Positioned(
                    left: d.pos,
                    top: 0,
                    child: _Dot(size: dotSize, scale: d.scale, color: d.color),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  final double size;
  final double scale;
  final Color color;

  const _Dot({required this.size, required this.scale, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
