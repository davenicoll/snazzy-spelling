import 'package:flutter/material.dart';

class QwertyKeyboard extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  const QwertyKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onSubmit,
  });

  static const _rows = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Allow up to 900px on tablets, no longer capped at 600
        final effectiveWidth = constraints.maxWidth.clamp(0.0, 900.0);

        // Action key takes ~16% of width
        final actionKeyWidth = (effectiveWidth * 0.16).clamp(60.0, 120.0);
        final gap = (effectiveWidth * 0.015).clamp(8.0, 14.0);

        // Letter area = total minus action column and gap
        final letterAreaWidth = effectiveWidth - actionKeyWidth - gap;

        // 10 keys in the widest row; derive key size from available space
        // Gap between keys scales proportionally
        final keyGap = (letterAreaWidth * 0.008).clamp(2.0, 5.0);
        final totalGaps = 10 * 2 * keyGap; // padding on both sides of each key
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
                SizedBox(width: gap),
                // Action keys: Delete aligned with top row, Check with bottom
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Delete — aligned with top row
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: rowGap),
                      child: _LabelActionKey(
                        label: 'Delete',
                        width: actionKeyWidth,
                        height: keyHeight,
                        onPressed: onBackspace,
                      ),
                    ),
                    // Spacer for middle row
                    SizedBox(height: keyHeight + rowGap * 2),
                    // Check — aligned with bottom row
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: rowGap),
                      child: _CheckKey(
                        width: actionKeyWidth,
                        height: keyHeight,
                        onPressed: onSubmit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LetterKey extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gap),
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onPressed,
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: width * 0.45,
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

class _LabelActionKey extends StatelessWidget {
  final String label;
  final double width;
  final double height;
  final VoidCallback onPressed;

  const _LabelActionKey({
    required this.label,
    required this.width,
    required this.height,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: height * 0.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckKey extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onPressed;

  const _CheckKey({
    required this.width,
    required this.height,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Center(
            child: Text(
              'Check',
              style: TextStyle(
                fontSize: height * 0.35,
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
