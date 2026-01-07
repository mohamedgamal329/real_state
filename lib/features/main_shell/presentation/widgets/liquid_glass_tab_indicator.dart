import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

class LiquidGlassTabIndicator extends StatefulWidget {
  const LiquidGlassTabIndicator({
    super.key,
    this.visible = true,
    required this.child,
    this.indicatorColor,
    required this.tabIndex,
    required this.tabCount,
    required this.onTabChanged,
  });

  final int tabIndex;
  final int tabCount;
  final bool visible;
  final Widget child;
  final Color? indicatorColor;
  final ValueChanged<int> onTabChanged;

  @override
  State<LiquidGlassTabIndicator> createState() =>
      LiquidGlassTabIndicatorState();
}

class LiquidGlassTabIndicatorState extends State<LiquidGlassTabIndicator>
    with SingleTickerProviderStateMixin {
  bool _isDown = false;
  bool _isDragging = false;

  late double xAlign = computeXAlignmentForTab(widget.tabIndex);

  bool get _isRtl => Directionality.of(context) == TextDirection.rtl;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassTabIndicator oldWidget) {
    if (oldWidget.tabIndex != widget.tabIndex ||
        oldWidget.tabCount != widget.tabCount) {
      setState(() {
        xAlign = computeXAlignmentForTab(widget.tabIndex);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  double computeXAlignmentForTab(int tabIndex) {
    final visualIndex = _actualToVisualIndex(tabIndex);
    final denominator = widget.tabCount <= 1 ? 1 : (widget.tabCount - 1);
    final relativeTabIndex = (visualIndex / denominator).clamp(0.0, 1.0);
    return (relativeTabIndex * 2) - 1; // -1 to 1
  }

  double _getAlignmentFromGlobalPostition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);

    // Calculate the effective draggable range
    // The indicator moves within the tab bar, but has its own width (1/tabCount of total)
    final indicatorWidth = 1.0 / widget.tabCount; // Relative width of indicator
    final draggableRange =
        1.0 - indicatorWidth; // Range the indicator center can move
    final padding = indicatorWidth / 2; // Padding on each side

    // Map the drag position to the draggable range
    final rawRelativeX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final visualRelativeX = _isRtl
        ? 1 - rawRelativeX
        : rawRelativeX; // 0 starts from the visible first tab
    final normalizedX = (visualRelativeX - padding) / draggableRange;

    // Apply rubber band resistance for overdrag
    final adjustedRelativeX = _applyRubberBandResistance(normalizedX);
    final directionalRelative = _isRtl
        ? 1 - adjustedRelativeX
        : adjustedRelativeX;
    return (directionalRelative * 2) -
        1; // Convert to -1:1 range respecting direction
  }

  void _onDragDown(DragDownDetails details) {
    setState(() {
      _isDown = true;
      xAlign = _getAlignmentFromGlobalPostition(details.globalPosition);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      xAlign = _getAlignmentFromGlobalPostition(details.globalPosition);
    });
  }

  // Apply rubber band resistance similar to iOS scroll views
  double _applyRubberBandResistance(double value) {
    const double resistance = 0.4; // Lower values = more resistance
    const double maxOverdrag =
        0.3; // Maximum overdrag as fraction of normal range

    if (value < 0) {
      // Overdrag to the left
      final overdrag = -value;
      final resistedOverdrag = overdrag * resistance;
      return -resistedOverdrag.clamp(0.0, maxOverdrag);
    } else if (value > 1) {
      // Overdrag to the right
      final overdrag = value - 1;
      final resistedOverdrag = overdrag * resistance;
      return 1 + resistedOverdrag.clamp(0.0, maxOverdrag);
    } else {
      // Normal range, no resistance
      return value;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _isDown = false;
    });

    final box = context.findRenderObject() as RenderBox;
    final currentRelativeX = (xAlign + 1) / 2; // Convert from -1:1 to 0:1
    final visualRelativeX = _isRtl ? 1 - currentRelativeX : currentRelativeX;
    final tabWidth = 1.0 / widget.tabCount;

    // Calculate velocity in relative units, adjusted for the draggable range
    final indicatorWidth = 1.0 / widget.tabCount;
    final draggableRange = 1.0 - indicatorWidth;
    final velocityX =
        (details.velocity.pixelsPerSecond.dx / box.size.width) / draggableRange;
    final visualVelocityX = _isRtl ? -velocityX : velocityX;

    // Determine target tab based on position and velocity
    int targetTabIndex;

    // Handle overdrag scenarios first
    if (visualRelativeX < 0) {
      // Overdragged to the left - snap to first tab
      targetTabIndex = 0;
    } else if (visualRelativeX > 1) {
      // Overdragged to the right - snap to last tab
      targetTabIndex = widget.tabCount - 1;
    } else {
      // Normal range - consider velocity
      const velocityThreshold = 0.5; // Adjust this threshold as needed
      if (visualVelocityX.abs() > velocityThreshold) {
        // High velocity - project where we would end up
        final projectedX = (visualRelativeX + visualVelocityX * 0.3).clamp(
          0.0,
          1.0,
        ); // 0.3s projection
        targetTabIndex = (projectedX / tabWidth).round().clamp(
          0,
          widget.tabCount - 1,
        );

        // Ensure we move at least one tab if velocity is strong enough
        final currentTabIndex = (visualRelativeX / tabWidth).round().clamp(
          0,
          widget.tabCount - 1,
        );
        if (visualVelocityX > velocityThreshold &&
            targetTabIndex <= currentTabIndex &&
            currentTabIndex < widget.tabCount - 1) {
          targetTabIndex = currentTabIndex + 1;
        } else if (visualVelocityX < -velocityThreshold &&
            targetTabIndex >= currentTabIndex &&
            currentTabIndex > 0) {
          targetTabIndex = currentTabIndex - 1;
        }
      } else {
        // Low velocity - snap to nearest tab
        targetTabIndex = (visualRelativeX / tabWidth).round().clamp(
          0,
          widget.tabCount - 1,
        );
      }
    }
    final resolvedTabIndex = _visualToActualIndex(targetTabIndex);
    xAlign = computeXAlignmentForTab(resolvedTabIndex);

    // Notify parent of tab change if different from current
    if (resolvedTabIndex != widget.tabIndex) {
      widget.onTabChanged(resolvedTabIndex);
    }
  }

  void _forceSnapToNearestTab() {
    setState(() {
      _isDown = false;
      _isDragging = false;

      // Convert xAlign (-1..1) → relativeX (0..1)
      double relativeX = ((xAlign + 1) / 2).clamp(0.0, 1.0);
      final visualRelativeX = _isRtl ? 1 - relativeX : relativeX;

      // Correct nearest tab calculation
      final nearestTab = (visualRelativeX * (widget.tabCount - 1))
          .round()
          .clamp(0, widget.tabCount - 1);
      final resolvedTabIndex = _visualToActualIndex(nearestTab);

      // Snap xAlign to nearest tab
      xAlign = computeXAlignmentForTab(resolvedTabIndex);

      if (resolvedTabIndex != widget.tabIndex) {
        widget.onTabChanged(resolvedTabIndex);
      }
    });
  }

  int _visualToActualIndex(int visualIndex) =>
      _isRtl ? (widget.tabCount - 1 - visualIndex) : visualIndex;

  int _actualToVisualIndex(int actualIndex) =>
      _isRtl ? (widget.tabCount - 1 - actualIndex) : actualIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indicatorColor =
        widget.indicatorColor ??
        colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.12);
    final targetAlignment = computeXAlignmentForTab(widget.tabIndex);

    return Listener(
      onPointerDown: (_) {
        _isDown = true;
      },
      onPointerUp: (_) {
        _forceSnapToNearestTab();
      },
      onPointerCancel: (_) {
        _forceSnapToNearestTab();
      },
      child: GestureDetector(
        onHorizontalDragEnd: _onDragEnd,
        behavior: HitTestBehavior.opaque,
        onHorizontalDragDown: _onDragDown,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragCancel: _forceSnapToNearestTab,
        child: VelocityMotionBuilder(
          converter: SingleMotionConverter(),
          value: xAlign,
          motion: _isDragging
              ? const Motion.interactiveSpring(snapToEnd: true)
              : const Motion.bouncySpring(snapToEnd: true),
          builder: (context, value, velocity, child) {
            final alignment = Alignment(value, 0);
            return SingleMotionBuilder(
              motion: const Motion.snappySpring(
                snapToEnd: true,
                duration: Duration(milliseconds: 300),
              ),
              value:
                  widget.visible &&
                      (_isDown || (alignment.x - targetAlignment).abs() > 0.30)
                  ? 1.0
                  : 0.0,
              builder: (context, thickness, child) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (thickness < 1)
                      _IndicatorTransform(
                        velocity: velocity,
                        tabCount: widget.tabCount,
                        alignment: alignment,
                        thickness: thickness,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: widget.visible && thickness <= .2 ? 1 : 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: indicatorColor,
                              borderRadius: BorderRadius.circular(64),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    child!,
                    if (thickness > 0)
                      _IndicatorTransform(
                        velocity: velocity,
                        tabCount: widget.tabCount,
                        alignment: alignment,
                        thickness: thickness,
                        child: LiquidGlass.withOwnLayer(
                          fake: false,
                          settings: LiquidGlassSettings(
                            visibility: thickness,
                            glassColor: Color.from(
                              alpha: .1,
                              red: 1,
                              green: 1,
                              blue: 1,
                            ),
                            saturation: 1.5,
                            refractiveIndex: 1.15,
                            thickness: 20,
                            lightIntensity: 2,
                            chromaticAberration: .5,
                            blur: 0,
                          ),
                          shape: const LiquidRoundedSuperellipse(
                            borderRadius: 64,
                          ),
                          child: GlassGlow(child: const SizedBox.expand()),
                        ),
                      ),
                  ],
                );
              },
              child: widget.child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class _IndicatorTransform extends StatelessWidget {
  const _IndicatorTransform({
    required this.child,
    required this.velocity,
    required this.tabCount,
    required this.alignment,
    required this.thickness,
  });

  final int tabCount;
  final double velocity;
  final double thickness;
  final Alignment alignment;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rect = RelativeRect.lerp(
      RelativeRect.fill,
      const RelativeRect.fromLTRB(-14, -14, -14, -14),
      thickness,
    );
    return Positioned.fill(
      left: 4,
      right: 4,
      top: 4,
      bottom: 4,
      child: FractionallySizedBox(
        widthFactor: 1 / tabCount,
        alignment: alignment,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRelativeRect(
              rect: rect!,
              child: SingleMotionBuilder(
                motion: Motion.bouncySpring(
                  duration: const Duration(milliseconds: 600),
                ),
                value: velocity,
                builder: (context, velocity, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: buildJellyTransform(
                      velocity: Offset(velocity, 0),
                      maxDistortion: .8,
                      velocityScale: 10,
                    ),
                    child: child,
                  );
                },
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a jelly transform matrix based on velocity for organic squash and stretch effect
  Matrix4 buildJellyTransform({
    required Offset velocity,
    double maxDistortion = 0.7,
    double velocityScale = 1000.0,
  }) {
    // Calculate the magnitude of velocity to determine distortion intensity
    final speed = velocity.distance;

    // Normalize velocity direction
    final direction = speed > 0 ? velocity / speed : Offset.zero;

    // Apply a scaling factor to make the effect more pronounced
    final distortionFactor =
        (speed / velocityScale).clamp(0.0, 1.0) * maxDistortion;

    if (distortionFactor == 0) {
      return Matrix4.identity();
    }

    // Create squash and stretch effect
    // Squash in the direction of movement, stretch perpendicular to it
    final squashX = 1.0 - (direction.dx.abs() * distortionFactor * 0.5);
    final squashY = 1.0 - (direction.dy.abs() * distortionFactor * 0.5);
    final stretchX = 1.0 + (direction.dy.abs() * distortionFactor * 0.3);
    final stretchY = 1.0 + (direction.dx.abs() * distortionFactor * 0.3);

    // Combine squash and stretch effects
    final scaleX = squashX * stretchX;
    final scaleY = squashY * stretchY;

    // Build the transformation matrix
    final matrix = Matrix4.identity();

    // Apply scale transformation
    matrix.scaleByVector3(
      vmath.Vector3(
        scaleX,
        scaleY,
        1,
      ),
    );

    return matrix;
  }
}
