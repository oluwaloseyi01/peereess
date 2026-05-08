import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/refundservice.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/model/refundmodel.dart';

class SellerRefundPage extends StatelessWidget {
  const SellerRefundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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

    final productProvider = context.watch<ProductUploadProvider>();
    final refundProvider = context.watch<RefundProvider>();

    /// 1️⃣ Get all productIds that belong to this seller
    final List<String> sellerProductIds = productProvider.sellerProducts
        .map((product) => product['productId'] as String)
        .toList();

    /// 2️⃣ Filter refunds that contain seller products
    final List<RefundModel> sellerRefunds = refundProvider.refunds.where((
      refund,
    ) {
      final items = refund.decodeAllItems();

      return items.any((item) => sellerProductIds.contains(item.productId));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
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
                  size: 16,
                  color: Color(0xff9D6E2D),
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: const Text(
                  "Refund",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // balance space instead of random spacing
            const SizedBox(width: 40),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
      ),
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
        child: refundProvider.isLoading
            ? const Center(child: LogoLoadingIndicator())
            : sellerRefunds.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconsaxPlusLinear.repeat,
                            size: 40, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "No refund yet",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: sellerRefunds.length,
                    itemBuilder: (context, index) {
                      final refund = sellerRefunds[index];

                      /// 3️⃣ Show ONLY items belonging to this seller
                      final sellerItems = refund
                          .decodeAllItems()
                          .where(
                            (item) => sellerProductIds.contains(item.productId),
                          )
                          .toList();

                      return Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Refund ID: ${refund.refundId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text('Status: ${refund.status}'),
                              Text(
                                'Amount: ₦${refund.refundAmount.toStringAsFixed(2)}',
                              ),
                              const Divider(),

                              /// 4️⃣ Seller items list
                              ...sellerItems.map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Image.network(
                                    item.image,
                                    width: 45,
                                    height: 45,
                                    fit: BoxFit.cover,
                                  ),
                                  title: Text(item.title),
                                  subtitle: Text(
                                    'Qty: ${item.quantity} • ${item.variant}',
                                  ),
                                  trailing: Text(
                                    '₦${item.price}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
