import 'package:peereess/provider/searchprovider.dart';

class SearchModel {
  final String productId;
  final String title;
  final String category;
  final List<String> imageUrl;
  final String sellerName;
  final SearchType type; // ✅ add this

  SearchModel({
    required this.productId,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.sellerName,
    this.type = SearchType.product,
  });
}
