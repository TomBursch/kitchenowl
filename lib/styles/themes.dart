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
        labelStyle: TextStyle(color: colorScheme.onPrimary),
      ).copyWith(
        checkmarkColor: colorScheme.onPrimary,
        side: BorderSide.none,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background,
        surfaceTintColor: colorScheme.background,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.background,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.background,
        height: 70,
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

  // ignore: long-method
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
        height: 70,
      ),
      appBarTheme: AppBarTheme(
        color: colorScheme.background,
        surfaceTintColor: colorScheme.background,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          backgroundColor: colorScheme.surfaceVariant,
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onBackground,
      ),
      chipTheme: ChipThemeData.fromDefaults(
        primaryColor: colorScheme.primary,
        secondaryColor: colorScheme.onPrimary,
        labelStyle: TextStyle(color: colorScheme.onPrimary),
      ).copyWith(
        checkmarkColor: colorScheme.onPrimary,
        side: BorderSide.none,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
