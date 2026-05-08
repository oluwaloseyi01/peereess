import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/tabbar_provider.dart';
import 'package:peereess/screens/orderhistory.dart';
import 'package:peereess/screens/widgets/orderstatuswidget.dart';

import 'package:provider/provider.dart';

class RecentOrdersWidget extends StatefulWidget {
  const RecentOrdersWidget({super.key});

  @override
  State<RecentOrdersWidget> createState() => _RecentOrdersWidgetState();
}

class _RecentOrdersWidgetState extends State<RecentOrdersWidget> {
  @override
  void initState() {
    super.initState();

    // ✅ Fetch recent orders ONCE
    Future.microtask(() {
      final userId = context.read<AuthProvider>().userId;
      context.read<TabbarProvider>().fetchRecentOrders(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TabbarProvider>(
      builder: (context, tabProvider, _) {
        if (tabProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 0.1,
              color: Colors.white,
            ),
          );
        }

        final recentOrders = tabProvider.allOrders.take(2).toList();

        if (recentOrders.isEmpty) {
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrderHistory()),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromARGB(255, 233, 226, 226),
              ),
              padding: const EdgeInsets.all(8),
              child: const Center(
                child: Text(
                  "No recent orders",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromARGB(255, 233, 226, 226),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recent Orders",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              5.getHeightWhiteSpacing,
              ...recentOrders.map((order) {
                final firstItem =
                    order.cartItems.isNotEmpty ? order.cartItems.first : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      "/orderHistoryDetail",
                      arguments: {"order": order},
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 40,
                                width: 60,
                                child: firstItem != null &&
                                        firstItem.image.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: firstItem.image,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(color: Colors.grey[200]),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Container(color: Colors.grey[300]),
                              ),
                            ),
                            10.getWidthWhiteSpacing,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "#${order.orderId}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  5.getHeightWhiteSpacing,
                                  Row(
                                    children: [
                                      OrderStatusBadge(status: order.status),
                                      Spacer(),
                                      const Text(
                                        "View Details",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xffB0864C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderHistory()),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: const Text(
                    "View all orders",
                    style: TextStyle(color: Color(0xffB0864C), fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
