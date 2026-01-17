import 'package:flutter/widgets.dart';
import 'package:real_state/core/utils/motion_utils.dart';

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.98,
    this.hoverScale = 0.99,
    this.duration = const Duration(milliseconds: 140),
  });

  final Widget child;
  final bool enabled;
  final double scale;
  final double hoverScale;
  final Duration duration;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;
  bool _hovered = false;

  double _targetScale() {
    if (!widget.enabled) return 1.0;
    if (_pressed) return widget.scale;
    if (_hovered) return widget.hoverScale;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;

    return Listener(
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
      child: MouseRegion(
        onEnter: widget.enabled ? (_) => _setHovered(true) : null,
        onExit: widget.enabled ? (_) => _setHovered(false) : null,
        child: AnimatedScale(
          scale: _targetScale(),
          duration: widget.duration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }
}
