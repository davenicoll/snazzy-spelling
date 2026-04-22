import 'package:flutter_test/flutter_test.dart';
import 'package:snazzy_spelling/models/wordlist.dart';
import 'package:snazzy_spelling/providers/wordlist_provider.dart';

void main() {
  group('filterAndSortWordlists — hide completed', () {
    Wordlist make(int id, String name, {bool isCompleted = false}) => Wordlist(
          id: id,
          name: name,
          createdAt: DateTime(2026, 1, id),
          isCompleted: isCompleted,
          words: const ['x'],
        );

    final source = [
      make(1, 'Alpha', isCompleted: true),
      make(2, 'Bravo'),
      make(3, 'Charlie', isCompleted: true),
      make(4, 'Delta'),
    ];

    test('hides completed wordlists when flag is set', () {
      final result = filterAndSortWordlists(
        source,
        SortField.alphabetical,
        SortDirection.ascending,
        hideCompleted: true,
      );
      expect(result.map((w) => w.name).toList(), ['Bravo', 'Delta']);
    });

    test('returns every wordlist when flag is off', () {
      final result = filterAndSortWordlists(
        source,
        SortField.alphabetical,
        SortDirection.ascending,
        hideCompleted: false,
      );
      expect(result.map((w) => w.name).toList(),
          ['Alpha', 'Bravo', 'Charlie', 'Delta']);
    });

    test('respects sort direction after filtering', () {
      final result = filterAndSortWordlists(
        source,
        SortField.alphabetical,
        SortDirection.descending,
        hideCompleted: true,
      );
      expect(result.map((w) => w.name).toList(), ['Delta', 'Bravo']);
    });

    test('sorts by createdAt ascending after filtering', () {
      final result = filterAndSortWordlists(
        source,
        SortField.createdAt,
        SortDirection.ascending,
        hideCompleted: true,
      );
      // Delta was created later than Bravo (id 4 vs 2).
      expect(result.map((w) => w.name).toList(), ['Bravo', 'Delta']);
    });

    test('does not mutate the source list', () {
      final copy = List<Wordlist>.from(source);
      filterAndSortWordlists(
        source,
        SortField.alphabetical,
        SortDirection.descending,
        hideCompleted: true,
      );
      expect(source, equals(copy));
    });
  });

  test('kHideCompletedSettingKey is stable', () {
    // Stability matters because it's what users' existing stored preferences
    // are keyed on. Changing it silently resets every install.
    expect(kHideCompletedSettingKey, 'wordlist:hideCompleted');
  });
}
