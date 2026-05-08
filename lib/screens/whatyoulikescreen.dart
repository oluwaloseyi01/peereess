import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/app_images.dart';
import 'package:peereess/core/num_extension.dart';

class Whatyoulikescreen extends StatefulWidget {
  const Whatyoulikescreen({super.key});

  @override
  State<Whatyoulikescreen> createState() => _WhatyoulikescreenState();
}

class _WhatyoulikescreenState extends State<Whatyoulikescreen> {
  Set<String> selectedOptions = {}; // for multi-selection

  Widget buildOption(String label, String imagePath) {
    final isSelected = selectedOptions.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedOptions.remove(label);
          } else {
            selectedOptions.add(label);
          }
        });
      },
      child: Container(
        margin: EdgeInsets.all(4),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? Color(0xffB0864C) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Color(0xffB0864C) : Colors.grey,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // shrink to fit content
          children: [
            SizedBox(height: 20, width: 20, child: Image.asset(imagePath)),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> options = [
      {"label": "Fashion", "image": AppImages.dress},
      {"label": "Shoes", "image": AppImages.shoee},
      {"label": "Hair Care", "image": AppImages.hair},
      {"label": "Skin Care", "image": AppImages.beautyy},
      {"label": "Toy", "image": AppImages.toys},
      {"label": "Jewelry", "image": AppImages.jewery},
      {"label": "Bags & Accessories", "image": AppImages.bag},
      {"label": "Makeup", "image": AppImages.makeup},
      {"label": "Fragrances", "image": AppImages.frag},
      {"label": "Wellness & Self-care", "image": AppImages.wellnesss},
      {"label": "Body Care", "image": AppImages.skin},
      {"label": "Home & Decor", "image": AppImages.decor},
      {"label": "Lingerie", "image": AppImages.ling},
    ];

    return Scaffold(
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      20.getHeightWhiteSpacing,
                      10.getHeightWhiteSpacing,
                      Text(
                        "Tell Us What You Like",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      10.getHeightWhiteSpacing,
                      Text(
                        "Select the categories you enjoy so we can personalize your shopping experience.",
                        style: TextStyle(color: Colors.black),
                      ),
                      25.getHeightWhiteSpacing,
                      Wrap(
                        children: options
                            .map(
                              (opt) =>
                                  buildOption(opt["label"]!, opt["image"]!),
                            )
                            .toList(),
                      ),
                      20.getHeightWhiteSpacing,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: AppButtons(
              onPressed: () {
                if (selectedOptions.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Please select at least one category to continue"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pushNamed(context, "/signupaddress");
              },
              text: "Done",
            ),
          ),
        ),
      ),
    );
  }
}
