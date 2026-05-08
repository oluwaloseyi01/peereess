import 'package:flutter/material.dart';
import 'package:peereess/core/app_color.dart';
import 'package:peereess/core/texttheme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppButtons — primary filled gradient button
// ─────────────────────────────────────────────────────────────────────────────
class AppButtons extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const AppButtons({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          gradient: colors.headerGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: context.textTheme.titleSmall?.copyWith(
              color: AppColor.white,
              fontFamily: 'poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Appbuttons2 — outlined / ghost button
// ─────────────────────────────────────────────────────────────────────────────
class Appbuttons2 extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const Appbuttons2({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.primary,
              fontFamily: 'poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppButtons3 — small compact filled button (e.g. chips, inline actions)
// ─────────────────────────────────────────────────────────────────────────────
class AppButtons3 extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const AppButtons3({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: context.textTheme.titleSmall?.copyWith(
              color: AppColor.white,
              fontFamily: 'poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
