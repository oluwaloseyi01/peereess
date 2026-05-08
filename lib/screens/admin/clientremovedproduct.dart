import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/screens/admin/adminproductdatails.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class AdminProductRejectedPage extends StatefulWidget {
  const AdminProductRejectedPage({super.key});

  @override
  State<AdminProductRejectedPage> createState() =>
      _AdminProductRejectedPageState();
}

class _AdminProductRejectedPageState extends State<AdminProductRejectedPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductUploadProvider>().fetchPendingProductsForAdmin();
    });
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
            10.getWidthWhiteSpacing,
            const Text("Removed Products", style: TextStyle(fontSize: 18)),
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
        child: Consumer<ProductUploadProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingProducts) {
              return const Center(child: CircularProgressIndicator());
            }

            // ✅ Filter to show ONLY rejected/removed products
            final rejectedProducts = provider.sellerProducts.where((product) {
              final status = (product["status"] ?? "").toString().toLowerCase();
              return status == "rejected" || status == "removed";
            }).toList();

            if (rejectedProducts.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No removed products",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // ✅ Header with count

                // ✅ Product List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: rejectedProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = rejectedProducts[index];
                      final String rowId = product["rowId"] ?? '';
                      final String title =
                          product["title"] ?? "Unnamed product";
                      final List images = product["imageUrl"] ?? [];
                      final String status = product["status"] ?? "rejected";
                      final String category = product["category"] ?? "";

                      // Extract variants to calculate total stock
                      final List variants = product["variants"] ?? [];
                      int totalStock = 0;
                      for (var variant in variants) {
                        final Map<String, dynamic> varData =
                            variant is String ? {} : variant;
                        totalStock += (varData['stock'] as num?)?.toInt() ?? 0;
                      }

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminProductDetailPage(product: product),
                              ),
                            ).then((_) {
                              // Refresh list when returning
                              provider.fetchPendingProductsForAdmin();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: images.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: images.first,
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                height: 100,
                                                width: 100,
                                                color: Colors.grey[200],
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                height: 100,
                                                width: 100,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              height: 100,
                                              width: 100,
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          if (category.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                category,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.inventory_2_outlined,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),

                                // Action Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _confirmPermanentDelete(
                                        context,
                                        provider,
                                        rowId,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      icon: const Icon(
                                        IconsaxPlusLinear.trash,
                                        size: 18,
                                      ),
                                      label: const Text("Delete"),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () => _confirmRestore(
                                        context,
                                        provider,
                                        rowId,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.restore, size: 18),
                                      label: const Text("Restore"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmRestore(
    BuildContext context,
    ProductUploadProvider provider,
    String rowId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Restore Product"),
        content: const Text(
          "Are you sure you want to restore this product to pending?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final requesterId = context.read<AuthProvider>().userId ?? '';
                await provider.approveProduct(rowId, requesterId);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Product restored successfully"),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                debugPrint("Restore error: $e");
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to restore product: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Restore"),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(
    BuildContext context,
    ProductUploadProvider provider,
    String rowId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text(
          "This will permanently delete this product. Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userId = context.read<AuthProvider>().userId ?? '';
                await provider.deleteProduct(rowId, userId);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product deleted successfully")),
                );
              } catch (e) {
                debugPrint("Delete error: $e");
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to delete product: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
