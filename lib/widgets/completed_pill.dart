import 'package:flutter/material.dart';

/// A small pill indicator rendered beside a wordlist title when the list is
/// marked completed. Shared between the main wordlist view and the admin
/// settings wordlist list so styling stays in lock-step.
class CompletedPill extends StatelessWidget {
  const CompletedPill({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Completed',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
