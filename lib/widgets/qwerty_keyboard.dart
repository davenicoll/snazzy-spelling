import 'package:flutter/material.dart';

class QwertyKeyboard extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;

  /// Backspace handler. Pass null to hide the Delete key (e.g. game mode, where
  /// correct letters lock in and wrong ones are ignored — nothing to delete).
  final VoidCallback? onBackspace;

  /// Submit handler. Pass null to hide the Check key (e.g. game mode, where the
  /// word auto-completes as the final correct letter is typed).
  final VoidCallback? onSubmit;

  const QwertyKeyboard({
    super.key,
    required this.onKeyPressed,
    this.onBackspace,
    this.onSubmit,
  });

  static const _rows = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  @override
  Widget build(BuildContext context) {
    final hasActions = onBackspace != null || onSubmit != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = constraints.maxWidth.clamp(0.0, 900.0);

        final actionKeyWidth =
            hasActions ? (effectiveWidth * 0.16).clamp(60.0, 120.0) : 0.0;
        final gap = hasActions ? (effectiveWidth * 0.015).clamp(8.0, 14.0) : 0.0;

        final letterAreaWidth = effectiveWidth - actionKeyWidth - gap;

        final keyGap = (letterAreaWidth * 0.008).clamp(2.0, 5.0);
        final totalGaps = 10 * 2 * keyGap;
        final keyWidth = ((letterAreaWidth - totalGaps) / 10).clamp(24.0, 64.0);
        final keyHeight = (keyWidth * 1.15).clamp(36.0, 60.0);
        final rowGap = (keyHeight * 0.08).clamp(2.0, 5.0);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Letter keys
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (final row in _rows)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: rowGap),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: row
                                .map((letter) => _LetterKey(
                                      letter: letter,
                                      width: keyWidth,
                                      height: keyHeight,
                                      gap: keyGap,
                                      onPressed: () => onKeyPressed(letter),
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasActions) ...[
                  SizedBox(width: gap),
                  // Action keys: Delete aligned with top row, Check with bottom
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onBackspace != null)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: rowGap),
                          child: _ActionKey(
                            label: 'Delete',
                            width: actionKeyWidth,
                            height: keyHeight,
                            onPressed: onBackspace!,
                          ),
                        ),
                      SizedBox(height: keyHeight + rowGap * 2),
                      if (onSubmit != null)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: rowGap),
                          child: _CheckKey(
                            width: actionKeyWidth,
                            height: keyHeight,
                            onPressed: onSubmit!,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A keyboard key that fires on tap-down for immediate response,
/// with a brief highlight instead of InkWell's splash (which debounces
/// rapid taps and drops key presses).
class _LetterKey extends StatefulWidget {
  final String letter;
  final double width;
  final double height;
  final double gap;
  final VoidCallback onPressed;

  const _LetterKey({
    required this.letter,
    required this.width,
    required this.height,
    required this.gap,
    required this.onPressed,
  });

  @override
  State<_LetterKey> createState() => _LetterKeyState();
}

class _LetterKeyState extends State<_LetterKey> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
    widget.onPressed();
    // Brief highlight then reset
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final pressedColor = Theme.of(context).colorScheme.inversePrimary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.gap),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            decoration: BoxDecoration(
              color: _pressed ? pressedColor : baseColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                widget.letter,
                style: TextStyle(
                  fontSize: widget.width * 0.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatefulWidget {
  final String label;
  final double width;
  final double height;
  final VoidCallback onPressed;

  const _ActionKey({
    required this.label,
    required this.width,
    required this.height,
    required this.onPressed,
  });

  @override
  State<_ActionKey> createState() => _ActionKeyState();
}

class _ActionKeyState extends State<_ActionKey> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
    widget.onPressed();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final pressedColor = Theme.of(context).colorScheme.inversePrimary;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: _pressed ? pressedColor : baseColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.height * 0.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckKey extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback onPressed;

  const _CheckKey({
    required this.width,
    required this.height,
    required this.onPressed,
  });

  @override
  State<_CheckKey> createState() => _CheckKeyState();
}

class _CheckKeyState extends State<_CheckKey> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
    widget.onPressed();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.tertiary;
    final pressedColor = Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.7);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: _pressed ? pressedColor : baseColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              'Check',
              style: TextStyle(
                fontSize: widget.height * 0.35,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
