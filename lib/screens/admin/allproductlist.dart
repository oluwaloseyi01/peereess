import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/screens/admin/adminproductdatails.dart';
import 'package:provider/provider.dart';

class AllProductList extends StatefulWidget {
  const AllProductList({super.key});

  @override
  State<AllProductList> createState() => _AllProductListState();
}

class _AllProductListState extends State<AllProductList> {
  late ProductProvider _productProvider;
  late ScrollController _scrollController;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _productProvider = context.read<ProductProvider>();

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productProvider.getProducts();
    });

    // Scroll controller for infinite scroll
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          _productProvider.hasMore &&
          !_productProvider.isFetchingMore) {
        _productProvider.getProducts(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<ProductModel> _filteredProducts() {
    if (_searchQuery.isEmpty) return _productProvider.products;
    return _productProvider.products
        .where(
          (p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
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
            const SizedBox(width: 10),
            const Text('All Products', style: TextStyle(fontSize: 18)),
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
        child: Column(
          children: [
            // ====== Search Field ======
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search product name",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // ====== Product List ======
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  final filtered = _filteredProducts();

                  if (provider.isLoading && provider.products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (filtered.isEmpty) {
                    return const Center(child: Text("No products found"));
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount:
                        filtered.length + (provider.isFetchingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      // Load more spinner at bottom
                      if (index == filtered.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final product = filtered[index];
                      final images = product.imageUrl;
                      final title = product.title;
                      final quantity = product.quantity;
                      final status = product.status;

                      Color statusColor;
                      switch (status) {
                        case 'pending':
                          statusColor = Colors.orange;
                          break;
                        case 'approved':
                          statusColor = Colors.green;
                          break;
                        case 'underreview':
                          statusColor = Colors.blue;
                          break;
                        default:
                          statusColor = Colors.grey;
                      }

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            // ✅ Create a proper map with rowId included
                            final productMap = product.toMap();

                            // ✅ Add rowId using productId
                            productMap['rowId'] = product.productId;

                            debugPrint(
                              "Navigating with product: ${product.title}",
                            );
                            debugPrint("RowId: ${productMap['rowId']}");

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminProductDetailPage(product: productMap),
                              ),
                            ).then((_) {
                              // ✅ Refresh products when returning from detail page
                              _productProvider.getProducts();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Product Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: images.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: images.first,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            width: 70,
                                            height: 70,
                                            color: Colors.grey[200],
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            width: 70,
                                            height: 70,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),

                                const SizedBox(width: 12),

                                // Product Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            "Qty: $quantity",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              (status ?? "unknown")
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Arrow Icon
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
