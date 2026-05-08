import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:peereess/databases/config/apihelper.dart';
import 'package:peereess/databases/config/appwrite.dart';

class UserProductViewProvider with ChangeNotifier {
  final Set<String> _viewedProducts = {};
  final Map<String, DateTime> _viewTimestamps = {};
  bool _isLoaded = false;

  static const int _viewCooldownMinutes = 10;

  Set<String> get viewedProductIds => Set.unmodifiable(_viewedProducts);
  bool get isLoaded => _isLoaded;

  bool hasViewed(String productId) => _viewedProducts.contains(productId);

  bool _shouldTrack(String productId) {
    final lastViewed = _viewTimestamps[productId];
    if (lastViewed == null) return true;
    return DateTime.now().difference(lastViewed).inMinutes >
        _viewCooldownMinutes;
  }

  /// Call this once on login / app start
  Future<void> loadViewedProducts(String userId) async {
    if (_isLoaded) return;

    try {
      final rows = await ApiHelper.guard(
        () => AppwriteConfig.tablesDB.listRows(
          databaseId: AppwriteConfig.databaseId,
          tableId: AppwriteConfig.productViews,
          queries: [
            Query.equal('userId', userId),
            Query.orderDesc('\$createdAt'),
            Query.limit(500),
          ],
        ),
      );

      if (rows == null) return;

      for (final row in rows.rows) {
        final productId = row.data['productId'] as String?;
        final rawTs = row.data['timestamp'] as String?;
        if (productId == null) continue;

        _viewedProducts.add(productId);
        if (rawTs != null) {
          _viewTimestamps[productId] =
              DateTime.tryParse(rawTs) ?? DateTime.now();
        }
      }

      _isLoaded = true;
      notifyListeners();
    } on AppwriteException catch (e) {
      // debugPrint('LOAD VIEWS ERROR: $e');
      if (e.code == 401) rethrow;
    } catch (e) {
      // debugPrint('LOAD VIEWS ERROR: $e');
    }
  }

  /// Optimistic local update → then persist via server function
  Future<void> trackProductView({
    required String userId,
    required String productId,
  }) async {
    if (!_shouldTrack(productId)) return;

    // ── Optimistic update ──
    _viewedProducts.add(productId);
    _viewTimestamps[productId] = DateTime.now();
    notifyListeners();

    await _saveToBackend(userId, productId);
  }

  /// Calls the server function — server owns cooldown check,
  /// view row creation, and viewCount increment
  Future<void> _saveToBackend(String userId, String productId) async {
    try {
      final res = await ApiHelper.guard(
        () => AppwriteConfig.functions.createExecution(
          functionId: AppwriteConfig.productFunction,
          body: json.encode({
            'action': 'trackProductView',
            'userId': userId,
            'productId': productId,
          }),
        ),
      );

      if (res == null) return; // session expired — non-fatal, local state kept

      final result = json.decode(res.responseBody) as Map<String, dynamic>;

      if (result['skipped'] == true) {
        // debugPrint('⏭️ View skipped (server cooldown): $productId');
      } else if (result['status'] == true) {
      } else {
        // debugPrint('⚠️ View not saved: ${result['message']}');
      }
    } on AppwriteException catch (e) {
      // debugPrint('SAVE VIEW ERROR: $e'); // non-fatal
    } catch (e) {
      // debugPrint('SAVE VIEW ERROR: $e');
    }
  }

  /// Call on logout
  void clearViews() {
    _viewedProducts.clear();
    _viewTimestamps.clear();
    _isLoaded = false;
    notifyListeners();
  }
}
