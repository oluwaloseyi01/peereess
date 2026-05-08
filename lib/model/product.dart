import 'dart:convert';
import 'package:intl/intl.dart';

class ProductModel {
  final String productId;
  final String title;
  final String description;
  final List<String> imageUrl;
  final int quantity;
  final String sellerName; // ✅ NEW

  /// 🔹 FILTER / EXTRA FIELDS
  final String? brand;
  final String? status;
  final String? shippedFrom;
  final double? rating;
  final int? deliveryDays;
  final int? deliveryFee;
  final double discount;
  final int likes;
  final String category;
  final DateTime createdAt;
  final List<String> likedBy;
  final List<String> colors;
  final List<Map<String, dynamic>> variants;

  /// ✅ NEW FIELDS
  final List<String>? reviews;
  final String refundable;

  ProductModel({
    required this.productId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.quantity,
    required this.sellerName, // ✅ NEW
    this.status,

    /// 🔹 FILTERS / EXTRA FIELDS (nullable)
    this.brand,
    this.shippedFrom,
    this.rating,
    this.deliveryDays,
    this.deliveryFee,

    required this.discount,
    required this.likes,
    required this.category,
    required this.createdAt,
    required this.likedBy,
    this.colors = const [],
    this.variants = const [],

    /// ✅ NEW FIELDS
    this.reviews,
    this.refundable = "no",
  });

  /// ======================
  /// FROM APPWRITE / MAP
  /// ======================
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final List<Map<String, dynamic>> parsedVariants =
        (map['variants'] as List? ?? []).map<Map<String, dynamic>>((v) {
          if (v is String) {
            return Map<String, dynamic>.from(jsonDecode(v));
          }
          return Map<String, dynamic>.from(v);
        }).toList();

    return ProductModel(
      productId: map['productId'] ?? map['\$id'] ?? "",
      title: map['title'] ?? "",
      description: map['description'] ?? "",
      imageUrl: map['imageUrl'] != null
          ? List<String>.from(map['imageUrl'])
          : [],
      quantity: map['quantity'] ?? 0,
      sellerName: map['sellerName']?.toString() ?? "", // ✅ NEW
      status: map['status']?.toString(),

      /// 🔹 FILTER / EXTRA FIELDS
      brand: map['brand'],
      shippedFrom: map['shippedFrom'],
      rating: map['rating'] != null
          ? double.tryParse(map['rating'].toString())
          : null,
      deliveryDays: map['deliveryDays'] != null
          ? int.tryParse(map['deliveryDays'].toString())
          : null,
      deliveryFee: map['deliveryFee'] != null
          ? int.tryParse(map['deliveryFee'].toString())
          : null,

      discount: double.tryParse(map['discount'].toString()) ?? 0,
      likes: int.tryParse(map['likes'].toString()) ?? 0,
      category: map['category'] ?? "",
      createdAt: map['\$createdAt'] != null
          ? DateTime.parse(map['\$createdAt'])
          : DateTime.now(),
      likedBy: map['likedBy'] != null ? List<String>.from(map['likedBy']) : [],
      colors: map['colors'] != null ? List<String>.from(map['colors']) : [],
      variants: parsedVariants,

      /// ✅ NEW FIELDS
      reviews: map['reviews'] != null
          ? List<String>.from(map['reviews'])
          : null,
      refundable: map['refundable']?.toString() ?? "no",
    );
  }

  /// ======================
  /// TO MAP / APPWRITE
  /// ======================
  Map<String, dynamic> toMap() {
    return {
      "productId": productId,
      "title": title,
      "description": description,
      "imageUrl": imageUrl,
      "quantity": quantity,
      "sellerName": sellerName, // ✅ NEW
      "status": status,

      /// 🔹 FILTER / EXTRA FIELDS
      "brand": brand,
      "shippedFrom": shippedFrom,
      "rating": rating,
      "deliveryDays": deliveryDays,
      "deliveryFee": deliveryFee,
      "discount": discount,
      "likes": likes,
      "category": category,
      "likedBy": likedBy,
      "colors": colors,

      /// 🔥 store variants as STRING ARRAY
      "variants": variants.map((v) => jsonEncode(v)).toList(),

      /// ✅ NEW FIELDS
      "reviews": reviews,
      "refundable": refundable,
    };
  }

  /// ======================
  /// COPY WITH
  /// ======================
  ProductModel copyWith({
    String? productId,
    String? title,
    String? description,
    List<String>? imageUrl,
    int? quantity,
    String? sellerName, // ✅ NEW
    String? brand,
    String? status,
    String? shippedFrom,
    double? rating,
    int? deliveryDays,
    int? deliveryFee,
    double? discount,
    int? likes,
    String? category,
    DateTime? createdAt,
    List<String>? likedBy,
    List<String>? colors,
    List<Map<String, dynamic>>? variants,
    List<String>? reviews,
    String? refundable,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      sellerName: sellerName ?? this.sellerName, // ✅ NEW
      status: status ?? this.status,
      brand: brand ?? this.brand,
      shippedFrom: shippedFrom ?? this.shippedFrom,
      rating: rating ?? this.rating,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      likes: likes ?? this.likes,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? this.likedBy,
      colors: colors ?? this.colors,
      variants: variants ?? this.variants,
      reviews: reviews ?? this.reviews,
      refundable: refundable ?? this.refundable,
    );
  }

  /// ======================
  /// PRICE HELPERS (RAW)
  /// ======================
  double get price {
    if (variants.isEmpty) return 0;
    return double.tryParse(variants.first['price'].toString()) ?? 0;
  }

  double get finalPrice {
    if (discount <= 0) return price;
    return price - (price * (discount / 100));
  }

  /// ======================
  /// PRICE HELPERS (FORMATTED)
  /// ======================
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  String get formattedPrice => _formatter.format(price);

  String get formattedFinalPrice => _formatter.format(finalPrice);
}
