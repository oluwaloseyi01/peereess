import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/screens/widgets/product_collectionwidget.dart';
import 'package:provider/provider.dart';

class Save extends StatefulWidget {
  const Save({super.key});

  @override
  State<Save> createState() => _SaveState();
}

class _SaveState extends State<Save> {
  bool _hasRefreshed = false; // ✅ track if refresh ran once

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Auto refresh liked products once
    if (!_hasRefreshed) {
      _hasRefreshed = true;
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null && userId.isNotEmpty) {
        context.read<ProductProvider>().loadUserLikes(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final userId = authProvider.userId;

    // ✅ Use likedProductIds instead of likedBy
    final likedProducts = productProvider.products
        .where((p) =>
            userId != null &&
            productProvider.likedProductIds.contains(p.productId))
        .toList();

    return Scaffold(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: Color(0xff9D6E2D),
                          ),
                        ),
                      ),
                    ),

                    // Center Title
                    Expanded(
                      child: Center(
                        child: const Text(
                          'Wishlist',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "poppins",
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Right side (same width balance)
                    if (likedProducts.isEmpty)
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/searchscreen'),
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
                      )
                    else
                      GestureDetector(
                        onTap: () async {
                          if (userId == null || userId.isEmpty) return;

                          await context
                              .read<ProductProvider>()
                              .clearAllLikes(userId: userId);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.red.shade200, width: 1),
                          ),
                          child: Text(
                            "Clear all",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                10.getHeightWhiteSpacing,

                // ── Grid ────────────────────────────────────────────
                Expanded(
                  child: Consumer<ProductProvider>(
                    builder: (context, productProvider, _) {
                      final likedProducts = productProvider.products
                          .where((p) =>
                              userId != null &&
                              productProvider.likedProductIds
                                  .contains(p.productId))
                          .toList();

                      if (likedProducts.isEmpty) {
                        return SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.favorite_border,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                "No saved items yet",
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return MasonryGridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 20),
                        gridDelegate:
                            const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                        ),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 5,
                        itemCount: likedProducts.length,
                        itemBuilder: (context, index) {
                          final product = likedProducts[index];
                          return ProductCollectionwidget(product: product);
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
