import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/addaddress.dart';
import 'package:provider/provider.dart';

class DeliveryInfoWidget extends StatelessWidget {
  final dynamic
      product; // Replace 'dynamic' with your ProductModel if available

  const DeliveryInfoWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final shippedFrom = product.shippedFrom?.toString() ?? "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 233, 226, 226),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Shipped From - only show if not Nigeria
          if (shippedFrom.isNotEmpty && shippedFrom.toLowerCase() != "nigeria")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    IconsaxPlusLinear.truck,
                    size: 16,
                    color: Color(0xff9D6E2D),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Shipped from: $shippedFrom",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (shippedFrom.isNotEmpty && shippedFrom.toLowerCase() != "nigeria")
            const Divider(color: Color.fromARGB(255, 244, 237, 237)),

          // ✅ User Delivery Address
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAddress()),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    IconsaxPlusLinear.location,
                    size: 16,
                    color: Color(0xff9D6E2D),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final address = auth.currentUserData?.deliveryAddress;
                        return Text(
                          (address == null || address.isEmpty)
                              ? "Enter delivery address"
                              : address,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Color.fromARGB(255, 244, 237, 237)),

          // ✅ Return Shipping Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
onTap: () {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // 👇 Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                // 👇 Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      Text(
                        "Return Policy",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Peereess return & refund guidelines",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // 👇 Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle("Return Shipping"),
                        SizedBox(height: 6),
                        Text(
                          "At Peereess, you can return items within 7 days of delivery. "
                          "Return shipping is covered for eligible cases.",
                          style: TextStyle(fontSize: 13),
                        ),

                        SizedBox(height: 14),

                        _SectionTitle("Return Eligibility"),
                        SizedBox(height: 6),
                        Text(
                          "• Item must be unused\n"
                          "• Must be in original packaging\n"
                          "• Tags must be intact\n"
                          "• Return within 7 days",
                          style: TextStyle(fontSize: 13),
                        ),

                        SizedBox(height: 14),

                        _SectionTitle("How to Return"),
                        SizedBox(height: 6),
                        Text(
                          "1. Go to Orders\n"
                          "2. Select item\n"
                          "3. Tap Return Item\n"
                          "4. Submit request\n"
                          "5. Wait for approval",
                          style: TextStyle(fontSize: 13),
                        ),

                        SizedBox(height: 14),

                        _SectionTitle("Refund Timeline"),
                        SizedBox(height: 6),
                        Text(
                          "• 1–2 days inspection\n"
                          "• 3–5 days refund processing\n"
                          "• Refund to original payment method",
                          style: TextStyle(fontSize: 13),
                        ),

                        SizedBox(height: 14),

                        _SectionTitle("Non-Returnable Items"),
                        SizedBox(height: 6),
                        Text(
                          "• Opened personal care items\n"
                          "• Underwear\n"
                          "• Customized items\n"
                          "• Damaged due to misuse",
                          style: TextStyle(fontSize: 13),
                        ),

                        SizedBox(height: 14),

                        _SectionTitle("Damaged Items"),
                        SizedBox(height: 6),
                        Text(
                          "Report damaged items within 48 hours with photos for replacement or refund.",
                          style: TextStyle(fontSize: 13),
                        ),

                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
},
child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    IconsaxPlusLinear.information,
                    size: 16,
                    color: Color(0xff9D6E2D),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Return shipping is covered for 7 days no-reason return",
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}