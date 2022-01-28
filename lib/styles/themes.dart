import 'package:flutter/material.dart';

import 'colors.dart';

abstract class AppThemes {
  static ThemeData light = ThemeData(
    primarySwatch: AppColors.green,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    chipTheme: ChipThemeData.fromDefaults(
      primaryColor: AppColors.green,
      secondaryColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.white),
    ),
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
