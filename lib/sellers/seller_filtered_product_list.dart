import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/sellers/sellerproductdatails.dart';
import 'package:provider/provider.dart';

const Color _kGold = Color(0xFFB0864C);
const Color _kGoldLight = Color(0xFFD4AA78);
const Color _kGoldDark = Color(0xFF7A5C2E);
const Color _kBg1 = Color.fromARGB(255, 217, 194, 162);

// ── Shared sold-out helper ────────────────────────────────────────────────────
bool isSoldOut(Map<String, dynamic> p) {
  final variants = (p['variants'] as List<dynamic>? ?? []);
  if (variants.isEmpty) return false;
  return variants.every((v) {
    try {
      final Map<String, dynamic> vm = v is String
          ? Map<String, dynamic>.from(jsonDecode(v))
          : Map<String, dynamic>.from(v as Map);
      final stock = vm['stock'];
      final stockInt =
          stock is int ? stock : int.tryParse(stock.toString()) ?? 0;
      return stockInt <= 0;
    } catch (_) {
      return false;
    }
  });
}

// ── Days until permanent deletion (30 days from updatedAt) ───────────────────
int daysUntilDeletion(Map<String, dynamic> product) {
  try {
    final raw = product['updatedAt'];
    DateTime updatedAt;
    if (raw is String) {
      updatedAt = DateTime.parse(raw).toLocal();
    } else if (raw is int) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
    } else {
      return 30;
    }
    final deleteAt = updatedAt.add(const Duration(days: 30));
    final diff = deleteAt.difference(DateTime.now()).inDays;
    return diff.clamp(0, 30);
  } catch (_) {
    return 30;
  }
}

class SellerFilteredProductList extends StatefulWidget {
  final String title;
  final String filterStatus;
  final Color accentColor;
  final String emptyMessage;
  final IconData headerIcon;

  const SellerFilteredProductList({
    super.key,
    required this.title,
    required this.filterStatus,
    required this.accentColor,
    required this.emptyMessage,
    required this.headerIcon,
  });

  @override
  State<SellerFilteredProductList> createState() =>
      _SellerFilteredProductListState();
}

