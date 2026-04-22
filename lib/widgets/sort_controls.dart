import 'package:flutter/material.dart';
import '../providers/wordlist_provider.dart';

class SortControls extends StatelessWidget {
  final SortField sortField;
  final SortDirection sortDirection;
  final ValueChanged<SortField> onToggleSort;
  final bool hideCompleted;
  final ValueChanged<bool> onHideCompletedChanged;

  const SortControls({
    super.key,
    required this.sortField,
    required this.sortDirection,
    required this.onToggleSort,
    required this.hideCompleted,
    required this.onHideCompletedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Sort by:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(width: 8),
            _SortChip(
              label: 'Name',
              isSelected: sortField == SortField.alphabetical,
              direction: sortField == SortField.alphabetical
                  ? sortDirection
                  : null,
              onTap: () => onToggleSort(SortField.alphabetical),
            ),
            const SizedBox(width: 8),
            _SortChip(
              label: 'Date',
              isSelected: sortField == SortField.createdAt,
              direction:
                  sortField == SortField.createdAt ? sortDirection : null,
              onTap: () => onToggleSort(SortField.createdAt),
            ),
            const SizedBox(width: 16),
            FilterChip(
              key: const Key('hide-completed-chip'),
              label: const Text('Hide completed'),
              selected: hideCompleted,
              onSelected: onHideCompletedChanged,
              avatar: hideCompleted
                  ? const Icon(Icons.check_box, size: 18)
                  : Icon(
                      Icons.check_box_outline_blank,
                      size: 18,
                      // Route the unchecked-state accent through the theme's
                      // tertiary token so each palette (Star Brawls orange,
                      // Cell Super pink, Snazzy muted green) drives the icon
                      // colour instead of the default chip styling leaking
                      // whichever hue `primary` happens to be.
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
              showCheckmark: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final SortDirection? direction;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.direction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (direction != null) ...[
            const SizedBox(width: 4),
            Icon(
              direction == SortDirection.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}
