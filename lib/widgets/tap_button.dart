import 'package:flutter/material.dart';

/// A button that fires on tap-down for immediate, consistent response.
///
/// Material's [FilledButton]/[IconButton]/[InkWell] fire on tap-up and take
/// part in the gesture arena, so a tiny finger movement — common for young
/// children, and especially when the button sits inside a scrollable — is
/// claimed as a drag and the tap is silently dropped. Their ripple also
/// debounces rapid repeated taps. Firing on tap-down sidesteps both problems
/// and guarantees the press registers every time. This mirrors the approach
/// already used by [QwertyKeyboard]'s keys.
///
/// Pass a null [onPressed] to render a disabled (dimmed, non-interactive)
/// button — matching the semantics of the Material buttons this replaces.
class TapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final Color pressedColor;

  /// Background when disabled. Defaults to [color] at 38% opacity.
  final Color? disabledColor;
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  /// Accessibility label announced by screen readers (Material buttons derive
  /// theirs from a Text/Icon child or tooltip; a custom gesture button must
  /// supply one explicitly).
  final String? semanticLabel;

  const TapButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.color,
    required this.pressedColor,
    this.disabledColor,
    this.width,
    this.height = 48,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.semanticLabel,
  });

  @override
  State<TapButton> createState() => _TapButtonState();
}

/// Circular, filled-tonal icon button that fires on tap-down — a responsive
/// replacement for [IconButton.filledTonal] for controls a child taps in quick
/// succession (replay/speak, flashcard navigation). See [TapButton].
class TapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final String? semanticLabel;

  const TapIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 56,
    this.iconSize = 32,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TapButton(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      color: scheme.secondaryContainer,
      pressedColor: scheme.inversePrimary,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: Icon(icon, size: iconSize, color: scheme.onSecondaryContainer),
    );
  }
}

class _TapButtonState extends State<TapButton> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    setState(() => _pressed = true);
    onPressed();
    // Brief highlight then reset, matching the keyboard keys.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final Color background = !enabled
        ? (widget.disabledColor ?? widget.color.withValues(alpha: 0.38))
        : (_pressed ? widget.pressedColor : widget.color);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: GestureDetector(
          onTapDown: enabled ? _handleTapDown : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            decoration: BoxDecoration(
              color: background,
              borderRadius: widget.borderRadius,
            ),
            child: Center(
              child: Opacity(
                opacity: enabled ? 1.0 : 0.6,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
