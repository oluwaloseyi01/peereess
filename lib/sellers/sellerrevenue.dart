import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/ledgerprovider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/sellers/sellerorderdetails.dart';
import 'package:peereess/sellers/sellerwithdraw.dart';
import 'package:peereess/sellers/withdrawalhistory.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/provider/sellerorder_provider.dart';

class _TxItem {
  final DateTime date;
  final double amount;
  final String label;
  final Color labelColor;
  final bool isDebit;
  final String? description;
  final Map<String, dynamic>? order;

  _TxItem({
    required this.date,
    required this.amount,
    required this.label,
    required this.labelColor,
    required this.isDebit,
    this.description,
    this.order,
  });
}

class SellerRevenuePage extends StatefulWidget {
  const SellerRevenuePage({super.key});

  @override
  State<SellerRevenuePage> createState() => _SellerRevenuePageState();
}

class _SellerRevenuePageState extends State<SellerRevenuePage> {
  List<String> sellerProductIds = [];
  final formatter = NumberFormat("#,##0", "en_US");
  bool _balanceVisible = false; // ── visibility toggle state ──

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userId ?? '';
    final productProvider = context.read<ProductUploadProvider>();
    final orderProvider = context.read<SellerOrderProvider>();

    sellerProductIds = productProvider.sellerProducts
        .map((p) => p['productId'] as String)
        .toList();

    await orderProvider.fetchSellerOrders(sellerProductIds);

    if (userId.isNotEmpty && mounted) {
      await context.read<LedgerProvider>().fetchLedger(userId: userId);
    }
  }

  double _calculateOrderRevenue(Map<String, dynamic> order) {
    double total = 0;
    final cartItems = order['cartItems'] as List<dynamic>? ?? [];
    for (final item in cartItems) {
      final map = item is String
          ? Map<String, dynamic>.from(jsonDecode(item))
          : Map<String, dynamic>.from(item);
      if (sellerProductIds.contains(map['productId'])) {
        final price = (map['price'] ?? 0).toDouble();
        final qty = (map['quantity'] as num? ?? 0).toDouble();
        total += price * qty;
      }
    }
    return total;
  }

  List<_TxItem> _buildItems(
    List<Map<String, dynamic>> orders,
    List<Map<String, dynamic>> ledgerRows,
  ) {
    final List<_TxItem> items = [];

    for (final order in orders) {
      final revenue = _calculateOrderRevenue(order);
      if (revenue == 0) continue;
      final status = (order['status'] ?? '').toString();
      final isCompleted = status == 'completed';
      items.add(_TxItem(
        date: DateTime.parse(order['\$createdAt']),
        amount: revenue,
        label: isCompleted ? 'COMPLETED' : status.toUpperCase(),
        labelColor: isCompleted ? Colors.green : Colors.orange,
        isDebit: false,
        description: 'Order',
        order: order,
      ));
    }

    for (final row in ledgerRows) {
      final type = (row['type'] ?? '').toString().toLowerCase().trim();
      if (type != 'debit') continue;
      final amount = (row['amount'] as num? ?? 0).toDouble();
      if (amount == 0) continue;
      final createdAt = row['createdAt'] ?? row['\$createdAt'] ?? '';
      if (createdAt.toString().isEmpty) continue;
      items.add(_TxItem(
        date: DateTime.tryParse(createdAt.toString()) ?? DateTime.now(),
        amount: amount,
        label: 'DEBIT',
        labelColor: Colors.red,
        isDebit: true,
        description: (row['description'] ?? '').toString(),
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> _goToWithdraw(BuildContext context, double balance) async {
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have no available balance to withdraw"),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WithdrawPage()),
    );
    await _loadAll();
  }

  Future<void> _goToHistory(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WithdrawalHistoryPage()),
    );
    await _loadAll();
  }

  Future<void> _goToOrderDetail(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerOrderDetail(
          order: order,
          sellerProductIds: sellerProductIds,
        ),
      ),
    );
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isConnected) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(child: LogoLoadingIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
        title: Row(
          children: [
            const Text(
              "Total Earnings",
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _goToHistory(context),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromARGB(255, 236, 216, 191),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    IconsaxPlusLinear.receipt,
                    size: 18,
                    color: Color(0xff9D6E2D),
                  ),
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
        child: Consumer3<SellerOrderProvider, LedgerProvider, AuthProvider>(
          builder: (context, orderProvider, ledgerProvider, auth, _) {
            if (orderProvider.isLoadingOrders || ledgerProvider.isLoading) {
              return const Center(child: LogoLoadingIndicator());
            }

            final userId = auth.userId ?? '';
            final totalBalance = ledgerProvider.getBalance(userId);
            final totalEarnings = ledgerProvider.totalCredits;
            final totalWithdrawn = ledgerProvider.totalDebits;

            final items = _buildItems(
              orderProvider.sellerOrders,
              ledgerProvider.ledgerRows,
            );

            return RefreshIndicator(
              color: const Color(0xffB0864C),
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Balance card ──────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 3, 59, 6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Available Balance",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          // ── Balance amount + eye toggle ──
                          Row(
                            children: [
                              Text(
                                _balanceVisible
                                    ? "₦${formatter.format(totalBalance)}"
                                    : "₦ ••••••",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => setState(
                                  () => _balanceVisible = !_balanceVisible,
                                ),
                                child: Icon(
                                  _balanceVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white60,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Total Earnings",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _balanceVisible
                                        ? "₦${formatter.format(totalEarnings)}"
                                        : "₦ ••••",
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Total Withdrawn",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _balanceVisible
                                        ? "₦${formatter.format(totalWithdrawn)}"
                                        : "₦ ••••",
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 18, 99, 20),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                _goToWithdraw(context, totalBalance),
                            child: const Text("Withdraw"),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Transaction History",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (items.isEmpty)
                      const SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconsaxPlusLinear.transaction_minus,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "No recent transaction",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: items.map((tx) {
                          final date = DateFormat(
                            'dd MMM yyyy • hh:mm a',
                          ).format(tx.date);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    tx.isDebit ? '−' : '+',
                                    style: TextStyle(
                                      color: tx.isDebit
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "₦${formatter.format(tx.amount)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(date),
                                  const SizedBox(height: 4),
                                  Text(
                                    tx.label,
                                    style: TextStyle(
                                      color: tx.labelColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: tx.order != null
                                  ? const Icon(Icons.arrow_forward_ios,
                                      size: 14)
                                  : null,
                              onTap: tx.order != null
                                  ? () => _goToOrderDetail(context, tx.order!)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
