import 'package:flutter/material.dart';
import '../model/product.dart';

class ProductFilterProvider extends ChangeNotifier {
  /// raw products
  List<ProductModel> _allProducts = [];

  /// cached filtered result — invalidated on any filter/data change
  List<ProductModel>? _cachedFiltered;

  /// current filter values
  String? selectedCategory;
  String? selectedBrand;
  String sortBy = 'popularity'; // popularity | new | rating
  double? minPrice;
  double? maxPrice;
  int? discount;
  String? shippedFrom;

  /// collection / express filter
  /// 0 = Express, 1 = New Product
  int selectedFilter = 0;
  String? _expressProductId;

  /// ===============================
  /// SET PRODUCTS
  /// ===============================
  void setProducts(List<ProductModel> products) {
    _allProducts = List.from(products);
    _cachedFiltered = null;
    notifyListeners();
  }

  /// ===============================
  /// ACTIVE FILTER CHECK
  /// ===============================
  bool get isFiltering {
    return selectedCategory != null ||
        selectedBrand != null ||
        minPrice != null ||
        maxPrice != null ||
        discount != null ||
        shippedFrom != null ||
        sortBy != 'popularity' ||
        selectedFilter == 1;
  }

  /// ===============================
  /// FILTERED PRODUCTS (cached)
  /// ===============================
  List<ProductModel> get filteredProducts {
    return _cachedFiltered ??= _computeFiltered();
  }

  List<ProductModel> _computeFiltered() {
    List<ProductModel> list = [..._allProducts];

    if (selectedCategory != null) {
      list = list.where((p) => p.category == selectedCategory).toList();
    }

    if (selectedBrand != null) {
      list = list.where((p) => p.brand == selectedBrand).toList();
    }

    if (minPrice != null) {
      list = list.where((p) => p.price >= minPrice!).toList();
    }

    if (maxPrice != null) {
      list = list.where((p) => p.price <= maxPrice!).toList();
    }

    if (discount != null) {
      list = list.where((p) => p.discount >= discount!).toList();
    }

    if (shippedFrom != null) {
      list = list.where((p) => p.shippedFrom == shippedFrom).toList();
    }

    // sorting
    if (sortBy == 'new') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (sortBy == 'rating') {
      list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    }
    // DO NOTHING for popularity → keeps original order

    // express filter
    if (selectedFilter == 0 && _expressProductId != null) {
      list.sort((a, b) {
        if (a.productId == _expressProductId) return -1;
        if (b.productId == _expressProductId) return 1;
        return 0;
      });
    }

    if (selectedFilter == 1) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }

  /// ===============================
  /// APPLY FILTER ON ANY LIST (SEARCH RESULTS)
  /// ===============================
  List<ProductModel> applyFilterOn(List<ProductModel> list) {
    List<ProductModel> filtered = list;

    if (selectedCategory != null) {
      filtered = filtered.where((p) => p.category == selectedCategory).toList();
    }

    if (selectedBrand != null) {
      filtered = filtered.where((p) => p.brand == selectedBrand).toList();
    }

    if (minPrice != null) {
      filtered = filtered.where((p) => p.price >= minPrice!).toList();
    }

    if (maxPrice != null) {
      filtered = filtered.where((p) => p.price <= maxPrice!).toList();
    }

    if (discount != null) {
      filtered = filtered.where((p) => p.discount >= discount!).toList();
    }

    if (shippedFrom != null) {
      filtered = filtered.where((p) => p.shippedFrom == shippedFrom).toList();
    }

    return filtered;
  }

  /// ===============================
  /// SETTERS
  /// ===============================
  void setCategory(String? value) {
    selectedCategory = value;
    _cachedFiltered = null;
    notifyListeners();
  }

  void setBrand(String? value) {
    selectedBrand = value;
    _cachedFiltered = null;
    notifyListeners();
  }

  void setSortBy(String value) {
    sortBy = value;
    _cachedFiltered = null;
    notifyListeners();
  }

  void setPrice(double? min, double? max) {
    minPrice = min;
    maxPrice = max;
    _cachedFiltered = null;
    notifyListeners();
  }

  void setDiscount(int? value) {
    discount = value;
    _cachedFiltered = null;
    notifyListeners();
  }

  void setShippedFrom(String? value) {
    shippedFrom = value;
    _cachedFiltered = null;
    notifyListeners();
  }

  /// ===============================
  /// COLLECTION ACTIONS
  /// ===============================
  void setExpressFirst(String productId) {
    selectedFilter = 0;
    _expressProductId = productId;
    _cachedFiltered = null;
    notifyListeners();
  }

  void applyNewProductFilter() {
    selectedFilter = 1;
    _expressProductId = null;
    _cachedFiltered = null;
    notifyListeners();
  }

  /// ===============================
  /// CLEAR ALL
  /// ===============================
  void clearAll() {
    selectedCategory = null;
    selectedBrand = null;
    sortBy = 'popularity';
    minPrice = null;
    maxPrice = null;
    discount = null;
    shippedFrom = null;
    selectedFilter = 0;
    _expressProductId = null;
    _allProducts = [];
    _cachedFiltered = null;
    notifyListeners();
  }
}
