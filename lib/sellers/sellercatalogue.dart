import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/sellers/sellerproductdatails.dart';
import 'package:peereess/sellers/sellerproductsearch.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/sellers/approved_products_screen.dart';
import 'package:peereess/sellers/pending_products_screen.dart';
import 'package:peereess/sellers/removed_products_screen.dart';
import 'package:peereess/sellers/outofstock_products_screen.dart';
import 'package:peereess/sellers/seller_filtered_product_list.dart';

class SellerCatalogueScreen extends StatefulWidget {
  const SellerCatalogueScreen({super.key});

  @override
  State<SellerCatalogueScreen> createState() => _SellerCatalogueScreenState();
}

class _SellerCatalogueScreenState extends State<SellerCatalogueScreen> {
  Timer? _autoRefreshTimer;
  DateTime? _lastRefreshed;

  static const _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) _load(silent: true);
    });
  }

  Future<void> _load({bool silent = false}) async {
    final userId = context.read<AuthProvider>().userId ?? '';
    if (userId.isEmpty) return;
    await context.read<ProductUploadProvider>().fetchSellerProducts(userId);
    if (mounted) setState(() => _lastRefreshed = DateTime.now());
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  String _timeAgo() {
    if (_lastRefreshed == null) return '';
    final diff = DateTime.now().difference(_lastRefreshed!);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 228, 213, 193), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── PINNED HEADER (never scrolls) ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
                child: Row(
                  children: [
                    // Back button (left)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.arrow_back,
                            size: 18, color: Color(0xff9D6E2D)),
                      ),
                    ),

                    // Title (centered between the two icon buttons)
                    const Expanded(
                      child: Text(
                        'My Catalogue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Search button (right)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Sellerproductsearch(),
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
              5.getHeightWhiteSpacing,

              // ── SCROLLABLE BODY (everything scrolls under the header) ──
              Expanded(
                child: Consumer<ProductUploadProvider>(
                  builder: (context, provider, _) {
                    // ── Exclude deleted products ──────────────────────
                    final all = provider.sellerProducts
                        .where((p) =>
                            (p['status']?.toString().toLowerCase() ?? '') !=
                            'deleted')
                        .toList();

                    final approved =
                        all.where((p) => p['status'] == 'approved').toList();
                    final pending =
                        all.where((p) => p['status'] == 'pending').toList();
                    final removed =
                        all.where((p) => p['status'] == 'removed').toList();
                    final soldOut = all.where(isSoldOut).toList();

                    return RefreshIndicator(
                      color: const Color(0xff9D6E2D),
                      onRefresh: () => _load(),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // ── Stat cards ────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _StatCard(
                                        label: 'Total',
                                        count: all.length,
                                        icon: IconsaxPlusLinear.category,
                                        color:
                                            const Color.fromARGB(255, 3, 59, 6),
                                        textColor: Colors.white,
                                        onTap: null,
                                      ),
                                      const SizedBox(width: 8),
                                      _StatCard(
                                        label: 'Approved',
                                        count: approved.length,
                                        icon: IconsaxPlusLinear.tick_circle,
                                        color: Colors.green.shade100,
                                        textColor: Colors.green.shade800,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ApprovedProductsScreen(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _StatCard(
                                        label: 'Pending',
                                        count: pending.length,
                                        icon: IconsaxPlusLinear.clock,
                                        color: Colors.orange.shade100,
                                        textColor: Colors.orange.shade800,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PendingProductsScreen(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _StatCard(
                                        label: 'Removed',
                                        count: removed.length,
                                        icon: IconsaxPlusLinear.trash,
                                        color: Colors.red.shade100,
                                        textColor: Colors.red.shade800,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RemovedProductsScreen(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _StatCard(
                                        label: 'Out of stock',
                                        count: soldOut.length,
                                        icon: IconsaxPlusLinear.shopping_cart,
                                        color: Colors.indigo.shade100,
                                        textColor: Colors.indigo.shade800,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const OutOfStockProductsScreen(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Divider ───────────────────────────────
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child:
                                  Divider(height: 1, color: Color(0xFFE8E0D8)),
                            ),
                          ),

                          // ── All products label ────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                              child: Row(
                                children: [
                                  const Text(
                                    'All',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'poppins',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color.fromARGB(255, 3, 59, 6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      all.length.toString(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Product list ──────────────────────────
                          provider.isLoading && all.isEmpty
                              ? const SliverFillRemaining(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xff9D6E2D)),
                                  ),
                                )
                              : all.isEmpty
                                  ? SliverFillRemaining(
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(IconsaxPlusLinear.box,
                                                size: 48,
                                                color: Colors.grey.shade400),
                                            const SizedBox(height: 12),
                                            Text(
                                              'No products found',
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 0, 12, 24),
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) => _ProductTile(
                                            product: all[index],
                                            index: index,
                                            onChanged: () =>
                                                _load(silent: true),
                                          ),
                                          childCount: all.length,
                                        ),
                                      ),
                                    ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Auto-refresh indicator badge ───────────────────────────────────────────────
class _RefreshIndicatorBadge extends StatefulWidget {
  final bool isLoading;
  final String lastRefreshedLabel;
  final VoidCallback onTap;

  const _RefreshIndicatorBadge({
    required this.isLoading,
    required this.lastRefreshedLabel,
    required this.onTap,
  });

  @override
  State<_RefreshIndicatorBadge> createState() => _RefreshIndicatorBadgeState();
}

class _RefreshIndicatorBadgeState extends State<_RefreshIndicatorBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(_RefreshIndicatorBadge old) {
    super.didUpdateWidget(old);
    if (widget.isLoading && !_spinController.isAnimating) {
      _spinController.repeat();
    } else if (!widget.isLoading && _spinController.isAnimating) {
      _spinController.stop();
      _spinController.reset();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xff9D6E2D).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xff9D6E2D).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _spinController,
              child: Icon(
                Icons.sync_rounded,
                size: 13,
                color: widget.isLoading
                    ? const Color(0xff9D6E2D)
                    : const Color(0xff9D6E2D).withOpacity(0.55),
              ),
            ),
            if (widget.lastRefreshedLabel.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                widget.isLoading ? 'Refreshing…' : widget.lastRefreshedLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'poppins',
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff9D6E2D).withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onTap != null
                  ? textColor.withOpacity(0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: textColor, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product Tile ───────────────────────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final int index;
  final VoidCallback onChanged;

  const _ProductTile({
    required this.product,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String title = (product['title'] ?? 'Untitled').toString();
    final String status = (product['status'] ?? 'pending').toString();
    final List<dynamic> images = product['imageUrl'] as List<dynamic>? ?? [];
    final String? imageUrl = images.isNotEmpty ? images.first.toString() : null;

    final List<dynamic> variants = product['variants'] as List<dynamic>? ?? [];
    double minPrice = 0;
    int totalStock = 0;

    for (final v in variants) {
      try {
        final Map<String, dynamic> vm = v is String
            ? Map<String, dynamic>.from(jsonDecode(v))
            : Map<String, dynamic>.from(v as Map);

        final price = vm['price'] ?? 0;
        final priceDouble = price is num
            ? price.toDouble()
            : double.tryParse(price.toString()) ?? 0;

        final stock = vm['stock'] ?? 0;
        final stockInt =
            stock is int ? stock : int.tryParse(stock.toString()) ?? 0;

        if (minPrice == 0 || priceDouble < minPrice) minPrice = priceDouble;
        totalStock += stockInt;
      } catch (_) {}
    }

    Color statusColor;
    Color statusBg;
    String statusLabel;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green.shade700;
        statusBg = Colors.green.shade50;
        statusLabel = 'Approved';
        break;
      case 'pending':
        statusColor = Colors.orange.shade700;
        statusBg = Colors.orange.shade50;
        statusLabel = 'Pending';
        break;
      case 'removed':
        statusColor = Colors.red.shade700;
        statusBg = Colors.red.shade50;
        statusLabel = 'Removed';
        break;
      default:
        statusColor = Colors.grey.shade700;
        statusBg = Colors.grey.shade100;
        statusLabel = status;
    }

    final formatter = NumberFormat('#,##0', 'en_US');

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SellerProductDetails(product: product),
          ),
        );
        if (result == true && context.mounted) {
          onChanged();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 233, 226, 226),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      minPrice > 0 ? '₦${formatter.format(minPrice)}' : '—',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xff9D6E2D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stock: $totalStock',
                      style: TextStyle(
                        fontSize: 11,
                        color: totalStock <= 0
                            ? Colors.red.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 28),
    );
  }
}
