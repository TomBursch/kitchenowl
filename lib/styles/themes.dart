import 'package:flutter/material.dart';

import 'colors.dart';

abstract class AppThemes {
  static ThemeData light = ThemeData(
    primarySwatch: AppColors.green,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
  static ThemeData dark = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: AppColors.green,
      accentColor: AppColors.green,
      brightness: Brightness.dark,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
