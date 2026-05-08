import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/aboutpeereess.dart';
import 'package:peereess/screens/addressbook.dart';
import 'package:peereess/screens/changepassword.dart';
import 'package:peereess/screens/help.dart';
import 'package:peereess/screens/personalinformation.dart';
import 'package:peereess/screens/privacypolicy.dart';
import 'package:peereess/screens/temsofuse.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:peereess/sellers/sellerrefund.dart';
import 'package:provider/provider.dart';

class Sellerprofile extends StatefulWidget {
  const Sellerprofile({super.key});

  @override
  State<Sellerprofile> createState() => _SellerprofileState();
}

class _SellerprofileState extends State<Sellerprofile> {
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
                        "Business Profile",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: "poppins",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  5.getHeightWhiteSpacing,

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
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Addressbook(),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  IconsaxPlusLinear.location,
                                  size: 16,
                                ),
                                10.getWidthWhiteSpacing,
                                const Text(
                                  "Addresses",
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
                                builder: (context) => Personalinformation(),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16),
                                10.getWidthWhiteSpacing,
                                const Text(
                                  "Business Information",
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
                                builder: (context) => ChangePasswordScreen(),
                              ),
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

                  // Notifications, Refund, Help
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
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellerRefundPage(),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  IconsaxPlusLinear.refresh_2,
                                  size: 16,
                                ),
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
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Help()),
                            ),
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
