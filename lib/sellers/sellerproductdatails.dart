import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/sellers/sellerproductedit.dart';
import 'package:provider/provider.dart';

// ─── Brand colours ─────────────────────────────────────────────────────────
const Color _kGold = Color(0xFFB0864C);
const Color _kGoldLight = Color(0xFFD4AA78);
const Color _kGoldDark = Color(0xFF7A5C2E);
const Color _kBg1 = Color.fromARGB(255, 217, 194, 162);

class SellerProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;
  const SellerProductDetails({super.key, required this.product});

  @override
  State<SellerProductDetails> createState() => _SellerProductDetailsState();
}

class _SellerProductDetailsState extends State<SellerProductDetails> {
  final _fmt = NumberFormat("#,##0", "en_US");
  int _selectedImage = 0;
  bool _removing = false;

  late Map<String, dynamic> _product;

  @override
  void initState() {
    super.initState();
    _product = Map<String, dynamic>.from(widget.product);
  }

  // ── Refresh from server ────────────────────────────────────────────────────
  Future<void> _refreshProduct() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userId == null) return;

    try {
      final res = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({
          'action': 'getProductById',
          'userId': auth.userId,
          'productId': _product['rowId'] ?? _product['productId'] ?? '',
        }),
      );

      final result = jsonDecode(res.responseBody) as Map<String, dynamic>;

      if (result['status'] == true && result['product'] != null && mounted) {
        setState(() {
          _product = Map<String, dynamic>.from(result['product'] as Map);
          _selectedImage = 0;
        });
      }
    } catch (e) {
      debugPrint('_refreshProduct error: $e');
    }
  }

  // ── Status helpers ─────────────────────────────────────────────────────────
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

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.pending_rounded;
      case 'removed':
        return Icons.remove_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ── Update status ──────────────────────────────────────────────────────────
  // Key fix: apply the new status to _product IMMEDIATELY (optimistic update),
  // rebuild the UI at once, THEN call the server in the background.
  // If the server call fails we roll back and show an error.
  Future<void> _updateProductStatus(
    BuildContext context,
    String newStatus,
  ) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    // ── 1. Snapshot for rollback ───────────────────────────────────────────
    final previousProduct = Map<String, dynamic>.from(_product);

    // ── 2. Apply change locally RIGHT NOW ─────────────────────────────────
    setState(() {
      _product = {..._product, 'status': newStatus};
      _removing = true;
    });

    // ── 3. Show instant feedback banner ───────────────────────────────────
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'removed'
                  ? 'Removing product…'
                  : 'Reuploading for approval…',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: newStatus == 'removed'
                ? const Color(0xFF8B1A1A)
                : const Color(0xFF1A6B3C),
          ),
        );
    }

    // ── 4. Send to server ──────────────────────────────────────────────────
    try {
      final res = await AppwriteConfig.functions.createExecution(
        functionId: AppwriteConfig.productFunction,
        body: jsonEncode({
          'action': 'updateProductStatus',
          'userId': auth.userId,
          'productId': _product['rowId'] ?? '',
          'status': newStatus,
        }),
      );

      final result = jsonDecode(res.responseBody) as Map<String, dynamic>;

      if (!context.mounted) return;

      if (result['status'] == true) {
        // Success — do a silent server refresh to sync any server-side fields
        // (e.g. updatedAt), but keep the UI showing the new status already.
        await _refreshProduct();

        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  newStatus == 'removed'
                      ? 'Product removed successfully.'
                      : 'Product submitted for approval.',
                ),
                backgroundColor: newStatus == 'removed'
                    ? const Color(0xFF8B1A1A)
                    : const Color(0xFF1A6B3C),
              ),
            );
        }
      } else {
        // ── 5a. Server rejected — roll back ─────────────────────────────
        if (mounted) {
          setState(() => _product = previousProduct);
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to update product.'),
                backgroundColor: Colors.red.shade700,
              ),
            );
        }
      }
    } catch (e) {
      // ── 5b. Network error — roll back ──────────────────────────────────
      if (mounted) {
        setState(() => _product = previousProduct);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _product['imageUrl'] as List<dynamic>? ?? [];
    final variants = _product['variants'] as List<dynamic>? ?? [];
    final colorsList = (_product['colors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final int discount = _product['discount'] ?? 0;
    final String status = _product['status'] ?? '';

    final bool canRemove =
        status.toLowerCase() == 'approved' || status.toLowerCase() == 'pending';
    final bool canEdit =
        status.toLowerCase() == 'pending' || status.toLowerCase() == 'removed';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(0, 5, 8, 5),
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
                  'Product details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
        backgroundColor: Color.fromARGB(255, 228, 213, 193),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProduct,
        color: _kGold,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 228, 213, 193), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image gallery ──────────────────────────────────────────
                if (images.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: images[_selectedImage].toString(),
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 260,
                        color: _kBg1.withOpacity(0.4),
                        child: const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kGold),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 260,
                        color: _kBg1.withOpacity(0.4),
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined,
                              color: _kGold, size: 40),
                        ),
                      ),
                    ),
                  ),
                  if (images.length > 1) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 64,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, i) {
                          final selected = i == _selectedImage;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedImage = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? _kGold : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                            color: _kGold.withOpacity(0.3),
                                            blurRadius: 6)
                                      ]
                                    : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: images[i].toString(),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                      width: 60,
                                      height: 60,
                                      color: _kBg1.withOpacity(0.4)),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: _kBg1.withOpacity(0.4),
                                    child: const Icon(Icons.broken_image,
                                        size: 20, color: _kGold),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],

                // ── Title + animated status badge ──────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _product['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontFamily: 'poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2A2A2A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (status.isNotEmpty)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          key: ValueKey(status),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _statusBg(status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_statusIcon(status),
                                  size: 12, color: _statusColor(status)),
                              const SizedBox(width: 4),
                              Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor(status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Description ────────────────────────────────────────────
                _SectionCard(
                  icon: Icons.description_rounded,
                  title: 'Description',
                  child: Text(
                    _product['description'] ?? 'No description available.',
                    style: const TextStyle(
                      fontFamily: 'poppins',
                      fontSize: 13,
                      color: Color(0xFF4A4A4A),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Details ────────────────────────────────────────────────
                _SectionCard(
                  icon: Icons.info_outline_rounded,
                  title: 'Details',
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.category_rounded,
                        label: 'Category',
                        value: _product['category'] ?? '-',
                      ),
                      if (colorsList.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _kBg1.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.palette_rounded,
                                  size: 14, color: _kGold),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Colors',
                                    style: TextStyle(
                                      fontFamily: 'poppins',
                                      fontSize: 10,
                                      color: _kGoldDark.withOpacity(0.55),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: colorsList
                                        .map((c) => _Tag(label: c))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.local_offer_rounded,
                        label: 'Discount',
                        value: discount > 0 ? '$discount%' : 'No discount',
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.star_rounded,
                        label: 'Rating',
                        value: '${_product['rating'] ?? 0}',
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.local_shipping_rounded,
                        label: 'Delivery',
                        value: '${_product['deliveryDays'] ?? 0} days',
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.location_on_rounded,
                        label: 'Shipped From',
                        value: _product['shippedFrom'] ?? '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Variants ───────────────────────────────────────────────
                if (variants.isNotEmpty)
                  _SectionCard(
                    icon: Icons.tune_rounded,
                    title: 'Variants & Pricing',
                    child: Column(
                      children: variants.asMap().entries.map((entry) {
                        final i = entry.key;
                        final v = entry.value;
                        final vm = v is String
                            ? Map<String, dynamic>.from(jsonDecode(v))
                            : Map<String, dynamic>.from(v);
                        final double price = (vm['price'] ?? 0).toDouble();
                        final double discountedPrice = discount > 0
                            ? price - (price * discount / 100)
                            : price;

                        return Column(
                          children: [
                            if (i > 0)
                              Divider(
                                  height: 16, color: _kGold.withOpacity(0.1)),
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _kGold.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        fontFamily: 'poppins',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _kGold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vm['description'] ?? '-',
                                        style: const TextStyle(
                                          fontFamily: 'poppins',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2A2A2A),
                                        ),
                                      ),
                                      if (vm.containsKey('stock') &&
                                          vm['stock'] != null)
                                        Text(
                                          ' ${vm['stock']} in stock',
                                          style: const TextStyle(
                                            fontFamily: 'poppins',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF2A2A2A),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (discount > 0)
                                      Text(
                                        '₦${_fmt.format(price)}',
                                        style: const TextStyle(
                                          fontFamily: 'poppins',
                                          fontSize: 10,
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    Text(
                                      '₦${_fmt.format(discountedPrice)}',
                                      style: TextStyle(
                                        fontFamily: 'poppins',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: discount > 0
                                            ? const Color(0xFF1A6B3C)
                                            : _kGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 28),

                // ── Reupload button (removed only) ─────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: status.toLowerCase() == 'removed'
                      ? SizedBox(
                          key: const ValueKey('reupload'),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _removing
                                ? null
                                : () =>
                                    _updateProductStatus(context, 'pending'),
                            icon: _removing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.upload_rounded, size: 18),
                            label: Text(
                              _removing
                                  ? 'Reuploading...'
                                  : 'Reupload for Approval',
                              style: const TextStyle(
                                fontFamily: 'poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A6B3C),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF1A6B3C).withOpacity(0.5),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-reupload')),
                ),

                // ── Edit button (pending / removed only) ───────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: canEdit
                      ? Padding(
                          key: const ValueKey('edit'),
                          padding: const EdgeInsets.only(top: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SellerProductEdit(
                                      productId: _product['productId'] ??
                                          _product['rowId'] ??
                                          '',
                                      productData: _product,
                                    ),
                                  ),
                                );
                                if (result == true && mounted) {
                                  await _refreshProduct();
                                }
                              },
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text(
                                'Edit Product',
                                style: TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kGold,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-edit')),
                ),

                // ── Remove button (approved / pending only) ────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: canRemove
                      ? Padding(
                          key: const ValueKey('remove'),
                          padding: const EdgeInsets.only(top: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _removing
                                  ? null
                                  : () =>
                                      _updateProductStatus(context, 'removed'),
                              icon: _removing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(
                                      Icons.remove_circle_outline_rounded,
                                      size: 18),
                              label: Text(
                                _removing ? 'Removing...' : 'Remove Product',
                                style: const TextStyle(
                                  fontFamily: 'poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1A1A),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFF8B1A1A).withOpacity(0.5),
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-remove')),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: _kGold),
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

// ─────────────────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
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

// ─────────────────────────────────────────────────────────────────────────────
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
