import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final String image;
  final String title;
  final Color backgroundColor;
  final Color textColor;

  const CategoryWidget({
    super.key,
    required this.onPressed,
    required this.image,
    required this.title,
    this.backgroundColor = const Color.fromARGB(255, 225, 202, 169),
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(9.0),
              child: Center(child: Image.asset(image, height: 27, width: 27)),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
