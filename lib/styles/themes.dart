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

  static ThemeData light([ColorScheme? colorScheme]) {
    colorScheme ??= lightScheme;

    return ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    ).copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      chipTheme: ChipThemeData.fromDefaults(
        primaryColor: colorScheme.primary,
        secondaryColor: ElevationOverlay.applySurfaceTint(
          colorScheme.surface,
          colorScheme.surfaceTint,
          1,
        ),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        color: colorScheme.background,
        surfaceTintColor: colorScheme.background,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.background,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.background,
      ),
      cardTheme: CardTheme(
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark([ColorScheme? colorScheme]) {
    colorScheme ??= darkScheme;

    return ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    ).copyWith(
      cardTheme: CardTheme(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: colorScheme.surfaceVariant,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.background,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.background,
      ),
      appBarTheme: AppBarTheme(
        color: colorScheme.background,
        surfaceTintColor: colorScheme.background,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          onPrimary: colorScheme.onSurfaceVariant,
          primary: colorScheme.surfaceVariant,
        ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.inversePrimary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      chipTheme: ChipThemeData.fromDefaults(
        primaryColor: colorScheme.primary,
        secondaryColor: colorScheme.onPrimary,
        labelStyle: const TextStyle(color: Colors.white),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
