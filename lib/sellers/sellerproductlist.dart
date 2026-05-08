import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/sellers/sellerproductdatails.dart';
import 'package:provider/provider.dart';

// ─── Brand colours ─────────────────────────────────────────────────────────
const Color _kGold = Color(0xFFB0864C);
const Color _kGoldLight = Color(0xFFD4AA78);
const Color _kGoldDark = Color(0xFF7A5C2E);
const Color _kBg1 = Color.fromARGB(255, 217, 194, 162);

class SellerProductList extends StatefulWidget {
  const SellerProductList({super.key});

  @override
  State<SellerProductList> createState() => _SellerProductListState();
}

class _SellerProductListState extends State<SellerProductList> with RouteAware {
  final _fmt = NumberFormat("#,##0", "en_US");

  // ✅ RouteObserver lets us detect when this page is resumed after
  // the user navigates back from SellerProductDetails — no server
  // call needed for the trigger itself, just re-fetch from provider.
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register with the RouteObserver so didPopNext fires correctly
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called by RouteObserver when user pops back TO this page
  /// (e.g. returns from SellerProductDetails).
  @override
  void didPopNext() {
    // ✅ Auto-refresh the list whenever we come back — no extra server
    // action required, just re-fetch the seller's product list.
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      await context.read<ProductUploadProvider>().fetchSellerProducts(userId);
    }
  }

  /// Opens the detail page and refreshes the list when the user returns,
  /// as a fallback for cases where RouteObserver may not fire (e.g. dialog
  /// routes or custom transitions).
  Future<void> _openProduct(Map<String, dynamic> product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SellerProductDetails(product: product)),
    );

    // ✅ Always refresh on return — covers every navigation path
    // (back button, swipe, Navigator.pop, etc.) without needing
    // the detail page to return a specific result value.
    _loadProducts();
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
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isConnected) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kBg1, Colors.white],
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
              'Uploaded Products',
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
        child: Consumer<ProductUploadProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingProducts) {
              return const Center(child: LogoLoadingIndicator());
            }

            if (provider.sellerProducts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: _kGold.withOpacity(0.25),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No products uploaded yet.',
                      style: TextStyle(
                        fontFamily: 'poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kGoldDark.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: _kGold,
              onRefresh: _loadProducts,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: provider.sellerProducts.length,
                itemBuilder: (context, index) {
                  final product = provider.sellerProducts[index];
                  return _ProductCard(
                    product: product,
                    formatter: _fmt,
                    statusColor: _statusColor,
                    statusBg: _statusBg,
                    // ✅ Navigation is handled by the parent State so it
                    // can await the push and trigger _loadProducts on return.
                    onTap: () => _openProduct(product),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final NumberFormat formatter;
  final Color Function(String) statusColor;
  final Color Function(String) statusBg;
  // ✅ Navigation callback owned by the parent State
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.formatter,
    required this.statusColor,
    required this.statusBg,
    required this.onTap,
  });

  double _firstVariantPrice() {
    final variants = product['variants'] as List<dynamic>? ?? [];
    if (variants.isEmpty) return 0;
    try {
      final vm = variants[0] is String
          ? Map<String, dynamic>.from(jsonDecode(variants[0]))
          : Map<String, dynamic>.from(variants[0]);
      return (vm['price'] ?? 0).toDouble();
    } catch (_) {
      return 0;
    }
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

    return GestureDetector(
      // ✅ Uses the callback from parent — no Navigator call here
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product image ────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 100,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 100,
                        height: 110,
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
                      errorWidget: (context, url, error) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            // ── Info ──────────────────────────────────────────────────
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

                    // Quantity
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_rounded,
                          size: 11,
                          color: _kGold.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Qty: ${product['quantity'] ?? 0}',
                          style: TextStyle(
                            fontFamily: 'poppins',
                            fontSize: 11,
                            color: _kGoldDark.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Price row
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
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 110,
      decoration: BoxDecoration(
        color: _kBg1.withOpacity(0.5),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: _kGold,
        size: 28,
      ),
    );
  }
}
