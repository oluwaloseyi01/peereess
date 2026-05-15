import 'dart:convert';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:peereess/databases/config/apihelper.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/compute.dart';
import 'package:peereess/provider/productranking.dart';

class ProductProvider extends ChangeNotifier {
  final List<ProductModel> _products = [];
  final List<ProductModel> _categoryProducts = [];
  final List<ProductModel> _searchResults = [];
  final List<ProductModel> _onboardingProducts = [];
  bool _isOnboardingLoading = false;
  List<ProductModel> get onboardingProducts => _onboardingProducts;
  bool get isOnboardingLoading => _isOnboardingLoading;

  // ── Home pagination ──────────────────────────────────
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  // ── Category pagination ───────────────────────────────
  bool _isCategoryLoading = false;
  bool _isCategoryFetchingMore = false;
  bool _categoryHasMore = true;
  int _categoryOffset = 0;

  // ── Search pagination ─────────────────────────────────
  bool _isSearchLoading = false;
  bool _isSearchFetchingMore = false;
  bool _searchHasMore = true;
  int _searchOffset = 0;
  String _lastQuery = '';

  final int _limit = 24;

  Set<String> likedProductIds = {};

  // ── Home getters ─────────────────────────────────────
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;

  // ── Category getters ─────────────────────────────────
  List<ProductModel> get categoryProducts => _categoryProducts;
  bool get isCategoryLoading => _isCategoryLoading;
  bool get isCategoryFetchingMore => _isCategoryFetchingMore;
  bool get categoryHasMore => _categoryHasMore;

  final List<ProductModel> _exploreProducts = [];
  bool _isExploreLoading = false;
  bool _isExploreFetchingMore = false;
  bool _exploreHasMore = true;
  int _exploreOffset = 0;

  // ── Search getters ────────────────────────────────────
  List<ProductModel> get searchResults => _searchResults;
  bool get isSearchLoading => _isSearchLoading;
  bool get isSearchFetchingMore => _isSearchFetchingMore;
  bool get searchHasMore => _searchHasMore;

  Future<void> loadUserLikes(String userId) async {
    likedProductIds = await getUserLikedProductIds(userId);
    notifyListeners();
  }

