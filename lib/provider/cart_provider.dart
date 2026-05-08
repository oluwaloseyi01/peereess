import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/cartmodel.dart';

class CartProvider extends ChangeNotifier {
  List<CartModel> _cartItems = [];
  List<CartModel> get cartItems => _cartItems;

  // ===================== PAGINATION HELPER =====================
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

  // ===================== SERVER FUNCTION CALL =====================
  Future<Map<String, dynamic>> _callFunction(Map<String, dynamic> body) async {
    final res = await AppwriteConfig.functions.createExecution(
      functionId: AppwriteConfig.productFunction,
      body: json.encode(body),
    );
    return json.decode(res.responseBody) as Map<String, dynamic>;
  }

  // ===================== HELPERS =====================
  double _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0;
    return 0;
  }

  // ===================== ADD TO CART (server) =====================
  Future<void> addToCart({
    required String userId,
    required String productId,
    required String title,
    required String description,
    required List<String> imageUrl,
    required List<Map<String, dynamic>> variants,
    required double discount,
    String? deliveryAddress,
    String? deliveryPhoneNumber,
    double? deliveryFee,
    int? deliveryDays,
    String? receiverFullName,
  }) async {
    final List<Map<String, dynamic>> selectedVariants = variants
        .where((v) => (v['quantity'] ?? 0) > 0)
        .map((v) => Map<String, dynamic>.from(v))
        .toList();

    if (selectedVariants.isEmpty) {
      throw Exception("Please add at least one item");
    }

    final cartId = const Uuid().v4();

    final result = await _callFunction({
      'action': 'addToCart',
      'userId': userId,
      'productId': productId,
      'cartId': cartId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'variants': selectedVariants,
      'deliveryAddress': deliveryAddress ?? '',
      'deliveryPhoneNumber': deliveryPhoneNumber ?? '',
      'deliveryFee': deliveryFee ?? 0,
      'deliveryDays': deliveryDays ?? 0,
      'receiverFullName': receiverFullName ?? '',
    });

    if (result['status'] != true) {
      throw Exception(result['message'] ?? 'Failed to add to cart.');
    }

    final double serverTotalPrice =
        (result['data']['totalPrice'] as num).toDouble();

    final cart = CartModel(
      cartId: cartId,
      userId: userId,
      productId: productId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      variants: selectedVariants,
      discount: discount,
      totalPrice: serverTotalPrice,
      createdAt: DateTime.now(),
      deliveryAddress: deliveryAddress,
      deliveryPhoneNumber: deliveryPhoneNumber,
      deliveryFee: deliveryFee,
      deliveryDays: deliveryDays,
      receiverFullName: receiverFullName,
    );

    _cartItems.insert(0, cart);
    notifyListeners();
  }

  // ===================== FETCH CART =====================
  Future<void> fetchCartItems(String userId) async {
    try {
      final allRows = await _fetchAllRows(
        tableId: AppwriteConfig.cart,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'),
        ],
      );

      _cartItems = allRows.map((data) {
        final List<Map<String, dynamic>> parsedVariants =
            (data['variants'] as List)
                .map((v) => Map<String, dynamic>.from(jsonDecode(v)))
                .toList();

        final double discount = (data['discount'] ?? 0).toDouble();

        double totalPrice = 0;
        for (var v in parsedVariants) {
          totalPrice += _parsePrice(v['price']) * ((v['quantity'] ?? 0) as int);
        }
        totalPrice = totalPrice - (totalPrice * (discount / 100));

        final double deliveryFee = data['deliveryFee'] != null
            ? (data['deliveryFee'] as num).toDouble()
            : 0;
        totalPrice += deliveryFee;

        return CartModel(
          cartId: data['cartId'],
          userId: data['userId'],
          productId: data['productId'],
          title: data['title'],
          description: data['description'],
          imageUrl: List<String>.from(data['imageUrl']),
          variants: parsedVariants,
          discount: discount,
          totalPrice: totalPrice,
          createdAt: DateTime.parse(data['\$createdAt']),
          deliveryAddress: data['deliveryAddress'],
          deliveryPhoneNumber: data['deliveryPhoneNumber'],
          deliveryFee: deliveryFee > 0 ? deliveryFee : null,
          deliveryDays: data['deliveryDays'],
          receiverFullName: data['receiverFullName'],
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      // debugPrint("Fetch Cart Error: $e");
    }
  }

  // ===================== DELETE CART ITEM =====================
  Future<void> deleteCartItem(String cartId, String userId) async {
    try {
      final result = await _callFunction({
        'action': 'deleteCartItem',
        'userId': userId,
        'cartId': cartId,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to delete cart item.');
      }

      _cartItems.removeWhere((item) => item.cartId == cartId);
      notifyListeners();
    } catch (e) {
      // debugPrint("Delete Cart Item Error: $e");
      rethrow;
    }
  }

  // ===================== DELETE ORDERED CART ITEMS =====================
  Future<void> deleteOrderedCartItems({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      final List<String> cartIdsToDelete = cartItems
          .where(
            (item) =>
                item['cartId'] != null && item['cartId'].toString().isNotEmpty,
          )
          .map((item) => item['cartId'] as String)
          .toList();

      if (cartIdsToDelete.isEmpty) {
        // debugPrint("No cart items to delete");
        return;
      }

      final result = await _callFunction({
        'action': 'deleteOrderedCartItems',
        'userId': userId,
        'cartIds': cartIdsToDelete,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to delete cart items.');
      }

      _cartItems.removeWhere((item) => cartIdsToDelete.contains(item.cartId));
      notifyListeners();

      // debugPrint("✅ Deleted ${cartIdsToDelete.length} cart items");
    } catch (e) {
      // debugPrint("Delete Ordered Cart Items Error: $e");
      rethrow;
    }
  }

  // ===================== CLEAR CART =====================
  Future<void> clearCartForUser(String userId) async {
    try {
      final result = await _callFunction({
        'action': 'clearCart',
        'userId': userId,
      });

      if (result['status'] != true) {
        throw Exception(result['message'] ?? 'Failed to clear cart.');
      }

      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      // debugPrint("Clear Cart Error: $e");
      rethrow;
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // ===================== STOCK INFO =====================
  Map<String, dynamic> getCartItemStockInfo({
    required CartModel cartItem,
    required List<dynamic> productVariants,
  }) {
    Map<String, dynamic> stockInfo = {
      'isOutOfStock': false,
      'variantStock': 0,
      'totalStock': 0,
      'canAddMore': false,
      'currentQty': 0,
    };

    final cartVariantDescription = cartItem.variants.isNotEmpty
        ? cartItem.variants[0]['description'] ?? ''
        : '';

    int totalStock = 0;
    int variantStock = 0;
    bool isOutOfStock = false;

    for (var variant in productVariants) {
      if (variant is Map<String, dynamic>) {
        final stock = variant['stock'] ?? 0;
        final stockInt =
            (stock is int) ? stock : int.tryParse(stock.toString()) ?? 0;

        totalStock += stockInt;

        if (variant['description'] == cartVariantDescription) {
          variantStock = stockInt;

          final String stockStatus =
              (variant['stockStatus'] ?? '').toString().toLowerCase().trim();

          if (stockStatus.isNotEmpty) {
            isOutOfStock = stockStatus == 'out of stock';
          } else {
            isOutOfStock = stockInt <= 0;
          }
        }
      }
    }

    final currentQty = cartItem.variants.isNotEmpty
        ? (cartItem.variants[0]['quantity'] ?? 0) as int
        : 0;

    final canAddMore = !isOutOfStock && currentQty < variantStock;

    stockInfo['isOutOfStock'] = isOutOfStock;
    stockInfo['variantStock'] = variantStock;
    stockInfo['totalStock'] = totalStock;
    stockInfo['canAddMore'] = canAddMore;
    stockInfo['currentQty'] = currentQty;

    return stockInfo;
  }

  // ===================== HAS OUT OF STOCK ITEMS =====================
  bool hasOutOfStockItems({
    required List<CartModel> cartItems,
    required Map<String, List<dynamic>> productVariantsMap,
  }) {
    for (var item in cartItems) {
      final productVariants = productVariantsMap[item.productId];
      if (productVariants == null || productVariants.isEmpty) continue;
      final stockInfo = getCartItemStockInfo(
        cartItem: item,
        productVariants: productVariants,
      );
      if (stockInfo['isOutOfStock'] == true) return true;
    }
    return false;
  }

  // ===================== REBUILD ITEM HELPER =====================
  // Rebuilds a CartModel with updated variants and recalculated totalPrice.
  // Replacing the whole object ensures Provider detects the change even when
  // CartModel fields are final.
  CartModel _rebuildItem(
    CartModel item,
    List<Map<String, dynamic>> updatedVariants,
  ) {
    double newTotalPrice = 0;
    for (var v in updatedVariants) {
      newTotalPrice += _parsePrice(v['price']) * ((v['quantity'] ?? 0) as int);
    }
    newTotalPrice = newTotalPrice - (newTotalPrice * (item.discount / 100));
    if (item.deliveryFee != null) newTotalPrice += item.deliveryFee!;

    return CartModel(
      cartId: item.cartId,
      userId: item.userId,
      productId: item.productId,
      title: item.title,
      description: item.description,
      imageUrl: item.imageUrl,
      variants: updatedVariants,
      discount: item.discount,
      totalPrice: newTotalPrice,
      createdAt: item.createdAt,
      deliveryAddress: item.deliveryAddress,
      deliveryPhoneNumber: item.deliveryPhoneNumber,
      deliveryFee: item.deliveryFee,
      deliveryDays: item.deliveryDays,
      receiverFullName: item.receiverFullName,
    );
  }

  // ===================== UPDATE QTY WITH STOCK CHECK =====================
  Future<void> updateCartItemQtyWithStockCheck({
    required String cartId,
    required int variantIndex,
    required int newQty,
    required int availableStock,
  }) async {
    try {
      if (newQty > availableStock) {
        throw Exception("Only $availableStock items available in stock");
      }

      final index = _cartItems.indexWhere((e) => e.cartId == cartId);
      if (index == -1) return;

      final item = _cartItems[index];

      // ✅ Build a fresh mutable list — direct map mutation is not guaranteed
      // to trigger a rebuild because the list reference doesn't change.
      final updatedVariants = item.variants
          .asMap()
          .entries
          .map((e) {
            final v = Map<String, dynamic>.from(e.value);
            if (e.key == variantIndex) v['quantity'] = newQty;
            return v;
          })
          .where((v) => (v['quantity'] ?? 0) > 0)
          .toList();

      // ✅ Replace the whole object so Provider detects the change
      _cartItems[index] = _rebuildItem(item, updatedVariants);
      notifyListeners();
    } catch (e) {
      // debugPrint("updateCartItemQtyWithStockCheck error: $e");
      rethrow;
    }
  }

  // ===================== UPDATE QTY =====================
  Future<void> updateCartItemQty({
    required String cartId,
    required int variantIndex,
    required int newQty,
  }) async {
    try {
      final index = _cartItems.indexWhere((e) => e.cartId == cartId);
      if (index == -1) return;

      final item = _cartItems[index];

      // ✅ Build a fresh mutable list
      final updatedVariants = item.variants
          .asMap()
          .entries
          .map((e) {
            final v = Map<String, dynamic>.from(e.value);
            if (e.key == variantIndex) v['quantity'] = newQty;
            return v;
          })
          .where((v) => (v['quantity'] ?? 0) > 0)
          .toList();

      // ✅ Replace the whole object so Provider detects the change
      _cartItems[index] = _rebuildItem(item, updatedVariants);
      notifyListeners();
    } catch (e) {
      // debugPrint("updateCartItemQty error: $e");
    }
  }
}
