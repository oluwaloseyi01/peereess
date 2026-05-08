import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';

class Privacypolicy extends StatelessWidget {
  const Privacypolicy({super.key});

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xff9D6E2D),
        ),
      ),
    );
  }

  Widget _sectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            10.getWidthWhiteSpacing,
            const Text(
              "Privacy Policy",
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              20.getHeightWhiteSpacing,
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Color(0xffFFF6D7)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 14),
                      10.getWidthWhiteSpacing,
                      Text(
                        "Last updated: Jan 1, 2026",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    10.getHeightWhiteSpacing,
                    _sectionContent(
                      "At Peereess, your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our mobile application.",
                    ),
                    _sectionTitle("1. Information We Collect"),
                    _sectionContent(
                      "- Personal Information: Name, email, phone number, delivery address, and payment information.\n- Account Information: Login credentials and profile details.\n- Usage Data: App interactions, search queries, and product preferences.\n- Device Information: Device type, operating system, and app version.",
                    ),
                    _sectionTitle("2. How We Use Your Information"),
                    _sectionContent(
                      "- To provide and personalize our services.\n- To process orders, payments, and deliveries.\n- To communicate with you regarding your account or purchases.\n- To improve the app and enhance your shopping experience.\n- For security and fraud prevention.",
                    ),
                    _sectionTitle("3. Sharing Your Information"),
                    _sectionContent(
                      "- We do not sell your personal information.\n- We may share information with trusted service providers to process payments, deliver products, and provide support.\n- We may disclose information if required by law or to protect our rights.",
                    ),
                    _sectionTitle("4. Data Security"),
                    _sectionContent(
                      "- We implement reasonable security measures to protect your data from unauthorized access, alteration, or disclosure.\n- However, no method of transmission over the internet or electronic storage is 100% secure.",
                    ),
                    _sectionTitle("5. Your Rights"),
                    _sectionContent(
                      "- You may access, update, or delete your personal information through the app.\n- You can opt out of marketing communications at any time.",
                    ),
                    _sectionTitle("6. Changes to This Policy"),
                    _sectionContent(
                      "- We may update this Privacy Policy from time to time. The updated version will be posted within the app.",
                    ),
                    _sectionTitle("7. Contact Us"),
                    _sectionContent(
                      "If you have questions about this Privacy Policy or how we handle your data, please contact us at peereessofficial@gmail.com.\n\nBy using the Peereess app, you agree to the terms of this Privacy Policy.",
                    ),
                  ],
                ),
              ),
              100.getHeightWhiteSpacing,
            ],
          ),
        ),
      ),
    );
  }
}
