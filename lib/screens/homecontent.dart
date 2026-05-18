import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/app_images.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/filter_provider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/provider/productview.dart';
import 'package:peereess/screens/widgets/authcheck.dart';
import 'package:peereess/screens/widgets/category_widget.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/screens/widgets/product_widget.dart';
import 'package:peereess/screens/widgets/skeletonwidget.dart';
import 'package:peereess/screens/widgets/ziprefresh.dart';
import 'package:provider/provider.dart';

const _kCategories = [
  {"title": "Bag", "image": AppImages.bagg, "type": "bag"},
  {"title": "Beauty", "image": AppImages.beauty, "type": "beauty"},
  {"title": "Jewelry", "image": AppImages.jeweryy, "type": "jewelry"},
  {"title": "Shoe", "image": AppImages.shoee, "type": "shoe"},
  {"title": "Wellness", "image": AppImages.wellness, "type": "wellness"},
  {"title": "Gym", "image": AppImages.gymm, "type": "gym"},
  {"title": "Dresses", "image": AppImages.dresss, "type": "Dresses"},
  {"title": "Hair", "image": AppImages.hairr, "type": "hair"},
];

const _kSearchPhrases = [
  'Discover new arrivals...',
  'Shop bestsellers...',
  'Find coveted pieces...',
  'Explore rare finds...',
  'Browse curated styles...',
  'Search top picks...',
  'Uncover timeless classics...',
  'Find what\'s trending...',
];

class Homecontent extends StatefulWidget {
  final ValueNotifier<int>? refreshNotifier;
  const Homecontent({super.key, this.refreshNotifier});

  @override
  State<Homecontent> createState() => _HomecontentState();
}

class _HomecontentState extends State<Homecontent> {
  VoidCallback? _productListener;
  late ProductProvider _productProvider;
  late ProductFilterProvider _filterProvider;
  final ScrollController _scrollController = ScrollController();
  bool _productsLoaded = false;
  int _lastKnownProductCount = 0;
  bool _isRefreshing = false;

  // ── Animated hint ────────────────────────────────────────────────
  int _phraseIndex = 0;
  Timer? _phraseTimer;

