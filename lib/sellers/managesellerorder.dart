import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:peereess/sellers/sellerorderdetails.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/provider/sellerorder_provider.dart';

class ManageSellerOrdersWidget extends StatelessWidget {
  const ManageSellerOrdersWidget({super.key});

  String _formatDate(String rawDate) {
    try {
      final dateTime = DateTime.parse(rawDate);
      final formatter = DateFormat('dd MMM yyyy, hh:mm a');
      return formatter.format(dateTime.toLocal());
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<SellerOrderProvider>();
    final productProvider = context.watch<ProductUploadProvider>();

    if (!authProvider.isConnected) return const SizedBox();

    if (orderProvider.isLoadingOrders) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
      );
    }

    final sellerProductIds = productProvider.sellerProducts
        .map((p) => p['productId'] as String)
        .toList();

    // ── Empty state ──────────────────────────────────────────────────────────
    if (orderProvider.sellerOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(IconsaxPlusLinear.box, size: 52, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No order history yet',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Orders from your products will appear here',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'poppins',
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orderProvider.sellerOrders.length,
      itemBuilder: (context, index) {
        final order = orderProvider.sellerOrders[index];
        final cartItems = order['cartItems'] as List<dynamic>? ?? [];

        final sellerItems = cartItems
            .map(
              (item) => item is String
                  ? Map<String, dynamic>.from(jsonDecode(item))
                  : Map<String, dynamic>.from(item),
            )
            .where((item) => sellerProductIds.contains(item['productId']))
            .toList();

        if (sellerItems.isEmpty) return const SizedBox();

        final status = order['status'] ?? 'pending';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerOrderDetail(
                order: order,
                sellerProductIds: sellerProductIds,
              ),
            ),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 3),
            elevation: 3,
            color: const Color.fromARGB(255, 233, 226, 226),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...sellerItems.map((item) {
                    final image = item['image'] ?? '';
                    final title = item['title'] ?? '';
                    final quantity = (item['quantity'] ?? 0) as int;
                    final price = (item['price'] ?? 0).toDouble();
                    final totalPrice = price * quantity;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Product image ──────────────────────────
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: image,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_outlined,
                                        size: 20,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_outlined),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${order['rowId']}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: status == 'order placed'
                                            ? const Color(0xFFFFF8EB)
                                            : status == 'shipped'
                                                ? const Color(0xFFF0FBF5)
                                                : status == 'intransist'
                                                    ? const Color(0xFFF0F5FF)
                                                    : status == 'delivered'
                                                        ? const Color(
                                                            0xFFF1F8F1)
                                                        : status == 'completed'
                                                            ? const Color(
                                                                0xFFF0F5FB)
                                                            : status ==
                                                                    'canceled'
                                                                ? const Color(
                                                                    0xFFFBF0F0)
                                                                : status ==
                                                                        'rejected'
                                                                    ? const Color(
                                                                        0xFFFFF0F0)
                                                                    : status ==
                                                                            'refund'
                                                                        ? const Color(
                                                                            0xFFF5F0FB)
                                                                        : Colors
                                                                            .grey
                                                                            .withOpacity(0.2),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 2),
                                      child: Text(
                                        status == 'order placed'
                                            ? 'Order Placed'
                                            : status == 'shipped'
                                                ? 'Shipped'
                                                : status == 'intransist'
                                                    ? 'In Transit'
                                                    : status == 'delivered'
                                                        ? 'Delivered'
                                                        : status == 'completed'
                                                            ? 'Completed'
                                                            : status ==
                                                                    'canceled'
                                                                ? 'Cancelled'
                                                                : status ==
                                                                        'rejected'
                                                                    ? 'Rejected'
                                                                    : status ==
                                                                            'refund'
                                                                        ? 'Refund'
                                                                        : status,
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                          color: status == 'order placed'
                                              ? const Color(0xFF8B5E00)
                                              : status == 'shipped'
                                                  ? const Color(0xFF1A6B3C)
                                                  : status == 'intransist'
                                                      ? const Color(0xFF1A4A8B)
                                                      : status == 'delivered'
                                                          ? const Color(
                                                              0xFF2E7D32)
                                                          : status ==
                                                                  'completed'
                                                              ? const Color(
                                                                  0xFF1A3A6B)
                                                              : status ==
                                                                      'canceled'
                                                                  ? const Color(
                                                                      0xFF8B1A1A)
                                                                  : status ==
                                                                          'rejected'
                                                                      ? const Color(
                                                                          0xFF6A1A1A)
                                                                      : status ==
                                                                              'refund'
                                                                          ? const Color(
                                                                              0xFF5C3D8B)
                                                                          : Colors
                                                                              .grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  title,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Quantity: $quantity',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    5.getWidthWhiteSpacing,
                                    Text(
                                      '₦${formatter.format(totalPrice)}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      IconsaxPlusLinear.profile,
                                      size: 10,
                                    ),
                                    2.getWidthWhiteSpacing,
                                    Expanded(
                                      child: Text(
                                        order['receiverFullName'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    5.getWidthWhiteSpacing,
                                    Text(
                                      _formatDate(order['\$createdAt'] ?? ''),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
