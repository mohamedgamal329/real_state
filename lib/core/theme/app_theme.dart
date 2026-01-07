import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Cairo',
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.35),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.35),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        color: Colors.white.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: base.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
        hintStyle: base.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Cairo',
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
    );
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.black.withValues(alpha: 0.7),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        color: Colors.grey[900]?.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[900]?.withValues(alpha: 0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
