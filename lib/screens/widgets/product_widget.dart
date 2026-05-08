import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:peereess/model/product.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/product_provider.dart';

import 'package:peereess/screens/widgets/skeletonwidget.dart';
import 'package:peereess/screens/widgets/starrating.dart';
import 'package:provider/provider.dart';

class ProductWidget extends StatelessWidget {
  final ProductModel product;
  final List<ProductModel> allProducts;
  final bool isLoading;

  const ProductWidget({
    super.key,
    required this.product,
    required this.allProducts,
    this.isLoading = false,
  });

  double get price {
    if (product.variants.isEmpty) return 0;
    return (product.variants.first['price'] ?? 0).toDouble();
  }

  double get finalPrice {
    if (product.discount == null || product.discount == 0) return price;
    return price - (price * (product.discount! / 100));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const ImageSkeleton();

    final formatter = NumberFormat("#,##0", "en_US");

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          "/collection",
          arguments: {
            "selectedProduct": product,
            "allProducts": allProducts,
          },
        );
      },
      child: Container(
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
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl.first,
                            fit: BoxFit.cover,
                            memCacheWidth: 400,
                            // ✅ ONLY change — ShimmerBox fills the SizedBox(150)
                            // without adding its own Column or fixed height
                            placeholder: (_, __) => const ShimmerBox(),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                  Icons.image_not_supported_outlined),
                            ),
                          )
                        : Container(color: Colors.grey[200]),

                    // Discount badge + like button
                    Positioned(
                      top: 4,
                      left: 4,
                      right: 4,
                      child: Row(
                        children: [
                          if (product.discount != null && product.discount! > 0)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.yellow,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 3,
                              ),
                              child: Text(
                                "-${product.discount!.toStringAsFixed(0)}% save",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Consumer<ProductProvider>(
                            builder: (context, provider, _) {
                              final userId =
                                  context.read<AuthProvider>().userId;
                              if (userId == null) return const SizedBox();

                              provider.products.firstWhere(
                                (p) => p.productId == product.productId,
                                orElse: () =>
                                    provider.categoryProducts.firstWhere(
                                  (p) => p.productId == product.productId,
                                  orElse: () => product,
                                ),
                              );

                              final isLiked = provider.likedProductIds
                                  .contains(product.productId);

                              return _AnimatedLikeButton(
                                isLiked: isLiked,
                                onTap: () {
                                  provider.toggleLike(
                                    productId: product.productId,
                                    userId: userId,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// TEXT SECTION — untouched
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        "₦${formatter.format(finalPrice)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xff9D6E2D),
                        ),
                      ),
                      if (product.discount != null &&
                          product.discount! > 0) ...[
                        const SizedBox(width: 2),
                        Text(
                          "₦${formatter.format(price)}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;

  const _AnimatedLikeButton({required this.isLiked, required this.onTap});

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: () {
          _controller.forward(from: 0);
          widget.onTap();
        },
        customBorder: const CircleBorder(),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white24,
          ),
          padding: const EdgeInsets.all(4),
          child: Icon(
            widget.isLiked ? Icons.favorite : Icons.favorite_outline,
            size: 13,
            color: widget.isLiked ? Colors.red : Colors.black,
          ),
        ),
      ),
    );
  }
}
