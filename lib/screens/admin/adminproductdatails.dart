import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/databases/config/appwrite.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/screens/admin/widget/productupdatewidget.dart';
import 'package:provider/provider.dart';

class AdminProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const AdminProductDetailPage({super.key, required this.product});

  @override
  State<AdminProductDetailPage> createState() => _AdminProductDetailPageState();
}

class _AdminProductDetailPageState extends State<AdminProductDetailPage> {
  Map<String, dynamic>? seller;
  bool isLoadingSeller = true;
  bool isDeleting = false;
  late Map<String, dynamic> product;

  @override
  void initState() {
    super.initState();
    product = widget.product;
    _fetchSeller();
  }

  Future<void> _fetchSeller() async {
    final sellerUserId = product['userId'];
    if (sellerUserId == null || sellerUserId.toString().isEmpty) {
      setState(() => isLoadingSeller = false);
      return;
    }

    try {
      final res = await AppwriteConfig.tablesDB.listRows(
        databaseId: AppwriteConfig.databaseId,
        tableId: AppwriteConfig.userCollection,
        queries: [Query.equal('userId', sellerUserId)],
      );

      if (res.rows.isNotEmpty) {
        setState(() {
          seller = res.rows.first.data;
          isLoadingSeller = false;
        });
      } else {
        setState(() => isLoadingSeller = false);
      }
    } catch (e) {
      debugPrint("Get seller error: $e");
      setState(() => isLoadingSeller = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoadingSeller = true;
      seller = null;
    });
    await _fetchSeller();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductUploadProvider>(context, listen: false);

    final String title = product["title"] ?? "Unnamed Product";
    final String description = product["description"] ?? "No description";

    final num discountNum = product["discount"] ?? 0;
    final int discount = discountNum.toInt();

    final List images = product["imageUrl"] ?? [];
    final List colors = product["colors"] ?? [];
    final List variants = product["variants"] ?? [];
    final String status = product["status"] ?? "";
    final String category = product["category"] ?? "";
    final String shippedFrom = product["shippedFrom"] ?? "";

    final num ratingNum = product["rating"] ?? 0;
    final double rating = ratingNum.toDouble();

    final num deliveryDaysNum = product["deliveryDays"] ?? 0;
    final int deliveryDays = deliveryDaysNum.toInt();

    final num deliveryFeeNum = product["deliveryFee"] ?? 0;
    final int deliveryFee = deliveryFeeNum.toInt();

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
            const Text("Product Details", style: TextStyle(fontSize: 18)),
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
        child: RefreshIndicator(
          color: const Color(0xff9D6E2D),
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: images[index],
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            width: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            width: 200,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'approved'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Status: ${status.isEmpty ? "pending" : status}",
                    style: TextStyle(
                      color:
                          status == 'approved' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Product Info Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Product Information",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _buildInfoRow("Category", category),
                        _buildInfoRow("Description", description),
                        _buildInfoRow("Shipped From", shippedFrom),
                        _buildInfoRow("Delivery Fee", "₦$deliveryFee"),
                        _buildInfoRow("Delivery Days", "$deliveryDays days"),
                        _buildInfoRow("Discount", "$discount%"),
                        _buildInfoRow(
                          "Rating",
                          "${rating.toStringAsFixed(1)} / 5.0",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Colors Section
                if (colors.isNotEmpty) ...[
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Available Colors",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(colors.join(", ")),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Variants Section
                if (variants.isNotEmpty) ...[
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Product Variants",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          ...variants.map((v) {
                            final Map<String, dynamic> varData =
                                v is String ? jsonDecode(v) : v;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${varData["description"] ?? 'N/A'}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Price: ₦${varData["price"] ?? 0}",
                                        ),
                                        Text(
                                          "Stock: ${varData["stock"] ?? 0}",
                                          style: TextStyle(
                                            color: (varData["stock"] ?? 0) > 0
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Seller Information Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Seller Information",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        if (isLoadingSeller)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (seller == null)
                          const Text("Seller information not found")
                        else ...[
                          _buildInfoRow(
                            "Business Name",
                            seller!['fullName'] ?? 'N/A',
                          ),
                          _buildInfoRow(
                            "Phone Number",
                            seller!['phoneNumber'] ?? 'N/A',
                          ),
                          _buildInfoRow(
                            "Address",
                            seller!['deliveryAddress'] ?? 'N/A',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                30.getHeightWhiteSpacing,

                // Action Buttons
                AppButtons(
                  onPressed: isDeleting
                      ? () {}
                      : () {
                          final rowId = product["rowId"] ?? '';
                          if (rowId.isNotEmpty) {
                            _confirmDelete(context, provider, rowId);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Invalid product ID"),
                              ),
                            );
                          }
                        },
                  text: isDeleting ? "Deleting..." : "Remove this product",
                ),
                10.getHeightWhiteSpacing,
                AppButtons(
                  text: "Update product details",
                  onPressed: () {
                    final productModel = ProductModel.fromMap(product);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditProductDetailPage(product: productModel),
                      ),
                    );
                  },
                ),
                100.getHeightWhiteSpacing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProductUploadProvider provider,
    String rowId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text(
          "This action cannot be undone. Do you want to delete this product?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isDeleting = true);
              try {
                final userId = context.read<AuthProvider>().userId ?? '';
                await provider.deleteProduct(rowId, userId);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product deleted successfully")),
                );
                Navigator.pop(context);
              } catch (e) {
                debugPrint("Delete error: $e");
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to delete product: $e")),
                );
              } finally {
                if (mounted) setState(() => isDeleting = false);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
