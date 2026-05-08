import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:peereess/core/app_color.dart';
import 'package:peereess/provider/adminprovider.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/provider/sellerorder_provider.dart';
import 'package:peereess/provider/supportchat_provider.dart';
import 'package:peereess/screens/admin/adminhomecontent.dart';
import 'package:peereess/screens/admin/adminprofile.dart';
import 'package:peereess/screens/admin/admintools.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';

class Adminhome extends StatefulWidget {
  const Adminhome({super.key});

  @override
  State<Adminhome> createState() => _AdminhomeState();
}

class _AdminhomeState extends State<Adminhome> {
  int _currentIndex = 0;
  bool _initialized = false; // ✅ guard: only load once

  @override
  void initState() {
    super.initState();

    // ✅ NO auth listener — RouteGuard + session timer handle redirects.
    // Adding one here caused double-navigation and reload loops.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      _initialized = true;
      _loadAll();
    });
  }

  void _loadAll() {
    final authProvider = context.read<AuthProvider>();
    final productProvider = context.read<ProductUploadProvider>();
    final orderProvider = context.read<SellerOrderProvider>();
    final adminProvider = context.read<AdminProvider>();
    final supportProvider = context.read<SupportChatProvider>();

    // ✅ Only fetch user data if not already loaded by initAuth()
    if (authProvider.currentUserData == null) {
      authProvider.fetchUserData();
    }

    productProvider.fetchAllProducts();
    productProvider.fetchPendingProductForAdmin();
    orderProvider.fetchAllOrders();
    adminProvider.fetchAdminStats();
    supportProvider.fetchAdminChatList();
  }

  @override
  Widget build(BuildContext context) {
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
      body: IndexedStack(
        index: _currentIndex,
        children: const [Adminhomecontent(), Admintools(), Adminprofile()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff9D6E2D),
        backgroundColor: Colors.white,
        unselectedItemColor: AppColor.iconColor,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(IconsaxPlusLinear.home_1),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(IconsaxPlusLinear.setting_2),
            label: 'Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(IconsaxPlusLinear.profile),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
