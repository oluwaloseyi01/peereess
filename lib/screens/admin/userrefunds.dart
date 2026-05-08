import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/admin/adminrefunddetails.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/refundservice.dart';
import 'package:peereess/model/refundmodel.dart';
import 'package:peereess/core/num_extension.dart';

class Adminrefund extends StatefulWidget {
  const Adminrefund({super.key});

  @override
  State<Adminrefund> createState() => _AdminrefundState();
}

class _AdminrefundState extends State<Adminrefund> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final auth = context.read<AuthProvider>();

      context.read<RefundProvider>().getAdminRefunds(userId: auth.userId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final refundProvider = context.watch<RefundProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "All Refund Requests",
          style: TextStyle(fontSize: 18),
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
              ? const Center(child: CircularProgressIndicator())
              : refundProvider.refunds.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      itemCount: refundProvider.refunds.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final refund = refundProvider.refunds[index];

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque, // 👈 IMPORTANT
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminRefundDetails(refund: refund),
                              ),
                            );
                          },
                          child: Container(
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

                                /// ITEMS (NO GestureDetector here anymore)
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: refund.refundItems.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 10),
                                  itemBuilder: (_, i) {
                                    final item = RefundModel.decodeItem(
                                      refund.refundItems[i],
                                    );

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
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
                                                    Container(
                                              height: 45,
                                              width: 45,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 20,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        10.getWidthWhiteSpacing,
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
                                  },
                                ),

                                8.getHeightWhiteSpacing,

                                Text(
                                  "Refund Amount: ₦${refund.refundAmount.toStringAsFixed(0)}",
                                  style: const TextStyle(fontSize: 11),
                                ),

                                6.getHeightWhiteSpacing,

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

                                Text(
                                  "Requested on: ${refund.createdAt.toLocal().toString().split(' ').first}",
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.receipt_long, size: 60, color: Colors.grey),
        15.getHeightWhiteSpacing,
        const Text("No refund requests yet", style: TextStyle(fontSize: 14)),
      ],
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
