import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/screens/addaddress.dart';
import 'package:peereess/screens/pickup.dart';
import 'package:peereess/model/peereess.dart';

class OrderPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;
  final String deliveryAddress;
  final String? receiverFullName;
  final String deliveryPhoneNumber;
  final double? deliveryFee;
  final int? deliveryDays;
  final bool deliveryIncludedInCart;

  const OrderPage({
    super.key,
    required this.cartItems,
    required this.totalPrice,
    required this.deliveryFee,
    required this.deliveryPhoneNumber,
    this.receiverFullName,
    required this.deliveryAddress,
    this.deliveryDays,
    this.deliveryIncludedInCart = false,
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late String _deliveryAddress;
  late String _deliveryPhone;
  Peereess? selectedPickup;

  // null = nothing chosen yet, true = pickup, false = home delivery
  bool? _usePickup;

  final formatter = NumberFormat("#,##0", "en_US");

  // ── Derived helpers ───────────────────────────────────────────────────────
  bool get isPickupSelected => _usePickup == true && selectedPickup != null;
  bool get isHomeDeliverySelected => _usePickup == false;

  double get currentFee {
    if (widget.deliveryIncludedInCart && !isPickupSelected) return 0;
    if (isPickupSelected && selectedPickup != null) {
      return selectedPickup!.fee.toDouble();
    }
    return widget.deliveryFee ?? 0;
  }

  String get selectedDelivery {
    if (isPickupSelected) return 'Pickup station';
    return 'Home delivery';
  }

  @override
  void initState() {
    super.initState();
    _deliveryAddress = widget.deliveryAddress;
    _deliveryPhone = widget.deliveryPhoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    final double itemTotal = widget.totalPrice;
    final double total =
        widget.deliveryIncludedInCart ? itemTotal : itemTotal + currentFee;

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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ─────────────────────────────────────────
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
                        'Check Out',
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: 'poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  20.getHeightWhiteSpacing,

                  // ── Order summary ───────────────────────────────────
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
                            'ORDER SUMMARY',
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
                                '${widget.cartItems.length}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          if (currentFee > 0) ...[
                            const Divider(),
                            Row(
                              children: [
                                const Text(
                                  'Delivery fee',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                Text(
                                  widget.deliveryIncludedInCart
                                      ? '₦0'
                                      : '₦${formatter.format(currentFee)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                          const Divider(),
                          Row(
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontSize: 14),
                              ),
                              const Spacer(),
                              Text(
                                '₦${formatter.format(total)}',
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

                  10.getHeightWhiteSpacing,

                  // ── Delivery address ────────────────────────────────
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
                          Row(
                            children: [
                              const Text(
                                'DELIVERY ADDRESS',
                                style: TextStyle(fontSize: 14),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddAddress(),
                                    ),
                                  );

                                  if (result != null) {
                                    setState(() {
                                      // ✅ Update local state variables
                                      _deliveryAddress = result['address'];
                                      _deliveryPhone = result['phone'];
                                    });
                                  }
                                },
                                child: const Icon(
                                  IconsaxPlusLinear.edit,
                                  size: 18,
                                  color: Color(0xffB0864C),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          // ✅ Use state variables, NOT widget props
                          Text(
                            _deliveryAddress,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            _deliveryPhone,
                            style: const TextStyle(fontSize: 14),
                          ),

                          // Home-delivery radio — only visible once a
                          // pickup station has been selected so the user
                          // can switch back to home delivery.
                          if (selectedPickup != null) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(() => _usePickup = false),
                              child: Row(
                                children: [
                                  _RadioDot(selected: isHomeDeliverySelected),
                                  5.getWidthWhiteSpacing,
                                  const Text(
                                    'Deliver to this address',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  10.getHeightWhiteSpacing,

                  // ── Pick-up station ─────────────────────────────────
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
                          Row(
                            children: [
                              const Text(
                                'PICK-UP STATION',
                                style: TextStyle(fontSize: 14),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Pickup(),
                                    ),
                                  );
                                  if (result != null && result is Peereess) {
                                    setState(() {
                                      selectedPickup = result;
                                      // Auto-select pickup when one is chosen
                                      _usePickup = true;
                                    });
                                  }
                                },
                                child: const Icon(
                                  IconsaxPlusLinear.edit,
                                  size: 18,
                                  color: Color(0xffB0864C),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (selectedPickup != null)
                            // Pickup radio — tap to switch to pickup
                            GestureDetector(
                              onTap: () => setState(() => _usePickup = true),
                              child: Row(
                                children: [
                                  _RadioDot(selected: isPickupSelected),
                                  5.getWidthWhiteSpacing,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedPickup!.pickupstation,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        selectedPickup!.address,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            const Text(
                              'No pickup station selected',
                              style: TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                  ),

                  10.getHeightWhiteSpacing,

                  // ── Delivery items ──────────────────────────────────
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
                            'DELIVERY ITEMS',
                            style: TextStyle(fontSize: 14),
                          ),
                          const Divider(),
                          5.getHeightWhiteSpacing,
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.cartItems.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = widget.cartItems[index];
                              return Row(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: item['image'],
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 50,
                                      width: 50,
                                      color: Colors.grey[200],
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      height: 50,
                                      width: 50,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  10.getWidthWhiteSpacing,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        'Variant: ${item['variant']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (item['color'] != null &&
                                          item['color']
                                              .toString()
                                              .trim()
                                              .isNotEmpty)
                                        Text(
                                          'Color: ${item['color']}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      Text(
                                        'Quantity: ${item['quantity']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        '₦${formatter.format(item['price'])}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  10.getHeightWhiteSpacing,
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Bottom bar ──────────────────────────────────────────────────
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppButtons(
              onPressed: () {
                // ✅ Validate using updated state variables
                if (!isPickupSelected &&
                    (_deliveryAddress.isEmpty || _deliveryPhone.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select a pickup or provide a delivery address',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pushNamed(
                  context,
                  '/selectPayment',
                  arguments: {
                    'cartItems': widget.cartItems.map((item) {
                      return {
                        'productId': item['productId'],
                        'cartId': item['cartId'],
                        'title': item['title'],
                        'description': item['description'],
                        'image': item['image'],
                        'variant': item['variant'],
                        'color': item['color'],
                        'quantity': item['quantity'],
                        'price': item['price'],
                        'discount': item['discount'] ?? 0,
                        'selectedVariantIndex':
                            item['selectedVariantIndex'] ?? 0,
                      };
                    }).toList(),
                    'totalPrice': total,
                    'deliveryFee': currentFee,
                    // ✅ Pass updated state variables, NOT widget props
                    'deliveryAddress': _deliveryAddress,
                    'deliveryPhoneNumber': _deliveryPhone,
                    'deliveryDays': widget.deliveryDays,
                    'receiverFullName': widget.receiverFullName,
                    'selectedPickup': selectedPickup,
                    'deliveryIncludedInCart': true,
                    'selectedDelivery': selectedDelivery,
                  },
                );
              },
              text: 'Proceed to Payment',
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable radio dot widget ─────────────────────────────────────────────────
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
