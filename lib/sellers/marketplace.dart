import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/sellers/sellerorderdetails.dart';
import 'package:peereess/sellers/sellerordersearch.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/sellerorder_provider.dart';

// ─── Brand colours (unchanged) ────────────────────────────────────────────────
const Color kBg1 = Color.fromARGB(255, 217, 194, 162);
const Color kBg2 = Colors.white;
const Color kGold = Color(0xFFB0864C);
const Color kGoldLight = Color(0xFFD4AA78);
const Color kGoldDark = Color(0xFF7A5C2E);
const Color kSurface = Color(0xFFFBF7F2);
const Color kBorder = Color(0xFFEDE0CE);

// ─── Status config ─────────────────────────────────────────────────────────────
class _Status {
  final String label;
  final Color color;
  final Color bg;
  final Color border;
  final IconData icon;
  const _Status({
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
    required this.icon,
  });
}

const Map<String, _Status> kStatusMap = {
  'order placed': _Status(
    label: 'Order Placed',
    color: Color(0xFF8B5E00),
    bg: Color(0xFFFFF8EB),
    border: Color(0xFFFFE5A0),
    icon: Icons.access_time_rounded,
  ),
  'shipped': _Status(
    label: 'Shipped',
    color: Color(0xFF1A6B3C),
    bg: Color(0xFFF0FBF5),
    border: Color(0xFFA8E6C3),
    icon: Icons.local_shipping_rounded,
  ),
  'intransist': _Status(
    label: 'InTransit',
    color: Color(0xFF1A4A8B),
    bg: Color(0xFFF0F5FF),
    border: Color(0xFFA8C0F0),
    icon: Icons.delivery_dining,
  ),
  'delivered': _Status(
    label: 'Delivered',
    color: Color(0xFF2E7D32),
    bg: Color(0xFFF1F8F1),
    border: Color(0xFFA5D6A7),
    icon: Icons.inventory_2_outlined,
  ),
  'completed': _Status(
    label: 'Completed',
    color: Color(0xFF1A3A6B),
    bg: Color(0xFFF0F5FB),
    border: Color(0xFFA8C4E6),
    icon: Icons.check_circle_outline_rounded,
  ),
  'canceled': _Status(
    label: 'Cancelled',
    color: Color(0xFF8B1A1A),
    bg: Color(0xFFFBF0F0),
    border: Color(0xFFE6A8A8),
    icon: Icons.remove_circle_outline_rounded,
  ),
  'rejected': _Status(
    label: 'Rejected',
    color: Color(0xFF6A1A1A),
    bg: Color(0xFFFFF0F0),
    border: Color(0xFFFFB3B3),
    icon: Icons.block_rounded,
  ),
  'refund': _Status(
    label: 'Refund',
    color: Color(0xFF5C3D8B),
    bg: Color(0xFFF5F0FB),
    border: Color(0xFFCDB8F0),
    icon: Icons.money,
  ),
};

const List<String> kTabStatuses = [
  'order placed',
  'shipped',
  'intransist',
  'delivered',
  'completed',
  'canceled',
  'rejected',
  'refund',
];

