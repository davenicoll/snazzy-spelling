import 'package:flutter/material.dart';

/// A button that fires on tap-down for immediate, consistent response.
///
/// Material's [FilledButton]/[InkWell] fire on tap-up and take part in the
/// gesture arena, so a tiny finger movement — common for young children, and
/// especially when the button sits inside a scrollable — is claimed as a drag
/// and the tap is silently dropped. Firing on tap-down sidesteps the arena and
/// guarantees the press registers every time. This mirrors the approach already
/// used by [QwertyKeyboard]'s keys.
class TapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color color;
  final Color pressedColor;
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const TapButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.color,
    required this.pressedColor,
    this.width,
    this.height = 48,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<TapButton> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
    widget.onPressed();
    // Brief highlight then reset, matching the keyboard keys.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: _pressed ? widget.pressedColor : widget.color,
            borderRadius: widget.borderRadius,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
