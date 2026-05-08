import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/provider/productview.dart';
import 'package:peereess/screens/searchscreen.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:peereess/core/app_images.dart';
import 'package:peereess/core/num_extension.dart';

class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> with TickerProviderStateMixin {
  late String selectedCategory;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  late ProductProvider _productProvider;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> categories = [
    {"label": "Bag", "icon": IconsaxPlusLinear.bag_2},
    {"label": "Fashion", "icon": IconsaxPlusLinear.shop},
    {"label": "Clothing", "icon": IconsaxPlusLinear.tag},
    {"label": "Dresses", "icon": IconsaxPlusLinear.woman},
    {"label": "Jeans", "icon": IconsaxPlusLinear.tag_2},
    {"label": "Footwear", "icon": IconsaxPlusLinear.map},
    {"label": "Purses", "icon": IconsaxPlusLinear.bag},
    {"label": "Makeup", "icon": IconsaxPlusLinear.star},
    {"label": "Skincare", "icon": IconsaxPlusLinear.health},
    {"label": "Supplements", "icon": IconsaxPlusLinear.heart},
    {"label": "Jewelry", "icon": IconsaxPlusLinear.diamonds},
    {"label": "Hair", "icon": IconsaxPlusLinear.scissor},
    {"label": "Watches", "icon": IconsaxPlusLinear.clock},
    {"label": "Heels", "icon": IconsaxPlusLinear.map_1},
    {"label": "Sneakers", "icon": IconsaxPlusLinear.map_1},
    {"label": "Accessories", "icon": IconsaxPlusLinear.crown_1},
  ];

  @override
  void initState() {
    super.initState();

    selectedCategory = categories.first['label'] as String;
    _productProvider = context.read<ProductProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productProvider.getExploreProducts(selectedCategory);
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        if (_productProvider.exploreHasMore &&
            !_productProvider.isExploreFetchingMore) {
          _productProvider.getExploreProducts(
            selectedCategory,
            loadMore: true,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _selectCategory(String cat) {
    if (cat == selectedCategory) return;
    setState(() => selectedCategory = cat);
    _fadeController.forward(from: 0);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _productProvider.getExploreProducts(cat);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isConnected) {
      return Container(
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

    Widget productsSliver;

    final exploreProducts = productProvider.exploreProducts;

    if (productProvider.isExploreLoading && exploreProducts.isEmpty) {
      productsSliver = const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(
            child: SizedBox(
              height: 28,
              width: 28,
              child: LogoLoadingIndicator(),
            ),
          ),
        ),
      );
    } else if (exploreProducts.isEmpty) {
      productsSliver = SliverToBoxAdapter(
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xffF0E4D4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 36,
                    color: Color(0xff9D6E2D),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Out of Stock',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff5C3D11),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check back soon',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final availableProducts =
          exploreProducts.where((p) => p.variants.isNotEmpty).toList();

      productsSliver = SliverFadeTransition(
        opacity: _fadeAnimation,
        sliver: SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = availableProducts[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/productDetails',
                      arguments: {'product': product},
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 233, 226, 226),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child: product.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: product.imageUrl.first,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (_, __) => Container(
                                      color: Colors.grey[200],
                                    ),
                                    errorWidget: (_, __, ___) => Image.asset(
                                        AppImages.peereesslogo,
                                        fit: BoxFit.cover),
                                  )
                                : Image.asset(
                                    AppImages.jewery,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff3D2200),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₦${(product.variants.first['price'] ?? 0).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff9D6E2D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: availableProducts.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── TOP BAR ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 350),
                          pageBuilder: (_, __, ___) => const Searchscreen(),
                          transitionsBuilder: (_, animation, __, child) =>
                              FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 233, 226, 226),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 10),
                          Icon(
                            IconsaxPlusLinear.search_normal_1,
                            color: Color(0xff9D6E2D),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Search products...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: 12.getHeightWhiteSpacing),

              // ── CATEGORY CHIPS ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    spacing: 4, // horizontal space between items
                    runSpacing: 4, // vertical space between rows
                    children: categories.map((cat) {
                      final label = cat['label'] as String;
                      final isSelected = selectedCategory == label;

                      return GestureDetector(
                        onTap: () => _selectCategory(label),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xff9D6E2D)
                                : const Color.fromARGB(255, 233, 226, 226),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xff9D6E2D)
                                          .withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'poppins',
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: 12.getHeightWhiteSpacing),

              // ── SECTION HEADER ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Text(
                        selectedCategory,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'poppins',
                          fontWeight: FontWeight.w700,
                          color: Color(0xff3D2200),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/categoryscreen',
                          arguments: {
                            'type': selectedCategory,
                            'allProducts': productProvider.products,
                          },
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xff9D6E2D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: Color(0xff9D6E2D),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: 10.getHeightWhiteSpacing),

              // ── PRODUCTS GRID ─────────────────────────────────────────
              productsSliver,

              if (productProvider.isExploreFetchingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SKELETON LOADING CARD ─────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        final opacity = 0.4 + (_shimmer.value * 0.4);
        return Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(200, 185, 165, opacity),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }
}
