import 'package:flutter/material.dart';

import 'tap_button.dart';

class WordCard extends StatelessWidget {
  final String word;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  const WordCard({
    super.key,
    required this.word,
    this.onSpeak,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    const buttonSize = 48.0;
    const margin = 24.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(margin, margin, margin, margin),
      child: Stack(
        children: [
          // Card inset by half the button height so button sits within bounds
          Positioned.fill(
            top: buttonSize / 2,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth * 0.8,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text(
                            word,
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Button on top, centered horizontally, straddling the card's top edge
          if (onSpeak != null)
            Align(
              alignment: Alignment.topCenter,
              child: Tooltip(
                message: 'Listen',
                child: TapIconButton(
                  icon: Icons.volume_up,
                  iconSize: 32,
                  semanticLabel: 'Listen',
                  onPressed: isSpeaking ? null : onSpeak,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
