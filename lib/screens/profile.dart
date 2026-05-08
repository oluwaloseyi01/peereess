import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/app_images.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/notificationprovider.dart';
import 'package:peereess/screens/aboutpeereess.dart';
import 'package:peereess/screens/addressbook.dart';
import 'package:peereess/screens/changepassword.dart';
import 'package:peereess/screens/help.dart';
import 'package:peereess/screens/notificationscreen.dart';
import 'package:peereess/screens/orderhistory.dart';
import 'package:peereess/screens/personalinformation.dart';
import 'package:peereess/screens/privacypolicy.dart';
import 'package:peereess/screens/refund.dart';
import 'package:peereess/screens/temsofuse.dart';
import 'package:peereess/screens/voucher.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/screens/widgets/recentorderwidget.dart';
import 'package:provider/provider.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
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
        child: Center(child: LogoLoadingIndicator()),
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: 'poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/searchscreen'),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(255, 236, 216, 191),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              IconsaxPlusLinear.search_normal,
                              size: 18,
                              color: Color(0xff9D6E2D),
                            ),
                          ),
                        ),
                      ),
                      5.getWidthWhiteSpacing,
                      Consumer<NotificationProvider>(
                        builder: (context, provider, _) {
                          return GestureDetector(
                            onTap: () {
                              final userId =
                                  context.read<AuthProvider>().userId ?? '';
                              provider.markAllAsRead(userId);
                              Navigator.pushNamed(
                                context,
                                "/notificationscreen",
                              );
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color.fromARGB(
                                      255,
                                      236,
                                      216,
                                      191,
                                    ),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6.0),
                                    child: Icon(
                                      IconsaxPlusLinear.notification,
                                      size: 18,
                                      color: Color(0xff9D6E2D),
                                    ),
                                  ),
                                ),
                                if (provider.hasUnread)
                                  Positioned(
                                    right: -1,
                                    top: -1,
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
                  10.getHeightWhiteSpacing,
                  const RecentOrdersWidget(),
                  10.getHeightWhiteSpacing,

                  // Account Settings
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 233, 226, 226),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Account Settings",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          5.getHeightWhiteSpacing,
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, "/addressbook"),
                            child: Row(
                              children: [
                                const Icon(
                                  IconsaxPlusLinear.location,
                                  size: 16,
                                ),
                                10.getWidthWhiteSpacing,
                                const Text(
                                  "Address",
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios, size: 13),
                              ],
                            ),
                          ),
                          const Divider(),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              "/personalinformation",
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16),
                                10.getWidthWhiteSpacing,
                                const Text(
                                  "Personal Information",
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios, size: 13),
                              ],
                            ),
                          ),
                          const Divider(),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, "/voucher"),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.card_membership_outlined,
                                  size: 16,
                                ),
                                10.getWidthWhiteSpacing,
                                const Text(
                                  "Vouchers",
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios, size: 13),
                              ],
                            ),
                          ),
                          const Divider(),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, "/refund"),
                            child: Row(
                              children: [
                                const Icon(IconsaxPlusLinear.refresh, size: 16),
                                10.getWidthWhiteSpacing,
                                const Text(
                                  "Refund",
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios, size: 13),
                              ],
                            ),
                          ),
                          const Divider(),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              "/changePasswordScreen",
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outlined, size: 16),
                                10.getWidthWhiteSpacing,
                                const Text(
                                  "Change Password",
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios, size: 13),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  10.getHeightWhiteSpacing,

                  // Notifications & Help
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 233, 226, 226),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_active_outlined,
                                    size: 16,
                                  ),
                                  10.getWidthWhiteSpacing,
                                  const Text(
                                    "Notifications",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Transform.scale(
                                      scale: 0.75,
                                      child: Switch(
                                        value: auth.notificationsEnabled,
                                        activeColor: Colors.pink,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onChanged: (value) {
                                          auth.toggleNotifications(value);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Divider(),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, "/help"),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.help_center_outlined,
                                  size: 16,
                                ),
                                10.getWidthWhiteSpacing,
                                const Text(
                                  "Help & Support",
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios, size: 13),
                              ],
                            ),
                          ),
                          10.getHeightWhiteSpacing,
                        ],
                      ),
                    ),
                  ),

                  5.getHeightWhiteSpacing,
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "PRIVACY",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  5.getHeightWhiteSpacing,

                  // Privacy
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 233, 226, 226),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Privacypolicy(),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  "Privacy Policy",
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios, size: 13),
                              ],
                            ),
                          ),
                          const Divider(),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TermsofUse(),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  "Term of Service",
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios, size: 13),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  5.getHeightWhiteSpacing,
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "ABOUT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  5.getHeightWhiteSpacing,

                  // About
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 233, 226, 226),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutPeereess(),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Peereess",
                              style: TextStyle(fontSize: 14),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios, size: 13),
                          ],
                        ),
                      ),
                    ),
                  ),

                  20.getHeightWhiteSpacing,
                  AppButtons(
                    onPressed: () {
                      context.read<AuthProvider>().logOut(context);
                    },
                    text: "Logout",
                  ),
                  20.getHeightWhiteSpacing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
