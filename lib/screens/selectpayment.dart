import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/globalnavigation.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/peereess.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/cart_provider.dart';
import 'package:peereess/provider/notificationprovider.dart';
import 'package:peereess/provider/paystack.dart';
import 'package:peereess/provider/tabbar_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class Selectpayment extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;
  final double deliveryFee;
  final String deliveryAddress;
  final String deliveryPhoneNumber;
  final int? deliveryDays;
  final String? receiverFullName;
  final Peereess? selectedPickup;
  final bool deliveryIncludedInCart;
  final String selectedDelivery;

  const Selectpayment({
    super.key,
    required this.cartItems,
    required this.totalPrice,
    required this.deliveryFee,
    required this.deliveryAddress,
    required this.deliveryPhoneNumber,
    this.deliveryDays,
    this.receiverFullName,
    this.selectedPickup,
    this.deliveryIncludedInCart = false,
    required this.selectedDelivery,
  });

  @override
  State<Selectpayment> createState() => _SelectpaymentState();
}

class _SelectpaymentState extends State<Selectpayment> {
  bool isPickupSelected = false;
  String selectedPayment = '';
  final formatter = NumberFormat("#,##0", "en_US");

  bool _canPayOnDelivery = false;
  bool _checkingEligibility = true;
  bool _isProcessing = false;

  double get currentFee => isPickupSelected && widget.selectedPickup != null
      ? widget.selectedPickup!.fee.toDouble()
      : widget.deliveryFee;

  @override
  void initState() {
    super.initState();
    isPickupSelected = widget.selectedPickup != null &&
        widget.selectedDelivery == 'Pickup station';
    _checkPayOnDeliveryEligibility();
  }

  Future<void> _checkPayOnDeliveryEligibility() async {
    final userId = context.read<AuthProvider>().userId ?? '';
    final count = await context.read<TabbarProvider>().getCompletedOrderCount(
          userId,
        );
    if (mounted) {
      setState(() {
        _canPayOnDelivery = count >= 2;
        _checkingEligibility = false;
      });
    }
  }

