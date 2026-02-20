import 'package:flutter/material.dart';

class WordCard extends StatelessWidget {
  final String word;
  final VoidCallback? onSpeak;

  const WordCard({
    super.key,
    required this.word,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    const buttonSize = 48.0;
    const margin = 24.0;

    return Padding(
      padding: const EdgeInsets.all(margin),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
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
          if (onSpeak != null)
            Positioned(
              top: -buttonSize / 2,
              left: 0,
              right: 0,
              child: Center(
                child: IconButton.filledTonal(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up),
                  iconSize: 32,
                  tooltip: 'Listen',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
