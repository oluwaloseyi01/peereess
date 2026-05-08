import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/refundservice.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/model/refundmodel.dart';
import 'package:peereess/core/num_extension.dart';

class Refund extends StatefulWidget {
  const Refund({super.key});

  @override
  State<Refund> createState() => _RefundState();
}

class _RefundState extends State<Refund> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        context.read<RefundProvider>().fetchUserRefunds(userId: userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final refundProvider = context.watch<RefundProvider>();

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
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: refundProvider.isLoading
              ? const Center(child: LogoLoadingIndicator())
              : refundProvider.refunds.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      itemCount: refundProvider.refunds.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final refund = refundProvider.refunds[index];

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 233, 226, 226),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// ORDER ID
                              Text(
                                "Order ID: ${refund.orderId}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              8.getHeightWhiteSpacing,

                              /// REFUND ITEMS
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: refund.refundItems.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 10),
                                itemBuilder: (_, i) {
                                  try {
                                    final item = RefundModel.decodeItem(
                                      refund.refundItems[i],
                                    );

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// IMAGE
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: CachedNetworkImage(
                                            imageUrl: item.image,
                                            height: 45,
                                            width: 45,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              height: 45,
                                              width: 45,
                                              color: Colors.grey[200],
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                              Icons.image_not_supported,
                                              size: 40,
                                            ),
                                          ),
                                        ),

                                        10.getWidthWhiteSpacing,

                                        /// DETAILS
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                "Variant: ${item.variant}",
                                                style: const TextStyle(
                                                    fontSize: 9),
                                              ),
                                              if (item.color != null &&
                                                  item.color!.isNotEmpty)
                                                Text(
                                                  "Color: ${item.color}",
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              Text(
                                                "Qty: ${item.quantity}",
                                                style: const TextStyle(
                                                    fontSize: 9),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  } catch (_) {
                                    return const Text(
                                      "Invalid refund item",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),

                              8.getHeightWhiteSpacing,

                              /// AMOUNT
                              Text(
                                "Amount: ₦${refund.refundAmount.toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 11),
                              ),

                              6.getHeightWhiteSpacing,

                              /// STATUS
                              Row(
                                children: [
                                  const Text(
                                    "Status:",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  5.getWidthWhiteSpacing,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(refund.status),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      refund.status.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              6.getHeightWhiteSpacing,

                              /// DATE
                              Text(
                                "Requested on: ${refund.createdAt.toLocal().toString().split(' ').first}",
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconsaxPlusLinear.repeat, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No refund yet",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "processing":
        return Colors.orange;
      case "completed":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