  Widget buildPaymentOption(String paymentName, String description) {
    final bool isSelected = selectedPayment == paymentName;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = paymentName),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 217, 194, 162)
              : const Color.fromARGB(255, 233, 226, 226),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            Container(
              height: 15,
              width: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: isSelected
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
            ),
            10.getWidthWhiteSpacing,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paymentName, style: const TextStyle(fontSize: 14)),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double itemTotal = widget.totalPrice;
    final double total =
        widget.deliveryIncludedInCart ? itemTotal : itemTotal + currentFee;

    return Stack(
      children: [
        Scaffold(
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.arrow_back,
                                  size: 18,
                                  color: Color(0xff9D6E2D),
                                ),
                              ),
                            ),
                          ),
                          10.getWidthWhiteSpacing,
                          const Text(
                            "Select Payment Method",
                            style: TextStyle(
                              fontSize: 17,
                              fontFamily: 'poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      20.getHeightWhiteSpacing,

                      // ── Order Summary ───────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 233, 226, 226),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ORDER SUMMARY",
                                style: TextStyle(fontSize: 14),
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  const Text(
                                    "Item's total",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "${widget.cartItems.length}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  const Text(
                                    "Sub Total",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "₦${formatter.format(total)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      5.getHeightWhiteSpacing,

                      // ── Delivery Information ────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 233, 226, 226),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "DELIVERY INFORMATION",
                                style: TextStyle(fontSize: 14),
                              ),
                              const Divider(),
                              if (isPickupSelected &&
                                  widget.selectedPickup != null) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.store_outlined,
                                      size: 16,
                                      color: Color(0xff9D6E2D),
                                    ),
                                    8.getWidthWhiteSpacing,
                                    const Text(
                                      "Pick-up Station",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                4.getHeightWhiteSpacing,
                                Text(
                                  widget.selectedPickup!.pickupstation,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  widget.selectedPickup!.address,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ] else ...[
                                if (widget.receiverFullName != null &&
                                    widget.receiverFullName!.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        size: 16,
                                        color: Color(0xff9D6E2D),
                                      ),
                                      8.getWidthWhiteSpacing,
                                      Text(
                                        widget.receiverFullName!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  4.getHeightWhiteSpacing,
                                ],
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Color(0xff9D6E2D),
                                    ),
                                    8.getWidthWhiteSpacing,
                                    Expanded(
                                      child: Text(
                                        widget.deliveryAddress,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                4.getHeightWhiteSpacing,
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: Color(0xff9D6E2D),
                                    ),
                                    8.getWidthWhiteSpacing,
                                    Text(
                                      widget.deliveryPhoneNumber,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      5.getHeightWhiteSpacing,
                      const Text(
                        "Payment Method",
                        style: TextStyle(fontSize: 14),
                      ),
                      5.getHeightWhiteSpacing,

                      buildPaymentOption(
                        "Pay with Pay-stack",
                        "You will be redirected to our secure checkout page.",
                      ),
                      10.getHeightWhiteSpacing,

                      if (_checkingEligibility)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: LogoLoadingIndicator()),
                        )
                      else if (_canPayOnDelivery)
                        GestureDetector(
                          onTap: () => setState(
                              () => selectedPayment = "Pay on Delivery"),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: selectedPayment == "Pay on Delivery"
                                  ? const Color.fromARGB(255, 217, 194, 162)
                                  : const Color.fromARGB(255, 233, 226, 226),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 15,
                                    width: 15,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: selectedPayment == "Pay on Delivery"
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
                                  ),
                                  10.getWidthWhiteSpacing,
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "PAYMENT ON DELIVERY",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        Divider(),
                                        Text(
                                          "Go Cashless: Pay on Delivery Via Bank Transfer",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "You can pay via bank through Peeress at the time of delivery,",
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        Text(
                                          "simply inform our delivery agent with your order Details",
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "⚠ Only available for orders below ₦30,000",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Colors.grey.shade400,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "PAYMENT ON DELIVERY",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Complete 2 successful orders to unlock Pay on Delivery",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      10.getHeightWhiteSpacing,
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            color: Colors.white,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AppButtons(
                  text: "Confirm Payment Method",
                  onPressed: () async {
                    if (selectedPayment.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select a payment method"),
                        ),
                      );
                      return;
                    }

                    final auth = context.read<AuthProvider>();
                    final userId = auth.userId;
                    final userEmail = auth.currentUserData?.email ?? '';

                    if (userId == null || userId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please login again")),
                      );
                      return;
                    }

                    final double total = widget.deliveryIncludedInCart
                        ? widget.totalPrice
                        : widget.totalPrice + currentFee;

                    final List<Map<String, dynamic>> transformedCartItems =
                        widget.cartItems.map((item) {
                      int totalQuantity = 0;
                      if (item.containsKey('quantity') &&
                          item['quantity'] != null) {
                        totalQuantity = item['quantity'] as int;
                      } else {
                        final variants =
                            item['variants'] as List<dynamic>? ?? [];
                        totalQuantity = variants.fold<int>(0, (sum, v) {
                          final variantMap = v is String ? jsonDecode(v) : v;
                          return sum + ((variantMap['quantity'] ?? 0) as int);
                        });
                      }
                      final int selectedVariantIndex =
                          item['selectedVariantIndex'] ?? 0;
                      return {
                        'cartId': item['cartId'] ?? '',
                        'productId': item['productId'] ?? '',
                        'quantity': totalQuantity,
                        'selectedVariantIndex': selectedVariantIndex,
                      };
                    }).toList();

                    final List<String> cartIdsToDelete = widget.cartItems
                        .map((item) => (item['cartId'] ?? '').toString())
                        .where((id) => id.isNotEmpty)
                        .toList();

                    debugPrint(
                      "📦 Placing order with ${transformedCartItems.length} items",
                    );
                    for (var item in transformedCartItems) {
                      debugPrint(
                        "  - ProductID: ${item['productId']}, Qty: ${item['quantity']}, Index: ${item['selectedVariantIndex']}",
                      );
                    }
                    debugPrint("🗑️ Cart IDs to delete: $cartIdsToDelete");

                    Future<({String firstOrderId, List<String> allOrderIds})>
                        placeOrder({
                      required String paymentRef,
                      required String paymentMethod,
                    }) async {
                      try {
                        final result =
                            await AppwriteConfig.functions.createExecution(
                          functionId: AppwriteConfig.productFunction,
                          body: jsonEncode({
                            'action': 'placeOrderWithVariants',
                            'userId': userId,
                            'paymentMethod': paymentMethod,
                            'paymentRef': paymentRef,
                            'cartItems': transformedCartItems,
                            'totalPrice': widget.totalPrice,
                            'deliveryFee': currentFee,
                            'deliveryAddress': widget.deliveryAddress,
                            'deliveryPhoneNumber': widget.deliveryPhoneNumber,
                            'deliveryDays': widget.deliveryDays ?? 0,
                            'receiverFullName': widget.receiverFullName ?? '',
                            'selectedPickup': widget.selectedPickup != null
                                ? jsonEncode(widget.selectedPickup!.toMap())
                                : null,
                          }),
                        );

                        final data = jsonDecode(result.responseBody);
                        if (data['status'] != true) {
                          throw Exception(
                            data['message'] ?? 'Failed to place order.',
                          );
                        }

                        final String firstOrderId =
                            data['data']['orderId'] as String;
                        final List<String> allOrderIds =
                            (data['data']['orderIds'] as List<dynamic>? ??
                                    [firstOrderId])
                                .map((e) => e.toString())
                                .toList();

                        debugPrint(
                          "✅ ${allOrderIds.length} order(s) placed: $allOrderIds",
                        );

                        if (mounted && cartIdsToDelete.isNotEmpty) {
                          try {
                            final deleteResult =
                                await AppwriteConfig.functions.createExecution(
                              functionId: AppwriteConfig.productFunction,
                              body: jsonEncode({
                                'action': 'deleteOrderedCartItemss',
                                'userId': userId,
                                'cartIds': cartIdsToDelete,
                              }),
                            );
                            final deleteData =
                                jsonDecode(deleteResult.responseBody);
                            if (deleteData['status'] == true) {
                              await context
                                  .read<CartProvider>()
                                  .fetchCartItems(userId);
                            } else {
                              debugPrint(
                                "⚠️ Cart deletion failed: ${deleteData['message']}",
                              );
                            }
                          } catch (e) {
                            debugPrint("⚠️ Failed to delete cart items: $e");
                          }
                        }

                        return (
                          firstOrderId: firstOrderId,
                          allOrderIds: allOrderIds,
                        );
                      } catch (e) {
                        debugPrint("❌ placeOrder error: $e");
                        rethrow;
                      }
                    }

                    // ── Paystack ────────────────────────────────────────
                    if (selectedPayment == "Pay with Pay-stack") {
                      setState(() => _isProcessing = true);
                      try {
                        final paystackProvider =
                            context.read<PaystackWebProvider>();
                        await paystackProvider.startPaystackPaymentWeb(
                          context: context,
                          totalPrice: total,
                          orderId: const Uuid().v4(),
                          userData: {
                            "email": userEmail,
                            "fullName": widget.receiverFullName ?? "Customer",
                          },
                          saveOrder: ({
                            required String paymentRef,
                            required String paymentMethod,
                          }) async {
                            await placeOrder(
                              paymentRef: paymentRef,
                              paymentMethod: paymentMethod,
                            );
                          },
                        );
                      } finally {
                        if (mounted) setState(() => _isProcessing = false);
                      }
                    }

                    // ── Pay on Delivery ─────────────────────────────────
                    if (selectedPayment == "Pay on Delivery") {
                      if (total > 50000) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.orange.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            content: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Pay on Delivery is only available for orders below ₦50,000.",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        return;
                      }

                      if (!_canPayOnDelivery) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Complete 2 successful orders to unlock Pay on Delivery',
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() => _isProcessing = true);
                      try {
                        final result = await placeOrder(
                          paymentRef: const Uuid().v4(),
                          paymentMethod: "Pay on Delivery",
                        );

                        if (!context.mounted) return;

                        Navigator.pushReplacementNamed(
                          context,
                          '/paymentOnDeliverySuccess',
                          arguments: {
                            'orderId': result.firstOrderId,
                            'orderIds': result.allOrderIds,
                          },
                        );
                      } catch (e) {
                        debugPrint("❌ PAY ON DELIVERY ERROR: $e");
                        if (!context.mounted) return;

                        String errorMessage = "Error placing order";
                        if (e.toString().contains('Exception:')) {
                          errorMessage =
                              e.toString().replaceAll('Exception:', '').trim();
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isProcessing = false);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ),

        // ── Full-page loading overlay ─────────────────────────────────
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: LogoLoadingIndicator(),
            ),
          ),
      ],
    );
  }
}
