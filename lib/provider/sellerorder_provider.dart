import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/apihelper.dart';
import 'package:peereess/databases/config/appwrite.dart';

class SellerOrderProvider extends ChangeNotifier {
  bool isLoadingOrders = false;
  String? updatingOrderId; // ✅ tracks which specific order is being updated

  int orderCount = 0;
  List<Map<String, dynamic>> sellerOrders = [];

  // ===================== SERVER FUNCTION CALL =====================
  Future<Map<String, dynamic>> _callFunction(Map<String, dynamic> body) async {
    final res = await ApiHelper.guard(
      () => AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: json.encode(body),
      ),
    );
    if (res == null) throw Exception('Session expired. Please log in again.');
    return json.decode(res.responseBody) as Map<String, dynamic>;
  }

  // ===================== PAGINATION HELPER =====================
  Future<List<Map<String, dynamic>>> _fetchAllRows({
    required String tableId,
    List<String> extraQueries = const [],
  }) async {
    const int pageSize = 100;
    final List<Map<String, dynamic>> all = [];
    String? lastId;

    while (true) {
      final queries = [
        Query.orderDesc('\$createdAt'),
        Query.limit(pageSize),
        if (lastId != null) Query.cursorAfter(lastId),
        ...extraQueries,
      ];

      final result = await ApiHelper.guard(
        () => AppwriteConfig.tablesDB.listRows(
          databaseId: AppwriteConfig.databaseId,
          tableId: tableId,
          queries: queries,
        ),
      );

      if (result == null) return all;

      final rows = result.rows;
      all.addAll(
        rows.map((row) {
          final map = Map<String, dynamic>.from(row.data);
          map[r'$id'] = row.$id;
          return map;
        }),
      );

      if (rows.length < pageSize) break;
      lastId = rows.last.$id;
    }

    return all;
  }

  // ===================== FETCH SELLER ORDERS =====================
  Future<void> fetchSellerOrders(List<String> sellerProductIds) async {
    try {
      isLoadingOrders = true;
      notifyListeners();

      final allRows = await _fetchAllRows(tableId: AppwriteConfig.order);

      sellerOrders = allRows.where((row) {
        final cartItems = row['cartItems'] as List<dynamic>? ?? [];
        return cartItems.any((item) {
          final map = item is String
              ? Map<String, dynamic>.from(jsonDecode(item))
              : Map<String, dynamic>.from(item);
          return sellerProductIds.contains(map['productId']);
        });
      }).map((row) {
        return {...row, 'rowId': row['\$id']};
      }).toList();

      orderCount = sellerOrders.length;
    } catch (e) {
      // debugPrint("FETCH SELLER ORDERS ERROR: $e");
    } finally {
      isLoadingOrders = false;
      notifyListeners();
    }
  }

  // ===================== UPDATE ORDER STATUS =====================
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    required String requesterId,
  }) async {
    try {
      updatingOrderId = orderId; // ✅ only this order shows loading
      notifyListeners();

      final result = await _callFunction({
        'action': 'updateOrderStatus',
        'userId': requesterId,
        'orderId': orderId,
        'status': status,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to update order status.');
      }

      final index = sellerOrders.indexWhere(
        (order) => order['rowId'] == orderId,
      );
      if (index != -1) {
        sellerOrders[index]['status'] = status;
      }
    } catch (e) {
      // debugPrint("UPDATE ORDER STATUS ERROR: $e");
      rethrow;
    } finally {
      updatingOrderId = null; // ✅ clear after done
      notifyListeners();
    }
  }

  // ===================== FETCH ALL ORDERS (admin) =====================
  Future<void> fetchAllOrders() async {
    isLoadingOrders = true;
    notifyListeners();
    try {
      final allRows = await _fetchAllRows(tableId: AppwriteConfig.order);
      sellerOrders = allRows;
    } catch (e) {
      // debugPrint("FETCH ALL ORDERS ERROR: $e");
    } finally {
      isLoadingOrders = false;
      notifyListeners();
    }
  }

  // ===================== LOCAL CALCULATIONS =====================
  double calculateTotalRevenue(List<String> sellerProductIds) {
    double total = 0;
    for (final order in sellerOrders) {
      if (order['status'] != 'completed') continue;
      final cartItems = order['cartItems'] as List<dynamic>? ?? [];
      for (final item in cartItems) {
        final map = item is String
            ? Map<String, dynamic>.from(jsonDecode(item))
            : Map<String, dynamic>.from(item);
        if (sellerProductIds.contains(map['productId'])) {
          total += (map['price'] ?? 0).toDouble() * (map['quantity'] ?? 0);
        }
      }
    }
    return total;
  }

  int getActiveOrdersCount(List<String> sellerProductIds) {
    int count = 0;
    for (final order in sellerOrders) {
      final cartItems = order['cartItems'] as List<dynamic>? ?? [];
      final hasSellerItem = cartItems.any((item) {
        final map = item is String
            ? Map<String, dynamic>.from(jsonDecode(item))
            : Map<String, dynamic>.from(item);
        return sellerProductIds.contains(map['productId']);
      });
      if (!hasSellerItem) continue;
      final status = (order['status'] ?? '').toString().toLowerCase();
      if (status == 'order placed' || status == 'shipped') count++;
    }
    return count;
  }
}
