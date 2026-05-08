import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/ledgerprovider.dart';
import 'package:peereess/provider/notificationprovider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/provider/sellerorder_provider.dart';
import 'package:peereess/provider/supportchat_provider.dart';
import 'package:peereess/screens/admin/productupload.dart';
import 'package:peereess/screens/notificationscreen.dart';
import 'package:peereess/screens/supportchatscreen.dart';
import 'package:peereess/sellers/managesellerorder.dart';
import 'package:peereess/sellers/sellercatalogue.dart';
import 'package:peereess/sellers/sellercustomerreview.dart';
import 'package:peereess/sellers/sellerproductlist.dart';
import 'package:peereess/sellers/sellerstats.dart';
import 'package:peereess/sellers/sellertabar.dart';
import 'package:provider/provider.dart';

class Sellershomepagecontent extends StatefulWidget {
  final int activeOrdersCount;

  const Sellershomepagecontent({super.key, required this.activeOrdersCount});

  @override
  State<Sellershomepagecontent> createState() => _SellershomepagecontentState();
}

class _SellershomepagecontentState extends State<Sellershomepagecontent> {
  SellerRecentTab _activeTab = SellerRecentTab.orders;
  final formatter = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId ?? '';
    if (userId.isEmpty) return;

    final productProvider = context.read<ProductUploadProvider>();
    final orderProvider = context.read<SellerOrderProvider>();
    final ledgerProvider = context.read<LedgerProvider>();

    await productProvider.fetchSellerProducts(userId);

    final sellerProductIds = productProvider.sellerProducts
        .map((p) => p['productId'] as String)
        .toList();

