import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/product_provider.dart';

import 'package:peereess/screens/home.dart';
import 'package:peereess/screens/orderhistory.dart';
import 'package:peereess/screens/widgets/product_collectionwidget.dart';
import 'package:provider/provider.dart';

class PaymentOnDeliverySuccess extends StatelessWidget {
  final String orderId; // ✅ Receive orderId

  const PaymentOnDeliverySuccess({
    super.key,
    required this.orderId, // required parameter
  });

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              40.getHeightWhiteSpacing,
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Text(
                      "Order Successful",
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Home()),
                      ),
                      child: Icon(Icons.cancel_outlined),
                    ),
                  ],
                ),
              ),
              10.getHeightWhiteSpacing,
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green, size: 30),
                    10.getWidthWhiteSpacing,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment on delivery Successful",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "ID# $orderId",
                          maxLines: 2,
                          style: TextStyle(fontSize: 12, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              30.getHeightWhiteSpacing,
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: AppButtons(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistory(),
                      ),
                    );
                  },
                  text: "See Order Details",
                ),
              ),
              20.getHeightWhiteSpacing,
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(children: [Text("Recommended for you"), Spacer()]),
                    if (productProvider.isLoading && products.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (products.isEmpty)
                      const Center(child: Text("No products available"))
                    else
                      MasonryGridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                        ),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 5,
                        itemCount: products.length > 10 ? 10 : products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCollectionwidget(product: product);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
