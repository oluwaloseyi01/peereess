import 'package:flutter/material.dart';
import 'package:peereess/core/app_button.dart';
import 'package:peereess/core/num_extension.dart';

class Recomendscreen extends StatefulWidget {
  const Recomendscreen({super.key});

  @override
  State<Recomendscreen> createState() => _RecomendscreenState();
}

class _RecomendscreenState extends State<Recomendscreen> {
  Set<String> selectedOptions = {};

  Widget buildOption(String label) {
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
        margin: EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isSelected ? Color(0xffB0864C) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Color(0xffB0864C) : Colors.grey,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<List<String>> chunkList(List<String> list, int size) {
    List<List<String>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> options = [
      "Myself",
      "My wife",
      "My Sister",
      "My mom",
      "Bestie",
      "Friends",
      "Daughter",
    ];

    final rows = chunkList(options, 3);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                20.getHeightWhiteSpacing,
                10.getHeightWhiteSpacing,
                Text(
                  "Help us recommend the right product for you",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                10.getHeightWhiteSpacing,
                Text(
                  "Who do you shop for?",
                  style: TextStyle(color: Colors.black),
                ),
                25.getHeightWhiteSpacing,
                Column(
                  children: rows.map((rowOptions) {
                    return Row(
                      children: rowOptions
                          .map((option) => buildOption(option))
                          .toList(),
                    );
                  }).toList(),
                ),
              ],
            ),
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
                      content:
                          Text("Please select at least one option to continue"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pushNamed(context, "/whatyoulikescreen");
              },
              text: "Continue",
            ),
          ),
        ),
      ),
    );
  }
}
