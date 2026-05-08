import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/provider/productview.dart';

import 'package:peereess/screens/widgets/starrating.dart';
import 'package:provider/provider.dart';

/// =====================
/// PRODUCT COLLECTION 1
/// =====================
class ProductCollectionwidget extends StatelessWidget {
  final ProductModel product;

  const ProductCollectionwidget({super.key, required this.product});

  double get basePrice {
    if (product.variants.isEmpty) return 0;
    return (product.variants.first['price'] ?? 0).toDouble();
  }

  double get finalPrice {
    final discount = product.discount;
    if (discount <= 0) return basePrice;
    return basePrice - (basePrice * (discount / 100));
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0", "en_US");

    return GestureDetector(
      onTap: () {
        // ✅ Fire-and-forget — does not delay navigation
        final userId = context.read<AuthProvider>().userId;
        if (userId != null) {
          context.read<UserProductViewProvider>().trackProductView(
                userId: userId,
                productId: product.productId,
              );
        }

        Navigator.pushNamed(
          context,
          "/productDetails",
          arguments: {"product": product},
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
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(color: Colors.grey[200]),
                    Positioned(
                      top: 4,
                      left: 4,
                      right: 4,
                      child: Row(
                        children: [
                          if (product.discount != null && product.discount > 0)
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

                              final currentProduct =
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

                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: isLiked ? 0.8 : 1.0,
                                  end: isLiked ? 1.2 : 1.0,
                                ),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.elasticOut,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: InkWell(
                                      onTap: () {
                                        provider.toggleLike(
                                          productId: currentProduct.productId,
                                          userId: userId,
                                        );
                                      },
                                      customBorder: const CircleBorder(),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white24,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_outline,
                                          size: 13,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
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

            /// TEXT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
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
                          "₦${formatter.format(basePrice)}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.rating != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: StarRating(rating: product.rating!, starSize: 14),
                    ),
                  5.getHeightWhiteSpacing,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================
/// PRODUCT COLLECTION 2
/// =====================
class ProductCollectionwidget2 extends StatelessWidget {
  final ProductModel product;

  const ProductCollectionwidget2({super.key, required this.product});

  double get basePrice {
    if (product.variants.isEmpty) return 0;
    return (product.variants.first['price'] ?? 0).toDouble();
  }

  double get finalPrice {
    final discount = product.discount ?? 0;
    if (discount <= 0) return basePrice;
    return basePrice - (basePrice * (discount / 100));
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0", "en_US");

    return GestureDetector(
      onTap: () {
        // ✅ Fire-and-forget — does not delay navigation
        final userId = context.read<AuthProvider>().userId;
        if (userId != null) {
          context.read<UserProductViewProvider>().trackProductView(
                userId: userId,
                productId: product.productId,
              );
        }

        Navigator.pushNamed(
          context,
          "/productDetails",
          arguments: {"product": product},
        );
      },
      child: Container(
        width: 150,
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
                height: 130,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(color: Colors.grey[200]),
                    Positioned(
                      top: 4,
                      left: 4,
                      right: 4,
                      child: Row(
                        children: [
                          if (product.discount != null && product.discount > 0)
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

                              final currentProduct =
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

                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: isLiked ? 0.8 : 1.0,
                                  end: isLiked ? 1.2 : 1.0,
                                ),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.elasticOut,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: InkWell(
                                      onTap: () {
                                        provider.toggleLike(
                                          productId: currentProduct.productId,
                                          userId: userId,
                                        );
                                      },
                                      customBorder: const CircleBorder(),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white24,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_outline,
                                          size: 13,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
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

            /// TEXT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        const SizedBox(width: 3),
                        Text(
                          "₦${formatter.format(basePrice)}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
