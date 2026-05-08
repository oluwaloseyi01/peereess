import 'package:flutter/material.dart';
import 'package:peereess/core/app_color.dart';

class AppTextTheme {
  static final textTheme = TextTheme(
    titleSmall: TextStyle(fontSize: 16, color: AppColor.dark),
    titleMedium: TextStyle(fontSize: 20, color: AppColor.dark),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColor.white,
    ),
    bodySmall: TextStyle(fontSize: 16, color: AppColor.dark),
    bodyMedium: TextStyle(fontSize: 18, color: AppColor.dark),
    bodyLarge: TextStyle(fontSize: 24, color: AppColor.dark),
  );
}

extension ThemeExtensions on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);
}
