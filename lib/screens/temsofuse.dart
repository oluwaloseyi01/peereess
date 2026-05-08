import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';

class TermsofUse extends StatelessWidget {
  const TermsofUse({super.key});

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
              "Terms of Service",
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
                    children: const [
                      Icon(Icons.description, size: 14),
                      SizedBox(width: 10),
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
                      "Welcome to Peereess! These Terms of Use govern your use of our mobile application and services. By using our app, you agree to these terms in full.",
                    ),
                    _sectionTitle("1. Use of the App"),
                    _sectionContent(
                      "- You may use the Peereess app only for lawful purposes.\n- You must comply with all applicable local, state, and national laws.\n- You agree not to misuse the app or interfere with its functionality.",
                    ),
                    _sectionTitle("2. Account Registration"),
                    _sectionContent(
                      "- To use certain features, you may be required to create an account.\n- You are responsible for maintaining the confidentiality of your login credentials.\n- You must provide accurate and current information during registration.",
                    ),
                    _sectionTitle("3. Orders and Payments"),
                    _sectionContent(
                      "- All orders placed through the app are subject to acceptance and availability.\n- Payments must be made through the app's approved methods.\n- Prices and availability are subject to change without notice.",
                    ),
                    _sectionTitle("4. Intellectual Property"),
                    _sectionContent(
                      "- All content in the Peereess app, including text, images, logos, and graphics, is the property of Peereess or its licensors.\n- You may not copy, reproduce, or distribute any content without prior written permission.",
                    ),
                    _sectionTitle("5. Limitation of Liability"),
                    _sectionContent(
                      "- Peereess is not responsible for any indirect, incidental, or consequential damages arising from your use of the app.\n- We do not guarantee uninterrupted or error-free service.",
                    ),
                    _sectionTitle("6. Termination"),
                    _sectionContent(
                      "- We may suspend or terminate your access to the app at any time for violating these Terms of Use.\n- You may also delete your account at any time, subject to app functionality.",
                    ),
                    _sectionTitle("7. Changes to Terms"),
                    _sectionContent(
                      "- Peereess may update these Terms of Use from time to time.\n- The updated version will be posted within the app, and continued use constitutes acceptance.",
                    ),
                    _sectionTitle("8. Contact Us"),
                    _sectionContent(
                      "If you have any questions about these Terms of Use, please contact us at peereessofficial@gmail.com.",
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
