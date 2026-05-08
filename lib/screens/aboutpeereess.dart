import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';

class AboutPeereess extends StatelessWidget {
  const AboutPeereess({super.key});

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
              "About Peereess",
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
        decoration: const BoxDecoration(
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
                decoration: const BoxDecoration(color: Color(0xffFFF6D7)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14),
                      SizedBox(width: 10),
                      Text("About this app", style: TextStyle(fontSize: 12)),
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
                      "Peereess is a dedicated marketplace for women where shopping meets comfort and convenience. It allows users to explore a wide variety of products curated just for them — from fashion and beauty to home essentials.",
                    ),
                    _sectionContent(
                      "Our goal is to create a simple and enjoyable shopping experience where women can browse, discover, and purchase products confidently from trusted sellers.",
                    ),
                    _sectionTitle("Our Mission"),
                    _sectionContent(
                      "Peereess empowers women to shop confidently from the comfort of their homes. We aim to build a community where sellers and buyers connect easily while enjoying a seamless digital marketplace.",
                    ),
                    _sectionTitle("What You Can Do on Peereess"),
                    _sectionContent(
                      "- Browse products from multiple sellers\n"
                      "- Discover fashion, beauty, and lifestyle items\n"
                      "- Shop easily with a simple and convenient interface\n"
                      "- Read product ratings and reviews\n"
                      "- Enjoy secure shopping and reliable delivery",
                    ),
                    _sectionContent(
                      "Peereess also supports women entrepreneurs by providing tools that allow them to manage and showcase their products easily within the marketplace.",
                    ),
                    _sectionTitle("Join Our Community"),
                    _sectionContent(
                      "Join thousands of women discovering amazing products every day. Peereess is more than just a shopping platform — it is a community built for women who love convenience, style, and smart shopping.",
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
