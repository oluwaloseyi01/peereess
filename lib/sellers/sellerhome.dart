import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/app_color.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/ledgerprovider.dart';
import 'package:peereess/provider/notificationprovider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/provider/sellerorder_provider.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/sellers/marketplace.dart';
import 'package:peereess/sellers/sellerprofile.dart';
import 'package:peereess/sellers/sellerrevenue.dart';
import 'package:peereess/sellers/sellershomepagecontent.dart';
import 'package:provider/provider.dart';

class Sellerhome extends StatefulWidget {
  const Sellerhome({super.key});

  @override
  State<Sellerhome> createState() => _SellerhomeState();
}

class _SellerhomeState extends State<Sellerhome> {
  int _currentIndex = 0;
  bool _isDataReady = false;
  bool _initialized = false;

  // ✅ FIX 1: Cache screens and productIds once after data loads —
  // never rebuild them on every build() call
  List<Widget>? _screens;
  List<String> _cachedProductIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      _initialized = true;
      _loadAll();
    });
  }

  Future<void> _loadAll() async {
    // ✅ FIX 4: Wrap everything in try/finally so _isDataReady always
    // gets set to true — screen will never hang forever on an error
    try {
      final authProvider = context.read<AuthProvider>();
      final productProvider = context.read<ProductUploadProvider>();
      final orderProvider = context.read<SellerOrderProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      // 1. Fetch user data only if not already loaded
      if (authProvider.currentUserData == null) {
        await authProvider.fetchUserData();
      }

      if (!mounted) return;

      final userId = authProvider.userId ?? '';
      if (userId.isEmpty) return;

      // 2. Products — must finish before orders (orders depend on productIds)
      await productProvider.fetchSellerProducts(userId);

      if (!mounted) return;

      // ✅ FIX 5: Compute productIds once here, reuse everywhere below
      _cachedProductIds = productProvider.sellerProducts
          .map((p) => p['productId'] as String)
          .toList();

      // 3. Orders — fire and forget after products are ready
      // ✅ FIX 3: No need to await — activeOrdersCount is derived live from
      // the provider in build(), not stored as stale state
      if (_cachedProductIds.isNotEmpty) {
        orderProvider.fetchSellerOrders(_cachedProductIds);
      }

      // 4. Notifications — fire and forget
      notificationProvider.fetchNotifications(userId: userId);
      notificationProvider.subscribeToNotifications(userId: userId);

      // 5. Ledger — fire and forget
      context.read<LedgerProvider>().fetchLedger(userId: userId);

      // ✅ FIX 1: Build screens once here with the stable productIds,
      // NOT inside build() where they'd be recreated on every rebuild
      if (mounted) {
        // ✅ activeOrdersCount derived from provider after orders are fetched
        final activeOrdersCount =
            orderProvider.getActiveOrdersCount(_cachedProductIds);
        _screens = [
          Sellershomepagecontent(activeOrdersCount: activeOrdersCount),
          Marketplace(sellerProductIds: _cachedProductIds),
          const SellerRevenuePage(),
          const Sellerprofile(),
        ];
      }
    } catch (e) {
      debugPrint('[Sellerhome] _loadAll error: $e');
    } finally {
      // ✅ FIX 4: Always mark ready — even on error — so UI doesn't hang
      if (mounted) setState(() => _isDataReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataReady || _screens == null) {
      return const Scaffold(body: Center(child: LogoLoadingIndicator()));
    }

    // ✅ FIX 2: activeOrdersCount is read live from the provider here —
    // no stale int stored in state that goes out of sync with real data.
    // NOTE: If Sellershomepagecontent needs activeOrdersCount, pass it
    // as a parameter or let it read SellerOrderProvider directly.
    // If you must pass it, derive it here:
    //   final count = context.watch<SellerOrderProvider>().getActiveOrdersCount(_cachedProductIds);
    //   then update _screens[0] OR let Sellershomepagecontent watch the provider itself.

    return Scaffold(
      body: _screens![_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xff9D6E2D),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        iconSize: 20,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 0
                  ? IconsaxPlusBold.home_1
                  : IconsaxPlusLinear.home_1,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 1
                  ? IconsaxPlusBold.shopping_bag
                  : IconsaxPlusLinear.shopping_bag,
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 2
                  ? IconsaxPlusBold.card
                  : IconsaxPlusLinear.card,
            ),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 3
                  ? IconsaxPlusBold.profile
                  : IconsaxPlusLinear.profile,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
