import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/admin/adminorderstatus.dart';
import 'package:provider/provider.dart';

class Deliverystatus extends StatefulWidget {
  final String orderId; // Required orderId to update this order

  const Deliverystatus({super.key, required this.orderId});

  @override
  State<Deliverystatus> createState() => _DeliverystatusState();
}

class _DeliverystatusState extends State<Deliverystatus> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController statusController = TextEditingController();
  DateTime? _selectedTime;
  int _currentStatusNumber = 1; // Track which status is active

  Map<int, List<Map<String, String>>> statusData = {1: [], 2: [], 3: []};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatuses();
  }

  @override
  void dispose() {
    statusController.dispose();
    super.dispose();
  }

  /// Fetch current delivery statuses from server
  Future<void> _fetchStatuses() async {
    setState(() => isLoading = true);
    try {
      // ✅ Call server function to get delivery statuses
      final result = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({
          'action': 'getDeliveryStatus',
          'orderId': widget.orderId,
        }),
      );

      final data = jsonDecode(result.responseBody);

      if (data['status'] == true) {
        final responseData = data['data'];

        // Parse the three status arrays
        for (int i = 1; i <= 3; i++) {
          final List<dynamic> rawList = responseData['deliveryStatus$i'] ?? [];

          statusData[i] = rawList.map((e) {
            if (e is Map) {
              return Map<String, String>.from(
                e.map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ),
              );
            }
            return <String, String>{};
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching statuses: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load delivery status: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Pick delivery time
  Future<void> _pickTime() async {
    final now = DateTime.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  /// Update the selected status via server function
  Future<void> _updateStatus() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a time")));
      return;
    }

    final message = statusController.text.trim();
    final timestamp = _selectedTime!.toIso8601String();
    final userId = context.read<AuthProvider>().userId ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login again")));
      return;
    }

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // ✅ Call server function to update delivery status
      final result = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({
          'action': 'updateDeliveryStatus',
          'userId': userId,
          'orderId': widget.orderId,
          'statusNumber': _currentStatusNumber,
          'message': message,
          'time': timestamp,
        }),
      );

      final data = jsonDecode(result.responseBody);

      // Dismiss loading dialog
      if (mounted) Navigator.pop(context);

      if (data['status'] == true) {
        // Clear input
        statusController.clear();
        _selectedTime = null;

        // Refresh statuses
        await _fetchStatuses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Status $_currentStatusNumber updated successfully",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      debugPrint("Error updating status: $e");

      // Dismiss loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update status: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _selectedTime != null
        ? DateFormat.jm().format(_selectedTime!)
        : "Select time";

    Widget buildStatusSection(int statusNumber) {
      final statusList = statusData[statusNumber] ?? [];
      final isActive = _currentStatusNumber == statusNumber;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Status $statusNumber",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (!isActive)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStatusNumber = statusNumber;
                      statusController.clear();
                      _selectedTime = null;
                    });
                  },
                  child: const Text("Update"),
                ),
            ],
          ),
          const SizedBox(height: 8),

          /// Show existing messages
          if (statusList.isEmpty)
            const Text("No updates yet", style: TextStyle(color: Colors.grey))
          else
            Column(
              children: statusList.map((status) {
                final time = DateTime.tryParse(status["time"] ?? "") != null
                    ? DateFormat.jm().format(DateTime.parse(status["time"]!))
                    : "Unknown time";
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status["message"] ?? "",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          if (isActive) ...[
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: statusController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Update message",
                      hintText: "e.g., Package picked up from warehouse",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? "Please enter a message"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: _selectedTime != null
                                ? const Color(0xff9D6E2D)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedTime != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _updateStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff9D6E2D),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Update Status $statusNumber",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  20.getHeightWhiteSpacing,
                ],
              ),
            ),
          ],

          const Divider(),
        ],
      );
    }

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
            const Text("Delivery Status", style: TextStyle(fontSize: 16)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xff9D6E2D)),
              onPressed: _fetchStatuses,
              tooltip: "Refresh",
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Track delivery progress with three status updates",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    buildStatusSection(1),
                    buildStatusSection(2),
                    buildStatusSection(3),

                    30.getHeightWhiteSpacing,

                    Appbuttons2(
                      text: "Update Order Status",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UpdateOrderStatusPage(orderId: widget.orderId),
                          ),
                        );
                      },
                    ),

                    30.getHeightWhiteSpacing,
                  ],
                ),
              ),
      ),
    );
  }
}
