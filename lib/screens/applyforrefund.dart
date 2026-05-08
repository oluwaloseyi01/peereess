import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/refundservice.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/model/ordermodel.dart';
import 'package:peereess/core/app_button.dart';

class ApplyForRefund extends StatefulWidget {
  final OrderModel order;

  const ApplyForRefund({super.key, required this.order});

  @override
  State<ApplyForRefund> createState() => _ApplyForRefundState();
}

class _ApplyForRefundState extends State<ApplyForRefund> {
  final TextEditingController reasonController = TextEditingController();
  String refundMethod = "wallet";
  bool isSubmitting = false;

  static const _gradientTop = Color.fromARGB(255, 217, 194, 162);
  static const _brown = Color(0xff9D6E2D);
  static const _brownDeep = Color(0xFF6B4A1B);

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refundProvider = context.watch<RefundProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    final alreadyRequested = refundProvider.refunds.any(
      (r) => r.orderId == widget.order.orderId,
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: const Color.fromARGB(255, 217, 194, 162),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
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
                  const Text(
                    "Item Refund",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientTop, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: alreadyRequested
              ? _alreadyRequestedUI()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Reason label ──────────────────────
                    const Text(
                      "Reason for Refund",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _brownDeep,
                      ),
                    ),
                    5.getHeightWhiteSpacing,

                    // ── Reason field ──────────────────────
                    TextField(
                      controller: reasonController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: "Enter your reason...",
                        hintStyle: TextStyle(
                          color: Colors.brown.shade300,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.75),
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.brown.shade200,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _brown,
                            width: 1.8,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    20.getHeightWhiteSpacing,

                    // ── Method label ──────────────────────
                    const Text(
                      "Refund Method",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _brownDeep,
                      ),
                    ),
                    5.getHeightWhiteSpacing,

                    // ── Method buttons ────────────────────
                    Row(
                      children: [
                        _buildRefundOption(
                          "Wallet",
                          Icons.account_balance_wallet_outlined,
                        ),
                        _buildRefundOption(
                          "Bank",
                          Icons.account_balance_outlined,
                        ),
                        _buildRefundOption("Card", Icons.credit_card_outlined),
                      ],
                    ),

                    30.getHeightWhiteSpacing,

                    // ── Submit ────────────────────────────
                    isSubmitting || refundProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: _brown),
                          )
                        : AppButtons(
                            text: "Submit Refund",
                            onPressed: () async {
                              if (reasonController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text("Please enter a reason"),
                                      ],
                                    ),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: const EdgeInsets.all(12),
                                  ),
                                );
                                return;
                              }

                              if (userId == null) return;
                              setState(() => isSubmitting = true);

                              final success = await refundProvider.createRefund(
                                userId: userId,
                                orderId: widget.order.orderId,
                                refundItems: widget.order.cartItems,
                                refundAmount: widget.order.totalPrice +
                                    widget.order.deliveryFee,
                                reason: reasonController.text.trim(),
                                refundMethod: refundMethod.toLowerCase(),
                              );

                              setState(() => isSubmitting = false);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text("Refund submitted successfully!"),
                                      ],
                                    ),
                                    backgroundColor: _brown,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: const EdgeInsets.all(12),
                                  ),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text("Failed to submit refund"),
                                      ],
                                    ),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: const EdgeInsets.all(12),
                                  ),
                                );
                              }
                            },
                          ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRefundOption(String method, IconData icon) {
    final selected = refundMethod.toLowerCase() == method.toLowerCase();

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => refundMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _brown : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _brown : Colors.brown.shade200,
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _brown.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : Colors.brown.shade400,
              ),
              const SizedBox(height: 5),
              Text(
                method,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : Colors.brown.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alreadyRequestedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200, width: 1.5),
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              size: 34,
              color: Colors.orange.shade400,
            ),
          ),
          15.getHeightWhiteSpacing,
          const Text(
            "Refund Already Requested",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _brownDeep,
            ),
          ),
          8.getHeightWhiteSpacing,
          Text(
            "You have already requested a refund\nfor this order.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.brown.shade500,
              height: 1.5,
            ),
          ),
          16.getHeightWhiteSpacing,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  "Check Notifications for updates",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
