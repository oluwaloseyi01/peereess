import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/ledgerprovider.dart';
import 'package:provider/provider.dart';

class UpdateOrderStatusPage extends StatefulWidget {
  final String orderId;

  const UpdateOrderStatusPage({super.key, required this.orderId});

  @override
  State<UpdateOrderStatusPage> createState() => _UpdateOrderStatusPageState();
}

class _UpdateOrderStatusPageState extends State<UpdateOrderStatusPage> {
  late String _status;
  bool _isLoading = true;
  bool _isUpdating = false;
  bool _isAdmin = false;

  // ✅ Updated statuses
  final List<String> _sellerStatusOptions = [
    "order placed",
    "shiped",
    "intransist",
    "delivered",
    "completed",
    "canceled",
    "rejected",
    "refund",
  ];

  final List<String> _adminStatusOptions = [
    "order placed",
    "shiped",
    "intransist",
    "delivered",
    "completed",
    "canceled",
    "rejected",
    "refund",
  ];

  List<String> get _availableStatuses =>
      _isAdmin ? _adminStatusOptions : _sellerStatusOptions;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _fetchOrderData();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final userId = context.read<AuthProvider>().userId ?? '';
      if (userId.isEmpty) return;

      final userDoc = await AppwriteConfig.tablesDB.getRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userCollection,
        rowId: userId,
      );

      final role = (userDoc.data['role'] ?? 'user').toString().toLowerCase();
      setState(() => _isAdmin = role == 'admin');
    } catch (e) {
      debugPrint("Error checking admin status: $e");
    }
  }

  Future<void> _fetchOrderData() async {
    try {
      final response = await AppwriteConfig.tablesDB.getRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.order,
        rowId: widget.orderId,
      );

      final fetchedStatus =
          (response.data['status'] ?? 'order placed').toString().toLowerCase();

      setState(() {
        _status = fetchedStatus;
        _isLoading = false;
      });
    } on AppwriteException catch (e) {
      debugPrint("Fetch order data error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch order data: ${e.message}")),
        );
      }
      setState(() {
        _status = 'order placed';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Unknown error fetching order data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch order data")),
        );
      }
      setState(() {
        _status = 'order placed';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_isUpdating) return;

    if (newStatus == 'rejected' ||
        newStatus == 'refund' ||
        newStatus == 'canceled') {
      final confirmed = await _showConfirmationDialog(newStatus);
      if (!confirmed) return;
    }

    setState(() => _isUpdating = true);

    try {
      final userId = context.read<AuthProvider>().userId ?? '';

      final result = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({
          "action": "updateOrderStatus",
          "orderId": widget.orderId,
          "status": newStatus,
          "userId": userId,
        }),
      );

      final data = jsonDecode(result.responseBody);

      if (data["status"] != true) {
        throw Exception(data["message"]);
      }

      setState(() => _status = newStatus);

      if (newStatus == 'completed' && userId.isNotEmpty && mounted) {
        await context.read<LedgerProvider>().fetchLedger(userId: userId);
      }

      if (newStatus == 'refund' && userId.isNotEmpty && mounted) {
        await context.read<LedgerProvider>().fetchLedger(userId: userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getSuccessMessage(newStatus)),
            backgroundColor: _getStatusColor(newStatus),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update status: ${e.toString()}"),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<bool> _showConfirmationDialog(String status) async {
    String title;
    String message;
    Color color;

    switch (status) {
      case 'rejected':
        title = 'Reject Order?';
        message =
            'This will reject the order and restore product stock. Customer will be notified.';
        color = Colors.red;
        break;
      case 'refund':
        title = 'Process Refund?';
        message =
            'This will reverse seller earnings and mark order as refunded. This action affects ledger balances.';
        color = Colors.orange;
        break;
      case 'canceled':
        title = 'Cancel Order?';
        message = 'This will cancel the order and restore product stock.';
        color = Colors.grey;
        break;
      default:
        return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 28),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  String _getSuccessMessage(String status) {
    switch (status) {
      case 'shiped':
        return "Order marked as shipped";
      case 'intransist':
        return "Order marked as in transit";
      case 'delivered':
        return "Order marked as delivered";
      case 'completed':
        return "Order completed — earnings credited to your balance";
      case 'rejected':
        return "Order rejected — stock restored";
      case 'refund':
        return "Refund processed — ledger updated";
      case 'canceled':
        return "Order canceled — stock restored";
      default:
        return "Order status updated successfully";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "order placed":
        return const Color(0xFF8B5E00);
      case "shiped":
        return const Color(0xFF1A6B3C);
      case "intransist":
        return const Color(0xFF1A4A8B);
      case "delivered":
        return const Color(0xFF2E7D32);
      case "completed":
        return const Color(0xFF1A3A6B);
      case "canceled":
        return const Color(0xFF8B1A1A);
      case "rejected":
        return const Color(0xFF6A1A1A);
      case "refund":
        return const Color(0xFF5C3D8B);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "order placed":
        return Icons.access_time_rounded;
      case "shiped":
        return Icons.local_shipping_rounded;
      case "intransist":
        return Icons.directions_transit_rounded;
      case "delivered":
        return Icons.inventory_2_rounded;
      case "completed":
        return Icons.check_circle_rounded;
      case "canceled":
        return Icons.remove_circle_outline_rounded;
      case "rejected":
        return Icons.block_rounded;
      case "refund":
        return Icons.currency_exchange_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case "order placed":
        return "ORDER PLACED";
      case "shiped":
        return "SHIPPED";
      case "intransist":
        return "IN TRANSIT";
      case "delivered":
        return "DELIVERED";
      case "completed":
        return "COMPLETED";
      case "canceled":
        return "CANCELLED";
      case "rejected":
        return "REJECTED";
      case "refund":
        return "REFUND";
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: Color(0xff9D6E2D),
                ),
              ),
            ),
            10.getWidthWhiteSpacing,
            const Text("Update order status", style: TextStyle(fontSize: 16)),
            const Spacer(),
            if (_isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "ADMIN",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Current Status Display ──────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(_status),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(_status),
                            color: _getStatusColor(_status),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Current Status",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _getStatusLabel(_status),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: _getStatusColor(_status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Update to:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Status Options Grid ─────────────────────────────
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _availableStatuses.length,
                        itemBuilder: (context, index) {
                          final statusOption = _availableStatuses[index];
                          final isSelected = _status == statusOption;

                          return GestureDetector(
                            onTap: isSelected
                                ? null
                                : () => _updateStatus(statusOption),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _getStatusColor(statusOption)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? _getStatusColor(statusOption)
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _getStatusColor(statusOption)
                                              .withOpacity(0.3),
                                          offset: const Offset(0, 4),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getStatusIcon(statusOption),
                                    color: isSelected
                                        ? Colors.white
                                        : _getStatusColor(statusOption),
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getStatusLabel(statusOption),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    if (_isUpdating)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
