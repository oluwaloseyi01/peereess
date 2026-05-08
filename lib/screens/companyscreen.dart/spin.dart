import 'dart:math';
import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';

import 'package:peereess/provider/spinservice.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// showAppBar: true  → standalone pushed route (has back button)
// showAppBar: false → inside the home bottom sheet modal (no AppBar)
// ─────────────────────────────────────────────────────────────────────────────

class SpinToWinPage extends StatefulWidget {
  final bool showAppBar;
  const SpinToWinPage({super.key, this.showAppBar = true});

  @override
  State<SpinToWinPage> createState() => _SpinToWinPageState();
}

// ─── Wheel segments ───────────────────────────────────────────────────────────
const List<_Segment> _kSegments = [
  _Segment(
    label: '30%\nDiscount',
    color: Color(0xFFE07B39),
    textColor: Colors.white,
  ),
  _Segment(
    label: 'Free\nDelivery',
    color: Color(0xFF9D6E2D),
    textColor: Colors.white,
  ),
  _Segment(
    label: '40%\nDiscount',
    color: Color(0xFFF5C97A),
    textColor: Color(0xFF5C3A00),
  ),
  _Segment(
    label: 'Try\nAgain',
    color: Color(0xFFD9C2A3),
    textColor: Color(0xFF5C3A00),
  ),
  _Segment(
    label: '₦5,000\nVoucher',
    color: Color(0xFF7B3F00),
    textColor: Colors.white,
  ),
  _Segment(
    label: '50%\nDiscount',
    color: Color(0xFFE8A96A),
    textColor: Colors.white,
  ),
];

const int _kForceIndex = 3;

class _Segment {
  final String label;
  final Color color;
  final Color textColor;
  const _Segment({
    required this.label,
    required this.color,
    required this.textColor,
  });
}

// ─── State ────────────────────────────────────────────────────────────────────
class _SpinToWinPageState extends State<SpinToWinPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isSpinning = false;
  bool _hasSpun = false;
  String? _result;
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addListener(
      () => setState(() => _currentAngle = _animation.value),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
          _hasSpun = true;
          _result = "Oops! Try Again";
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Spin ──────────────────────────────────────────────────────────────────
  void _spin() {
    if (_isSpinning) return;

    // ✅ Check SpinService — if admin disabled mid-session, block
    final spin = context.read<SpinService>();
    if (!spin.spinEnabled) return;

    if (_hasSpun) {
      _showNoMoreSpinsSheet();
      return;
    }

    setState(() {
      _isSpinning = true;
      _result = null;
    });

    const int n = 6;
    final double segAngle = (2 * pi) / n;
    double targetRemainder = -((_kForceIndex + 0.5) * segAngle) % (2 * pi);
    if (targetRemainder < 0) targetRemainder += 2 * pi;
    final double extraSpins = (3 + Random().nextInt(3)) * 2 * pi;
    final double normalised = _currentAngle % (2 * pi);
    double delta = (targetRemainder - normalised) % (2 * pi);
    if (delta < 0) delta += 2 * pi;

    _animation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle + extraSpins + delta,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.duration = const Duration(milliseconds: 4200);
    _controller.reset();
    _controller.forward();
  }

  // ── No More Spins sheet ───────────────────────────────────────────────────
  void _showNoMoreSpinsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _NoMoreSpinsSheet(
        onContinue: () {
          // Close the "No more spins" sheet
          Navigator.pop(context);
          // If we're inside the home modal, close that too
          if (!widget.showAppBar) Navigator.pop(context);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ✅ React to SpinService in real time
    // If admin disables spin while user is on this screen, button greys out
    final spinService = context.watch<SpinService>();
    final bool spinEnabled = spinService.spinEnabled;

    final body = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Title ──────────────────────────────────────────────────────
              const Text(
                "🎁 Your Lucky Spin",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'poppins',
                  color: Color(0xFF5C3A00),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                !spinEnabled
                    ? "Spins are currently unavailable."
                    : _hasSpun
                        ? "You've used your spin for today."
                        : "One spin per session. Good luck!",
                style: const TextStyle(fontSize: 13, color: Colors.brown),
              ),
              const SizedBox(height: 32),

              // ── Wheel ───────────────────────────────────────────────────────
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: 300,
                    height: 300,
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9D6E2D).withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: _currentAngle,
                      child: CustomPaint(
                        painter: _WheelPainter(
                          segments: _kSegments,
                          dimmed: _hasSpun || !spinEnabled,
                        ),
                      ),
                    ),
                  ),
                  // Centre hub
                  Positioned(
                    top: 16 + 150 - 28,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF7B3F00),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  ),
                  const _Pointer(),
                ],
              ),

              const SizedBox(height: 10),

              // ── Disabled banner ─────────────────────────────────────────────
              if (!spinEnabled)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "Spinning is currently unavailable.\nCheck back soon!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'poppins',
                    ),
                  ),
                )
              // ── Result banner ───────────────────────────────────────────────
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _result != null
                      ? Container(
                          key: const ValueKey('result'),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B3F00),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 10),
                            ],
                          ),
                          child: Text(
                            _result!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'poppins',
                            ),
                          ),
                        )
                      : const SizedBox(key: ValueKey('empty'), height: 22),
                ),

              const SizedBox(height: 10),

              // ── Button ──────────────────────────────────────────────────────
              _SpinButton(
                onTap: (!spinEnabled || _isSpinning) ? null : _spin,
                spinning: _isSpinning,
                exhausted: _hasSpun,
                disabled: !spinEnabled,
                label: _hasSpun ? "Spin Again" : "Spin Now",
              ),

              30.getHeightWhiteSpacing,
            ],
          ),
        ),
      ),
    );

    // Standalone route — wrap in Scaffold with AppBar
    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromARGB(255, 217, 194, 162),
          title: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Color(0xff9D6E2D),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Spin to Win",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        body: body,
      );
    }

    // Inside modal — return body directly (Home provides the container)
    return body;
  }
}