  @override
  void initState() {
    super.initState();

    widget.refreshNotifier?.addListener(_onRefreshNotified);

    _productProvider = context.read<ProductProvider>();
    _filterProvider = context.read<ProductFilterProvider>();

    _productListener = () {
      final newCount = _productProvider.products.length;
      if (newCount != _lastKnownProductCount) {
        _lastKnownProductCount = newCount;
        _filterProvider.setProducts(_productProvider.products);
      }
    };
    _productProvider.addListener(_productListener!);

    // ✅ Infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        if (_productProvider.hasMore && !_productProvider.isFetchingMore) {
          final viewedIds =
              context.read<UserProductViewProvider>().viewedProductIds;
          _productProvider.getProducts(loadMore: true, viewedIds: viewedIds);
        }
      }
    });

    // ── Cycle hint text every 3 seconds ─────────────────────────────
    _phraseTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % _kSearchPhrases.length;
        });
      }
    });

    // ✅ Load products immediately — no auth required for public browsing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_productsLoaded) {
        _loadProducts();
      }
    });
  }

  Future<void> _onRefreshNotified() async {
    await _doRefresh();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _loadProducts() {
    _productsLoaded = true;
    final viewedIds = context.read<UserProductViewProvider>().viewedProductIds;
    _productProvider.getProducts(viewedIds: viewedIds);
  }

  Future<void> _doRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    _filterProvider.clearAll();
    _productsLoaded = false;
    _lastKnownProductCount = 0;

    final viewedIds = context.read<UserProductViewProvider>().viewedProductIds;
    await _productProvider.refreshProducts(viewedIds: viewedIds);

    _productsLoaded = true;
    _isRefreshing = false;
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    widget.refreshNotifier?.removeListener(_onRefreshNotified);
    _scrollController.dispose();
    if (_productListener != null) {
      _productProvider.removeListener(_productListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final filterProvider = context.watch<ProductFilterProvider>();
    final productsToShow = filterProvider.filteredProducts;
    final bool isOffline = !authProvider.isConnected;
    final bool isLoading = productProvider.isLoading;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: TextField(
                              onTap: () {
                                if (!authProvider.isLoggedIn) {
                                  AuthPromptSheet.show(context);
                                } else {
                                  Navigator.pushNamed(context, '/searchscreen');
                                }
                              },
                              readOnly: true,
                              style: const TextStyle(color: Colors.grey),
                              decoration: InputDecoration(
                                hintText: _kSearchPhrases[_phraseIndex],
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                prefixIcon: const Icon(
                                  IconsaxPlusLinear.search_normal_1,
                                  color: Color(0xff9D6E2D),
                                  size: 19,
                                ),
                                filled: true,
                                fillColor: const Color.fromARGB(
                                  255,
                                  233,
                                  226,
                                  226,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 233, 226, 226),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        5.getWidthWhiteSpacing,
                        GestureDetector(
                          onTap: () {
                            if (!authProvider.isLoggedIn) {
                              AuthPromptSheet.show(context);
                            } else {
                              Navigator.pushNamed(context, '/save');
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color.fromARGB(255, 236, 216, 191),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Icon(
                                    Icons.favorite_outline,
                                    size: 18,
                                    color: Color(0xff9D6E2D),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Consumer<ProductProvider>(
                                  builder: (context, provider, _) {
                                    final userId = authProvider.userId;
                                    if (userId == null) return const SizedBox();
                                    if (provider.likedProductIds.isEmpty) {
                                      return const SizedBox();
                                    }
                                    return Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.pink,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 8,
                                        minHeight: 8,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        5.getWidthWhiteSpacing,
                        GestureDetector(
                          onTap: () {
                            if (!authProvider.isLoggedIn) {
                              AuthPromptSheet.show(context);
                            } else {
                              Navigator.pushNamed(context, '/filter');
                            }
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromARGB(255, 236, 216, 191),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                IconsaxPlusLinear.setting_4,
                                size: 18,
                                color: Color(0xff9D6E2D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ZipperRefreshWrapper(
                      onRefresh: _doRefresh,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        key: const PageStorageKey<String>('home_scroll'),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Categories ──────────────────────────────
                            isTablet
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: _kCategories
                                        .map(
                                          (cat) => CategoryWidget(
                                            onPressed: () =>
                                                Navigator.pushNamed(
                                              context,
                                              '/categoryscreen',
                                              arguments: {
                                                'type': cat['type']!,
                                                'allProducts':
                                                    productProvider.products,
                                              },
                                            ),
                                            image: cat['image']!,
                                            title: cat['title']!,
                                          ),
                                        )
                                        .toList(),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: _kCategories
                                          .map(
                                            (cat) => Padding(
                                              padding: const EdgeInsets.only(
                                                right: 16,
                                              ),
                                              child: CategoryWidget(
                                                onPressed: () =>
                                                    Navigator.pushNamed(
                                                  context,
                                                  '/categoryscreen',
                                                  arguments: {
                                                    'type': cat['type']!,
                                                    'allProducts':
                                                        productProvider
                                                            .products,
                                                  },
                                                ),
                                                image: cat['image']!,
                                                title: cat['title']!,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),

                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Trending collection',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  10.getHeightWhiteSpacing,

                                  // ✅ No longer blocks on !authProvider.isInitialized
                                  // Products are public — show skeleton while loading,
                                  // show products as soon as they arrive.
                                  if (isOffline)
                                    _buildSkeletonGrid()
                                  else if (isLoading && productsToShow.isEmpty)
                                    _buildSkeletonGrid()
                                  else if (!isLoading && productsToShow.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 60),
                                      child:
                                          Center(child: LogoLoadingIndicator()),
                                    )
                                  else
                                    MasonryGridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                      ),
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 5,
                                      itemCount: productsToShow.length,
                                      itemBuilder: (context, index) {
                                        final product = productsToShow[index];
                                        return ProductWidget(
                                          product: product,
                                          allProducts: productsToShow,
                                          isLoading: false,
                                        );
                                      },
                                    ),

                                  if (productProvider.isFetchingMore)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: ImageSkeleton(),
                                      ),
                                    ),

                                  20.getHeightWhiteSpacing,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Offline banner ──────────────────────────────────────
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (!auth.isConnected) {
                    return Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: Colors.red,
                        child: const Center(
                          child: Text(
                            'No internet connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return MasonryGridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      mainAxisSpacing: 8,
      crossAxisSpacing: 5,
      itemCount: 14,
      itemBuilder: (context, index) {
        return SizedBox(
          height: 210,
          child: ProductWidget(
            product: dummyProduct,
            allProducts: const [],
            isLoading: true,
          ),
        );
      },
    );
  }
}
