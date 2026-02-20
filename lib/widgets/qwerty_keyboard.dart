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
        final effectiveWidth = constraints.maxWidth.clamp(0.0, 600.0);
        final actionKeyWidth = (effectiveWidth * 0.18).clamp(60.0, 100.0);
        // Estimate letter area to derive consistent keyHeight for action keys
        final letterArea = effectiveWidth - actionKeyWidth - 18;
        final keyWidth = ((letterArea - 10 * 6) / 10).clamp(18.0, 44.0);
        final keyHeight = (keyWidth * 1.1).clamp(28.0, 48.0);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Letter keys (left section)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, letterConstraints) {
                      final available = letterConstraints.maxWidth;
                      final lkw =
                          ((available - 10 * 6) / 10).clamp(18.0, 44.0);
                      final lkh = (lkw * 1.1).clamp(28.0, 48.0);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (final row in _rows)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: row
                                    .map((letter) => _LetterKey(
                                          letter: letter,
                                          width: lkw,
                                          height: lkh,
                                          onPressed: () =>
                                              onKeyPressed(letter),
                                        ))
                                    .toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Action keys (right section): Delete + Check
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Delete — aligned with top row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: _LabelActionKey(
                        label: 'Delete',
                        width: actionKeyWidth,
                        height: keyHeight,
                        onPressed: onBackspace,
                      ),
                    ),
                    // Spacer for middle row
                    SizedBox(height: keyHeight + 4),
                    // Check — aligned with bottom row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
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
  final VoidCallback onPressed;

  const _LetterKey({
    required this.letter,
    required this.width,
    required this.height,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Theme.of(context).colorScheme.primary,
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
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
