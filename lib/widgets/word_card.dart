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
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LayoutBuilder(
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
            if (onSpeak != null) ...[
              const SizedBox(height: 32),
              IconButton.filledTonal(
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up),
                iconSize: 32,
                tooltip: 'Listen',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
