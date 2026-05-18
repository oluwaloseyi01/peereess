import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/auth_provider.dart';

import 'package:peereess/screens/chatscreen.dart';

import 'package:peereess/screens/widgets/addtocart_widget.dart';
import 'package:peereess/screens/widgets/authcheck.dart';
import 'package:peereess/screens/widgets/deliveryday.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/screens/widgets/product_collectionwidget.dart';
import 'package:peereess/screens/widgets/productdeliverywidget.dart';
import 'package:peereess/screens/widgets/productimageslide.dart';
import 'package:peereess/screens/widgets/productquantitywidget.dart';
import 'package:peereess/screens/widgets/productreviews.dart';
import 'package:peereess/screens/widgets/starrating.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/product_provider.dart';

class ProductDetails extends StatefulWidget {
  final ProductModel product;
  const ProductDetails({super.key, required this.product});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  int currentIndex = 0;
  List<ProductModel> filteredProducts = [];
  final formatter = NumberFormat("#,##0", "en_US");

  double get basePrice => widget.product.price;

  double get finalPrice {
    final discount = widget.product.discount ?? 0;
    if (discount == 0) return basePrice;
    return basePrice - (basePrice * (discount / 100));
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      filteredProducts = provider.products
          .where(
            (p) =>
                p.category == widget.product.category &&
                p.productId != widget.product.productId,
          )
          .toList();
      setState(() {});
    });
  }

  /// Shows a login prompt bottom sheet when a guest taps a protected action
  void _showLoginPrompt() {
    AuthPromptSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;

    if (!authProvider.isConnected) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(child: LogoLoadingIndicator()),
      );
    }

    final product = widget.product;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImageSlider(product: product),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        5.getHeightWhiteSpacing,
                        Row(
                          children: [
                            if (product.refundable == "refundable" ||
                                product.refundable == "nonrefundable")
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xff9D6E2D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        product.refundable,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                  10.getWidthWhiteSpacing,
                                ],
                              ),
                            if ((product.discount ?? 0) > 0)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    "-${product.discount!.toStringAsFixed(0)}% save",
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        10.getHeightWhiteSpacing,

                        // TITLE
                        Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontFamily: 'poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        // PRICE
                        Row(
                          children: [
                            Text(
                              "₦${formatter.format(finalPrice)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color(0xff9D6E2D),
                              ),
                            ),
                            if ((product.discount ?? 0) > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                "₦${formatter.format(basePrice)}",
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),

                        if (product.rating != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: StarRating(
                              rating: product.rating!,
                              starSize: 14,
                            ),
                          ),

                        if (product.colors
                            .any((c) => c != null && c.trim().isNotEmpty)) ...[
                          5.getHeightWhiteSpacing,
                          Wrap(
                            spacing: 8,
                            children: product.colors
                                .where((color) =>
                                    color != null && color.trim().isNotEmpty)
                                .map((color) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      const Color.fromARGB(255, 233, 226, 226),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Text(
                                  color,
                                  style: const TextStyle(
                                    color: Color(0xff9D6E2D),
                                    fontFamily: 'poppins',
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        10.getHeightWhiteSpacing,

                        // DESCRIPTION
                        const Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          product.description,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),

                        DeliveryDayWidget(deliveryDays: product.deliveryDays),
                        10.getHeightWhiteSpacing,
                      ],
                    ),
                  ),
                  DeliveryInfoWidget(product: product),
                  20.getHeightWhiteSpacing,
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Recommended for you",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredProducts.length,
                      padding: const EdgeInsets.only(top: 10),
                      itemBuilder: (context, index) {
                        final p = filteredProducts[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ProductCollectionwidget2(product: p),
                        );
                      },
                    ),
                  ),
                  20.getHeightWhiteSpacing,
                  CustomerReviewsWidget(product: widget.product),
                ],
              ),
              100.getHeightWhiteSpacing,
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── MESSAGE BUTTON ─────────────────────────────
                GestureDetector(
                  onTap: () {
                    if (!isLoggedIn) {
                      _showLoginPrompt();
                      return;
                    }
                    final currentUserId = context.read<AuthProvider>().userId;
                    if (currentUserId == null) return;

                    Navigator.pushNamed(
                      context,
                      "/chat",
                      arguments: {
                        "productId": product.productId,
                        "userId": currentUserId,
                        "imageUrl": product.imageUrl.isNotEmpty
                            ? product.imageUrl[0]
                            : null,
                        "firstVariantPrice": finalPrice,
                        "productTitle": product.title,
                      },
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        IconsaxPlusLinear.message,
                        size: 22,
                        // ✅ Dim icon for guests
                        color: isLoggedIn ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                5.getWidthWhiteSpacing,

                // ── ADD TO CART ────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!isLoggedIn) {
                        _showLoginPrompt();
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        builder: (context) {
                          return SafeArea(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 16,
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom +
                                        16,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AddtocartWidget(
                                      product: product,
                                      parentContext: context,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isLoggedIn
                              ? const Color(0xff9D6E2D)
                              : Colors.grey,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        child: Text(
                          "Add cart",
                          style: TextStyle(
                            fontSize: 12,
                            color: isLoggedIn
                                ? const Color(0xff9D6E2D)
                                : Colors.grey,
                            fontFamily: "poppins",
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                5.getWidthWhiteSpacing,

                // ── ORDER NOW ──────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!isLoggedIn) {
                        _showLoginPrompt();
                        return;
                      }
                      final screenContext = context;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        builder: (context) {
                          return SafeArea(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 16,
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom +
                                        16,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AddtocartWidget(
                                      product: product,
                                      isOrderNow: true,
                                      parentContext: screenContext,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isLoggedIn
                            ? const Color(0xff9D6E2D)
                            : Colors.grey.shade400,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        child: Text(
                          "Order now",
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: "poppins",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


//required