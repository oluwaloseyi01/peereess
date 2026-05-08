import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/sellerorder_provider.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/sellers/sellerorderdetails.dart';

// reuse colors
const Color kBg1 = Color.fromARGB(255, 217, 194, 162);
const Color kSurface = Color(0xFFFBF7F2);
const Color kGold = Color(0xFFB0864C);
const Color kGoldDark = Color(0xFF7A5C2E);
const Color kBorder = Color(0xFFEDE0CE);

enum SortType { newest, oldest }

class Sellerordersearch extends StatefulWidget {
  final List<String> sellerProductIds;

  const Sellerordersearch({super.key, required this.sellerProductIds});

  @override
  State<Sellerordersearch> createState() => _SellerordersearchState();
}

class _SellerordersearchState extends State<Sellerordersearch> {
  String query = '';
  SortType sortType = SortType.newest;

  List<Map<String, dynamic>> _parseSellerItems(Map<String, dynamic> order) {
    final cartItems = order['cartItems'] as List<dynamic>? ?? [];

    return cartItems
        .map<Map<String, dynamic>>((item) {
          try {
            if (item is String) {
              return Map<String, dynamic>.from(jsonDecode(item));
            }
            if (item is Map) return Map<String, dynamic>.from(item);
          } catch (_) {}
          return {};
        })
        .where((item) =>
            item.isNotEmpty &&
            widget.sellerProductIds.contains(item['productId']))
        .toList();
  }

  List<Map<String, dynamic>> _filterAndSort(List<Map<String, dynamic>> orders) {
    List<Map<String, dynamic>> filtered = orders.where((order) {
      final orderId = (order['rowId'] ?? '').toString().toLowerCase();

      final buyerName = (order['buyerName'] ?? order['userName'] ?? '')
          .toString()
          .toLowerCase();

      final sellerItems = _parseSellerItems(order);

      final titles = sellerItems
          .map((e) => (e['title'] ?? '').toString().toLowerCase())
          .join(' ');

      // ❗ Only show orders that belong to this seller
      if (sellerItems.isEmpty) return false;

      return orderId.contains(query) ||
          buyerName.contains(query) ||
          titles.contains(query);
    }).toList();

    // sort
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['\$createdAt'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['\$createdAt'] ?? '') ?? DateTime(2000);

      return sortType == SortType.newest
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SellerOrderProvider>();
    final auth = context.watch<AuthProvider>();

    if (!auth.isConnected) return const SizedBox();

    final orders = _filterAndSort(provider.sellerOrders);

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(5),
          child: Container(color: Colors.grey, height: 0.5),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
        elevation: 0,
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
            const Text(
              "Search order",
              maxLines: 1,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
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
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 🔍 SEARCH
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => query = val.toLowerCase()),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Order ID, product, buyer...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 243, 146, 178),
                          width: 1.5,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              // 🔽 SORT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<SortType>(
                      value: sortType,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: SortType.newest, child: Text('Newest')),
                        DropdownMenuItem(
                            value: SortType.oldest, child: Text('Oldest')),
                      ],
                      onChanged: (val) => setState(() => sortType = val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 📦 RESULTS
              if (orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: Text('No matching orders')),
                )
              else
                ListView.builder(
                  itemCount: orders.length,
                  shrinkWrap: true, // 👈 KEY
                  physics: const NeverScrollableScrollPhysics(), // 👈 KEY
                  itemBuilder: (context, i) {
                    final order = orders[i];
                    final orderId = order['rowId'] ?? '-';

                    final createdAt =
                        DateTime.tryParse(order['\$createdAt'] ?? '');

                    final formattedDate = createdAt != null
                        ? DateFormat('MMM d, yyyy').format(createdAt)
                        : '';

                    final sellerItems = _parseSellerItems(order);

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerOrderDetail(
                            order: order,
                            sellerProductIds: widget.sellerProductIds,
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${orderId.toString().substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kGoldDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (sellerItems.isNotEmpty)
                              Text(
                                sellerItems.first['title'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 6),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
