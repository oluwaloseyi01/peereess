import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:peereess/model/refundmodel.dart';
import 'package:peereess/provider/refundservice.dart';
import 'package:peereess/core/num_extension.dart';

class AdminRefundDetails extends StatelessWidget {
  final RefundModel refund;

  const AdminRefundDetails({super.key, required this.refund});

  @override
  Widget build(BuildContext context) {
    final refundProvider = context.watch<RefundProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Refund Details"),
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("Refund Info"),

            /// ✅ FIXED
            _info("Refund ID", refund.refundId),
            _info("Order ID", refund.orderId),

            _info("Amount", "₦${refund.refundAmount.toStringAsFixed(0)}"),
            _info("Status", refund.status.toUpperCase()),
            _info("Requested On", refund.createdAt.toLocal().toString()),

            if (refund.reason != null) _info("Reason", refund.reason!),

            if (refund.refundMethod != null)
              _info("Refund Method", refund.refundMethod!),

            15.getHeightWhiteSpacing,

            _section("Refund Items"),
            ...refund.refundItems.map((e) {
              final item = RefundModel.decodeItem(e);
              return _itemCard(item);
            }),

            20.getHeightWhiteSpacing,

            _section("Admin Actions"),
            refundProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          context,
                          label: "Process",
                          color: Colors.orange,
                          status: "processing",
                        ),
                      ),
                      10.getWidthWhiteSpacing,
                      Expanded(
                        child: _actionButton(
                          context,
                          label: "Refunded",
                          color: Colors.green,
                          status: "refunded",
                        ),
                      ),
                      10.getWidthWhiteSpacing,
                      Expanded(
                        child: _actionButton(
                          context,
                          label: "Cancel",
                          color: Colors.red,
                          status: "cancelled",
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required String status,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: () async {
        final provider = context.read<RefundProvider>();

        /// ✅ FIXED
        final auth = context.read<AuthProvider>();

        final ok = await provider.updateRefundStatus(
          userId: auth.userId!, // 👈 add this
          refundId: refund.refundId,
          status: status,
        );

        if (ok && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Text(label, style: TextStyle(fontSize: 10, color: Colors.white)),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$title:",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  Widget _itemCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: item.image,
              width: 45,
              height: 45,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(width: 45, height: 45, color: Colors.grey[200]),
              errorWidget: (context, url, error) => Container(
                width: 45,
                height: 45,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Variant: ${item.variant}",
                  style: const TextStyle(fontSize: 9),
                ),
                if (item.color != null)
                  Text(
                    "Color: ${item.color}",
                    style: const TextStyle(fontSize: 9),
                  ),
                Text(
                  "Qty: ${item.quantity}",
                  style: const TextStyle(fontSize: 9),
                ),
                Text(
                  "productId: ${item.productId}",
                  style: const TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
