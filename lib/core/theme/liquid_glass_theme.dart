import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidGlassTheme {
  LiquidGlassTheme._internal();
  static final LiquidGlassTheme _instance = LiquidGlassTheme._internal();
  factory LiquidGlassTheme() => _instance;

  static Brightness _brightness(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context);
  static bool _isDark(BuildContext context) =>
      _brightness(context) == Brightness.dark;

  static LiquidGlassSettings glassSettings(
    BuildContext context, {
    Color? glassColor,
  }) {
    final isDark = _isDark(context);

    return LiquidGlassSettings(
      blur: 8,
      thickness: 30,
      saturation: 1.5,
      refractiveIndex: 1.21,
      lightAngle: math.pi / 4,
      lightIntensity: isDark ? .7 : 1,
      ambientStrength: isDark ? .2 : .5,
      glassColor:
          glassColor ??
          CupertinoTheme.of(context).barBackgroundColor.withValues(alpha: 0.6),
    );
  }
}
