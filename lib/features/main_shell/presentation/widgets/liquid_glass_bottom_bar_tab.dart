import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:real_state/core/constants/app_colors.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

class LiquidGlassTabItem {
  const LiquidGlassTabItem({
    this.icon,
    this.svgAsset,
    this.glowColor,
    this.activeStyle,
    this.inactiveStyle,
    required this.label,
    this.activeColor,
    this.inactiveColor,
  });

  final IconData? icon;
  final String? svgAsset;
  final String label;
  final Color? glowColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final TextStyle? activeStyle;
  final TextStyle? inactiveStyle;
}

class LiquidGlassBottomBarTab extends StatelessWidget {
  const LiquidGlassBottomBarTab({
    super.key,
    required this.tab,
    required this.onTap,
    required this.selected,
  });

  final bool selected;
  final VoidCallback onTap;
  final LiquidGlassTabItem tab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = tab.icon;
    final svgAsset = tab.svgAsset;
    final activeColor = AppColors.primary; // tab.activeColor ?? scheme.primary;
    final inactiveColor = tab.inactiveColor ?? scheme.onSurfaceVariant;
    final baseText = Theme.of(context).textTheme.labelSmall;
    final activeStyle =
        tab.activeStyle ??
        baseText?.copyWith(color: activeColor, fontWeight: FontWeight.w700);
    final inactiveStyle =
        tab.inactiveStyle ??
        baseText?.copyWith(color: inactiveColor, fontWeight: FontWeight.w600);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: tab.label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null || svgAsset != null)
                ExcludeSemantics(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (tab.glowColor != null)
                        Positioned(
                          top: -24,
                          right: -24,
                          left: -24,
                          bottom: -24,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            transformAlignment: Alignment.center,
                            curve: Curves.easeOutCirc,
                            transform: selected
                                ? Matrix4.identity()
                                : (Matrix4.identity()
                                    ..scaleByVector3(vmath.Vector3.all(0.4))
                                    ..rotateZ(-math.pi)),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: selected ? 1 : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tab.glowColor!.withValues(
                                        alpha: selected ? 0.6 : 0,
                                      ),
                                      blurRadius: 32,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      AnimatedScale(
                        scale: 1,
                        duration: const Duration(milliseconds: 150),
                        child: svgAsset != null
                            ? AppSvgIcon(
                                svgAsset,
                                size: 24,
                                color: selected ? activeColor : inactiveColor,
                              )
                            : Icon(
                                icon,
                                size: 24,
                                color: selected ? activeColor : inactiveColor,
                              ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: selected ? activeStyle : inactiveStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
