import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/sellers/seller_filtered_product_list.dart';

class ApprovedProductsScreen extends StatelessWidget {
  const ApprovedProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SellerFilteredProductList(
      title: 'Approved Products',
      filterStatus: 'approved',
      accentColor: Colors.green.shade700,
      emptyMessage: 'No approved products yet',
      headerIcon: IconsaxPlusLinear.tick_circle,
    );
  }
}
