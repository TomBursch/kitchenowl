import 'package:flutter/material.dart';

import 'colors.dart';

abstract class AppThemes {
  static ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    secondary: AppColors.green,
    tertiary: AppColors.green,
    background: Colors.grey[50],
    brightness: Brightness.light,
  );

  static ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    secondary: AppColors.green,
    tertiary: AppColors.green,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onTertiary: Colors.white,
    background: Colors.grey[850],
    brightness: Brightness.dark,
  );

  static ThemeData light = ThemeData.from(
    colorScheme: lightScheme,
    useMaterial3: true,
  ).copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    chipTheme: ChipThemeData.fromDefaults(
      primaryColor: lightScheme.primary,
      secondaryColor: ElevationOverlay.applySurfaceTint(
        lightScheme.surface,
        lightScheme.surfaceTint,
        1,
      ),
      labelStyle: const TextStyle(color: Colors.white),
    ),
    appBarTheme: AppBarTheme(
      color: lightScheme.background,
      surfaceTintColor: lightScheme.background,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: lightScheme.background,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightScheme.background,
    ),
    cardTheme: CardTheme(
      clipBehavior: Clip.antiAlias,
      color: lightScheme.surface,
      surfaceTintColor: lightScheme.surfaceTint,
    ),
  );

  static ThemeData dark = ThemeData.from(
    colorScheme: darkScheme,
    useMaterial3: true,
  ).copyWith(
    cardTheme: CardTheme(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: darkScheme.surfaceVariant,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: darkScheme.background,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkScheme.background,
    ),
    appBarTheme: AppBarTheme(
      color: darkScheme.background,
      surfaceTintColor: darkScheme.background,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        onPrimary: darkScheme.onSurfaceVariant,
        primary: darkScheme.surfaceVariant,
      ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
