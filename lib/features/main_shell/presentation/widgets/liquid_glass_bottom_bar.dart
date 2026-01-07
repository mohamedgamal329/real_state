import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:real_state/features/main_shell/presentation/widgets/liquid_glass_bottom_bar_tab.dart';
import 'package:real_state/features/main_shell/presentation/widgets/liquid_glass_tab_indicator.dart';

class LiquidGlassBottomBar extends StatelessWidget {
  const LiquidGlassBottomBar({
    super.key,
    required this.tabs,
    this.barHeight = 64,
    this.indicatorColor,
    this.showIndicator = true,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final double barHeight;
  final int selectedIndex;
  final bool showIndicator;
  final Color? indicatorColor;
  final List<LiquidGlassTabItem> tabs;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: EdgeInsets.zero,
      child: LiquidGlassLayer(
        fake: false,
        settings: _buildGlassSettings(colorScheme, isDark),
        child: LiquidGlassBlendGroup(
          blend: 12,
          child: Container(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxWidth: 777),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(33),
              boxShadow: [
                BoxShadow(
                  inset: true,
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(4, 2),
                  blurStyle: BlurStyle.inner,
                  color: colorScheme.shadow.withValues(
                    alpha: isDark ? 0.2 : 0.12,
                  ),
                ),
              ],
              gradient: LinearGradient(
                end: AlignmentDirectional.centerEnd,
                begin: AlignmentDirectional.centerStart,
                colors: [
                  Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.2),
                    colorScheme.surface.withValues(alpha: isDark ? 0.24 : 0.3),
                  ),
                  Color.alphaBlend(
                    colorScheme.secondary.withValues(
                      alpha: isDark ? 0.12 : 0.16,
                    ),
                    colorScheme.surfaceContainerHighest.withValues(
                      alpha: isDark ? 0.12 : 0.16,
                    ),
                  ),
                ],
              ),
              border: Border.all(
                width: 1.6,
                color: Color.alphaBlend(
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.28 : 0.2,
                  ),
                ),
              ),
            ),
            child: LiquidGlassTabIndicator(
              tabCount: tabs.length,
              visible: showIndicator,
              tabIndex: selectedIndex,
              indicatorColor: indicatorColor,
              onTabChanged: onTabSelected,
              child: LiquidGlass.grouped(
                clipBehavior: Clip.none,
                shape: const LiquidRoundedSuperellipse(borderRadius: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  height: barHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Expanded(
                          child: LiquidGlassBottomBarTab(
                            tab: tabs[i],
                            selected: selectedIndex == i,
                            onTap: () => onTabSelected(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LiquidGlassSettings _buildGlassSettings(ColorScheme scheme, bool isDark) {
    return LiquidGlassSettings(
      blur: isDark ? 18 : 14,
      thickness: 22,
      saturation: isDark ? 1.05 : 1.2,
      ambientStrength: isDark ? 0.32 : 0.4,
      lightIntensity: isDark ? 0.75 : 0.95,
      glassColor: Color.alphaBlend(
        scheme.primary.withValues(alpha: isDark ? 0.16 : 0.12),
        scheme.surface.withValues(alpha: isDark ? 0.32 : 0.26),
      ),
      refractiveIndex: 1.2,
    );
  }
}
