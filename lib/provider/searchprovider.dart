import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:peereess/databases/config/errorhandling.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/model/searchmodel.dart';
import 'package:peereess/databases/config/apihelper.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/databases/config/error.dart';

// ✅ Search type enum
enum SearchType { product, category, seller }

class SearchProvider extends ChangeNotifier {
  /// ================= DATA =================
  final List<SearchModel> _allSearchItems = [];
  final List<SearchModel> _suggestions = [];
  final List<ProductModel> _results = [];
  final List<String> _recentSearches = [];
  List<Map<String, dynamic>> sellerOrders = [];

  String _query = '';
  bool _showSuggestions = false;

  bool isFetchingSearches = false;
  String? errorMessage;

  /// ================= GETTERS =================
  List<SearchModel> get suggestions => _suggestions;
  List<ProductModel> get results => _results;
  List<String> get recentSearches => _recentSearches;
  bool get showSuggestions => _showSuggestions;
  String get currentQuery => _query;

  /// ================= API HELPER =================
  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    try {
      final res = await ApiHelper.guard(
        () => AppwriteConfig.functions.createExecution(
          functionId: AppwriteConfig.productFunction,
          body: json.encode(body),
        ),
      );

      if (res == null) throw Exception('Session expired');

      return json.decode(res.responseBody);
    } catch (e) {
      rethrow;
    }
  }

  /// ================= INIT =================
  void setProducts(List<ProductModel> products) {
    _allSearchItems.clear();
    final seenCategories = <String>{};
    final seenSellers = <String>{};

    for (final product in products) {
      // ── Every product title ──
      _allSearchItems.add(SearchModel(
        productId: product.productId,
        title: product.title,
        category: product.category,
        imageUrl: product.imageUrl,
        sellerName: product.sellerName,
        type: SearchType.product,
      ));

      // ── Every unique category ──
      if (product.category.isNotEmpty && seenCategories.add(product.category)) {
        _allSearchItems.add(SearchModel(
          productId: '',
          title: product.category,
          category: product.category,
          imageUrl: [],
          sellerName: '',
          type: SearchType.category,
        ));
      }

      // ── Every unique seller ──
      if (product.sellerName.isNotEmpty &&
          seenSellers.add(product.sellerName)) {
        _allSearchItems.add(SearchModel(
          productId: '',
          title: product.sellerName,
          category: '',
          imageUrl: [],
          sellerName: product.sellerName,
          type: SearchType.seller,
        ));
      }
    }

    notifyListeners();
  }

  void showInitialSuggestions() {
    _showSuggestions = true;
    notifyListeners();
  }

  void hideSuggestions() {
    _showSuggestions = false;
    notifyListeners();
  }

  /// ================= QUERY =================
  void onQueryChanged(String value) {
    _query = value.trim().toLowerCase();

    if (_query.isEmpty) {
      _suggestions.clear();
      _results.clear();
      _showSuggestions = true;
      notifyListeners();
      return;
    }

    // ✅ Search across title, category, and sellerName — no arbitrary cap
    _suggestions
      ..clear()
      ..addAll(
        _allSearchItems.where((item) {
          final q = _query;
          return item.title.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q) ||
              item.sellerName.toLowerCase().contains(q);
        }),
      );

    _showSuggestions = true;
    notifyListeners();
  }

  /// ================= SERVER: SAVE SEARCH =================
  Future<void> saveSearchToServer({
    required String userId,
    required String query,
  }) async {
    try {
      await _call({
        'action': 'saveUserSearch',
        'userId': userId,
        'query': query,
      });
    } catch (_) {
      // silent fail (don't break UX)
    }
  }

  /// ================= SERVER: FETCH SEARCHES =================
  Future<void> fetchUserSearches({required String userId}) async {
    try {
      isFetchingSearches = true;
      notifyListeners();

      final result = await _call({
        'action': 'getUserSearches',
        'userId': userId,
      });

      if (result['status'] != true) {
        throw Exception(result['message']);
      }

      final data = result['data'] as List<dynamic>? ?? [];

      _recentSearches
        ..clear()
        ..addAll(data.map((e) => e.toString()));
    } on SocketException {
      errorMessage = 'No internet connection';
    } catch (e) {
      errorMessage = AppError.from(e).message;
    } finally {
      isFetchingSearches = false;
      notifyListeners();
    }
  }

  /// ================= RECENT SEARCHES =================
  Future<void> addRecentSearch(String query, String userId) async {
    final q = query.trim();
    if (q.isEmpty) return;

    _recentSearches.remove(q);
    _recentSearches.insert(0, q);

    if (_recentSearches.length > 15) {
      _recentSearches.removeLast();
    }

    notifyListeners();

    // ✅ Save to server
    await saveSearchToServer(userId: userId, query: q);
  }

  Future<void> clearRecentSearches(String userId) async {
    _recentSearches.clear();
    notifyListeners();

    try {
      await _call({
        'action': 'clearUserSearches',
        'userId': userId,
      });
    } catch (_) {}
  }

  /// ================= CLEAR =================
  void clearSearch() {
    _query = '';
    _suggestions.clear();
    _results.clear();
    _showSuggestions = false;
    notifyListeners();
  }

  void selectSuggestion(
    SearchModel item,
    List<ProductModel> allProducts,
    String userId,
  ) async {
    _results.clear();

    switch (item.type) {
      case SearchType.product:
        _results.addAll(
          allProducts.where((p) => p.productId == item.productId),
        );
        break;

      case SearchType.category:
        _results.addAll(
          allProducts.where(
            (p) => p.category.toLowerCase() == item.title.toLowerCase(),
          ),
        );
        break;

      case SearchType.seller:
        _results.addAll(
          allProducts.where(
            (p) => p.sellerName.toLowerCase() == item.title.toLowerCase(),
          ),
        );
        break;
    }

    _showSuggestions = false;
    notifyListeners();

    // ✅ Save selected search
    await addRecentSearch(item.title, userId);
  }

  /// ================= SELLER ORDERS =====================
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
      if (status == 'order placed' || status == 'shipped') {
        // ✅ was 'ondelivery'
        count++;
      }
    }

    return count;
  }
}
