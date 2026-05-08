import 'dart:convert';

import 'package:peereess/model/ordermodel.dart';

class RefundModel {
  final String refundId; // ✅ PRIMARY ID
  final String orderId;

  /// Stored in Appwrite as String[] (JSON strings)
  final List<String> refundItems;

  final double refundAmount;
  final String? reason;
  final String status;
  final String? refundMethod;

  final DateTime createdAt;
  final DateTime updatedAt;

  RefundModel({
    required this.refundId,
    required this.orderId,
    required this.refundItems,
    required this.refundAmount,
    this.reason,
    this.refundMethod,
    this.status = "pending",
    required this.createdAt,
    required this.updatedAt,
  });

  /// ================================
  /// Convert RefundModel → Map (SAVE)
  /// ================================
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'refundItems': refundItems,
      'refundAmount': refundAmount,
      'reason': reason,
      'refundMethod': refundMethod,
      'status': status,
    };
  }

  /// ================================
  /// Create RefundModel ← Map (READ)
  /// ================================
  factory RefundModel.fromMap(Map<String, dynamic> map, {String? refundId}) {
    return RefundModel(
      refundId: refundId ?? map['\$id'] ?? '',
      orderId: map['orderId'] ?? '',
      refundItems: map['refundItems'] is List
          ? List<String>.from(map['refundItems'])
          : [],
      refundAmount: _safeDouble(map['refundAmount']),
      reason: map['reason'],
      refundMethod: map['refundMethod'],
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['\$createdAt']),
      updatedAt: DateTime.parse(map['\$updatedAt']),
    );
  }

  /// ================================
  /// COPY WITH (ADMIN STATUS UPDATE)
  /// ================================
  RefundModel copyWith({String? status}) {
    return RefundModel(
      refundId: refundId,
      orderId: orderId,
      refundItems: refundItems,
      refundAmount: refundAmount,
      reason: reason,
      refundMethod: refundMethod,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(), // 👈 reflect update
    );
  }

  /// ================================
  /// Encode OrderItem → JSON strings
  /// ================================
  static List<String> encodeItems(List<OrderItem> items) {
    return items.map((item) => jsonEncode(item.toMap())).toList();
  }

  /// ================================
  /// Decode JSON string → OrderItem
  /// ================================
  static OrderItem decodeItem(String jsonString) {
    return OrderItem.fromMap(Map<String, dynamic>.from(jsonDecode(jsonString)));
  }

  /// ================================
  /// Decode ALL refundItems → OrderItem list
  /// ================================
  List<OrderItem> decodeAllItems() {
    return refundItems.map(decodeItem).toList();
  }

  /// ================================
  /// Safe double parser
  /// ================================
  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
