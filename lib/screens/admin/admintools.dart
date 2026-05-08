import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/app_color.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/adminprovider.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/productupload_provider.dart';
import 'package:peereess/screens/admin/adminwithdraw.dart';
import 'package:peereess/screens/admin/allproductlist.dart';
import 'package:peereess/screens/admin/clientremovedproduct.dart';
import 'package:peereess/screens/admin/userrefunds.dart';
import 'package:peereess/screens/admin/addminorderplcaed.dart';
import 'package:peereess/screens/admin/admindeliverdorder.dart';
import 'package:peereess/screens/admin/adminondeliveryorder.dart';
import 'package:peereess/screens/admin/adminproductapprove.dart';
import 'package:peereess/screens/admin/widget/makeseller.dart';
import 'package:peereess/screens/companyscreen.dart/adminspincontroll.dart';
import 'package:provider/provider.dart';

const _gold = Color(0xffB0864C);
const _goldLight = Color(0xffD4A96A);
const _surface = Color(0xFFFBF7F2);
const _cardBg = Color(0xFFFFFFFF);
const _textDark = Color(0xFF2C1A0E);
const _textMid = Color(0xFF7A5C3A);

class Admintools extends StatefulWidget {
  const Admintools({super.key});

  @override
  State<Admintools> createState() => _AdmintoolsState();
}

class _AdmintoolsState extends State<Admintools> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Admin Tools",
              style: TextStyle(
                color: _textDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              "Manage your platform",
              style: TextStyle(
                color: _textMid,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEDD9B8), _surface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Divider accent
            Container(
              height: 2,
              width: 40,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Section: Orders
            _sectionLabel("Orders"),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildActionCard(
                  context,
                  title: "New Orders",
                  subtitle: "Awaiting action",
                  icon: IconsaxPlusLinear.shopping_cart,
                  badgeCount: context.watch<AdminProvider>().newOrdersCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Addminorderplcaed(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  context,
                  title: "On Delivery",
                  subtitle: "In transit",
                  icon: IconsaxPlusLinear.ship,
                  badgeCount:
                      context.watch<AdminProvider>().ondeliveryorderCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnDeliveryOrdersPage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  context,
                  title: "Delivered",
                  subtitle: "Completed",
                  icon: Icons.delivery_dining_outlined,
                  badgeCount:
                      context.watch<AdminProvider>().deliveredOrdersCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Admindeliverdorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section: Products
            _sectionLabel("Products"),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildActionCard(
                  context,
                  title: "New Products",
                  subtitle: "Pending approval",
                  icon: IconsaxPlusLinear.setting_4,
                  badgeCount: context
                      .watch<ProductUploadProvider>()
                      .pendingProductsCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminProductApprovalPage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  context,
                  title: "All Products",
                  subtitle: "Browse catalog",
                  icon: Icons.shop,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllProductList()),
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  context,
                  title: "Removed",
                  subtitle: "Rejected items",
                  icon: IconsaxPlusLinear.shopping_cart,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminProductRejectedPage(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section: Finance & Users
            _sectionLabel("Finance & Users"),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildActionCard(
                  context,
                  title: "Refunds",
                  subtitle: "Customer claims",
                  icon: IconsaxPlusLinear.refresh_square_2,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Adminrefund()),
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  context,
                  title: "Withdrawals",
                  subtitle: "Payout requests",
                  icon: Icons.account_balance_wallet_outlined,
                  badgeCount:
                      context.watch<AdminProvider>().deliveredOrdersCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminWithdrawalsScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionCard(
                  context,
                  title: "Make Seller",
                  subtitle: "Promote users",
                  icon: IconsaxPlusLinear.shop,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MakeSellerPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabel("promo"),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildActionCard(
                  context,
                  title: "Spin",
                  subtitle: "user promo",
                  icon: IconsaxPlusLinear.refresh_square_2,
                  onTap: () {
                    final adminId = context.read<AuthProvider>().userId ?? '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpinAdminPage(adminId: adminId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _sectionLabel(String label) {
  return Text(
    label.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _textMid,
      letterSpacing: 1.4,
    ),
  );
}

Widget _buildActionCard(
  BuildContext context, {
  required String title,
  required IconData icon,
  String? subtitle,
  int? badgeCount,
  VoidCallback? onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE0CF), width: 1),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEDD9B8), Color(0xFFF5ECD8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _gold, size: 22),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textDark,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: _textMid,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
