import 'package:flutter/material.dart';

import 'colors.dart';

abstract class AppThemes {
  static ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    primary: AppColors.green,
    secondary: AppColors.green,
    tertiary: AppColors.green,
    surface: Colors.grey[50],
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
    surface: Colors.grey[850],
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
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Use PredictiveBackPageTransitionsBuilder to get the predictive back route transition!
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
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
        color: colorScheme.surfaceBright,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        height: 70,
      ),
      appBarTheme: AppBarTheme(
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          backgroundColor: colorScheme.surfaceBright,
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurface,
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Use PredictiveBackPageTransitionsBuilder to get the predictive back route transition!
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
