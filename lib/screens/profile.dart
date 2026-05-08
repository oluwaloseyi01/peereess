import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/app_images.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/core/texttheme.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/notificationprovider.dart';
import 'package:peereess/provider/themeprovider.dart';
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
          padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
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

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: children),
    );
  }
}

// // ── Normal tile ──────────────────────────────────────────────
// class _Tile extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;
//   final bool showDivider;

//   const _Tile({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//     this.showDivider = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.appColors;

//     return Column(
//       children: [
//         InkWell(
//           onTap: onTap,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 13),
//             child: Row(
//               children: [
//                 Icon(icon, size: 20, color: colors.primary),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Text(
//                     label,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: colors.textPrimary,
//                     ),
//                   ),
//                 ),
//                 Icon(
//                   Icons.arrow_forward_ios,
//                   size: 13,
//                   color: colors.textSecondary,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         if (showDivider)
//           Divider(height: 1, thickness: 0.5, color: colors.border),
//       ],
//     );
//   }
// }

// // ── Switch tile ──────────────────────────────────────────────
// class _SwitchTile extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool value;
//   final ValueChanged<bool> onChanged;
//   final bool showDivider;

//   const _SwitchTile({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.onChanged,
//     this.showDivider = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.appColors;

//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: Row(
//             children: [
//               Icon(icon, size: 20, color: colors.primary),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: colors.textPrimary,
//                   ),
//                 ),
//               ),
//               Transform.scale(
//                 scale: 0.85,
//                 child: Switch(
//                   value: value,
//                   onChanged: onChanged,
//                   activeColor: colors.primary,
//                   activeTrackColor: colors.primaryLight.withOpacity(0.4),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (showDivider)
//           Divider(height: 1, thickness: 0.5, color: colors.border),
//       ],
//     );
//   }
// }
