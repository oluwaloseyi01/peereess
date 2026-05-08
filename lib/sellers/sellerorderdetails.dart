import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/notificationprovider.dart';
import 'package:provider/provider.dart';

import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/screens/widgets/deliveryday.dart';
import 'package:peereess/provider/sellerorder_provider.dart';

// ─── Brand colours ────────────────────────────────────────────────────────────
const Color _kGold = Color(0xFFB0864C);
const Color _kGoldLight = Color(0xFFD4AA78);
const Color _kGoldDark = Color(0xFF7A5C2E);
const Color _kBg1 = Color.fromARGB(255, 217, 194, 162);

class SellerOrderDetail extends StatefulWidget {
  final Map<String, dynamic> order;
  final List<String> sellerProductIds;

  const SellerOrderDetail({
    super.key,
    required this.order,
    required this.sellerProductIds,
  });

  @override
  State<SellerOrderDetail> createState() => _SellerOrderDetailState();
}

class _SellerOrderDetailState extends State<SellerOrderDetail> {
  final _fmt = NumberFormat("#,##0", "en_US");

  List<Map<String, dynamic>> _parseSellerItems() {
    final cartItems = widget.order['cartItems'] as List<dynamic>? ?? [];
    return cartItems
        .map<Map<String, dynamic>>((item) {
          try {
            if (item is String)
              return Map<String, dynamic>.from(jsonDecode(item));
            if (item is Map) return Map<String, dynamic>.from(item);
          } catch (_) {}
          return {};
        })
        .where(
          (item) =>
              item.isNotEmpty &&
              widget.sellerProductIds.contains(item['productId']),
        )
        .toList();
  }

  Color _statusColor(String s) {
    switch (s) {
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
        return const Color(0xFF8B5E00);
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'shipped':
        return const Color(0xFFF0FBF5);
      case 'intransist':
        return const Color(0xFFF0F5FF);
      case 'delivered':
        return const Color(0xFFF1F8F1);
      case 'completed':
        return const Color(0xFFD6E4F5);
      case 'canceled':
        return const Color(0xFFF5D6D6);
      case 'rejected':
        return const Color(0xFFFFF0F0);
      case 'refund':
        return const Color(0xFFF5F0FB);
      default:
        return const Color(0xFFFFF8EB);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'intransist':
        return Icons.directions_transit_rounded;
      case 'delivered':
        return Icons.inventory_2_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'canceled':
        return Icons.cancel_rounded;
      case 'rejected':
        return Icons.block_rounded;
      case 'refund':
        return Icons.currency_exchange_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
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
      case 'order placed':
        return 'Order Placed';
      default:
        return s[0].toUpperCase() + s.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerItems = _parseSellerItems();
    final orderId = widget.order['rowId'] ?? '-';
    final createdAt = DateTime.tryParse(widget.order['\$createdAt'] ?? '');
    final formattedDate =
        createdAt != null ? DateFormat('dd MMM yyyy').format(createdAt) : '-';

    return Scaffold(
      // ── AppBar ────────────────────────────────────────────────────────────
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
              'Order Details',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: _kBg1,
      ),

      // ── Background ────────────────────────────────────────────────────────
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kBg1, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order ID + Date + Status ──────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kGold.withOpacity(0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: _kGold.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${orderId.length > 10 ? orderId.substring(0, 10) : orderId}',
                            style: const TextStyle(
                              fontFamily: 'poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _kGoldDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Placed $formattedDate',
                            style: TextStyle(
                              fontFamily: 'poppins',
                              fontSize: 11,
                              color: _kGoldDark.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Live status badge
                    Consumer<SellerOrderProvider>(
                      builder: (context, provider, _) {
                        final idx = provider.sellerOrders.indexWhere(
                          (o) => o['rowId'] == widget.order['rowId'],
                        );
                        final raw = idx != -1
                            ? (provider.sellerOrders[idx]['status'] ??
                                'order placed')
                            : (widget.order['status'] ?? 'order placed');

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBg(raw),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusIcon(raw),
                                size: 12,
                                color: _statusColor(raw),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _statusLabel(raw),
                                style: TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor(raw),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Customer info card ────────────────────────────────────
              _SectionCard(
                icon: Icons.person_rounded,
                title: 'Customer Info',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.badge_rounded,
                      label: 'Name',
                      value: widget.order['receiverFullName'] ?? '-',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'Address',
                      value: widget.order['deliveryAddress'] ?? '-',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Products ──────────────────────────────────────────────
              _SectionCard(
                icon: Icons.inventory_2_rounded,
                title: 'Your Products in this Order',
                child: sellerItems.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No products from you in this order.',
                            style: TextStyle(
                              fontFamily: 'poppins',
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: sellerItems
                            .map(
                              (item) =>
                                  _ProductRow(item: item, formatter: _fmt),
                            )
                            .toList(),
                      ),
              ),

              const SizedBox(height: 16),

              // ── Delivery info ─────────────────────────────────────────
              _SectionCard(
                icon: Icons.local_shipping_rounded,
                title: 'Delivery',
                child: DeliveryDayWidget(
                  deliveryDays: widget.order['deliveryDays'],
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),

      // ── Bottom action button ──────────────────────────────────────────────
      bottomNavigationBar: Consumer2<SellerOrderProvider, NotificationProvider>(
        builder: (context, orderProvider, notificationProvider, _) {
          final currentStatus = widget.order['status'] ?? 'order placed';

          if (currentStatus != 'order placed') {
            return const SizedBox.shrink();
          }

          // ✅ Only show loading for this specific order
          final thisOrderId = widget.order['rowId'] ?? '';
          final isThisUpdating = orderProvider.updatingOrderId == thisOrderId;

          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isThisUpdating
                        ? null
                        : () async {
                            if (thisOrderId.isEmpty) return;
                            await orderProvider.updateOrderStatus(
                              orderId: thisOrderId,
                              status: 'shipped',
                              requesterId:
                                  context.read<AuthProvider>().userId ?? '',
                            );
                            setState(() {});
                          },
                    icon: isThisUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.local_shipping_rounded, size: 18),
                    label: Text(
                      isThisUpdating ? 'Updating...' : 'Mark as Shipped',
                      style: const TextStyle(
                        fontFamily: 'poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kGoldLight,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGold.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: _kGold.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kGold.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _kGold),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _kGoldDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _kBg1.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _kGold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'poppins',
                  fontSize: 10,
                  color: _kGoldDark.withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2A2A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _ProductRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final NumberFormat formatter;

  const _ProductRow({required this.item, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item['image'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kBg1.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _imagePlaceholder(),
                    errorWidget: (context, url, error) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if ((item['variant'] ?? '').toString().isNotEmpty)
                      _Tag(label: item['variant'].toString()),
                    if ((item['color'] ?? '').toString().isNotEmpty)
                      _Tag(label: item['color'].toString()),
                    _Tag(label: 'Qty: ${item['quantity'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '₦${formatter.format(item['price'] ?? 0)}',
                  style: const TextStyle(
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _kGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: _kBg1.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: _kGold,
        size: 24,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _kGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _kGoldDark,
        ),
      ),
    );
  }
}
