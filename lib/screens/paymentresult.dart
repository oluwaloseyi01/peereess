import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/product_provider.dart';

import 'package:peereess/screens/orderhistory.dart';
import 'package:peereess/screens/widgets/product_collectionwidget.dart';
import 'package:provider/provider.dart';

class PaymentResultPage extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final String? reference;

  const PaymentResultPage({
    super.key,
    required this.isSuccess,
    required this.message,
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = isSuccess ? Colors.green : Colors.red;
    final IconData icon = isSuccess ? Icons.check_circle : Icons.cancel;
    final String title = isSuccess ? "Payment Completed!" : "Payment Failed";
    final String titles = isSuccess ? "Order Successful" : "Payment Failed";
    final String subtitle = isSuccess
        ? "Thank you for placing an order on Peereess!"
        : "Please try again or contact support.";

    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

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
            children: [
              40.getHeightWhiteSpacing,

              // ── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      titles,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B4A1B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    // ✅ FIXED — pop instead of pushing new Home
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.brown.shade200,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.brown.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              10.getHeightWhiteSpacing,

              // ── Status card ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: primaryColor, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (message.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                message
                                    .replaceAll("by user", "")
                                    .replaceAll("User", "")
                                    .trim(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              30.getHeightWhiteSpacing,

              // ✅ FIXED — only show if payment succeeded
              if (isSuccess)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AppButtons(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderHistory(),
                        ),
                      );
                    },
                    text: "See Order Details",
                  ),
                ),

              20.getHeightWhiteSpacing,

              // ── Recommended ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recommended for you",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B4A1B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (productProvider.isLoading && products.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (products.isEmpty)
                      const Center(child: Text("No products available"))
                    else
                      MasonryGridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                        ),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 5,
                        itemCount: products.length > 10 ? 10 : products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCollectionwidget(product: product);
                        },
                      ),
                  ],
                ),
              ),

              20.getHeightWhiteSpacing,
            ],
          ),
        ),
      ),
    );
  }
}
