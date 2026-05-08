import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/app_color.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/adminprovider.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/supportchat_provider.dart';
import 'package:peereess/provider/withdrawservice.dart'; // ✅ added
import 'package:peereess/screens/admin/adminchat.dart';
import 'package:peereess/screens/admin/adminchatlist.dart';
import 'package:peereess/screens/admin/adminsupportchatlist.dart';
import 'package:peereess/screens/admin/adminwithdraw.dart';
import 'package:peereess/screens/admin/manageorders.dart';
import 'package:peereess/screens/admin/managesellers.dart';
import 'package:peereess/screens/chat.dart';
// ✅ added
import 'package:provider/provider.dart';

class Adminhomecontent extends StatelessWidget {
  const Adminhomecontent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Welcome Admin!", style: TextStyle(fontSize: 18)),
        backgroundColor: Color.fromARGB(255, 217, 194, 162),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Consumer<AdminProvider>(
                builder: (context, provider, _) {
                  // ✅ read pending withdrawals count
                  final withdrawService = context.watch<WithdrawService>();
                  final pendingWithdrawals = withdrawService.withdrawRows
                      .where((w) => w['status'] == 'pending')
                      .length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Overview",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Stats row 1
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(
                            context,
                            title: "Users",
                            value: provider.totalAllUsers.toString(),
                            icon: IconsaxPlusLinear.people,
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            context,
                            title: "Sellers",
                            value: provider.totalSellers.toString(),
                            icon: IconsaxPlusLinear.shop,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stats row 2
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(
                            context,
                            title: "Orders",
                            value: provider.totalOrders.toString(),
                            icon: IconsaxPlusLinear.shopping_cart,
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            context,
                            title: "Revenue",
                            value:
                                "₦${provider.totalRevenue.toStringAsFixed(2)}",
                            icon: IconsaxPlusLinear.money,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ✅ Stats row 3 — Admins + Pending Withdrawals
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(
                            context,
                            title: "Admins",
                            value: provider.totalAdmins.toString(),
                            icon: IconsaxPlusLinear.shield_tick,
                            color: Colors.teal,
                          ),
                          _buildStatCard(
                            context,
                            title: "Withdrawals",
                            value: pendingWithdrawals.toString(),
                            icon: IconsaxPlusLinear.money_send,
                            color: Colors.deepOrange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionCard(
                            context,
                            title: "Users Supports",
                            icon: IconsaxPlusLinear.message_circle,
                            badgeCount: context
                                .watch<SupportChatProvider>()
                                .totalUserUnreadCount,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminSupportChatListScreen(),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            title: "Product chats",
                            icon: IconsaxPlusLinear.message,
                            onTap: () {
                              final userId =
                                  context.read<AuthProvider>().userId;

                              if (userId == null) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Chat(
                                    userId: userId,
                                    role: 'admin', // 👈 important
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionCard(
                            context,
                            title: "Manage Orders",
                            icon: IconsaxPlusLinear.shopping_cart,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageOrdersPage(),
                              ),
                            ),
                          ),
                          // ✅ added withdrawals action card
                          _buildActionCard(
                            context,
                            title: "Withdrawals",
                            icon: IconsaxPlusLinear.money_send,
                            badgeCount: pendingWithdrawals > 0
                                ? pendingWithdrawals
                                : null,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminWithdrawalsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      20.getHeightWhiteSpacing,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionCard(
                            context,
                            title: "Manage Sellers",
                            icon: IconsaxPlusLinear.people,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageSellerPage(),
                              ),
                            ),
                          ),
                          _buildActionCard(
                            context,
                            title: "Reports",
                            icon: IconsaxPlusLinear.chart,
                            onTap: () {},
                          ),
                        ],
                      ),
                      20.getHeightWhiteSpacing,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 233, 226, 226),
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    VoidCallback? onTap,
    int? badgeCount,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 233, 226, 226),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: AppColor.iconColor, size: 28),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
