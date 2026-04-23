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

  group('admin settings wordlist view (allWordlistsByCreatedDesc params)', () {
    // `WordlistProvider.allWordlistsByCreatedDesc` is a thin wrapper that
    // delegates to `filterAndSortWordlists` with `SortField.createdAt`,
    // `SortDirection.descending`, and `hideCompleted: false`. These tests
    // pin that contract directly so the admin screen can't regress to the
    // main-screen filter/sort state.
    final mixed = [
      Wordlist(
        id: 1,
        name: 'Alpha',
        createdAt: DateTime(2026, 1, 1),
        isCompleted: true,
        words: const ['x'],
      ),
      Wordlist(
        id: 2,
        name: 'Bravo',
        createdAt: DateTime(2026, 2, 1),
        words: const ['x'],
      ),
      Wordlist(
        id: 3,
        name: 'Charlie',
        createdAt: DateTime(2026, 3, 1),
        isCompleted: true,
        words: const ['x'],
      ),
    ];

    test('returns every wordlist sorted by createdAt desc', () {
      final result = filterAndSortWordlists(
        mixed,
        SortField.createdAt,
        SortDirection.descending,
        hideCompleted: false,
      );
      expect(result.map((w) => w.name).toList(),
          ['Charlie', 'Bravo', 'Alpha']);
    });

    test('completed wordlists are retained', () {
      final result = filterAndSortWordlists(
        mixed,
        SortField.createdAt,
        SortDirection.descending,
        hideCompleted: false,
      );
      expect(result.where((w) => w.isCompleted).length, 2);
    });
  });

  test('kHideCompletedSettingKey is stable', () {
    // Stability matters because it's what users' existing stored preferences
    // are keyed on. Changing it silently resets every install.
    expect(kHideCompletedSettingKey, 'wordlist:hideCompleted');
  });
}
