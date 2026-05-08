import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/sellers/sellerproductdatails.dart';

// reuse colors
const Color kBg1 = Color.fromARGB(255, 217, 194, 162);
const Color kGold = Color(0xFFB0864C);
const Color kGoldDark = Color(0xFF7A5C2E);
const Color kBorder = Color(0xFFEDE0CE);

enum SortType { newest, oldest }

class Sellerproductsearch extends StatefulWidget {
  const Sellerproductsearch({super.key});

  @override
  State<Sellerproductsearch> createState() => _SellerproductsearchState();
}

class _SellerproductsearchState extends State<Sellerproductsearch> {
  String query = '';
  SortType sortType = SortType.newest;

  List<Map<String, dynamic>> _filterAndSort(
      List<Map<String, dynamic>> products) {
    List<Map<String, dynamic>> filtered = products.where((p) {
      // Never show deleted products
      if ((p['status']?.toString().toLowerCase() ?? '') == 'deleted') {
        return false;
      }
      final title = (p['title'] ?? '').toString().toLowerCase();
      final desc = (p['description'] ?? '').toString().toLowerCase();
      return title.contains(query) || desc.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['\$createdAt'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['\$createdAt'] ?? '') ?? DateTime(2000);

      return sortType == SortType.newest
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductUploadProvider>();
    final auth = context.watch<AuthProvider>();

    if (!auth.isConnected) return const SizedBox();

    final products = _filterAndSort(provider.sellerProducts);

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: Colors.grey, height: 0.5),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: kBg1,
        elevation: 0,
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
                child: const Icon(Icons.arrow_back,
                    size: 18, color: Color(0xff9D6E2D)),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Search product",
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kBg1, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 🔍 SEARCH
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => query = val.toLowerCase()),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search product...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 243, 146, 178),
                          width: 1.5,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 🔽 SORT
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<SortType>(
                      value: sortType,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: SortType.newest, child: Text('Newest')),
                        DropdownMenuItem(
                            value: SortType.oldest, child: Text('Oldest')),
                      ],
                      onChanged: (val) => setState(() => sortType = val!),
                    ),
                  ],
                ),
              ),
            ),

            // 📦 LIST
            provider.isLoading && provider.sellerProducts.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xff9D6E2D)),
                    ),
                  )
                : products.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text('No matching products'),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final product = products[i];
                              return _ProductTile(product: product);
                            },
                            childCount: products.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}

// ── PRODUCT TILE ─────────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final title = (product['title'] ?? '').toString();

    final List<dynamic> images = product['imageUrl'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images.first.toString() : null;

    final createdAt = DateTime.tryParse(product['\$createdAt'] ?? '');
    final formattedDate =
        createdAt != null ? DateFormat('MMM d, yyyy').format(createdAt) : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerProductDetails(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (_, __) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
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
                    formattedDate,
                    style: const TextStyle(fontSize: 11),
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
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 24),
    );
  }
}
