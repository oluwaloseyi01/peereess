import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/picturechat_provider.dart';
import 'package:peereess/provider/searchprovider.dart';
import 'package:peereess/provider/product_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/screens/widgets/product_collectionwidget.dart';
import 'package:provider/provider.dart';

class Searchscreen extends StatefulWidget {
  const Searchscreen({super.key});

  @override
  State<Searchscreen> createState() => _SearchscreenState();
}

class _SearchscreenState extends State<Searchscreen> {
  bool _hasSearched = false;

  final ScrollController _scrollController = ScrollController();
  late ProductProvider _productProvider;
  late SearchProvider _searchProvider;
  late String _userId;

  @override
  void initState() {
    super.initState();

    _productProvider = context.read<ProductProvider>();
    _searchProvider = context.read<SearchProvider>();
    _userId = context.read<AuthProvider>().userId ?? '';

    // Load more when near bottom of results
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        if (_productProvider.searchHasMore &&
            !_productProvider.isSearchFetchingMore &&
            _hasSearched) {
          _productProvider.searchProducts(
            _searchProvider.currentQuery,
            loadMore: true,
          );
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _searchProvider.setProducts(_productProvider.products);
      _searchProvider.showInitialSuggestions();

      // ✅ Fetch saved searches from server
      if (_userId.isNotEmpty) {
        _searchProvider.fetchUserSearches(userId: _userId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _runSearchWithType(String query, SearchType type) {
    setState(() => _hasSearched = true);

    _searchProvider.addRecentSearch(query, _userId); // ✅ pass userId
    _searchProvider.hideSuggestions();

    if (type == SearchType.seller) {
      _productProvider.searchBySeller(query);
    } else if (type == SearchType.category) {
      _productProvider.searchByCategory(query);
    } else {
      _productProvider.searchProducts(query);
    }

    FocusScope.of(context).unfocus();
  }

  void _runSearch(String query) {
    setState(() => _hasSearched = true);
    _searchProvider.addRecentSearch(query, _userId); // ✅ pass userId
    _searchProvider.hideSuggestions();
    _productProvider.searchProducts(query);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final pictureProvider = context.watch<PictureSearchProvider>();
    final searchProvider = context.watch<SearchProvider>();
    final productProvider = context.watch<ProductProvider>();

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
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                /// ================= TOP BAR =================
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xff9D6E2D),
                        ),
                      ),
                    ),
                    5.getWidthWhiteSpacing,
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          autofocus: true,
                          onChanged: (value) {
                            setState(() => _hasSearched = false);
                            searchProvider.onQueryChanged(value);
                            if (value.trim().isEmpty) {
                              productProvider.clearSearch();
                            }
                          },
                          onSubmitted: (value) => _runSearch(value),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            hintText: "Search for dresses and more..",
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            prefixIcon: const Icon(
                              IconsaxPlusLinear.search_normal,
                              size: 18,
                              color: Color(0xff9D6E2D),
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 233, 226, 226),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                8.getHeightWhiteSpacing,

                Expanded(
                  child: !_hasSearched
                      ? _buildSuggestions(context, searchProvider)
                      : _buildResults(pictureProvider, productProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= SUGGESTIONS =================
  Widget _buildSuggestions(
    BuildContext context,
    SearchProvider searchProvider,
  ) {
    // ✅ Show loading spinner while fetching recent searches
    if (searchProvider.isFetchingSearches) {
      return const Center();
    }

    if (!searchProvider.showSuggestions &&
        searchProvider.recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 233, 226, 226),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (searchProvider.recentSearches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent searches",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => searchProvider
                        .clearRecentSearches(_userId), // ✅ pass userId
                    child: const Text(
                      "Clear",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // ✅ Recent searches — plain product search
          ...searchProvider.recentSearches.map(
            (query) => ListTile(
              dense: true,
              leading: const Icon(Icons.history_outlined, size: 18),
              title: Text(query),
              onTap: () => _runSearch(query),
            ),
          ),

          // ✅ Suggestions — routed by SearchType
          ...searchProvider.suggestions.map(
            (suggestion) => ListTile(
              dense: true,
              leading: Icon(
                suggestion.type == SearchType.seller
                    ? Icons.store_outlined
                    : suggestion.type == SearchType.category
                        ? Icons.category_outlined
                        : IconsaxPlusLinear.search_normal,
                size: 18,
              ),
              title: Text(suggestion.title),
              subtitle: suggestion.type != SearchType.product
                  ? Text(
                      suggestion.type == SearchType.seller
                          ? 'Seller'
                          : 'Category',
                      style: const TextStyle(fontSize: 11),
                    )
                  : Text(suggestion.category),
              onTap: () =>
                  _runSearchWithType(suggestion.title, suggestion.type),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= RESULTS =================
  Widget _buildResults(
    PictureSearchProvider pictureProvider,
    ProductProvider productProvider,
  ) {
    // Picture search takes priority
    if (pictureProvider.hasImage) {
      return MasonryGridView.builder(
        gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        mainAxisSpacing: 8,
        crossAxisSpacing: 5,
        itemCount: pictureProvider.searchResults.length,
        itemBuilder: (context, index) {
          return ProductCollectionwidget(
            product: pictureProvider.searchResults[index],
          );
        },
      );
    }

    final products = productProvider.searchResults;

    if (productProvider.isSearchLoading && products.isEmpty) {
      return const Center(child: LogoLoadingIndicator());
    }

    if (products.isEmpty) {
      return const Center(child: Text("No product match your search"));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          MasonryGridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            mainAxisSpacing: 8,
            crossAxisSpacing: 5,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCollectionwidget(product: products[index]);
            },
          ),
          if (productProvider.isSearchFetchingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xff9D6E2D),
                  strokeWidth: 1.5,
                ),
              ),
            )
          else if (!productProvider.searchHasMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(),
            ),
        ],
      ),
    );
  }
}
