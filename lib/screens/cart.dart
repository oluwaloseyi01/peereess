import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/deliveryfee_provider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/screens/orderpage.dart';
import 'package:peereess/screens/product_details.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/screens/widgets/productquantitywidget.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/cart_provider.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/model/cartmodel.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final Set<String> selectedCartIds = {};

  bool get isSelectionMode => selectedCartIds.isNotEmpty;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  Future<void> _loadCart() async {
    final auth = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    final String? userId = auth.currentUserData?.userId;
    if (userId == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await cartProvider.fetchCartItems(userId);
    } catch (e) {
      debugPrint('⚠️ Cart fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final formatter = NumberFormat("#,##0", "en_US");

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.read<ProductProvider>();

    final bool hasUser = authProvider.currentUserData != null;
    if (!hasUser && !authProvider.isConnected) {
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
        child: const Center(child: LogoLoadingIndicator()),
      );
    }

    final cartItems = cartProvider.cartItems;

    final checkoutItems = selectedCartIds.isEmpty
        ? cartItems
        : cartItems
            .where((item) => selectedCartIds.contains(item.cartId))
            .toList();

    double subtotal = 0;
    double totalDiscount = 0;
    double totalDelivery = 0;
    bool hasSurcharge = false;

    for (var item in checkoutItems) {
      final double baseFee = (item.deliveryFee ?? 0).toDouble();
      subtotal += item.totalPrice - baseFee;
      totalDiscount += item.totalDiscount;

      final int itemQty = item.totalItems as int? ?? 0;
      if (itemQty >= 3) {
        totalDelivery += baseFee * 1.5;
        hasSurcharge = true;
      } else {
        totalDelivery += baseFee;
      }
    }

    final productVariantsMap = <String, List<dynamic>>{};
    for (var product in productProvider.products) {
      if (product.variants is List) {
        productVariantsMap[product.productId] =
            product.variants as List<dynamic>;
      }
    }

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
        child: SafeArea(
          child: Column(
            children: [
              // ── PINNED HEADER (never scrolls) ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Row(
                  children: [
                    10.getWidthWhiteSpacing,
                    Text(
                      selectedCartIds.isEmpty
                          ? "Cart Summary"
                          : "${selectedCartIds.length} selected",
                      style: const TextStyle(
                        fontSize: 17,
                        fontFamily: 'poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (selectedCartIds.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() => selectedCartIds.clear());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "Clear",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ),
                    10.getWidthWhiteSpacing,
                  ],
                ),
              ),

              // ── SCROLLABLE BODY (everything scrolls under the header) ──
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xff9D6E2D),
                  backgroundColor: const Color.fromARGB(255, 236, 216, 191),
                  onRefresh: _loadCart,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // ── SUBTOTAL CARD ──────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              5.getHeightWhiteSpacing,
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color:
                                      const Color.fromARGB(255, 233, 226, 226),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            "Subtotal",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          const Spacer(),
                                          Text(
                                            "₦${formatter.format(subtotal)}",
                                            style: const TextStyle(
                                              color: Color(0xffB0864C),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (totalDiscount > 0) ...[
                                        5.getHeightWhiteSpacing,
                                        Row(
                                          children: [
                                            const Text(
                                              "Discount",
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            const Spacer(),
                                            Text(
                                              "-₦${formatter.format(totalDiscount)}",
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (totalDelivery > 0) ...[
                                        5.getHeightWhiteSpacing,
                                        Row(
                                          children: [
                                            const Text(
                                              "Delivery fee",
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            const Spacer(),
                                            Text(
                                              "₦${formatter.format(totalDelivery)}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                        5.getHeightWhiteSpacing,
                                        const Divider(height: 1),
                                        5.getHeightWhiteSpacing,
                                        Row(
                                          children: [
                                            const Text(
                                              "Total",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              "₦${formatter.format(subtotal + totalDelivery)}",
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              5.getHeightWhiteSpacing,
                              if (cartItems.isNotEmpty)
                                Text(
                                  isSelectionMode
                                      ? "Selected (${selectedCartIds.length})"
                                      : "Cart (${cartItems.length})",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              5.getHeightWhiteSpacing,
                            ],
                          ),
                        ),
                      ),

                      // ── CART ITEMS ─────────────────────────────
                      if (_isLoading)
                        const SliverToBoxAdapter(
                          child: Center(child: LogoLoadingIndicator()),
                        )
                      else if (cartItems.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  IconsaxPlusLinear.shopping_cart,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Your cart is empty",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final CartModel item = cartItems[index];

                                final productVariants =
                                    productVariantsMap[item.productId] ?? [];

                                final stockInfo =
                                    cartProvider.getCartItemStockInfo(
                                  cartItem: item,
                                  productVariants: productVariants,
                                );

                                final isOutOfStock =
                                    stockInfo['isOutOfStock'] as bool;
                                final variantStock =
                                    stockInfo['variantStock'] as int;
                                final canAddMore =
                                    stockInfo['canAddMore'] as bool;
                                final currentQty =
                                    stockInfo['currentQty'] as int;

                                final product = productProvider.products
                                    .where((p) => p.productId == item.productId)
                                    .firstOrNull;

                                double basePrice = 0;
                                double discountedPrice = 0;
                                for (var v in item.variants) {
                                  final price = (v['price'] ?? 0).toDouble();
                                  final qty = (v['quantity'] ?? 0) as int;
                                  final discountPercent =
                                      (v['discount'] ?? item.discount ?? 0)
                                          .toDouble();
                                  basePrice += price * qty;
                                  discountedPrice +=
                                      price * qty * (1 - discountPercent / 100);
                                }

                                double discountAmount =
                                    basePrice - discountedPrice;
                                double mainDiscountPercent = item.discount;

                                return Opacity(
                                  opacity: isOutOfStock ? 0.5 : 1.0,
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: const Color.fromARGB(
                                          255, 233, 226, 226),
                                      border: selectedCartIds
                                              .contains(item.cartId)
                                          ? Border.all(
                                              color: const Color(0xff9D6E2D),
                                              width: 2,
                                            )
                                          : null,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Stack(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (selectedCartIds
                                                      .contains(item.cartId)) {
                                                    selectedCartIds
                                                        .remove(item.cartId);
                                                  } else {
                                                    selectedCartIds
                                                        .add(item.cartId);
                                                  }
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 8,
                                                  top: 4,
                                                ),
                                                child: _RadioDot(
                                                  selected: selectedCartIds
                                                      .contains(item.cartId),
                                                ),
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                InkWell(
                                                  onTap: isOutOfStock
                                                      ? null
                                                      : () {
                                                          if (product != null) {
                                                            Navigator.pushNamed(
                                                              context,
                                                              "/productDetails",
                                                              arguments: {
                                                                "product":
                                                                    product,
                                                              },
                                                            );
                                                          }
                                                        },
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: SizedBox(
                                                      height: 70,
                                                      width: 70,
                                                      child: item.imageUrl
                                                              .isNotEmpty
                                                          ? CachedNetworkImage(
                                                              imageUrl: item
                                                                  .imageUrl
                                                                  .first,
                                                              height: 70,
                                                              width: 70,
                                                              fit: BoxFit.cover,
                                                              placeholder:
                                                                  (context,
                                                                          url) =>
                                                                      Container(
                                                                color: Colors
                                                                    .grey
                                                                    .shade200,
                                                              ),
                                                              errorWidget: (
                                                                context,
                                                                url,
                                                                error,
                                                              ) =>
                                                                  Container(
                                                                color: Colors
                                                                    .grey
                                                                    .shade200,
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  size: 24,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                            )
                                                          : Container(
                                                              color: Colors.grey
                                                                  .shade200,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                                if (mainDiscountPercent > 0)
                                                  7.getHeightWhiteSpacing,
                                                if (mainDiscountPercent > 0)
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: Colors.yellow,
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 15,
                                                      vertical: 6,
                                                    ),
                                                    child: Text(
                                                      "-${mainDiscountPercent.toStringAsFixed(0)}% save",
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            15.getWidthWhiteSpacing,
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (productVariants
                                                      .isNotEmpty)
                                                    QuantityWidget(
                                                      quantity: productVariants,
                                                    ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "₦${formatter.format(discountedPrice)}",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                          color:
                                                              Color(0xff9D6E2D),
                                                        ),
                                                      ),
                                                      if (discountAmount >
                                                          0) ...[
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          "₦${formatter.format(basePrice)}",
                                                          style:
                                                              const TextStyle(
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            color: Colors.grey,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  if (item.variants.isNotEmpty)
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: item.variants
                                                          .map((v) {
                                                        return Text(
                                                          "${v['color'] ?? v['description'] ?? ''} x${v['quantity'] ?? 0} - ₦${formatter.format(v['price'])}",
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 10,
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  5.getHeightWhiteSpacing,
                                                  Row(
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          color: Colors.white,
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                          vertical: 3,
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: isOutOfStock
                                                                  ? null
                                                                  : () async {
                                                                      final auth =
                                                                          context
                                                                              .read<AuthProvider>();
                                                                      final String
                                                                          currentUserId =
                                                                          auth.currentUserData?.userId ??
                                                                              '';
                                                                      if (currentQty >
                                                                          1) {
                                                                        await cartProvider
                                                                            .updateCartItemQty(
                                                                          cartId:
                                                                              item.cartId,
                                                                          variantIndex:
                                                                              0,
                                                                          newQty:
                                                                              currentQty - 1,
                                                                        );
                                                                      } else {
                                                                        await cartProvider
                                                                            .deleteCartItem(
                                                                          item.cartId,
                                                                          currentUserId,
                                                                        );
                                                                      }
                                                                    },
                                                              child: Icon(
                                                                Icons.remove,
                                                                size: 15,
                                                                color: isOutOfStock
                                                                    ? Colors
                                                                        .grey
                                                                    : Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                            10.getWidthWhiteSpacing,
                                                            Text(
                                                              item.totalItems
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                            10.getWidthWhiteSpacing,
                                                            GestureDetector(
                                                              onTap: (!canAddMore ||
                                                                      isOutOfStock)
                                                                  ? null
                                                                  : () async {
                                                                      try {
                                                                        await cartProvider
                                                                            .updateCartItemQtyWithStockCheck(
                                                                          cartId:
                                                                              item.cartId,
                                                                          variantIndex:
                                                                              0,
                                                                          newQty:
                                                                              currentQty + 1,
                                                                          availableStock:
                                                                              variantStock,
                                                                        );
                                                                      } catch (e) {
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                            content:
                                                                                Text(
                                                                              e.toString().replaceAll('Exception: ', ''),
                                                                            ),
                                                                            duration:
                                                                                const Duration(seconds: 2),
                                                                            backgroundColor:
                                                                                Colors.red,
                                                                          ),
                                                                        );
                                                                      }
                                                                    },
                                                              child: Icon(
                                                                Icons.add,
                                                                size: 15,
                                                                color: (!canAddMore ||
                                                                        isOutOfStock)
                                                                    ? Colors
                                                                        .grey
                                                                    : Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      GestureDetector(
                                                        onTap: () async {
                                                          final auth =
                                                              context.read<
                                                                  AuthProvider>();
                                                          final String
                                                              currentUserId =
                                                              auth.currentUserData
                                                                      ?.userId ??
                                                                  '';
                                                          await cartProvider
                                                              .deleteCartItem(
                                                            item.cartId,
                                                            currentUserId,
                                                          );
                                                        },
                                                        child: const Icon(
                                                          IconsaxPlusLinear
                                                              .trash,
                                                          color: Colors.red,
                                                          size: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isOutOfStock)
                                          Positioned.fill(
                                            child: Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  "OUT OF STOCK",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: cartItems.length,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (subtotal + totalDelivery) == 0
          ? null
          : Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 8, right: 8),
                child: SafeArea(
                  child: AppButtons(
                    onPressed: () {
                      if (cartItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Your cart is empty")),
                        );
                        return;
                      }

                      final checkoutItems = selectedCartIds.isEmpty
                          ? cartItems
                          : cartItems
                              .where((item) =>
                                  selectedCartIds.contains(item.cartId))
                              .toList();

                      if (checkoutItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Select items to checkout"),
                          ),
                        );
                        return;
                      }

                      if (cartProvider.hasOutOfStockItems(
                        cartItems: checkoutItems,
                        productVariantsMap: productVariantsMap,
                      )) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Some items in your cart are out of stock. Please remove them before checkout.",
                            ),
                            duration: Duration(seconds: 3),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final auth = context.read<AuthProvider>();

                      Navigator.pushNamed(
                        context,
                        "/orderPage",
                        arguments: {
                          "cartItems": checkoutItems
                              .map(
                                (item) => item.variants
                                    .map(
                                      (v) => {
                                        'title': item.title,
                                        'cartId': item.cartId,
                                        'productId': item.productId,
                                        'image': item.imageUrl.isNotEmpty
                                            ? item.imageUrl.first
                                            : '',
                                        'variant': v['description'] ?? '',
                                        'quantity': v['quantity'] ?? 0,
                                        'color': v['color'] ?? '',
                                        'price': (v['price'] ?? 0).toDouble() -
                                            ((v['discount'] ??
                                                    item.discount ??
                                                    0) *
                                                (v['price'] ?? 0) /
                                                100),
                                      },
                                    )
                                    .toList(),
                              )
                              .expand((i) => i)
                              .toList(),
                          "totalPrice": subtotal,
                          "deliveryAddress":
                              auth.currentUserData?.deliveryAddress ??
                                  "No address provided",
                          "deliveryPhoneNumber":
                              auth.currentUserData?.deliveryPhoneNumber ??
                                  "No phone number",
                          "deliveryFee": totalDelivery,
                          "deliveryIncludedInCart": true,
                        },
                      );
                    },
                    text: totalDelivery > 0
                        ? "Checkout ₦${formatter.format(subtotal + totalDelivery)}"
                        : "Checkout ₦${formatter.format(subtotal)}",
                  ),
                ),
              ),
            ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 15,
      width: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey),
      ),
      child: selected
          ? const Padding(
              padding: EdgeInsets.all(2.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xff9D6E2D),
                ),
              ),
            )
          : null,
    );
  }
}
