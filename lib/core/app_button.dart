import 'package:flutter/material.dart';
import 'package:peereess/core/app_color.dart';
import 'package:peereess/core/texttheme.dart';

class AppButtons extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  const AppButtons({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor = const Color(0xffB0864C),
    this.textColor = AppColor.white,
    TextStyle? style,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xffB0864C),
              const Color.fromARGB(255, 120, 89, 45),
            ],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: context.textTheme.titleSmall?.copyWith(
              color: AppColor.white,
              fontFamily: "poppins",
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class Appbuttons2 extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  const Appbuttons2({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor = AppColor.white,
    this.textColor = const Color(0xffB0864C),
    TextStyle? style,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xffB0864C)),
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: context.textTheme.titleSmall?.copyWith(
              color: Color(0xffB0864C),
              fontFamily: "poppins",
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class AppButtons3 extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  const AppButtons3({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor = const Color(0xffB0864C),
    this.textColor = AppColor.white,
    TextStyle? style,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: context.textTheme.titleSmall?.copyWith(
              color: AppColor.white,
              fontFamily: "poppins",
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
