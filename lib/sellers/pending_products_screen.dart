import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/sellers/seller_filtered_product_list.dart';

class PendingProductsScreen extends StatelessWidget {
  const PendingProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SellerFilteredProductList(
      title: 'Pending Products',
      filterStatus: 'pending',
      accentColor: Colors.orange.shade700,
      emptyMessage: 'No products pending approval',
      headerIcon: IconsaxPlusLinear.clock,
    );
  }
}
