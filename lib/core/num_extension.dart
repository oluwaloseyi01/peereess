import 'package:flutter/material.dart';

extension NumExtension on int {
  Widget get getHeightWhiteSpacing => SizedBox(height: toDouble());
  Widget get getWidthWhiteSpacing => SizedBox(width: toDouble());
}
