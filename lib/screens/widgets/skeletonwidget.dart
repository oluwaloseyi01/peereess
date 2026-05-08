import 'package:flutter/material.dart';

/// Full card skeleton — used when isLoading: true
class ImageSkeleton extends StatefulWidget {
  const ImageSkeleton({super.key});

  @override
  State<ImageSkeleton> createState() => _ImageSkeletonState();
}

class _ImageSkeletonState extends State<ImageSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    double radius = 4,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0D6CC),
                Color(0xFFF5EEE8),
                Color(0xFFE0D6CC),
              ],
              stops: [
                (_animation.value - 0.4).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.4).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 233, 226, 226),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
            child: _shimmerBox(height: 150, width: double.infinity, radius: 0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _shimmerBox(height: 12, width: 100),
                const SizedBox(height: 4),
                _shimmerBox(height: 9, width: 130),
                const SizedBox(height: 2),
                _shimmerBox(height: 12, width: 70),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Inline shimmer — used ONLY as CachedNetworkImage placeholder
/// It fills whatever space it's given without its own Column or fixed height.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0D6CC),
                Color(0xFFF5EEE8),
                Color(0xFFE0D6CC),
              ],
              stops: [
                (_animation.value - 0.4).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.4).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
