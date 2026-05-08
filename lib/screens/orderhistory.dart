import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/model/ordermodel.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/cart_provider.dart';
import 'package:peereess/provider/home_provider.dart';
import 'package:peereess/provider/tabbar_provider.dart';
import 'package:peereess/screens/orderhistorydetail.dart';
import 'package:peereess/screens/widgets/deliveryday.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/screens/widgets/orderstatuswidget.dart';
import 'package:provider/provider.dart';

class OrderHistory extends StatefulWidget {
  const OrderHistory({super.key});

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    final tabProvider = context.read<TabbarProvider>();
    tabProvider.initController(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tabProvider.fetchUserOrders(context.read<AuthProvider>().userId);
    });
  }

  Future<void> _refresh() {
    return context.read<TabbarProvider>().fetchUserOrders(
          context.read<AuthProvider>().userId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tabProvider = context.watch<TabbarProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isConnected) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(child: LogoLoadingIndicator()),
      );
    }

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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xff9D6E2D),
                        ),
                      ),
                    ),
                    10.getWidthWhiteSpacing,
                    const Spacer(),
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, _) {
                        final cartCount = cartProvider.cartItems.length;
                        return GestureDetector(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            context.read<HomeProvider>().changeIndex(2);
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                IconsaxPlusBold.shopping_cart,
                                size: 24,
                                color: Color(0xff9D6E2D),
                              ),
                              if (cartCount > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "My Orders",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              10.getHeightWhiteSpacing,

              // Tabs
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(tabProvider.orderTabs.length, (
                      index,
                    ) {
                      final isSelected = tabProvider.currentIndex == index;
                      return GestureDetector(
                        onTap: () => tabProvider.changeTab(index),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2.2,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            children: [
                              Text(
                                tabProvider.orderTabs[index],
                                style: const TextStyle(
                                  color: Color(0xff9D6E2D),
                                  fontSize: 14,
                                ),
                              ),
                              Divider(
                                color: isSelected
                                    ? const Color(0xff9D6E2D)
                                    : Colors.transparent,
                                thickness: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              Expanded(
                child: tabProvider.isLoading
                    ? const Center(child: LogoLoadingIndicator())
                    : TabBarView(
                        controller: tabProvider.tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildOrderList(tabProvider.ongoingDelivered),
                          _buildOrderList(tabProvider.canceledReturned),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      // ✅ Wrap in scrollable so pull-to-refresh triggers on empty state
      return RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xff9D6E2D),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Text("No orders", style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Pull-to-refresh on list
    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xff9D6E2D),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: orders.length,
        itemBuilder: (_, index) {
          final order = orders[index];
          final item = order.cartItems.first;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderHistoryDetail(order: order),
              ),
            ),
            child: Card(
              color: const Color.fromARGB(255, 233, 226, 226),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Image
                    if (item.image.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: item.image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      Container(width: 50, height: 50, color: Colors.grey[300]),

                    10.getWidthWhiteSpacing,

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Order ID ${order.orderId}",
                            style: const TextStyle(fontSize: 11),
                          ),
                          6.getHeightWhiteSpacing,
                          OrderStatusBadge(status: order.status),
                          5.getHeightWhiteSpacing,
                          DeliveryDayWidget(deliveryDays: order.deliveryDays),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
