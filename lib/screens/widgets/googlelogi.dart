import 'package:flutter/material.dart';
import 'package:peereess/core/texttheme.dart';

class GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFF5EBD8),
          borderRadius: BorderRadius.circular(10), // matches AppButtons radius
          border: Border.all(color: const Color(0xFFD9C2A2), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            Text(
              "Continue with Google",
              style: context.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF5C3A00),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawArc(
      rect,
      -0.3,
      1.9,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.width * 0.18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );
    canvas.drawArc(
      rect,
      -1.0,
      -1.2,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..strokeWidth = size.width * 0.18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );
    canvas.drawArc(
      rect,
      2.2,
      0.9,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..strokeWidth = size.width * 0.18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );
    canvas.drawArc(
      rect,
      1.6,
      0.65,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..strokeWidth = size.width * 0.18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.95, center.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.width * 0.18
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
