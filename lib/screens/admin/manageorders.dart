import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/adminprovider.dart';
import 'package:peereess/screens/admin/adminorder.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = context.read<AdminProvider>();
      adminProvider.fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
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
                  size: 18,
                  color: Color(0xff9D6E2D),
                ),
              ),
            ),
            10.getWidthWhiteSpacing,
            const Text("Manage Orders", style: TextStyle(fontSize: 18)),
          ],
        ),
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
        child: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingOrders) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = provider.filteredOrders;

            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search by buyer or order ID...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: provider.searchOrders,
                  ),
                ),

                // Order list
                Expanded(
                  child: orders.isEmpty
                      ? const Center(child: Text("No orders found"))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final buyerName =
                                order['receiverFullName'] ?? 'Unknown';
                            final orderId = order['rowId'] ?? '';
                            final status = order['status'] ?? 'pending';
                            final createdAt = order['\$createdAt'] ?? '';
                            final cartItems =
                                order['cartItems'] as List<dynamic>? ?? [];

                            // Calculate total price
                            double total = 0;
                            for (var item in cartItems) {
                              try {
                                final mapItem = item is String
                                    ? Map<String, dynamic>.from(
                                        jsonDecode(item),
                                      )
                                    : Map<String, dynamic>.from(item);
                                final price =
                                    (mapItem['price'] ?? 0).toDouble();
                                final quantity =
                                    (mapItem['quantity'] ?? 0).toInt();
                                total += price * quantity;
                              } catch (_) {}
                            }

                            // Format date
                            String formattedDate = '';
                            try {
                              final date = DateTime.parse(createdAt);
                              formattedDate = DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(date);
                            } catch (_) {}

                            return Card(
                              elevation: 2,
                              child: ListTile(
                                title: Text("Buyer: $buyerName"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Order ID: $orderId"),
                                    Text("Total: ₦${total.toStringAsFixed(2)}"),
                                    Text(
                                      "Status: $status",
                                      style: TextStyle(
                                        color: status == 'completed'
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                    if (formattedDate.isNotEmpty)
                                      Text("Date: $formattedDate"),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminOrderDetailPage(order: order),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
