import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/ordermodel.dart';
import 'package:peereess/model/refundmodel.dart';

class RefundProvider extends ChangeNotifier {
  final List<RefundModel> _refunds = [];
  bool _isLoading = false;

  List<RefundModel> get refunds => _refunds;
  bool get isLoading => _isLoading;

  /// ================================
  /// FETCH USER REFUNDS
  /// ================================
  Future<void> fetchUserRefunds({required String userId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final res = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({'action': 'fetchUserRefunds', 'userId': userId}),
      );

      final response = jsonDecode(res.responseBody);

      if (response['status'] == true) {
        // ✅ Clear and addAll instead of assigning to final
        _refunds
          ..clear()
          ..addAll(
            (response['data'] as List)
                .map((e) => RefundModel.fromMap(e))
                .toList(),
          );
      }
    } catch (e) {
      // debugPrint("FETCH ERROR: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================================
  /// FETCH REFUNDS BY ORDER
  /// ================================
  Future<void> fetchRefundsByOrder({
    required String userId,
    required String orderId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final res = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({
          'action': 'fetchRefundsByOrder',
          'userId': userId,
          'orderId': orderId,
        }),
      );

      final result = jsonDecode(res.responseBody);

      if (result['status'] == true) {
        _refunds
          ..clear()
          ..addAll(
            (result['refunds'] as List)
                .map((r) => RefundModel.fromMap(r, refundId: r['refundId']))
                .toList(),
          );
      }
    } catch (e) {
      // debugPrint("FETCH ORDER REFUNDS ERROR: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================================
  /// CREATE REFUND
  /// ================================
  Future<bool> createRefund({
    required String userId,
    required String orderId,
    required List<OrderItem> refundItems,
    required double refundAmount,
    String? reason,
    String? refundMethod,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final encodedItems = RefundModel.encodeItems(refundItems);

      final res = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({
          'action': 'createRefund',
          'userId': userId,
          'orderId': orderId,
          'refundItems': encodedItems,
          'refundAmount': refundAmount,
          'reason': reason,
          'refundMethod': refundMethod,
        }),
      );

      final result = jsonDecode(res.responseBody);

      return result['status'] == true;
    } catch (e) {
      // debugPrint("CREATE REFUND ERROR: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================================
  /// ADMIN FETCH ALL REFUNDS
  /// ================================
  Future<void> getAdminRefunds({required String userId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final res = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({'action': 'getAdminRefunds', 'userId': userId}),
      );

      final result = jsonDecode(res.responseBody);

      if (result['status'] == true) {
        _refunds
          ..clear()
          ..addAll(
            (result['refunds'] as List)
                .map((r) => RefundModel.fromMap(r, refundId: r['refundId']))
                .toList(),
          );
      }
    } catch (e) {
      // debugPrint("FETCH ADMIN REFUNDS ERROR: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================================
  /// ADMIN UPDATE REFUND STATUS
  /// ================================
  Future<bool> updateRefundStatus({
    required String userId,
    required String refundId,
    required String status,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final res = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({
          'action': 'updateRefundStatus',
          'userId': userId,
          'refundId': refundId,
          'status': status,
        }),
      );

      final result = jsonDecode(res.responseBody);

      if (result['status'] == true) {
        final index = _refunds.indexWhere((r) => r.refundId == refundId);

        if (index != -1) {
          _refunds[index] = _refunds[index].copyWith(status: status);
        }

        return true;
      }

      return false;
    } catch (e) {
      // debugPrint("UPDATE REFUND STATUS ERROR: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================================
  /// CLEAR LOCAL LIST
  /// ================================
  void clearRefunds() {
    _refunds.clear();
    notifyListeners();
  }
}
