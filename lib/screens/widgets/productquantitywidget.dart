import 'dart:convert';
import 'package:flutter/material.dart';

class QuantityWidget extends StatelessWidget {
  final List<dynamic> quantity; // ✅ Parameter is named "quantity"

  const QuantityWidget({super.key, required this.quantity});

  // ✅ Calculate total stock from all variants
  int get totalStock {
    if (quantity.isEmpty) return 0;

    int total = 0;
    for (var variant in quantity) {
      try {
        // ✅ Handle both Map and JSON string formats
        final Map<String, dynamic> variantMap = variant is String
            ? jsonDecode(variant) // Parse JSON string
            : (variant is Map<String, dynamic> ? variant : {});

        final stock = variantMap['stock'] ?? 0;
        total += (stock is int) ? stock : int.tryParse(stock.toString()) ?? 0;
      } catch (e) {
        continue;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final stock = totalStock;

    return Row(
      children: [
        Text(
          stock > 0 ? "In stock ($stock)" : "Out of stock",
          style: TextStyle(
            fontSize: 10,
            color: stock > 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
