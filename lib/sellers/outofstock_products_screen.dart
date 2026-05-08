import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/sellers/seller_filtered_product_list.dart';

class OutOfStockProductsScreen extends StatelessWidget {
  const OutOfStockProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SellerFilteredProductList(
      title: 'Out of Stock',
      filterStatus: 'sold_out',
      accentColor: Colors.indigo.shade700,
      emptyMessage: 'No out-of-stock products',
      headerIcon: IconsaxPlusLinear.shopping_cart,
    );
  }
}
