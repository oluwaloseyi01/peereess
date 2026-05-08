import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/sellers/seller_filtered_product_list.dart';

class RemovedProductsScreen extends StatelessWidget {
  const RemovedProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SellerFilteredProductList(
      title: 'Removed Products',
      filterStatus: 'removed',
      accentColor: Colors.red.shade700,
      emptyMessage: 'No removed products',
      headerIcon: IconsaxPlusLinear.trash,
    );
  }
}
