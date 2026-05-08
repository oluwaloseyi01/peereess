import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  Color get _bg {
    switch (status) {
      case 'order placed':
        return const Color(0xFFFFF8EB);
      case 'shipped':
        return const Color(0xFFF0FBF5);
      case 'intransist':
        return const Color(0xFFF0F5FF);
      case 'delivered':
        return const Color(0xFFF1F8F1);
      case 'completed':
        return const Color(0xFFF0F5FB);
      case 'canceled':
        return const Color(0xFFFBF0F0);
      case 'rejected':
        return const Color(0xFFFFF0F0);
      case 'refund':
        return const Color(0xFFF5F0FB);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color get _color {
    switch (status) {
      case 'order placed':
        return const Color(0xFF8B5E00);
      case 'shipped':
        return const Color(0xFF1A6B3C);
      case 'intransist':
        return const Color(0xFF1A4A8B);
      case 'delivered':
        return const Color(0xFF2E7D32);
      case 'completed':
        return const Color(0xFF1A3A6B);
      case 'canceled':
        return const Color(0xFF8B1A1A);
      case 'rejected':
        return const Color(0xFF6A1A1A);
      case 'refund':
        return const Color(0xFF5C3D8B);
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status) {
      case 'order placed':
        return 'Order Placed';
      case 'shipped':
        return 'Shipped';
      case 'intransist':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'canceled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'refund':
        return 'Refund';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _bg,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
