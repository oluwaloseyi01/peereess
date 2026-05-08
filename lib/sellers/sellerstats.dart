import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/ledgerprovider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/provider/sellerorder_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

// ─── Brand colours ─────────────────────────────────────────────────────────
const Color _kGold = Color(0xFFB0864C);
const Color _kGoldLight = Color(0xFFD4AA78);
const Color _kGoldDark = Color(0xFF7A5C2E);
const Color _kBg1 = Color.fromARGB(255, 217, 194, 162);

class SellerStatsPage extends StatelessWidget {
  const SellerStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0", "en_US");
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
        child: Center(child: LogoLoadingIndicator()),
      );
    }

    final orderProvider = context.watch<SellerOrderProvider>();
    final productProvider = context.watch<ProductUploadProvider>();
    final ledgerProvider = context.watch<LedgerProvider>();
    final userId = authProvider.userId ?? '';

    // Order counts
    final processing = orderProvider.sellerOrders
        .where((o) => (o['status'] ?? 'order placed') == 'order placed')
        .length;
    final shipped = orderProvider.sellerOrders // ✅ was 'ondelivery'
        .where((o) => (o['status'] ?? '') == 'shipped')
        .length;
    final completed = orderProvider.sellerOrders
        .where((o) => (o['status'] ?? '') == 'completed')
        .length;
    final rejected = orderProvider.sellerOrders
        .where((o) => (o['status'] ?? '') == 'canceled')
        .length;

    final totalOrders = processing + shipped + completed + rejected;
    final revenue = ledgerProvider.getBalance(userId);
    final totalProducts = productProvider.sellerProducts.length;
    final pendingProducts = productProvider.sellerProducts
        .where((p) => (p['status'] ?? '') == 'pending')
        .length;
    final approvedProducts = productProvider.sellerProducts
        .where((p) => (p['status'] ?? '') == 'approved')
        .length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Color(0xff9D6E2D),
                  ),
                ),
              ),
            ),
            10.getWidthWhiteSpacing,
            const Text(
              "Analysis",
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Stats Grid ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.money,
                      title: "Revenue",
                      value: "₦${formatter.format(revenue)}",
                      color: const Color(0xFF1A6B3C),
                      bgColor: const Color(0xFFD6F5E3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.shopping_cart_rounded,
                      title: "Orders",
                      value: "$totalOrders",
                      color: const Color(0xFF8B5E00),
                      bgColor: const Color(0xFFFFF3D6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.inventory_2_rounded,
                      title: "Products",
                      value: "$totalProducts",
                      color: const Color(0xFF5B21B6),
                      bgColor: const Color(0xFFEDE9FE),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_rounded,
                      title: "Approved",
                      value: "$approvedProducts",
                      color: _kGoldDark,
                      bgColor: _kGold.withOpacity(0.15),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ─── Orders Breakdown Section ───────────────────────────
              _SectionCard(
                title: "Order Status Breakdown",
                icon: Icons.pie_chart_rounded,
                child: Column(
                  children: [
                    // Pie Chart
                    if (totalOrders > 0)
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                color: const Color(0xFFFF9800),
                                value: processing.toDouble(),
                                title: "$processing",
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                radius: 60,
                              ),
                              PieChartSectionData(
                                color: const Color(0xFF4CAF50),
                                value: shipped.toDouble(), // ✅ was onDelivery
                                title: "$shipped",
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                radius: 60,
                              ),
                              PieChartSectionData(
                                color: const Color(0xFF2196F3),
                                value: completed.toDouble(),
                                title: "$completed",
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                radius: 60,
                              ),
                              PieChartSectionData(
                                color: const Color(0xFFF44336),
                                value: rejected.toDouble(),
                                title: "$rejected",
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                radius: 60,
                              ),
                            ],
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No orders yet",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Status Legend
                    _OrderStatusRow(
                      label: "Order Placed",
                      count: processing,
                      total: totalOrders,
                      color: const Color(0xFFFF9800),
                    ),
                    const SizedBox(height: 10),
                    _OrderStatusRow(
                      label: "Shipped", // ✅ was "On Delivery"
                      count: shipped, // ✅ was onDelivery
                      total: totalOrders,
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 10),
                    _OrderStatusRow(
                      label: "Completed",
                      count: completed,
                      total: totalOrders,
                      color: const Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 10),
                    _OrderStatusRow(
                      label: "Canceled",
                      count: rejected,
                      total: totalOrders,
                      color: const Color(0xFFF44336),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Product Performance ────────────────────────────────
              _SectionCard(
                title: "Product Performance",
                icon: Icons.trending_up_rounded,
                child: Column(
                  children: [
                    _MetricRow(
                      label: "Total Products",
                      value: "$totalProducts",
                      icon: Icons.inventory_2_rounded,
                      color: _kGold,
                    ),
                    const Divider(height: 24),
                    _MetricRow(
                      label: "Approved Products",
                      value: "$approvedProducts",
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF1A6B3C),
                    ),
                    const Divider(height: 24),
                    _MetricRow(
                      label: "Pending Approval",
                      value: "$pendingProducts",
                      icon: Icons.pending_rounded,
                      color: const Color(0xFF8B5E00),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Quick Insights ─────────────────────────────────────
              _SectionCard(
                title: "Quick Insights",
                icon: Icons.lightbulb_rounded,
                child: Column(
                  children: [
                    _InsightTile(
                      icon: Icons.local_shipping_rounded,
                      title: "Active Deliveries",
                      value: "$shipped orders in transit", // ✅ was onDelivery
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 12),
                    _InsightTile(
                      icon: Icons.timer_rounded,
                      title: "Pending Orders",
                      value: "$processing orders to process",
                      color: const Color(0xFFFF9800),
                    ),
                    const SizedBox(height: 12),
                    _InsightTile(
                      icon: Icons.verified_rounded,
                      title: "Success Rate",
                      value: totalOrders > 0
                          ? "${((completed / totalOrders) * 100).toStringAsFixed(1)}%"
                          : "0%",
                      color: const Color(0xFF2196F3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// STAT CARD (Top Grid)
// ──────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'poppins',
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'poppins',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION CARD
// ──────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGold.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: _kGold.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kGold.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: _kGold, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kGoldDark,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ORDER STATUS ROW
// ──────────────────────────────────────────────────────────────────────────────
class _OrderStatusRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _OrderStatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : (count / total);

    return Row(
      children: [
        // Color indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        // Label
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2A2A2A),
            ),
          ),
        ),
        // Progress bar
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              color: color,
              backgroundColor: color.withOpacity(0.15),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Count
        SizedBox(
          width: 35,
          child: Text(
            "$count",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// METRIC ROW
// ──────────────────────────────────────────────────────────────────────────────
class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'poppins',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// INSIGHT TILE
// ──────────────────────────────────────────────────────────────────────────────
class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InsightTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'poppins',
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
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
