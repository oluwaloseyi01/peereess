import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/screens/admin/deliverystatus.dart';
import 'package:peereess/screens/widgets/deliveryday.dart';

class AdminOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const AdminOrderDetailPage({super.key, required this.order});

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  Map<String, Map<String, dynamic>> sellersInfo =
      {}; // key: sellerId, value: seller data
  bool isLoadingSellers = true;

  @override
  void initState() {
    super.initState();
    _fetchSellersForOrder();
  }

  Future<void> _fetchSellersForOrder() async {
    final cartItems = widget.order['cartItems'] as List<dynamic>? ?? [];
    final productIds = <String>{};

    // Collect all productIds from cart
    for (var item in cartItems) {
      try {
        final mapItem = item is String
            ? Map<String, dynamic>.from(jsonDecode(item))
            : Map<String, dynamic>.from(item);
        final productId = mapItem['productId']?.toString();
        if (productId != null && productId.isNotEmpty) {
          productIds.add(productId);
        }
      } catch (_) {}
    }

    // Fetch seller info for each product
    for (String pid in productIds) {
      try {
        final productRes = await AppwriteConfig.tablesDB.getRow(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.product,
          rowId: pid,
        );

        final sellerId = productRes.data['userId']?.toString();
        if (sellerId != null &&
            sellerId.isNotEmpty &&
            !sellersInfo.containsKey(sellerId)) {
          final sellerRes = await AppwriteConfig.tablesDB.listRows(
            databaseId: AppwriteConfig.databaseId,
            tableId: AppwriteConfig.userCollection,
            queries: [Query.equal('userId', sellerId)],
          );

          if (sellerRes.rows.isNotEmpty) {
            sellersInfo[sellerId] = sellerRes.rows.first.data;
          }
        }
      } catch (e) {
        debugPrint("Error fetching seller for product $pid: $e");
      }
    }

    setState(() {
      isLoadingSellers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final String buyerName = order['receiverFullName'] ?? 'Unknown';
    final String buyerPhone = order['deliveryPhoneNumber'] ?? 'N/A';
    final String buyerAddress = order['deliveryAddress'] ?? 'N/A';
    final String orderId = order['rowId'] ?? '';
    final String paymentMethod = order['paymentMethod'] ?? '';

    final int? deliveryDays = order['deliveryDays'] is int
        ? order['deliveryDays'] as int
        : int.tryParse(order['deliveryDays']?.toString() ?? '');
    final String deliveryFee = order['deliveryFee']?.toString() ?? '0';
    final String selectedPickup = order['selectedPickup']?.toString() ?? '';

    final String status = order['status'] ?? 'pending';
    final createdAt = order['\$createdAt'] ?? '';
    final cartItems = order['cartItems'] as List<dynamic>? ?? [];

    double total = 0;

    List<Map<String, dynamic>> parsedItems = [];

    for (var item in cartItems) {
      try {
        final mapItem = item is String
            ? Map<String, dynamic>.from(jsonDecode(item))
            : Map<String, dynamic>.from(item);
        final price = (mapItem['price'] ?? 0).toDouble();
        final quantity = (mapItem['quantity'] ?? 0).toInt();
        final discount = (mapItem['discount'] ?? 0).toDouble();
        total += price * quantity * (1 - discount / 100);

        parsedItems.add(mapItem);
      } catch (_) {}
    }

    String formattedDate = '';
    try {
      final date = DateTime.parse(createdAt);
      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {}

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
            const Text("Order Details", style: TextStyle(fontSize: 18)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buyer Info
              const Text(
                "Buyer Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Name: $buyerName"),
              Text("Phone: $buyerPhone"),
              Text("Address: $buyerAddress"),
              const SizedBox(height: 12),

              // Sellers Info
              const Text(
                "Sellers Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              isLoadingSellers
                  ? const CircularProgressIndicator()
                  : sellersInfo.isEmpty
                      ? const Text("No seller information found")
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sellersInfo.values.map((s) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Name: ${s['fullName'] ?? 'N/A'}"),
                                  Text("Phone: ${s['phoneNumber'] ?? 'N/A'}"),
                                  Text(
                                      "Address: ${s['deliveryAddress'] ?? 'N/A'}"),
                                  const Divider(),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

              10.getHeightWhiteSpacing,

              // Order Info
              const Text(
                "Order Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Order ID: $orderId"),
              Text(
                "Status: $status",
                style: TextStyle(
                  color: status == 'completed' ? Colors.green : Colors.orange,
                ),
              ),
              if (formattedDate.isNotEmpty) Text("Date: $formattedDate"),
              Text("Delivery Fee: ₦$deliveryFee"),
              Text("paymentMethod: $paymentMethod"),

              const SizedBox(height: 8),
              Text("Delivery days: $deliveryDays days from order date"),

              if (selectedPickup.isNotEmpty) Text("Pickup: $selectedPickup"),
              Text("Total: ₦${total.toStringAsFixed(2)}"),
              const SizedBox(height: 12),

              // Cart Items
              const Text(
                "Cart Items",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...parsedItems.map((item) {
                final title = item['title'] ?? 'Unnamed Product';
                final quantity = item['quantity'] ?? 0;
                final productId = item['productId'] ?? '';
                final price = (item['price'] ?? 0).toDouble();
                final discount = (item['discount'] ?? 0).toDouble();
                final subtotal = price * quantity * (1 - discount / 100);
                final imageUrl = item['image'] ?? '';
                final color = item['color'] ?? '';
                final variant = item['variant'] ?? '';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.image_not_supported),
                    title: Text(title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (variant.isNotEmpty) Text("Variant: $variant"),
                        if (color.isNotEmpty) Text("Color: $color"),
                        Text("Quantity: $quantity"),
                        if (discount > 0) Text("Discount: $discount%"),
                        Text("ProductId: $productId"),
                      ],
                    ),
                    trailing: Text("₦${subtotal.toStringAsFixed(2)}"),
                  ),
                );
              }).toList(),
              20.getHeightWhiteSpacing,
              AppButtons(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Deliverystatus(orderId: orderId),
                    ),
                  );
                },
                text: "Update delivery status",
              ),

              100.getHeightWhiteSpacing,
            ],
          ),
        ),
      ),
    );
  }
}
