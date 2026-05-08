import 'dart:convert';

import 'package:peereess/model/peereess.dart';

class OrderItem {
  final String productId;
  final String title;
  final String description;
  final String image;
  final String variant;
  final String? color;
  final int quantity;
  final double price;
  final double discount;

  OrderItem({
    required this.productId,
    required this.title,
    required this.description,
    required this.image,
    required this.variant,
    this.color,
    required this.quantity,
    required this.price,
    this.discount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'description': description,
      'image': image,
      'variant': variant,
      'color': color,
      'quantity': quantity,
      'price': price,
      'discount': discount,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      variant: map['variant'] ?? '',
      color: map['color'],
      quantity: map['quantity'] ?? 1,
      price: (map['price'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
    );
  }
}

class OrderModel {
  final String orderId; // <-- added orderId
  final List<OrderItem> cartItems;
  final double totalPrice;
  final double deliveryFee;
  final String deliveryAddress;
  final String deliveryPhoneNumber;
  final int? deliveryDays;
  final String? receiverFullName;
  final Peereess? selectedPickup;
  final String? paymentMethod;
  final bool isPaid;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paymentRef;
  final String? deliveryCode;

  /// New nullable delivery statuses
  final List<String>? deliveryStatus1;
  final List<String>? deliveryStatus2;
  final List<String>? deliveryStatus3;

  OrderModel({
    this.paymentRef,
    required this.orderId,
    required this.cartItems,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
    required this.deliveryFee,
    required this.deliveryAddress,
    required this.deliveryPhoneNumber,
    this.deliveryDays,
    this.receiverFullName,
    this.selectedPickup,
    this.deliveryCode,
    this.paymentMethod,
    this.isPaid = false,
    this.status = "pending",
    this.deliveryStatus1,
    this.deliveryStatus2,
    this.deliveryStatus3,
  });

  Map<String, dynamic> toMap() {
    return {
      '\$id': orderId,
      "paymentRef": paymentRef,
      'cartItems': cartItems.map((e) => e.toMap()).toList(),
      'totalPrice': totalPrice,
      'deliveryFee': deliveryFee,
      'deliveryAddress': deliveryAddress,
      'deliveryPhoneNumber': deliveryPhoneNumber,
      'deliveryDays': deliveryDays,
      'receiverFullName': receiverFullName,
      'selectedPickup': selectedPickup?.toMap(),
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'status': status,
      'deliveryCode': deliveryCode,
      'deliveryStatus1': deliveryStatus1,
      'deliveryStatus2': deliveryStatus2,
      'deliveryStatus3': deliveryStatus3,
      "\$createdAt": createdAt.toIso8601String(),
      "\$updatedAt": updatedAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? orderId}) {
    // Handle cartItems
    List<OrderItem> items = [];
    if (map['cartItems'] is String) {
      try {
        final decoded = jsonDecode(map['cartItems']);
        if (decoded is List) {
          items = decoded
              .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {
        items = [];
      }
    } else if (map['cartItems'] is List) {
      items = (map['cartItems'] as List)
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Handle selectedPickup
    Peereess? pickup;
    if (map['selectedPickup'] != null) {
      if (map['selectedPickup'] is String) {
        try {
          final decoded = jsonDecode(map['selectedPickup']);
          if (decoded is Map) {
            pickup = Peereess.fromMap(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          pickup = null;
        }
      } else if (map['selectedPickup'] is Map) {
        pickup = Peereess.fromMap(
          Map<String, dynamic>.from(map['selectedPickup']),
        );
      }
    }

    // Safe numeric parsing
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper for deliveryStatus
    List<String>? parseDeliveryStatus(dynamic value) {
      if (value == null) return null;
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return OrderModel(
      orderId: orderId ?? map['\$id'] ?? '',
      cartItems: items,
      totalPrice: safeDouble(map['totalPrice']),
      deliveryFee: safeDouble(map['deliveryFee']),
      deliveryAddress: map['deliveryAddress'] ?? '',
      deliveryPhoneNumber: map['deliveryPhoneNumber'] ?? '',
      deliveryDays: safeInt(map['deliveryDays']),
      receiverFullName: map['receiverFullName'],
      paymentRef: map["paymentRef"],
      selectedPickup: pickup,
      paymentMethod: map['paymentMethod'],
      deliveryCode: map['deliveryCode'],
      isPaid: map['isPaid'] ?? false,
      status: map['status'] ?? "pending",
      deliveryStatus1: parseDeliveryStatus(map['deliveryStatus1']),
      deliveryStatus2: parseDeliveryStatus(map['deliveryStatus2']),
      deliveryStatus3: parseDeliveryStatus(map['deliveryStatus3']),
      createdAt: DateTime.parse(map['\$createdAt']),
      updatedAt: DateTime.parse(map['\$updatedAt']),
    );
  }
}