  // ===================== SERVER FUNCTION CALL =====================
  // ✅ Only used for authenticated actions (like, delete, etc.)
  // Returns null silently if the user is a guest — never throws session error
  Future<Map<String, dynamic>?> _callFunction(Map<String, dynamic> body) async {
    final res = await ApiHelper.guard(
      () => AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: json.encode(body),
      ),
    );
    if (res == null) return null; // ✅ guest or session expired — silent
    return json.decode(res.responseBody) as Map<String, dynamic>;
  }

  // ===================== PUBLIC CLIENT (no auth) =====================
  // A fresh TablesDB with no session — used for all public product reads.
  // Guests never trigger a 401 redirect loop when browsing home.
  static TablesDB _publicTablesDB() {
    final client = Client()
      ..setEndpoint(AppwriteConfig.endPoint)
      ..setProject(AppwriteConfig.appwriteProjectId);
    return TablesDB(client);
  }

  // ===================== GET PRODUCTS WITH PAGINATION =====================
  Future<void> getProducts({
    bool loadMore = false,
    bool isRefresh = false,
    Set<String> viewedIds = const {},
  }) async {
    if (_isFetchingMore) return;

    if (!loadMore) {
      _isLoading = true;
      _offset = 0;
      _products.clear();
      _hasMore = true;
    }

    if (!_hasMore) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      // ✅ Use public client — works for both guests and logged-in users
      final rows = await _publicTablesDB().listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        queries: [
          Query.equal('status', 'approved'),
          Query.orderDesc("\$createdAt"),
          Query.limit(_limit),
          Query.offset(_offset),
        ],
      );

      final newProducts =
          rows.rows.map((row) => ProductModel.fromMap(row.data)).toList();

      if (!loadMore && !isRefresh) {
        newProducts.shuffle();
      }

      _products.addAll(newProducts);
      notifyListeners();

      _offset += newProducts.length;
      if (newProducts.length < _limit) _hasMore = false;

      if (isRefresh) {
        final snapshot = List<ProductModel>.from(_products);
        final ranked = await ProductRanker.rankAsync(snapshot, viewedIds);
        _products
          ..clear()
          ..addAll(ranked);
        notifyListeners();
      }
    } catch (e) {
      // debugPrint("GET PRODUCTS ERROR: $e");
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts({Set<String> viewedIds = const {}}) =>
      getProducts(isRefresh: true, viewedIds: viewedIds);

  // ===================== CATEGORY PRODUCTS =====================
  Future<void> getProductsByCategory(
    String category, {
    bool loadMore = false,
    Set<String> viewedIds = const {},
  }) async {
    if (_isCategoryFetchingMore) return;

    if (!loadMore) {
      _isCategoryLoading = true;
      _categoryOffset = 0;
      _categoryProducts.clear();
      _categoryHasMore = true;
    }

    if (!_categoryHasMore) return;

    _isCategoryFetchingMore = true;
    notifyListeners();

    try {
      final rows = await _publicTablesDB().listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        queries: [
          Query.equal('category', category),
          Query.equal('status', 'approved'),
          Query.orderDesc("\$createdAt"),
          Query.limit(_limit),
          Query.offset(_categoryOffset),
        ],
      );

      final newProducts =
          rows.rows.map((row) => ProductModel.fromMap(row.data)).toList();

      _categoryProducts.addAll(newProducts);

      final currentList = List<ProductModel>.from(_categoryProducts);

      Future(() async {
        final ranked = await rankProductsInBackground(currentList, viewedIds);
        _categoryProducts
          ..clear()
          ..addAll(ranked);
        notifyListeners();
      });

      _categoryOffset += newProducts.length;
      if (newProducts.length < _limit) _categoryHasMore = false;
    } catch (e) {
      // debugPrint("GET CATEGORY PRODUCTS ERROR: $e");
    } finally {
      _isCategoryLoading = false;
      _isCategoryFetchingMore = false;
      notifyListeners();
    }
  }

  void clearCategoryProducts() {
    _categoryProducts.clear();
    _categoryOffset = 0;
    _categoryHasMore = true;
    _isCategoryLoading = false;
    _isCategoryFetchingMore = false;
    notifyListeners();
  }

  List<ProductModel> get exploreProducts => _exploreProducts;
  bool get isExploreLoading => _isExploreLoading;
  bool get isExploreFetchingMore => _isExploreFetchingMore;
  bool get exploreHasMore => _exploreHasMore;

  void clearExploreProducts() {
    _exploreProducts.clear();
    _exploreOffset = 0;
    _exploreHasMore = true;
    _isExploreLoading = false;
    _isExploreFetchingMore = false;
    notifyListeners();
  }

  Future<void> getExploreProducts(
    String category, {
    bool loadMore = false,
    Set<String> viewedIds = const {},
  }) async {
    if (_isExploreFetchingMore) return;

    if (!loadMore) {
      _isExploreLoading = true;
      _exploreOffset = 0;
      _exploreProducts.clear();
      _exploreHasMore = true;
    }

    if (!_exploreHasMore) return;

    _isExploreFetchingMore = true;
    notifyListeners();

    try {
      final rows = await _publicTablesDB().listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        queries: [
          Query.equal('category', category),
          Query.equal('status', 'approved'),
          Query.orderDesc("\$createdAt"),
          Query.limit(_limit),
          Query.offset(_exploreOffset),
        ],
      );

      final newProducts =
          rows.rows.map((row) => ProductModel.fromMap(row.data)).toList();

      _exploreProducts.addAll(newProducts);
      notifyListeners();

      final snapshot = List<ProductModel>.from(_exploreProducts);

      Future(() async {
        final ranked = await rankProductsInBackground(snapshot, viewedIds);
        _exploreProducts
          ..clear()
          ..addAll(ranked);
        notifyListeners();
      });

      _exploreOffset += newProducts.length;
      if (newProducts.length < _limit) _exploreHasMore = false;
    } catch (e) {
      // debugPrint("GET EXPLORE PRODUCTS ERROR: $e");
    } finally {
      _isExploreLoading = false;
      _isExploreFetchingMore = false;
      notifyListeners();
    }
  }

  // ===================== SEARCH PRODUCTS =====================
  Future<void> searchProducts(String query, {bool loadMore = false}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    if (_isSearchFetchingMore) return;

    if (!loadMore || trimmed != _lastQuery) {
      _isSearchLoading = true;
      _searchOffset = 0;
      _searchResults.clear();
      _searchHasMore = true;
      _lastQuery = trimmed;
    }

    if (!_searchHasMore) return;

    _isSearchFetchingMore = true;
    notifyListeners();

    try {
      final rows = await _publicTablesDB().listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        queries: [
          Query.equal('status', 'approved'),
          Query.contains('title', trimmed),
          Query.orderDesc("\$createdAt"),
          Query.limit(_limit),
          Query.offset(_searchOffset),
        ],
      );

      final newProducts =
          rows.rows.map((row) => ProductModel.fromMap(row.data)).toList();

      _searchResults.addAll(newProducts);
      _searchOffset += newProducts.length;
      if (newProducts.length < _limit) _searchHasMore = false;
    } catch (e) {
      // debugPrint("SEARCH PRODUCTS ERROR: $e");
    } finally {
      _isSearchLoading = false;
      _isSearchFetchingMore = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults.clear();
    _searchHasMore = true;
    _searchOffset = 0;
    _lastQuery = '';
    notifyListeners();
  }

  // ===================== GET SINGLE PRODUCT =====================
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final row = await _publicTablesDB().getRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        rowId: productId,
      );
      return ProductModel.fromMap(row.data);
    } catch (e) {
      // debugPrint("GET PRODUCT ERROR: $e");
      return null;
    }
  }

  // ===================== DELETE PRODUCT =====================
  // ✅ Authenticated action — uses _callFunction (requires login)
  Future<void> deleteProduct(String productId, String userId) async {
    final result = await _callFunction({
      'action': 'deleteProduct',
      'userId': userId,
      'productId': productId,
    });

    if (result == null) throw Exception('Not authenticated.');
    if (result['status'] != true) {
      throw Exception(result['message'] ?? 'Failed to delete product.');
    }

    _products.removeWhere((p) => p.productId == productId);
    _categoryProducts.removeWhere((p) => p.productId == productId);
    _searchResults.removeWhere((p) => p.productId == productId);
    notifyListeners();
  }

  // ===================== TOGGLE LIKE =====================
  // ✅ Authenticated action — requires login
  Future<void> toggleLike({
    required String productId,
    required String userId,
  }) async {
    final lists = [_products, _categoryProducts, _searchResults];

    final Map<List<ProductModel>, int> foundIndices = {};
    final Map<List<ProductModel>, ProductModel> originals = {};

    for (final list in lists) {
      final index = list.indexWhere((p) => p.productId == productId);
      if (index != -1) {
        foundIndices[list] = index;
        originals[list] = list[index];
      }
    }

    if (foundIndices.isEmpty) return;

    final sourceList = foundIndices.keys.first;
    final product = originals[sourceList]!;

    final List<String> likedBy = List<String>.from(product.likedBy);
    final bool isLiking = !likedBy.contains(userId);

    if (isLiking) {
      likedProductIds.add(productId);
      likedBy.add(userId);
    } else {
      likedProductIds.remove(productId);
      likedBy.remove(userId);
    }

    final updated = product.copyWith(
      likedBy: likedBy,
      likes: isLiking
          ? product.likes + 1
          : ((product.likes - 1).clamp(0, 999999) as int),
    );

    for (final entry in foundIndices.entries) {
      final list = entry.key;
      list.removeWhere((p) => p.productId == productId);
      list.insert(0, updated);
    }

    notifyListeners();

    try {
      final result = await _callFunction({
        'action': 'toggleLike',
        'userId': userId,
        'productId': productId,
      });

      if (result == null) {
        // Not authenticated — rollback optimistic update
        _rollback(foundIndices, originals);
        notifyListeners();
        return;
      }

      if (result['status'] != true) throw Exception('Failed to toggle like');

      final data = result['data'] ?? {};
      final bool backendLiked = data['liked'] ?? isLiking;
      final int backendLikes = data['likes'] ?? updated.likes;

      final correctedLikedBy = List<String>.from(updated.likedBy);
      if (backendLiked && !correctedLikedBy.contains(userId)) {
        correctedLikedBy.add(userId);
      } else if (!backendLiked && correctedLikedBy.contains(userId)) {
        correctedLikedBy.remove(userId);
      }

      if (backendLikes != updated.likes || backendLiked != isLiking) {
        final correctedProduct = updated.copyWith(
          likedBy: correctedLikedBy,
          likes: backendLikes,
        );
        for (final entry in foundIndices.entries) {
          final list = entry.key;
          list.removeWhere((p) => p.productId == productId);
          list.insert(0, correctedProduct);
        }
        notifyListeners();
      }
    } catch (e) {
      _rollback(foundIndices, originals);
      notifyListeners();
      // debugPrint("TOGGLE LIKE ERROR: $e");
    }
  }

  void _rollback(
    Map<List<ProductModel>, int> foundIndices,
    Map<List<ProductModel>, ProductModel> originals,
  ) {
    for (final entry in foundIndices.entries) {
      final list = entry.key;
      final originalItem = originals[list]!;
      final originalIndex = entry.value;
      list.removeWhere((p) => p.productId == originalItem.productId);
      if (originalIndex >= 0 && originalIndex <= list.length) {
        list.insert(originalIndex, originalItem);
      } else {
        list.add(originalItem);
      }
    }
  }

  // ===================== CLEAR ALL LIKES =====================
  Future<void> clearAllLikes({required String userId}) async {
    try {
      final result = await _callFunction({
        'action': 'clearAllLikes',
        'userId': userId,
      });

      if (result == null || result['status'] != true) return;

      likedProductIds.clear();

      void resetLikesInList(List<ProductModel> list) {
        for (int i = 0; i < list.length; i++) {
          final p = list[i];
          if (p.likedBy.contains(userId)) {
            list[i] = p.copyWith(
              likedBy: List<String>.from(p.likedBy)..remove(userId),
              likes: p.likes - 1 >= 0 ? p.likes - 1 : 0,
            );
          }
        }
      }

      resetLikesInList(_products);
      resetLikesInList(_categoryProducts);
      resetLikesInList(_searchResults);
      resetLikesInList(_exploreProducts);
      resetLikesInList(_onboardingProducts);

      notifyListeners();
    } catch (e) {
      // debugPrint("CLEAR ALL LIKES ERROR: $e");
    }
  }

  void clearLikesLocally() {
    likedProductIds.clear();

    void resetList(List<ProductModel> list) {
      for (int i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(likedBy: [], likes: 0);
      }
    }

    resetList(_products);
    resetList(_categoryProducts);
    resetList(_searchResults);
    resetList(_exploreProducts);
    resetList(_onboardingProducts);

    notifyListeners();
  }

  Future<Set<String>> getUserLikedProductIds(String userId) async {
    try {
      final result = await _callFunction({
        'action': 'getUserLikes',
        'userId': userId,
      });
      if (result != null && result['status'] == true) {
        final List data = result['data'] ?? [];
        return data.map((e) => e['productId'].toString()).toSet();
      }
      return {};
    } catch (e) {
      // debugPrint("GET USER LIKES ERROR: $e");
      return {};
    }
  }

  Future<void> getPublicOnboardingProducts() async {
    if (_isOnboardingLoading || _onboardingProducts.isNotEmpty) return;

    _isOnboardingLoading = true;
    notifyListeners();

    try {
      final client = Client()
        ..setEndpoint(AppwriteConfig.endPoint)
        ..setProject(AppwriteConfig.appwriteProjectId);

      final functions = Functions(client);

      final execution = await functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: json.encode({'action': 'getOnboardingProducts'}),
      );

      final result =
          json.decode(execution.responseBody) as Map<String, dynamic>;

      if (result['status'] != true) {
        throw Exception(
          result['message'] ?? 'Failed to load onboarding products.',
        );
      }

      final rawList = result['products'] as List<dynamic>;

      _onboardingProducts
        ..clear()
        ..addAll(
          rawList.map((e) => ProductModel.fromMap(e as Map<String, dynamic>)),
        );
    } catch (e) {
      // debugPrint("ONBOARDING PRODUCTS ERROR: $e");
    } finally {
      _isOnboardingLoading = false;
      notifyListeners();
    }
  }

  void clearOnboardingProducts() {
    _onboardingProducts.clear();
    notifyListeners();
  }

  void clearProducts() {
    _products.clear();
    _hasMore = true;
    _isFetchingMore = false;
    _isLoading = false;
    _offset = 0;
    notifyListeners();
  }

  // ===================== SEARCH BY CATEGORY =====================
  Future<void> searchByCategory(String category,
      {bool loadMore = false}) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    if (_isSearchFetchingMore) return;

    if (!loadMore || trimmed != _lastQuery) {
      _isSearchLoading = true;
      _searchOffset = 0;
      _searchResults.clear();
      _searchHasMore = true;
      _lastQuery = trimmed;
    }

    if (!_searchHasMore) return;

    _isSearchFetchingMore = true;
    notifyListeners();

    try {
      final rows = await _publicTablesDB().listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        queries: [
          Query.equal('status', 'approved'),
          Query.equal('category', trimmed),
          Query.orderDesc("\$createdAt"),
          Query.limit(_limit),
          Query.offset(_searchOffset),
        ],
      );

      final newProducts =
          rows.rows.map((row) => ProductModel.fromMap(row.data)).toList();

      _searchResults.addAll(newProducts);
      _searchOffset += newProducts.length;
      if (newProducts.length < _limit) _searchHasMore = false;
    } catch (e) {
      // debugPrint("SEARCH BY CATEGORY ERROR: $e");
    } finally {
      _isSearchLoading = false;
      _isSearchFetchingMore = false;
      notifyListeners();
    }
  }

  // ===================== SEARCH BY SELLER =====================
  Future<void> searchBySeller(String sellerName,
      {bool loadMore = false}) async {
    final trimmed = sellerName.trim();
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    if (_isSearchFetchingMore) return;

    if (!loadMore || trimmed != _lastQuery) {
      _isSearchLoading = true;
      _searchOffset = 0;
      _searchResults.clear();
      _searchHasMore = true;
      _lastQuery = trimmed;
    }

    if (!_searchHasMore) return;

    _isSearchFetchingMore = true;
    notifyListeners();

    try {
      final rows = await _publicTablesDB().listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.product,
        queries: [
          Query.equal('status', 'approved'),
          Query.equal('sellerName', trimmed),
          Query.orderDesc("\$createdAt"),
          Query.limit(_limit),
          Query.offset(_searchOffset),
        ],
      );

      final newProducts =
          rows.rows.map((row) => ProductModel.fromMap(row.data)).toList();

      _searchResults.addAll(newProducts);
      _searchOffset += newProducts.length;
      if (newProducts.length < _limit) _searchHasMore = false;
    } catch (e) {
      // debugPrint("SEARCH BY SELLER ERROR: $e");
    } finally {
      _isSearchLoading = false;
      _isSearchFetchingMore = false;
      notifyListeners();
    }
  }
}