class _SellerFilteredProductListState extends State<SellerFilteredProductList> {
  final _fmt = NumberFormat("#,##0", "en_US");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      await context.read<ProductUploadProvider>().fetchSellerProducts(userId);
    }
  }

  Future<void> _openProduct(Map<String, dynamic> product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SellerProductDetails(product: product)),
    );
    _load();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> all) {
    final nonDeleted = all.where((p) {
      final status = p['status']?.toString().toLowerCase() ?? '';
      return status != 'deleted';
    }).toList();

    if (widget.filterStatus == 'sold_out') {
      return nonDeleted.where(isSoldOut).toList();
    }
    return nonDeleted.where((p) => p['status'] == widget.filterStatus).toList();
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return const Color(0xFF1A6B3C);
      case 'pending':
        return const Color(0xFF8B5E00);
      case 'removed':
        return const Color(0xFF8B1A1A);
      default:
        return Colors.grey;
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return const Color(0xFFD6F5E3);
      case 'pending':
        return const Color(0xFFFFF3D6);
      case 'removed':
        return const Color(0xFFF5D6D6);
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              // ── PINNED HEADER (never scrolls) ───────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
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
                        child: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xff9D6E2D),
                        ),
                      ),
                    ),

                    // Title (centered)
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Invisible placeholder to balance the back button
                    const SizedBox(width: 34),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE8E0D8)),

              // ── SCROLLABLE BODY ─────────────────────────────────
              Expanded(
                child: Consumer<ProductUploadProvider>(
                  builder: (context, provider, _) {
                    final displayed = _filter(provider.sellerProducts);

                    return RefreshIndicator(
                      color: _kGold,
                      onRefresh: _load,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // ── List ──────────────────────────────
                          provider.isLoading
                              ? const SliverFillRemaining(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: _kGold),
                                  ),
                                )
                              : displayed.isEmpty
                                  ? SliverFillRemaining(
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              IconsaxPlusLinear.box,
                                              size: 48,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              widget.emptyMessage,
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
                                          8, 16, 8, 32),
                                      sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            final product = displayed[index];
                                            return _FilteredProductCard(
                                              product: product,
                                              formatter: _fmt,
                                              statusColor: _statusColor,
                                              statusBg: _statusBg,
                                              isRemovedView:
                                                  widget.filterStatus ==
                                                      'removed',
                                              isSoldOutView:
                                                  widget.filterStatus ==
                                                      'sold_out',
                                              onTap: () =>
                                                  _openProduct(product),
                                              onRemove: () =>
                                                  _openProduct(product),
                                              onUpdateStock: () =>
                                                  _openProduct(product),
                                            );
                                          },
                                          childCount: displayed.length,
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

// ── Product Card ──────────────────────────────────────────────────────────────
class _FilteredProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final NumberFormat formatter;
  final Color Function(String) statusColor;
  final Color Function(String) statusBg;
  final bool isRemovedView;
  final bool isSoldOutView;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onUpdateStock;

  const _FilteredProductCard({
    required this.product,
    required this.formatter,
    required this.statusColor,
    required this.statusBg,
    required this.isRemovedView,
    required this.isSoldOutView,
    required this.onTap,
    required this.onRemove,
    required this.onUpdateStock,
  });

  double _firstVariantPrice() {
    final variants = product['variants'] as List<dynamic>? ?? [];
    if (variants.isEmpty) return 0;
    try {
      final vm = variants[0] is String
          ? Map<String, dynamic>.from(jsonDecode(variants[0]))
          : Map<String, dynamic>.from(variants[0] as Map);
      return (vm['price'] ?? 0).toDouble();
    } catch (_) {
      return 0;
    }
  }

  int _totalStock() {
    final variants = product['variants'] as List<dynamic>? ?? [];
    int total = 0;
    for (final v in variants) {
      try {
        final vm = v is String
            ? Map<String, dynamic>.from(jsonDecode(v))
            : Map<String, dynamic>.from(v as Map);
        final stock = vm['stock'];
        total += stock is int ? stock : int.tryParse(stock.toString()) ?? 0;
      } catch (_) {}
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (product['imageUrl'] as List?)?.isNotEmpty == true
        ? product['imageUrl'][0].toString()
        : null;
    final price = _firstVariantPrice();
    final status = product['status']?.toString() ?? '';
    final int discount = product['discount'] ?? 0;
    final double discountedPrice =
        discount > 0 ? price - (price * discount / 100) : price;
    final int stock = _totalStock();

    final int daysLeft = isRemovedView ? daysUntilDeletion(product) : 30;
    final bool hasBanner = isRemovedView || isSoldOutView;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGold.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: _kGold.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image ──────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    bottomLeft: Radius.circular(hasBanner ? 0 : 16),
                  ),
                  child: SizedBox(
                    width: 100,
                    height: 110,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 100,
                            height: 110,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            placeholder: (context, url) => Container(
                              color: _kBg1.withOpacity(0.5),
                              child: const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: _kGold,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),

                // ── Info ────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + status badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product['title'] ?? 'No Title',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2A2A2A),
                                ),
                              ),
                            ),
                            if (status.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBg(status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status[0].toUpperCase() + status.substring(1),
                                  style: TextStyle(
                                    fontFamily: 'poppins',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Category
                        Row(
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 11,
                              color: _kGold.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product['category'] ?? 'N/A',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 11,
                                  color: _kGoldDark.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Stock
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_rounded,
                              size: 11,
                              color: _kGold.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stock: $stock',
                              style: TextStyle(
                                fontFamily: 'poppins',
                                fontSize: 11,
                                color: stock <= 0
                                    ? Colors.red.shade400
                                    : _kGoldDark.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Price
                        Row(
                          children: [
                            if (discount > 0) ...[
                              Text(
                                '₦${formatter.format(price)}',
                                style: const TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 10,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '₦${formatter.format(discountedPrice)}',
                                style: const TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A6B3C),
                                ),
                              ),
                            ] else
                              Text(
                                '₦${formatter.format(price)}',
                                style: const TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _kGold,
                                ),
                              ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: _kGoldLight,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Deletion countdown banner (removed products only) ──
            if (isRemovedView)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: daysLeft <= 3
                      ? const Color(0xFFFFEBEB)
                      : const Color(0xFFFFF4EC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: daysLeft <= 3
                          ? const Color(0xFFE57373).withOpacity(0.4)
                          : const Color(0xFFFFB74D).withOpacity(0.4),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: daysLeft <= 3
                          ? const Color(0xFFC62828)
                          : const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      daysLeft == 0
                          ? 'Permanently deletes today'
                          : 'Permanently deletes in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontFamily: 'poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: daysLeft <= 3
                            ? const Color(0xFFC62828)
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Sold-out action bar ──────────────────────────────
            if (isSoldOutView)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F4EE),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(color: _kGold.withOpacity(0.15)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Remove Product or update stock',
                              style: TextStyle(
                                fontFamily: 'poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: _kGold.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 110,
      color: _kBg1.withOpacity(0.5),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: _kGold,
        size: 28,
      ),
    );
  }
}
