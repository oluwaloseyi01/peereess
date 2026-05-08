import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/screens/admin/deliverystatus.dart';
import 'package:provider/provider.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/ordermodel.dart';
import 'package:peereess/provider/adminprovider.dart';

class Admindeliverdorder extends StatefulWidget {
  const Admindeliverdorder({super.key});

  @override
  State<Admindeliverdorder> createState() => _AdmindeliverdorderState();
}

class _AdmindeliverdorderState extends State<Admindeliverdorder> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AdminProvider>().fetchdeliveredOrders();
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
            const Text("New Placed Orders", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          if (admin.isLoadingOnDelivery) {
            return const Center(child: CircularProgressIndicator());
          }

          if (admin.onDeliveryOrders.isEmpty) {
            return _emptyState();
          }

          final orders = admin.onDeliveryOrders
              .map((e) => OrderModel.fromMap(e, orderId: e['rowId']))
              .toList();

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
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _orderCard(context, orders[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.local_shipping, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No orders currently",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(BuildContext context, OrderModel order) {
    final formattedDate = DateFormat('dd MMM yyyy').format(order.createdAt);

    final totalItems = order.cartItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Deliverystatus(orderId: order.orderId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Order #${order.orderId}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "delivered",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            6.getHeightWhiteSpacing,
            Text("Placed on: $formattedDate"),
            Text("Items: $totalItems"),
            Text(
              "Total: ₦${(order.totalPrice + order.deliveryFee).toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
