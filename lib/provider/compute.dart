import 'package:flutter/foundation.dart';
import 'package:peereess/model/product.dart';
import 'package:peereess/provider/productranking.dart';

Future<List<ProductModel>> rankProductsInBackground(
  List<ProductModel> products,
  Set<String> viewedIds,
) async {
  return await compute(_rankProducts, {
    'products': products,
    'viewedIds': viewedIds,
  });
}

List<ProductModel> _rankProducts(Map<String, dynamic> data) {
  final products = data['products'] as List<ProductModel>;
  final viewedIds = data['viewedIds'] as Set<String>;
  return ProductRanker.rankSync(products, viewedIds);
}
