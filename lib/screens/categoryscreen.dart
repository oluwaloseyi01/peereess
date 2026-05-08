import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/cart_provider.dart';
import 'package:peereess/provider/home_provider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/screens/widgets/product_collectionwidget.dart';
import 'package:provider/provider.dart';

class Categoryscreen extends StatefulWidget {
  final String categoryType;
  final List<ProductModel> allProducts;

  const Categoryscreen({
    super.key,
    required this.categoryType,
    required this.allProducts,
  });

  @override
  State<Categoryscreen> createState() => _CategoryscreenState();
}

class _CategoryscreenState extends State<Categoryscreen> {
  int selectedFilter = 0;
  final ScrollController _scrollController = ScrollController();
  late ProductProvider _productProvider;

  List<ProductModel> _displayProducts = [];
  int _lastSourceLength = 0;

  String get _formattedcategoryType {
    if (widget.categoryType.isEmpty) return "categories";
    return "${widget.categoryType[0].toUpperCase()}${widget.categoryType.substring(1)}";
  }

  void _applyFilter() {
    final source = List<ProductModel>.from(_productProvider.categoryProducts);
    if (selectedFilter == 0) {
      source.shuffle(Random());
    } else {
      source.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    _displayProducts = source;
    _lastSourceLength = source.length;
  }

  @override
  void initState() {
    super.initState();

    _productProvider = context.read<ProductProvider>();
    _productProvider.addListener(_onProductsUpdated);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        if (_productProvider.categoryHasMore &&
            !_productProvider.isCategoryFetchingMore) {
          _productProvider.getProductsByCategory(
            widget.categoryType,
            loadMore: true,
          );
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productProvider.getProductsByCategory(widget.categoryType);
    });
  }

  void _onProductsUpdated() {
    if (!mounted) return;
    if (_productProvider.categoryProducts.length != _lastSourceLength) {
      setState(() => _applyFilter());
    }
  }

  @override
  void dispose() {
    _productProvider.removeListener(_onProductsUpdated);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();

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
        child: Center(child: LogoLoadingIndicator()),
      );
    }

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
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── TOP ROW: back, title, cart ──────────────────────────
                SliverToBoxAdapter(
                  child: Row(
                    children: [
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
                      10.getWidthWhiteSpacing,
                      Text(
                        _formattedcategoryType,
                        style: const TextStyle(
                          fontSize: 17,
                          fontFamily: 'poppins',
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, _) {
                          final cartCount = cartProvider.cartItems.length;
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              context.read<HomeProvider>().changeIndex(2);
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(
                                  IconsaxPlusBold.shopping_cart,
                                  color: Color(0xff9D6E2D),
                                  size: 24,
                                ),
                                if (cartCount > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      5.getWidthWhiteSpacing,
                    ],
                  ),
                ),

                SliverToBoxAdapter(child: 10.getHeightWhiteSpacing),

                // ── FILTER BUTTONS ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      filterButton(
                        index: 0,
                        icon: Icons.delivery_dining,
                        label: "Express",
                      ),
                      10.getWidthWhiteSpacing,
                      filterButton(
                        index: 1,
                        icon: CupertinoIcons.chevron_down,
                        label: "New product",
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(child: 10.getHeightWhiteSpacing),

                // ── PRODUCTS ────────────────────────────────────────────
                if (productProvider.isCategoryLoading &&
                    _displayProducts.isEmpty)
                  const SliverToBoxAdapter(child: SizedBox.shrink())
                else if (_displayProducts.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.remove_shopping_cart,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Out of Stock",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: MasonryGridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                      ),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 5,
                      itemCount: _displayProducts.length,
                      itemBuilder: (context, index) {
                        return ProductCollectionwidget(
                          product: _displayProducts[index],
                        );
                      },
                    ),
                  ),

                // ── LOAD MORE / END INDICATOR ───────────────────────────
                if (productProvider.isCategoryFetchingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: LogoLoadingIndicator()),
                    ),
                  )
                else if (!productProvider.categoryHasMore)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget filterButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = index;
          _applyFilter();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selectedFilter == index
              ? const Color.fromARGB(255, 225, 214, 173)
              : Colors.grey.shade300,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: selectedFilter == index
                    ? const Color(0xffA68202)
                    : Colors.black,
              ),
              5.getWidthWhiteSpacing,
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selectedFilter == index
                      ? const Color(0xffA68202)
                      : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
