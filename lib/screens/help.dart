import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/screens/supportchatscreen.dart';
import 'package:provider/provider.dart';

class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _HelpState();
}

class _HelpState extends State<Help> {
  int? expandedIndex;

  void toggle(int index) {
    setState(() {
      expandedIndex = expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userdata = context.watch<AuthProvider>().currentUserData;

    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromARGB(255, 217, 194, 162),
          title: Row(
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

              Expanded(
                child: Center(
                  child: const Text(
                    "Help Center",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // 👇 this is what you asked for
              const SizedBox(width: 40),
            ],
          )),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting banner
              Container(
                width: double.infinity,
                color: const Color.fromARGB(255, 233, 226, 226),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi ${userdata?.fullName ?? ''}, how can we help you?",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Text(
                      "You can try to find your problem here or contact us",
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Guides
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Guides on How To:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    10.getHeightWhiteSpacing,
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          guideTile(
                            index: 0,
                            icon: Icons.card_membership,
                            title: "Place an Order",
                            description:
                                "Browse products, add them to cart and proceed to checkout to place your order easily.",
                          ),
                          guideTile(
                            index: 1,
                            icon: Icons.payment,
                            title: "Pay for Your Order",
                            description:
                                "Choose your preferred payment method and complete payment securely.",
                          ),
                          guideTile(
                            index: 2,
                            icon: Icons.delivery_dining,
                            title: "Track Your Order",
                            description:
                                "Go to your orders page to track delivery status in real time.",
                          ),
                          guideTile(
                            index: 3,
                            icon: Icons.cancel_outlined,
                            title: "Cancel an Order",
                            description:
                                "You can cancel an order before it is shipped from the seller.",
                          ),
                          guideTile(
                            index: 4,
                            icon: Icons.history_outlined,
                            title: "Create a Return",
                            description:
                                "If you're not satisfied, request a return within the allowed return window.",
                          ),
                          guideTile(
                            index: 5,
                            icon: Icons.sell_outlined,
                            title: "Sell on Peeress",
                            description:
                                "Register as a seller, upload your products and start selling to customers.",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contact
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Contact us",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    10.getHeightWhiteSpacing,
                    GestureDetector(
                      onTap: () {
                        if (userdata == null) return;
                        Navigator.pushNamed(
                          context,
                          "/supportChat",
                          arguments: {
                            "supportId": "SUPPORT_${userdata.userId ?? ''}",
                            "userId": userdata.userId ?? '',
                            "userName": userdata.fullName ?? '',
                            "role": "user",
                          },
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Icon(
                              IconsaxPlusLinear.message_tick,
                              size: 22,
                            ),
                            5.getWidthWhiteSpacing,
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Live Chat",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    "We are available Monday to Friday (8am–6pm)\nWeekends (8am–5pm)\nPublic Holidays (9am–5pm)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget guideTile({
    required int index,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isOpen = expandedIndex == index;

    return InkWell(
      onTap: () => toggle(index),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xff9D6E2D)),
                10.getWidthWhiteSpacing,
                Text(title, style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.arrow_forward_ios,
                  size: 14,
                  color: const Color(0xff9D6E2D),
                ),
              ],
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