// ─── No More Spins Sheet ──────────────────────────────────────────────────────
class _NoMoreSpinsSheet extends StatelessWidget {
  final VoidCallback onContinue;
  const _NoMoreSpinsSheet({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5EBD8),
              border: Border.all(color: const Color(0xFF9D6E2D), width: 2),
            ),
            child: const Icon(
              Icons.block_rounded,
              size: 36,
              color: Color(0xFF9D6E2D),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No More Spins! 🚫",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'poppins',
              color: Color(0xFF5C3A00),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "You've already used your free spin.\nCheck back later for a new chance to win!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.brown, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onContinue,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B3F00), Color(0xFF9D6E2D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x559D6E2D),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Continue Shopping 🛍️",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'poppins',
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wheel painter ────────────────────────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final List<_Segment> segments;
  final bool dimmed;
  _WheelPainter({required this.segments, this.dimmed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final int n = segments.length;
    final double sweep = (2 * pi) / n;

    for (int i = 0; i < n; i++) {
      final seg = segments[i];
      final startAngle = i * sweep - pi / 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        Paint()..color = dimmed ? seg.color.withOpacity(0.45) : seg.color,
      );

      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle),
        ),
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..strokeWidth = 2,
      );

      final midAngle = startAngle + sweep / 2;
      final labelCenter = Offset(
        center.dx + radius * 0.62 * cos(midAngle),
        center.dy + radius * 0.62 * sin(midAngle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: seg.label,
          style: TextStyle(
            color: dimmed ? seg.textColor.withOpacity(0.45) : seg.textColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 70);

      canvas.save();
      canvas.translate(labelCenter.dx, labelCenter.dy);
      canvas.rotate(midAngle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..color = const Color(0xFF7B3F00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.dimmed != dimmed;
}

// ─── Pointer ──────────────────────────────────────────────────────────────────
class _Pointer extends StatelessWidget {
  const _Pointer();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36,
        height: 36,
        child: CustomPaint(painter: _PointerPainter()),
      );
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF7B3F00));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Spin Button ──────────────────────────────────────────────────────────────
class _SpinButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool spinning;
  final bool exhausted;
  final bool disabled;
  final String label;

  const _SpinButton({
    required this.onTap,
    required this.spinning,
    required this.exhausted,
    required this.disabled,
    this.label = "Spin Now 🎡",
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (spinning || disabled) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 48),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: spinning
              ? const LinearGradient(
                  colors: [Color(0xFFB0956A), Color(0xFFCFAF80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : (exhausted || disabled)
                  ? const LinearGradient(
                      colors: [Color(0xFF888888), Color(0xFFAAAAAA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF7B3F00), Color(0xFF9D6E2D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: spinning
              ? []
              : [
                  BoxShadow(
                    color: (exhausted || disabled)
                        ? Colors.grey.withOpacity(0.4)
                        : const Color(0x559D6E2D),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: spinning
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'poppins',
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
