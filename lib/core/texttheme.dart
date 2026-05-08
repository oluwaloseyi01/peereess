import 'package:flutter/material.dart';
import 'package:peereess/core/app_color.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppTextTheme — call the correct factory based on brightness
// Usage in AppTheme:
//   lightTheme: ThemeData(textTheme: AppTextTheme.light, ...)
//   darkTheme:  ThemeData(textTheme: AppTextTheme.dark,  ...)
// ─────────────────────────────────────────────────────────────────────────────
class AppTextTheme {
  AppTextTheme._();

  static ThemeData get lightTheme => ThemeData(
        textTheme: AppTextTheme.light, // ← add this
      );
  static ThemeData get darkTheme => ThemeData(
        textTheme: AppTextTheme.dark, // ← add this
      );

  static final TextTheme light = TextTheme(
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColor.textPrimLight,
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColor.textPrimLight,
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColor.textPrimLight,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColor.textSecLight,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColor.textSecLight,
    ),
    bodyLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      color: AppColor.textPrimLight,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: AppColor.textSecLight,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColor.textSecLight,
    ),
  );

  static final TextTheme dark = TextTheme(
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColor.textPrimDark,
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColor.textPrimDark,
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColor.textPrimDark,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColor.textSecDark,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColor.textSecDark,
    ),
    bodyLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      color: AppColor.textPrimDark,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: AppColor.textSecDark,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColor.textSecDark,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Extensions — shorthand access on BuildContext
// ─────────────────────────────────────────────────────────────────────────────
extension ThemeExtensions on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