    await Future.wait([
      if (sellerProductIds.isNotEmpty)
        orderProvider.fetchSellerOrders(sellerProductIds),
      ledgerProvider.fetchLedger(userId: userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 228, 213, 193), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: RefreshIndicator(
                color: const Color(0xff9D6E2D),
                onRefresh: _loadAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Greeting ─────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            10.getHeightWhiteSpacing,
                            Row(
                              children: [
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, _) {
                                    final username = authProvider
                                            .currentUserData?.fullName ??
                                        '';
                                    return Text(
                                      'Hi, $username!',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                const Spacer(),
                                Consumer<NotificationProvider>(
                                  builder: (context, provider, _) {
                                    return GestureDetector(
                                      onTap: () {
                                        final userId = context
                                                .read<AuthProvider>()
                                                .userId ??
                                            '';
                                        if (userId.isNotEmpty) {
                                          provider.markAllAsRead(userId);
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const Notificationscreen(),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.all(4.0),
                                            child: Icon(
                                              IconsaxPlusLinear.notification,
                                              size: 18,
                                              color: Color(0xff9D6E2D),
                                            ),
                                          ),
                                          if (provider.hasUnread)
                                            Positioned(
                                              right: 2,
                                              top: 2,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.pink,
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
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, _) {
                                final level =
                                    authProvider.currentUserData?.level ?? 1;
                                return Text(
                                  "Level $level",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'poppins',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                );
                              },
                            ),
                            const Text(
                              "Here's your dashboard overview",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'poppins',
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 5),
                      Container(
                        height: 6,
                        width: double.infinity,
                        color: const Color.fromARGB(255, 240, 237, 237),
                      ),
                      const SizedBox(height: 5),

                      // ── Stats ─────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // ── Available balance — reacts instantly to
                                //    any LedgerProvider change ──
                                Consumer2<AuthProvider, LedgerProvider>(
                                  builder: (
                                    context,
                                    authProvider,
                                    ledgerProvider,
                                    _,
                                  ) {
                                    final userId = authProvider.userId ?? '';
                                    final availableBalance =
                                        ledgerProvider.getBalance(userId);
                                    return StatCard(
                                      title: 'Available Balance',
                                      balance: availableBalance,
                                      icon: IconsaxPlusLinear.money,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Consumer2<ProductUploadProvider,
                                    SellerOrderProvider>(
                                  builder: (
                                    context,
                                    productProvider,
                                    orderProvider,
                                    _,
                                  ) {
                                    final sellerProductIds =
                                        productProvider.sellerProducts
                                            .map(
                                              (p) => p['productId'] as String,
                                            )
                                            .toList();
                                    final activeOrderCount =
                                        orderProvider.getActiveOrdersCount(
                                      sellerProductIds,
                                    );
                                    return _buildActionCard(
                                      title: 'Active order',
                                      containerColor: Colors.indigo.shade100,
                                      iconColor: Colors.indigo,
                                      value: activeOrderCount.toString(),
                                      icon: IconsaxPlusLinear.shopping_cart,
                                    );
                                  },
                                ),
                                Consumer<ProductUploadProvider>(
                                  builder: (context, provider, _) {
                                    return _buildActionCard(
                                      title: 'Items',
                                      value: provider.productCount.toString(),
                                      containerColor: Colors.orange.shade100,
                                      iconColor: Colors.orange,
                                      icon: IconsaxPlusLinear.category,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      Container(
                        height: 7,
                        width: double.infinity,
                        color: const Color.fromARGB(255, 247, 241, 241),
                      ),
                      const SizedBox(height: 10),

                      // ── Quick actions ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActioncard(
                            title: 'Upload Product',
                            containerColor: Colors.yellow.shade100,
                            iconColor: Colors.yellow,
                            icon: IconsaxPlusLinear.add_square,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Productupload(),
                              ),
                            ),
                          ),
                          _buildActioncard(
                            title: 'Catalogue',
                            containerColor: Colors.purple.shade100,
                            iconColor: Colors.purple,
                            icon: IconsaxPlusLinear.category,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellerCatalogueScreen(),
                              ),
                            ),
                          ),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              final userdata = authProvider.currentUserData;
                              if (userdata == null) return const SizedBox();
                              return _buildActioncard(
                                title: 'Messages',
                                containerColor: Colors.blue.shade100,
                                iconColor: Colors.blue,
                                icon: IconsaxPlusLinear.message,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChangeNotifierProvider.value(
                                      value:
                                          context.read<SupportChatProvider>(),
                                      child: SupportChatScreen(
                                        supportId: 'SUPPORT_${userdata.userId}',
                                        userId: userdata.userId,
                                        userName: userdata.fullName,
                                        role: 'user',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildActioncard(
                            title: 'View Analysis',
                            containerColor: Colors.pink.shade100,
                            iconColor: Colors.pink,
                            icon: IconsaxPlusLinear.chart,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SellerStatsPage(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Container(
                        height: 7,
                        width: double.infinity,
                        color: const Color.fromARGB(255, 247, 241, 241),
                      ),
                      const SizedBox(height: 10),

                      // ── Recent tab ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            SellerRecentTabBar(
                              activeTab: _activeTab,
                              onChanged: (tab) =>
                                  setState(() => _activeTab = tab),
                            ),
                            10.getHeightWhiteSpacing,
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _activeTab == SellerRecentTab.orders
                                  ? const ManageSellerOrdersWidget(
                                      key: ValueKey('orders'),
                                    )
                                  : const SellerCustomerReviewWidget(
                                      key: ValueKey('reviews'),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // ── Offline banner ────────────────────────────────────────
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (!authProvider.isConnected) {
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: Colors.red,
                      child: const SafeArea(
                        child: Center(
                          child: Text(
                            'No internet connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── StatCard ──────────────────────────────────────────────────────────────────
class StatCard extends StatefulWidget {
  final String title;
  final double balance;
  final IconData icon;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.balance,
    required this.icon,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isVisible = false; // ← starts obscured
  final formatter = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 3, 59, 6),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isVisible
                        ? '₦${formatter.format(widget.balance)}'
                        : '₦ ••••••',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _isVisible = !_isVisible),
                    child: Icon(
                      _isVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action card (with value) ──────────────────────────────────────────────────
Widget _buildActionCard({
  required String title,
  required IconData icon,
  String? value,
  Color containerColor = const Color.fromARGB(255, 233, 226, 226),
  Color iconColor = const Color(0xff9D6E2D),
  VoidCallback? onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(icon, color: iconColor, size: 17),
              ],
            ),
            if (value != null) ...[
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ],
        ),
      ),
    ),
  );
}

// ── Action card (icon only) ───────────────────────────────────────────────────
Widget _buildActioncard({
  required String title,
  required IconData icon,
  Color containerColor = const Color.fromARGB(255, 233, 226, 226),
  Color iconColor = const Color(0xff9D6E2D),
  VoidCallback? onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          5.getHeightWhiteSpacing,
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    ),
  );
}
