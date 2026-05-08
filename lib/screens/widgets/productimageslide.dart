import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/core/num_extension.dart';

class ProductImageSlider extends StatefulWidget {
  final ProductModel product;

  const ProductImageSlider({super.key, required this.product});

  @override
  State<ProductImageSlider> createState() => _ProductImageSliderState();
}

class _ProductImageSliderState extends State<ProductImageSlider> {
  int currentIndex = 0;
  late final PageController _pageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final nextIndex = (currentIndex + 1) % widget.product.imageUrl.length;

      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreen(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(
          images: widget.product.imageUrl,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Column(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: Stack(
            children: [
              /// ── BIG IMAGES ────────────────────────────────────────────
              PageView.builder(
                controller: _pageController,
                itemCount: product.imageUrl.length,
                onPageChanged: (i) {
                  setState(() => currentIndex = i);
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openFullScreen(context, index),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl[index],
                      key: ValueKey(product.imageUrl[index]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: LogoLoadingIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                },
              ),

              /// ── TOP BAR ───────────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
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
                        20.getWidthWhiteSpacing,
                        const Text(
                          "Item Details",
                          style: TextStyle(fontSize: 18),
                        ),
                        const Spacer(),
                        10.getWidthWhiteSpacing,
                        Consumer<ProductProvider>(
                          builder: (context, provider, _) {
                            final userId = context.read<AuthProvider>().userId;
                            if (userId == null) return const SizedBox();

                            final currentProduct = provider.products.firstWhere(
                              (p) => p.productId == product.productId,
                              orElse: () =>
                                  provider.categoryProducts.firstWhere(
                                (p) => p.productId == product.productId,
                                orElse: () => product,
                              ),
                            );

                            final isLiked = provider.likedProductIds
                                .contains(product.productId);

                            return _LikeButton(
                              isLiked: isLiked,
                              onTap: () {
                                provider.toggleLike(
                                  productId: currentProduct.productId,
                                  userId: userId,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// ── DOT INDICATOR ─────────────────────────────────────────
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    product.imageUrl.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 6,
                      width: currentIndex == index ? 12 : 6,
                      decoration: BoxDecoration(
                        color:
                            currentIndex == index ? Colors.brown : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        5.getHeightWhiteSpacing,

        /// ── THUMBNAIL STRIP ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: product.imageUrl.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: currentIndex == index
                            ? const Color(0xff9D6E2D)
                            : Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20),
    );
  }
}

/// ================= FULL SCREEN VIEWER =================
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _controller;
  late int current;

  @override
  void initState() {
    super.initState();
    current = widget.initialIndex;
    _controller = PageController(initialPage: current);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => current = i),
            itemBuilder: (_, index) {
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),

          /// CLOSE BUTTON
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;

  const _LikeButton({required this.isLiked, required this.onTap});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double iconScale = _isPressed ? 1.4 : 1.0;
    final double containerScale = _isPressed ? 1.2 : 1.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: containerScale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(6),
          ),
          child: AnimatedScale(
            scale: iconScale,
            duration: const Duration(milliseconds: 100),
            curve: Curves.elasticOut,
            child: Icon(
              Icons.favorite_outline,
              size: 23,
              color: widget.isLiked ? Colors.red : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
