import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/app_color.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/cart_provider.dart';
import 'package:peereess/screens/addaddress.dart';
import 'package:peereess/screens/orderpage.dart';
import 'package:provider/provider.dart';

class AddtocartWidget extends StatefulWidget {
  final ProductModel product;
  final bool isOrderNow;
  final BuildContext? parentContext;

  const AddtocartWidget({
    super.key,
    required this.product,
    this.isOrderNow = false,
    this.parentContext,
  });

  @override
  State<AddtocartWidget> createState() => _AddtocartWidgetState();
}

class _AddtocartWidgetState extends State<AddtocartWidget>
    with TickerProviderStateMixin {
  String? activeColor;
  late Map<String, List<int>> colorQuantities;
  final formatter = NumberFormat("#,##0", "en_US");

  final GlobalKey _cartSummaryKey = GlobalKey();
  late List<GlobalKey> _plusButtonKeys;
  OverlayEntry? _flyOverlay;
  final GlobalKey _addButtonKey = GlobalKey();

  bool get isColorSelected {
    if (widget.product.colors.isNotEmpty && activeColor == null) return false;
    return true;
  }

  bool get hasValidColors {
    return widget.product.colors.any((c) => c != null && c.trim().isNotEmpty);
  }

  // ── Delivery fee: +50% when 3+ items in cart ──────────────────────────────
  double get effectiveDeliveryFee {
    final int baseFee = widget.product.deliveryFee ?? 0;
    if (totalItems >= 3) {
      return baseFee + (baseFee * 0.5);
    }
    return baseFee.toDouble();
  }

  @override
  void initState() {
    super.initState();
    colorQuantities = {};

    _plusButtonKeys = List.generate(
      widget.product.variants.length,
      (_) => GlobalKey(),
    );

    if (!hasValidColors) {
      activeColor = 'default';
      colorQuantities[activeColor!] = List.filled(
        widget.product.variants.length,
        0,
      );
    }
  }

  @override
  void dispose() {
    _flyOverlay?.remove();
    _flyOverlay = null;
    super.dispose();
  }

  void _runFlyAnimation({required GlobalKey fromKey}) {
    final fromBox = fromKey.currentContext?.findRenderObject() as RenderBox?;
    if (fromBox == null) return;
    final fromPos = fromBox.localToGlobal(Offset.zero);
    final startOffset = Offset(
      fromPos.dx + fromBox.size.width / 2,
      fromPos.dy + fromBox.size.height / 2,
    );

    Offset endOffset;
    if (_cartSummaryKey.currentContext != null) {
      final cartBox =
          _cartSummaryKey.currentContext!.findRenderObject() as RenderBox;
      final cartPos = cartBox.localToGlobal(Offset.zero);
      endOffset = Offset(
        cartPos.dx + cartBox.size.width / 2,
        cartPos.dy + cartBox.size.height / 2,
      );
    } else {
      final screenSize = MediaQuery.of(context).size;
      endOffset = Offset(screenSize.width / 2, screenSize.height * 0.5);
    }

    final animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final overlay = Overlay.of(context);

    _flyOverlay?.remove();
    _flyOverlay = OverlayEntry(
      builder: (ctx) {
        return AnimatedBuilder(
          animation: animController,
          builder: (ctx, _) {
            final t = animController.value;
            final ease = t < 0.5
                ? 4 * t * t * t
                : 1 - ((-2 * t + 2) * (-2 * t + 2) * (-2 * t + 2)) / 2;
            final arc = -80.0 * (1 - (2 * ease - 1) * (2 * ease - 1));
            final x = startOffset.dx + (endOffset.dx - startOffset.dx) * ease;
            final y =
                startOffset.dy + (endOffset.dy - startOffset.dy) * ease + arc;
            final scale = 1.0 - t * 0.5;
            final opacity = t > 0.8 ? (1.0 - t) * 5.0 : 1.0;

            return Positioned(
              left: x - 8,
              top: y - 8,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xff9D6E2D),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(_flyOverlay!);

    animController.forward().then((_) {
      _flyOverlay?.remove();
      _flyOverlay = null;
      animController.dispose();
    });
  }

  Offset _getAddButtonCenter() {
    final box = _addButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    final pos = box.localToGlobal(Offset.zero);
    return Offset(pos.dx + box.size.width / 2, pos.dy + box.size.height / 2);
  }

  double variantFinalPrice(Map<String, dynamic> variant) {
    final price = (variant['price'] ?? 0).toDouble();
    final discount = (variant['discount'] ?? widget.product.discount ?? 0);
    if (discount <= 0) return price;
    return price - (price * (discount / 100));
  }

  int getVariantStock(int variantIndex) {
    if (variantIndex >= widget.product.variants.length) return 0;
    final variant = widget.product.variants[variantIndex];
    final stock = variant['stock'] ?? 0;
    return (stock is int) ? stock : int.tryParse(stock.toString()) ?? 0;
  }

  int get totalItems {
    int total = 0;
    colorQuantities.forEach((_, list) {
      total += list.fold<int>(0, (a, b) => a + b);
    });
    return total;
  }

  double get totalPrice {
    double total = 0;
    colorQuantities.forEach((color, list) {
      for (int i = 0; i < list.length; i++) {
        total += list[i] * variantFinalPrice(widget.product.variants[i]);
      }
    });
    return total;
  }

  void ensureActiveColorInitialized() {
    if (activeColor != null && colorQuantities[activeColor!] == null) {
      colorQuantities[activeColor!] = List.filled(
        widget.product.variants.length,
        0,
      );
    }
  }

  void showTopBanner(String message) {
    final messengerContext = widget.parentContext ?? context;
    final messenger = ScaffoldMessenger.maybeOf(messengerContext);
    if (messenger == null) return;

    messenger.hideCurrentMaterialBanner();

    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text("DISMISS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      messenger.hideCurrentMaterialBanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final product = widget.product;

    ensureActiveColorInitialized();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delivery address row
        Row(
          children: [
            const Icon(IconsaxPlusLinear.truck_fast, size: 16),
            5.getWidthWhiteSpacing,
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final address = auth.currentUserData?.deliveryAddress;
                  return Text(
                    (address == null || address.isEmpty)
                        ? "Enter delivery information to add to cart and order"
                        : address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            10.getWidthWhiteSpacing,
            IconButton(
              onPressed: () => Navigator.pushNamed(context, "/addaddress"),
              icon: Icon(IconsaxPlusLinear.edit, size: 15),
            ),
          ],
        ),
        25.getHeightWhiteSpacing,

        // Product image + title
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 60,
                width: 60,
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl.first,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(color: Colors.grey.shade200),
              ),
            ),
            15.getWidthWhiteSpacing,
            Expanded(
              child: Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        // Color selection
        if (product.colors
            .where((c) => c != null && c.trim().isNotEmpty)
            .isNotEmpty) ...[
          15.getHeightWhiteSpacing,
          const Text(
            "Colors",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Wrap(
            spacing: 8,
            children: product.colors
                .where((color) => color != null && color.trim().isNotEmpty)
                .map((color) {
              final isSelected = activeColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    activeColor = isSelected ? null : color;
                    ensureActiveColorInitialized();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xffB0864C)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey,
                    ),
                  ),
                  child: Text(
                    color,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // Variants
        if (product.variants.isNotEmpty) ...[
          15.getHeightWhiteSpacing,
          Column(
            children: List.generate(product.variants.length, (index) {
              final variant = product.variants[index];
              final qty = activeColor != null
                  ? colorQuantities[activeColor!]![index]
                  : 0;

              final variantStock = getVariantStock(index);
              final isOutOfStock = variantStock <= 0;
              final canAddMore = !isOutOfStock && qty < variantStock;

              return Opacity(
                opacity: isOutOfStock ? 0.5 : 1.0,
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  variant['description'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (isOutOfStock) ...[
                                  5.getWidthWhiteSpacing,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "OUT OF STOCK",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else if (variantStock <= 5) ...[
                                  5.getWidthWhiteSpacing,
                                  Text(
                                    "($variantStock left)",
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  "₦${formatter.format(variantFinalPrice(variant))}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if ((variant['discount'] ??
                                        product.discount ??
                                        0) >
                                    0)
                                  Text(
                                    " ₦${formatter.format(variant['price'])}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isOutOfStock
                                  ? null
                                  : () {
                                      if (hasValidColors &&
                                          activeColor == null) {
                                        showTopBanner("Please select a color");
                                        return;
                                      }
                                      setState(() {
                                        final currentQty = colorQuantities[
                                            activeColor!]![index];
                                        if (currentQty > 0) {
                                          colorQuantities[activeColor!]![
                                              index] = currentQty - 1;
                                        }
                                      });
                                    },
                              child: Icon(
                                Icons.remove,
                                size: 15,
                                color:
                                    isOutOfStock ? Colors.grey : Colors.black,
                              ),
                            ),
                            10.getWidthWhiteSpacing,
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Text(
                                qty.toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            10.getWidthWhiteSpacing,
                            GestureDetector(
                              key: _plusButtonKeys[index],
                              onTap: (!canAddMore || isOutOfStock)
                                  ? null
                                  : () {
                                      if (product.colors.isNotEmpty &&
                                          activeColor == null) {
                                        showTopBanner("Please select a color");
                                        return;
                                      }
                                      if (qty >= variantStock) {
                                        showTopBanner(
                                          "Only $variantStock items available in stock",
                                        );
                                        return;
                                      }
                                      setState(() {
                                        colorQuantities[activeColor!]![index]++;
                                      });
                                      _runFlyAnimation(
                                        fromKey: _plusButtonKeys[index],
                                      );
                                    },
                              child: Icon(
                                Icons.add,
                                size: 15,
                                color: (!canAddMore || isOutOfStock)
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],

        15.getHeightWhiteSpacing,
        const Divider(),
        15.getHeightWhiteSpacing,

        // Summary row
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  key: _cartSummaryKey,
                  IconsaxPlusLinear.shopping_cart,
                  size: 22,
                  color: const Color(0xff9D6E2D),
                ),
                if (totalItems > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xffE24B4A),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        totalItems > 99 ? "99+" : "$totalItems",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              " selected",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            10.getWidthWhiteSpacing,
            const Spacer(),
            if (totalPrice > 0) ...[
              Text(
                "Amount:",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                " ₦${formatter.format(totalPrice)}",
                style: const TextStyle(
                  color: Color(0xff9D6E2D),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        5.getHeightWhiteSpacing,

        // ── Shipping fee row (reads totalItems directly, no provider) ────────
        if (totalItems > 0) ...[
          Row(
            children: [
              const Text(
                "shipping fee:",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              5.getWidthWhiteSpacing,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    effectiveDeliveryFee == 0
                        ? "Free Shipping"
                        : "₦${formatter.format(effectiveDeliveryFee)}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: effectiveDeliveryFee == 0
                          ? Colors.green
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                "Total: ",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                "₦${formatter.format(totalPrice + effectiveDeliveryFee)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],

        10.getHeightWhiteSpacing,

        AppButtons3(
          key: _addButtonKey,
          text: widget.isOrderNow ? "Order now" : "Add to Cart",
          onPressed: () async {
            // 1. Check delivery address
            final deliveryAddress = auth.currentUserData?.deliveryAddress;
            if (deliveryAddress == null || deliveryAddress.isEmpty) {
              showTopBanner("Please set your delivery address");
              return;
            }

            // 2. Require color if product has colors
            if (hasValidColors && activeColor == null) {
              showTopBanner("Please select a color");
              return;
            }

            // 3. At least one item
            if (totalItems == 0) {
              showTopBanner("Please add at least one item");
              return;
            }

            final userId = auth.currentUserData?.userId;
            if (userId == null) return;

            final deliveryPhoneNumber =
                auth.currentUserData?.deliveryPhoneNumber ?? "No phone number";
            final receiverFullName =
                auth.currentUserData?.receiverFullName ?? "No receiver name";

            // ── Use effectiveDeliveryFee (already includes 50% if 3+ items) ──
            final double? currentDeliveryFee =
                (product.deliveryFee != null && product.deliveryFee! > 0)
                    ? effectiveDeliveryFee
                    : null;

            // 4. Collect selected variants
            final List<Map<String, dynamic>> selectedVariants = [];

            colorQuantities.forEach((color, qtyList) {
              if (qtyList == null) return;
              for (int i = 0; i < qtyList.length; i++) {
                final qty = qtyList[i] ?? 0;
                if (qty <= 0) continue;

                final variantStock = getVariantStock(i);
                if (qty > variantStock) {
                  showTopBanner(
                    "Only $variantStock items available for ${widget.product.variants[i]['description']}",
                  );
                  return;
                }

                final variant = Map<String, dynamic>.from(
                  widget.product.variants[i],
                );
                variant['discount'] = widget.product.variants[i]['discount'] ??
                    widget.product.discount ??
                    0;
                variant['quantity'] = qty;
                variant['color'] = hasValidColors ? color : '';
                selectedVariants.add(variant);
              }
            });

            // 5. Final validation
            if (selectedVariants.isEmpty) {
              showTopBanner("Please add at least one item");
              return;
            }

            // 6. Handle based on isOrderNow flag
            if (widget.isOrderNow) {
              Navigator.pop(context);

              Future.microtask(() {
                final List<Map<String, dynamic>> cartItemsForOrder = [];

                colorQuantities.forEach((color, qtyList) {
                  if (qtyList == null) return;
                  for (int variantIndex = 0;
                      variantIndex < qtyList.length;
                      variantIndex++) {
                    final qty = qtyList[variantIndex] ?? 0;
                    if (qty <= 0) continue;

                    final variant = widget.product.variants[variantIndex];
                    cartItemsForOrder.add({
                      'productId': product.productId,
                      'title': product.title,
                      'cartId':
                          'order_now_${DateTime.now().millisecondsSinceEpoch}_${cartItemsForOrder.length}',
                      'description': variant['description'] ?? '',
                      'image': product.imageUrl.isNotEmpty
                          ? product.imageUrl.first
                          : '',
                      'variant': variant['description'] ?? '',
                      'color': hasValidColors ? color : '',
                      'quantity': qty,
                      'price': variantFinalPrice(variant),
                      'discount': variant['discount'] ?? product.discount ?? 0,
                      'selectedVariantIndex': variantIndex,
                    });
                  }
                });

                print("📦 Order Now - Cart Items:");
                for (var item in cartItemsForOrder) {
                  print(
                    "  - ${item['title']}: Qty=${item['quantity']}, Index=${item['selectedVariantIndex']}",
                  );
                }

                Navigator.of(widget.parentContext ?? context).pushNamed(
                  "/orderPage",
                  arguments: {
                    "cartItems": cartItemsForOrder,
                    "totalPrice": totalPrice,
                    "deliveryAddress": deliveryAddress,
                    "deliveryPhoneNumber": deliveryPhoneNumber,
                    "deliveryFee": currentDeliveryFee, // ← surcharge included
                    "deliveryDays": product.deliveryDays,
                    "receiverFullName": receiverFullName,
                  },
                );
              });
            } else {
              await context.read<CartProvider>().addToCart(
                    userId: userId,
                    productId: product.productId,
                    discount: product.discount,
                    title: product.title,
                    description: product.description,
                    imageUrl: product.imageUrl,
                    variants: selectedVariants,
                    deliveryAddress: deliveryAddress,
                    deliveryPhoneNumber: deliveryPhoneNumber,
                    deliveryFee: currentDeliveryFee, // ← surcharge included
                    deliveryDays: product.deliveryDays,
                    receiverFullName: receiverFullName,
                  );

              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
