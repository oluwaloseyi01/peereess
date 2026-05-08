import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';

class ZipperRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const ZipperRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<ZipperRefreshWrapper> createState() => _ZipperRefreshWrapperState();
}

class _ZipperRefreshWrapperState extends State<ZipperRefreshWrapper>
    with SingleTickerProviderStateMixin {
  double _dragProgress = 0.0;
  static const double _maxDragHeight = 80.0;
  bool _isRefreshing = false;
  bool _trackingDrag = false;

  late AnimationController _snapBackController;
  double _snapStartProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dragProgress =
                _snapStartProgress * (1 - _snapBackController.value);
          });
        }
      });
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  bool _handleNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    final atTop = metrics.pixels <= 0;

    if (notification is ScrollStartNotification && atTop) {
      _snapBackController.stop();
      _trackingDrag = true;
    }

    if (notification is ScrollUpdateNotification && _trackingDrag) {
      final delta = notification.scrollDelta ?? 0;

      if (delta < 0 && atTop && !_isRefreshing) {
        final newProgress =
            (_dragProgress + (-delta / (_maxDragHeight * 2.5))).clamp(0.0, 1.0);
        _safeSetState(() => _dragProgress = newProgress);
      } else if (delta > 0 && _dragProgress > 0 && !_isRefreshing) {
        final newProgress =
            (_dragProgress - (delta / (_maxDragHeight * 2.5))).clamp(0.0, 1.0);
        _safeSetState(() => _dragProgress = newProgress);
      }
    }

    if (notification is ScrollEndNotification && _trackingDrag) {
      _trackingDrag = false;
      final progress = _dragProgress;
      if (progress >= 0.65 && !_isRefreshing) {
        _safeSetState(() {});
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _triggerRefresh();
        });
      } else if (progress > 0) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) _snapBack();
        });
      }
    }

    return false;
  }

  void _triggerRefresh() async {
    if (!mounted) return;
    setState(() {
      _isRefreshing = true;
      _dragProgress = 1.0;
    });
    await widget.onRefresh();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _snapStartProgress = 1.0;
      });
      _snapBackController.forward(from: 0);
    }
  }

  void _snapBack() {
    if (!mounted) return;
    _snapStartProgress = _dragProgress;
    _snapBackController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: _dragProgress * _maxDragHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleNotification,
            child: widget.child,
          ),
        ),
        if (_dragProgress > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _dragProgress * _maxDragHeight,
            child: ZipperIndicator(
              progress: _dragProgress,
              isRefreshing: _isRefreshing,
            ),
          ),
      ],
    );
  }
}

class ZipperIndicator extends StatelessWidget {
  final double progress;
  final bool isRefreshing;

  const ZipperIndicator({
    super.key,
    required this.progress,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.pinkAccent,
      child: isRefreshing
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: LogoLoadingIndicator(),
              ),
            )
          : CustomPaint(
              painter: _ZipperPainter(progress: progress),
              child: const SizedBox.expand(),
            ),
    );
  }
}

class _ZipperPainter extends CustomPainter {
  final double progress;
  _ZipperPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final unzipLength = size.height;

    const teethSpacing = 10.0;
    const teethWidth = 9.0;
    const teethHeight = 7.0;
    const teethGap = 8.0;
    const tapeWidth = 18.0;

    // Left tape strip
    canvas.drawRect(
      Rect.fromLTWH(centerX - tapeWidth - teethGap, 0, tapeWidth, unzipLength),
      Paint()..color = const Color(0xFFE6A020),
    );

    // Right tape strip
    canvas.drawRect(
      Rect.fromLTWH(centerX + teethGap, 0, tapeWidth, unzipLength),
      Paint()..color = const Color(0xFFE6A020),
    );

    // Center gap line
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, unzipLength),
      Paint()
        ..color = const Color(0xFF8B5E00)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // Interlocked teeth
    final teethPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final teethBorderPaint = Paint()
      ..color = const Color(0xFFB87A10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final numTeeth = (unzipLength / teethSpacing).floor();

    for (int i = 0; i < numTeeth; i++) {
      final leftY = i * teethSpacing + teethSpacing / 2;
      final rightY = leftY + teethSpacing / 2;

      // Left tooth
      final leftRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX - teethGap - teethWidth / 2, leftY),
          width: teethWidth,
          height: teethHeight,
        ),
        const Radius.circular(2.5),
      );
      canvas.drawRRect(leftRect, teethPaint);
      canvas.drawRRect(leftRect, teethBorderPaint);

      // Right tooth — interlocked (half step offset)
      if (rightY < unzipLength) {
        final rightRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX + teethGap + teethWidth / 2, rightY),
            width: teethWidth,
            height: teethHeight,
          ),
          const Radius.circular(2.5),
        );
        canvas.drawRRect(rightRect, teethPaint);
        canvas.drawRRect(rightRect, teethBorderPaint);
      }
    }

    // Zipper slider + pull tab at bottom
    if (unzipLength > 12) {
      final sliderY = unzipLength;
      const sliderW = 32.0;
      const sliderH = 14.0;

      // Trapezoidal slider body
      final sliderPath = Path()
        ..moveTo(centerX - sliderW / 2, sliderY - sliderH)
        ..lineTo(centerX + sliderW / 2, sliderY - sliderH)
        ..lineTo(centerX + sliderW / 2 - 4, sliderY)
        ..lineTo(centerX - sliderW / 2 + 4, sliderY)
        ..close();

      canvas.drawPath(
        sliderPath,
        Paint()..color = const Color(0xFFFFD700),
      );
      canvas.drawPath(
        sliderPath,
        Paint()
          ..color = const Color(0xFF8B5E00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Slider center ridge
      canvas.drawLine(
        Offset(centerX, sliderY - sliderH + 3),
        Offset(centerX, sliderY - 3),
        Paint()
          ..color = const Color(0xFF8B5E00)
          ..strokeWidth = 1.5,
      );

      // Pull tab
      const tabW = 14.0;
      const tabH = 18.0;
      final tabRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, sliderY + tabH / 2),
          width: tabW,
          height: tabH,
        ),
        const Radius.circular(3),
      );

      canvas.drawRRect(
        tabRect,
        Paint()..color = const Color(0xFFFFD700),
      );
      canvas.drawRRect(
        tabRect,
        Paint()
          ..color = const Color(0xFF8B5E00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Hole in pull tab
      canvas.drawCircle(
        Offset(centerX, sliderY + tabH / 2),
        3.0,
        Paint()..color = const Color(0xFF8B5E00),
      );
    }
  }

  @override
  bool shouldRepaint(_ZipperPainter old) => old.progress != progress;
}
