import 'dart:convert';

class CartModel {
  final String cartId;
  final String userId;
  final String productId;
  final String title;
  final String description;
  final List<String> imageUrl;

  /// Variants quantity can change
  final List<Map<String, dynamic>> variants;

  /// Discount in percent
  final double discount;

  /// Total price can change
  double totalPrice;

  final DateTime createdAt;

  /// Delivery information
  final String? deliveryAddress;
  final String? deliveryPhoneNumber;
  final double? deliveryFee;
  final int? deliveryDays;

  final String? receiverFullName;

  CartModel({
    required this.cartId,
    required this.userId,
    required this.productId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.variants,
    required this.discount,
    required this.totalPrice,
    required this.createdAt,
    this.deliveryAddress,
    this.deliveryPhoneNumber,
    this.deliveryFee,
    this.deliveryDays,
    this.receiverFullName,
  });

  /// 🔒 SAFE PRICE PARSER (COMMA-SAFE)
  static double _parsePrice(dynamic value) {
    if (value == null) return 0;

    if (value is num) return value.toDouble();

    if (value is String) {
      final cleaned = value.replaceAll(',', '');
      return double.tryParse(cleaned) ?? 0;
    }

    return 0;
  }

  /// Total items from variants
  int get totalItems => variants.fold<int>(
    0,
    (sum, v) => sum + ((v['quantity'] is int) ? v['quantity'] as int : 0),
  );

  /// Total discount amount
  double get totalDiscount {
    double total = 0;

    for (final v in variants) {
      final price = _parsePrice(v['price']);
      final qty = (v['quantity'] ?? 0) as int;
      total += price * qty;
    }

    return total * (discount / 100);
  }

  /// Recalculate total price (with discount)
  void recalculateTotalPrice() {
    double total = 0;

    for (final v in variants) {
      final price = _parsePrice(v['price']);
      final qty = (v['quantity'] ?? 0) as int;
      total += price * qty;
    }

    totalPrice = total - (total * (discount / 100));
  }

  /// All variants with color always present
  List<Map<String, dynamic>> get variantsWithColor {
    return variants.map((v) => {...v, 'color': v['color'] ?? ''}).toList();
  }

  /// Convert to map (Appwrite)
  Map<String, dynamic> toMap() {
    return {
      "cartId": cartId,
      "userId": userId,
      "productId": productId,
      "title": title,
      "description": description,
      "imageUrl": imageUrl,
      "variants": variants.map((v) => jsonEncode(v)).toList(),
      "discount": discount,
      "totalPrice": totalPrice,
      "totalItems": totalItems,
      "totalDiscount": totalDiscount,
      "deliveryAddress": deliveryAddress,
      "deliveryPhoneNumber": deliveryPhoneNumber,
      "deliveryFee": deliveryFee,
      "deliveryDays": deliveryDays,
      "receiverFullName": receiverFullName,
      "\$createdAt": createdAt.toIso8601String(),
    };
  }

  /// Create from map
  factory CartModel.fromMap(Map<String, dynamic> data) {
    final parsedVariants = (data['variants'] as List)
        .map((v) => Map<String, dynamic>.from(jsonDecode(v)))
        .toList();

    return CartModel(
      cartId: data['cartId'],
      userId: data['userId'],
      productId: data['productId'],
      title: data['title'],
      description: data['description'],
      imageUrl: List<String>.from(data['imageUrl']),
      variants: parsedVariants,
      discount: (data['discount'] ?? 0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      createdAt: DateTime.parse(data['\$createdAt']),
      deliveryAddress: data['deliveryAddress'],
      deliveryPhoneNumber: data['deliveryPhoneNumber'],
      deliveryFee: data['deliveryFee'] != null
          ? (data['deliveryFee'] as num).toDouble()
          : null,
      deliveryDays: data['deliveryDays'],
      receiverFullName: data['receiverFullName'],
    );
  }
}