// ══════════════════════════════════════════════════════════════════════════════
class Marketplace extends StatefulWidget {
  final List<String> sellerProductIds;
  const Marketplace({super.key, required this.sellerProductIds});

  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kTabStatuses.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _selectedTab) {
        setState(() => _selectedTab = _tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.sellerProductIds.isNotEmpty) {
        context.read<SellerOrderProvider>().fetchSellerOrders(
              widget.sellerProductIds,
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterOrders(
    List<Map<String, dynamic>> all,
    String status,
  ) {
    return all.where((o) => (o['status'] ?? 'order placed') == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<SellerOrderProvider>().sellerOrders;

    final counts = {
      for (final s in kTabStatuses) s: _filterOrders(orders, s).length,
    };

    return Scaffold(
      backgroundColor: kSurface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kBg1, kSurface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.38],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── PINNED HEADER (never scrolls) ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Orders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'poppins',
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${orders.length} order${orders.length == 1 ? '' : 's'} in total',
                            style: TextStyle(
                              fontSize: 12,
                              color: kGoldDark.withOpacity(0.55),
                              fontFamily: 'poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Sellerordersearch(
                            sellerProductIds: widget.sellerProductIds,
                          ),
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 236, 216, 191),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            IconsaxPlusLinear.search_normal,
                            size: 18,
                            color: Color(0xff9D6E2D),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── SCROLLABLE BODY (stats + tabs + orders scroll under header) ──
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // ── Stats row ───────────────────────────────────
                          SizedBox(
                            height: 78,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              children: kTabStatuses.map((s) {
                                final st = kStatusMap[s]!;
                                final count = counts[s]!;
                                return _StatCard(
                                  label: st.label,
                                  count: count,
                                  color: st.color,
                                  bg: st.bg,
                                  border: st.border,
                                  icon: st.icon,
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Segmented tab bar ───────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorder, width: 1),
                              ),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(3),
                                children:
                                    List.generate(kTabStatuses.length, (i) {
                                  final s = kTabStatuses[i];
                                  final st = kStatusMap[s]!;
                                  final selected = _selectedTab == i;
                                  return GestureDetector(
                                    onTap: () => _tabController.animateTo(i),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(right: 3),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? kGold
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            st.icon,
                                            size: 14,
                                            color: selected
                                                ? Colors.white
                                                : kGoldDark.withOpacity(0.45),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            st.label.split(' ').first,
                                            style: TextStyle(
                                              fontFamily: 'poppins',
                                              fontSize: 9.5,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: selected
                                                  ? Colors.white
                                                  : kGoldDark.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: kTabStatuses
                        .map(
                          (s) => _OrderList(
                            tabStatus: s,
                            sellerProductIds: widget.sellerProductIds,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color, bg, border;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
    required this.border,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: color),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'poppins',
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'poppins',
              color: color.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _OrderList extends StatelessWidget {
  final String tabStatus;
  final List<String> sellerProductIds;

  const _OrderList({required this.tabStatus, required this.sellerProductIds});

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> all) {
    return all
        .where((o) => (o['status'] ?? 'order placed') == tabStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isConnected) return const SizedBox();

    return Consumer<SellerOrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingOrders) {
          return const Center(child: LogoLoadingIndicator());
        }

        final orders = _filter(provider.sellerOrders);

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: kBorder.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    kStatusMap[tabStatus]!.icon,
                    size: 32,
                    color: kGoldLight,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No ${kStatusMap[tabStatus]!.label.toLowerCase()} orders',
                  style: const TextStyle(
                    fontFamily: 'poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kGoldDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Orders with this status will appear here.',
                  style: TextStyle(
                    fontFamily: 'poppins',
                    fontSize: 12,
                    color: kGoldDark.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchSellerOrders(sellerProductIds),
          color: kGold,
          backgroundColor: Colors.white,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 24),
            itemCount: orders.length,
            itemBuilder: (context, i) => _OrderCard(
              order: orders[i],
              sellerProductIds: sellerProductIds,
              provider: provider,
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final List<String> sellerProductIds;
  final SellerOrderProvider provider;

  const _OrderCard({
    required this.order,
    required this.sellerProductIds,
    required this.provider,
  });

  List<Map<String, dynamic>> _parseSellerItems() {
    final cartItems = order['cartItems'] as List<dynamic>? ?? [];
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
              item.isNotEmpty && sellerProductIds.contains(item['productId']),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final orderId = order['rowId']?.toString() ?? '-';
    final rawStatus = (order['status'] ?? 'order placed').toString();
    final st = kStatusMap[rawStatus] ?? kStatusMap['order placed']!;

    final createdAt = DateTime.tryParse(order['\$createdAt'] ?? '');
    final formattedDate = createdAt != null
        ? DateFormat('MMM d, yyyy').format(createdAt)
        : 'Unknown date';
    final shortId =
        '#${orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}';

    final isOrderPlaced = rawStatus == 'order placed';
    final sellerItems = _parseSellerItems();

    final isThisCardUpdating = provider.updatingOrderId == orderId;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerOrderDetail(
            order: order,
            sellerProductIds: sellerProductIds,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: kGold.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top strip ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Text(
                    shortId,
                    style: const TextStyle(
                      fontFamily: 'poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kGoldDark,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kGoldLight.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontFamily: 'poppins',
                      fontSize: 11,
                      color: kGoldDark.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 1, color: kBorder.withOpacity(0.6)),

            // ── Product items ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Column(
                children: sellerItems.map((item) {
                  final title = item['title'] ?? 'Untitled product';
                  final qty = item['quantity'] ?? 0;
                  final imageUrl = item['image'] ?? '';
                  final price = item['price'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        _ProductThumb(imageUrl: imageUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2A2A2A),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _MiniChip(
                                    label: 'Qty $qty',
                                    color: kGoldDark,
                                    bg: kGold.withOpacity(0.09),
                                  ),
                                  if (price != null) ...[
                                    const SizedBox(width: 6),
                                    _MiniChip(
                                      label: '₦${_fmtPrice(price)}',
                                      color: const Color(0xFF1A6B3C),
                                      bg: const Color(0xFFEBF8F1),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: kGoldLight,
                          size: 20,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
              child: Column(
                children: [
                  if (sellerItems.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 13,
                            color: kGoldDark.withOpacity(0.4),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${sellerItems.length} items in this order',
                            style: TextStyle(
                              fontFamily: 'poppins',
                              fontSize: 11,
                              color: kGoldDark.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ✅ Action button only for 'order placed'
                  if (isOrderPlaced)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: isThisCardUpdating
                            ? null
                            : () async {
                                await provider.updateOrderStatus(
                                  orderId: orderId,
                                  status: 'shipped',
                                  requesterId:
                                      context.read<AuthProvider>().userId ?? '',
                                );
                              },
                        icon: isThisCardUpdating
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.local_shipping_outlined,
                                size: 17,
                              ),
                        label: Text(
                          isThisCardUpdating ? 'Updating…' : 'Mark as Shipped',
                          style: const TextStyle(
                            fontFamily: 'poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGold,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: kGoldLight,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  if (!isOrderPlaced)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'View details',
                          style: TextStyle(
                            fontFamily: 'poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kGold.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: kGold.withOpacity(0.75),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtPrice(dynamic val) {
    try {
      final n = double.parse(val.toString());
      return NumberFormat('#,##0').format(n);
    } catch (_) {
      return val.toString();
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _ProductThumb extends StatelessWidget {
  final String imageUrl;
  const _ProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(),
              errorWidget: (_, __, ___) => _errorBox(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: kBg1.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 1.8, color: kGold),
          ),
        ),
      );

  Widget _errorBox() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: kBg1.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: kGoldLight,
          size: 22,
        ),
      );
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _MiniChip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
