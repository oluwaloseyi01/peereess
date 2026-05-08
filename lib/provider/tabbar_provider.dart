import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:peereess/databases/config/apihelper.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/ordermodel.dart';
import 'package:peereess/model/peereess.dart';

class TabbarProvider extends ChangeNotifier {
  TabController? tabController;

  bool isLoading = false;
  int currentIndex = 0;

  final List<String> orderTabs = [
    "Processing / Delivered",
    "Canceled / Returned"
  ];

  List<OrderModel> _allOrders = [];

  List<OrderModel> get allOrders => _allOrders;

  List<OrderModel> get ongoingDelivered =>
      _allOrders.where((o) => o.status != "canceled").toList();

  List<OrderModel> get canceledReturned =>
      _allOrders.where((o) => o.status == "canceled").toList();

  void initController(TickerProvider vsync) {
    tabController ??= TabController(length: orderTabs.length, vsync: vsync);
  }

  void changeTab(int index) {
    currentIndex = index;
    tabController?.animateTo(index);
    notifyListeners();
  }

  // ===================== FETCH USER ORDERS =====================
  Future<void> fetchUserOrders(String? userId) async {
    if (userId == null || userId.isEmpty) {
      // debugPrint("⚠️ fetchUserOrders: userId is null, skipping");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      // Cursor-based pagination — fetches ALL orders, not just the first 25
      const int pageSize = 100;
      final List<Map<String, dynamic>> allRows = [];
      String? lastId;

      while (true) {
        final queries = [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
          Query.limit(pageSize),
          if (lastId != null) Query.cursorAfter(lastId),
        ];

        final response = await AppwriteConfig.tablesDB.listRows(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.order,
          queries: queries,
        );

        final rows = response.rows;
        for (final row in rows) {
          final data = Map<String, dynamic>.from(row.data);
          data[r'$id'] = row.$id; // ensure $id is always set from SDK
          allRows.add(data);
        }

        if (rows.length < pageSize) break;
        lastId = rows.last.$id;
      }

      _allOrders = allRows.map((data) => _parseOrder(data)).toList();

      // debugPrint("✅ Orders fetched: ${_allOrders.length}");
    } catch (e, st) {
      // debugPrint("❌ FETCH ORDERS ERROR: $e\n$st");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ===================== PARSE ORDER ROW =====================
  OrderModel _parseOrder(Map<String, dynamic> data) {
    // Decode cart items
    final List<OrderItem> cartItems = [];
    if (data['cartItems'] is List) {
      for (final rawItem in data['cartItems']) {
        if (rawItem is String) {
          try {
            final decoded = jsonDecode(rawItem);
            cartItems.add(
              OrderItem.fromMap(Map<String, dynamic>.from(decoded)),
            );
          } catch (e) {
            // debugPrint("❌ Failed to decode cart item: $e");
          }
        }
      }
    }

    // Decode selected pickup
    Peereess? pickup;
    if (data['selectedPickup'] is String &&
        (data['selectedPickup'] as String).isNotEmpty) {
      try {
        pickup = Peereess.fromMap(
          Map<String, dynamic>.from(jsonDecode(data['selectedPickup'])),
        );
      } catch (e) {
        // debugPrint("❌ Failed to decode pickup: $e");
      }
    }

    // Decode delivery statuses
    List<String>? _decodeStatusList(dynamic value) {
      if (value is List) return value.map((e) => e.toString()).toList();
      return null;
    }

    return OrderModel(
      orderId: data[r'$id'] ?? '',
      cartItems: cartItems,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      deliveryAddress: data['deliveryAddress'] ?? '',
      deliveryPhoneNumber: data['deliveryPhoneNumber'] ?? '',
      deliveryDays: data['deliveryDays'],
      receiverFullName: data['receiverFullName'],
      selectedPickup: pickup,
      paymentMethod: data['paymentMethod'],
      isPaid: data['isPaid'] ?? false,
      status: data['status'] ?? 'processing',
      createdAt: DateTime.parse(data[r'$createdAt']),
      updatedAt: DateTime.parse(data[r'$updatedAt']),
      deliveryStatus1: _decodeStatusList(data['deliveryStatus1']),
      deliveryStatus2: _decodeStatusList(data['deliveryStatus2']),
      deliveryStatus3: _decodeStatusList(data['deliveryStatus3']),
      paymentRef: data['paymentRef'],
      deliveryCode: data['deliveryCode'],
    );
  }

  // ===================== COMPLETED ORDER COUNT =====================
  Future<int> getCompletedOrderCount(String userId) async {
    try {
      final result = await ApiHelper.guard(
        () => AppwriteConfig.tablesDB.listRows(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.order,
          queries: [
            Query.equal('userId', userId),
            Query.equal('status', 'completed'),
            Query.limit(1), // we only need the total count, not the rows
          ],
        ),
      );
      if (result == null) return 0;
      return result.total; // Appwrite returns total count regardless of limit
    } catch (e) {
      // debugPrint("GET COMPLETED ORDER COUNT ERROR: $e");
      return 0;
    }
  }

  Future<void> fetchRecentOrders(String? userId) async {
    if (userId == null || userId.isEmpty) {
      // debugPrint("⚠️ fetchRecentOrders: userId is null");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      final response = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.order,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
          Query.limit(5), // 👈 only recent 5
        ],
      );

      _allOrders = response.rows.map((row) {
        final data = Map<String, dynamic>.from(row.data);
        data[r'$id'] = row.$id;
        return _parseOrder(data);
      }).toList();

      // debugPrint("✅ Recent Orders fetched: ${_allOrders.length}");
    } catch (e, st) {
      // debugPrint("❌ RECENT ORDERS ERROR: $e\n$st");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
