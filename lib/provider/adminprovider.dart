import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';

class AdminProvider extends ChangeNotifier {
  // ================= STATS =================
  int totalAllUsers = 0;
  int totalUsers = 0;
  int totalSellers = 0;
  int totalAdmins = 0;
  int totalOrders = 0;
  double totalRevenue = 0.0;

  bool isLoading = false;
  bool isLoadingSellers = false;
  bool isLoadingOrders = false;

  // ================= SELLERS =================
  List<Map<String, dynamic>> sellers = [];
  List<Map<String, dynamic>> filteredSellers = [];
  bool isLoadingOnDelivery = false;
  List<Map<String, dynamic>> onDeliveryOrders = [];

  // ================= SELLER PRODUCTS =================
  bool isLoadingSellerProducts = false;
  List<Map<String, dynamic>> sellerProducts = [];
  int productCount = 0;

  // ================= ORDERS =================
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];

  int get deliveredOrdersCount =>
      orders.where((o) => o['status'] == 'delivered').length;

  int get newOrdersCount =>
      orders.where((o) => o['status'] == 'order placed').length;

  int get ondeliveryorderCount =>
      orders.where((o) => o['status'] == 'ondelivery').length;

  // ================= PAGINATION HELPER =================
  Future<List<Map<String, dynamic>>> _fetchAllRows({
    required String tableId,
    required List<String> queries,
  }) async {
    const int pageSize = 500;
    int offset = 0;
    final List<Map<String, dynamic>> allRows = [];

    while (true) {
      final res = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: tableId,
        queries: [...queries, Query.limit(pageSize), Query.offset(offset)],
      );

      for (final row in res.rows) {
        allRows.add({
          ...row.data,
          '\$id': row.$id,
          '\$createdAt': row.$createdAt,
        });
      }

      if (res.rows.length < pageSize) break;
      offset += pageSize;
    }

    return allRows;
  }

  // ================= ADMIN STATS =================
  Future<void> fetchAdminStats() async {
    try {
      isLoading = true;
      notifyListeners();

      // ✅ .total is accurate regardless of limit — no pagination needed for counts
      final allUsersRows = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userCollection,
        queries: [Query.limit(1)],
      );
      totalAllUsers = allUsersRows.total;

      final usersRows = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userCollection,
        queries: [Query.equal("role", "user"), Query.limit(1)],
      );
      totalUsers = usersRows.total;

      final sellersRows = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userCollection,
        queries: [Query.equal("role", "seller"), Query.limit(1)],
      );
      totalSellers = sellersRows.total;

      final adminsRows = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userCollection,
        queries: [Query.equal("role", "admin"), Query.limit(1)],
      );
      totalAdmins = adminsRows.total;

      await fetchOrdersStats();
    } catch (e) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= FETCH ORDERS =================
  Future<void> fetchOrders({bool refresh = true}) async {
    if (refresh) isLoadingOrders = true;
    notifyListeners();

    try {
      // ✅ paginated — shows all orders
      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.order,
        queries: [Query.orderDesc("\$createdAt")],
      );

      orders = allRows.map((row) => {...row, "rowId": row['\$id']}).toList();
      filteredOrders = List.from(orders);
      totalOrders = orders.length;

      double revenue = 0.0;
      for (var order in orders) {
        final cartItems = order['cartItems'] as List<dynamic>? ?? [];
        for (var item in cartItems) {
          try {
            final mapItem = item is String
                ? Map<String, dynamic>.from(jsonDecode(item))
                : Map<String, dynamic>.from(item);
            final price = (mapItem['price'] ?? 0).toDouble();
            final quantity = (mapItem['quantity'] ?? 0).toInt();
            revenue += price * quantity;
          } catch (_) {}
        }
      }
      totalRevenue = revenue;
    } catch (e) {
    } finally {
      if (refresh) isLoadingOrders = false;
      notifyListeners();
    }
  }

  // ================= FETCH ORDERS FOR STATS =================
  Future<void> fetchOrdersStats() async {
    try {
      // ✅ paginated — calculates revenue across all orders
      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.order,
        queries: [],
      );

      totalOrders = allRows.length;

      double revenue = 0.0;
      for (var order in allRows) {
        final cartItems = order['cartItems'] as List<dynamic>? ?? [];
        for (var item in cartItems) {
          try {
            final mapItem = item is String
                ? Map<String, dynamic>.from(jsonDecode(item))
                : Map<String, dynamic>.from(item);
            final price = (mapItem['price'] ?? 0).toDouble();
            final quantity = (mapItem['quantity'] ?? 0).toInt();
            revenue += price * quantity;
          } catch (_) {}
        }
      }
      totalRevenue = revenue;
    } catch (e) {}
  }

  // ================= SEARCH ORDERS =================
  void searchOrders(String query) {
    if (query.trim().isEmpty) {
      filteredOrders = List.from(orders);
    } else {
      filteredOrders = orders.where((order) {
        final buyerName = (order['buyerName'] ?? '').toString().toLowerCase();
        final orderId = (order['rowId'] ?? '').toString().toLowerCase();
        return buyerName.contains(query.toLowerCase()) ||
            orderId.contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  // ================= FETCH SELLERS =================
  Future<void> fetchSellers() async {
    try {
      isLoadingSellers = true;
      notifyListeners();

      // ✅ paginated — shows all sellers
      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.userCollection,
        queries: [
          Query.equal("role", "seller"),
          Query.orderDesc("\$createdAt"),
        ],
      );

      sellers = allRows;
      filteredSellers = List.from(sellers);
    } catch (e) {
    } finally {
      isLoadingSellers = false;
      notifyListeners();
    }
  }

  // ================= SEARCH SELLERS =================
  void searchSellers(String query) {
    if (query.trim().isEmpty) {
      filteredSellers = List.from(sellers);
    } else {
      filteredSellers = sellers.where((seller) {
        final name = (seller['fullName'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  // ================= FETCH SELLER PRODUCTS FOR ADMIN =================
  Future<void> fetchSellerProductsByUserId(String sellerId) async {
    try {
      isLoadingSellerProducts = true;
      notifyListeners();

      // ✅ paginated — shows all seller products
      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.product,
        queries: [
          Query.equal("userId", sellerId),
          Query.orderDesc("\$createdAt"),
        ],
      );

      sellerProducts =
          allRows.map((row) => {...row, "rowId": row['\$id']}).toList();
      productCount = sellerProducts.length;
    } catch (e) {
      debugPrint("FETCH SELLER PRODUCTS ERROR: $e");
    } finally {
      isLoadingSellerProducts = false;
      notifyListeners();
    }
  }

  // ================= FETCH ON DELIVERY ORDERS =================
  Future<void> fetchAllOrdersOnDelivery() async {
    try {
      isLoadingOnDelivery = true;
      notifyListeners();

      // ✅ paginated
      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.order,
        queries: [
          Query.equal("status", "ondelivery"),
          Query.orderDesc("\$createdAt"),
        ],
      );

      onDeliveryOrders = allRows.map((row) {
        final data = Map<String, dynamic>.from(row);
        data["rowId"] = row['\$id'];
        final rawItems = data['cartItems'] as List<dynamic>? ?? [];
        data['cartItems'] = rawItems.map((item) {
          if (item is String)
            return Map<String, dynamic>.from(jsonDecode(item));
          return Map<String, dynamic>.from(item);
        }).toList();
        return data;
      }).toList();
    } catch (e) {
      onDeliveryOrders = [];
    } finally {
      isLoadingOnDelivery = false;
      notifyListeners();
    }
  }

  // ================= FETCH NEW PLACED ORDERS =================
  Future<void> fetchAllNewPlacedOrders() async {
    try {
      isLoadingOnDelivery = true;
      notifyListeners();

      // ✅ paginated
      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.order,
        queries: [
          Query.equal("status", "order placed"),
          Query.orderDesc("\$createdAt"),
        ],
      );

      onDeliveryOrders = allRows.map((row) {
        final data = Map<String, dynamic>.from(row);
        data["rowId"] = row['\$id'];
        final rawItems = data['cartItems'] as List<dynamic>? ?? [];
        data['cartItems'] = rawItems.map((item) {
          if (item is String)
            return Map<String, dynamic>.from(jsonDecode(item));
          return Map<String, dynamic>.from(item);
        }).toList();
        return data;
      }).toList();
    } catch (e) {
      onDeliveryOrders = [];
    } finally {
      isLoadingOnDelivery = false;
      notifyListeners();
    }
  }

  // ================= FETCH DELIVERED ORDERS =================
  Future<void> fetchdeliveredOrders() async {
    try {
      isLoadingOnDelivery = true;
      notifyListeners();

      // ✅ paginated
      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.order,
        queries: [
          Query.equal("status", "delivered"),
          Query.orderDesc("\$createdAt"),
        ],
      );

      onDeliveryOrders = allRows.map((row) {
        final data = Map<String, dynamic>.from(row);
        data["rowId"] = row['\$id'];
        final rawItems = data['cartItems'] as List<dynamic>? ?? [];
        data['cartItems'] = rawItems.map((item) {
          if (item is String)
            return Map<String, dynamic>.from(jsonDecode(item));
          return Map<String, dynamic>.from(item);
        }).toList();
        return data;
      }).toList();
    } catch (e) {
      ;
      onDeliveryOrders = [];
    } finally {
      isLoadingOnDelivery = false;
      notifyListeners();
    }
  }

  // ================= FETCH HOME ORDER COUNTS =================
  Future<void> fetchHomeOrderCounts() async {
    try {
      // ✅ paginated — needs all statuses to compute counts correctly
      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.order,
        queries: [
          Query.select(['status']),
        ],
      );

      orders = allRows.map((row) => {'status': row['status']}).toList();
      notifyListeners();
    } catch (e) {}
  }
}
