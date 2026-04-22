import 'package:flutter_test/flutter_test.dart';
import 'package:snazzy_spelling/models/wordlist.dart';

void main() {
  group('Wordlist model — isCompleted', () {
    test('defaults to false when not provided', () {
      final wl = Wordlist(name: 'test', createdAt: DateTime(2025, 1, 1));
      expect(wl.isCompleted, isFalse);
    });

    test('toMap serialises isCompleted as 1/0', () {
      final incomplete = Wordlist(name: 'a', createdAt: DateTime(2025, 1, 1));
      final complete = Wordlist(
        name: 'b',
        createdAt: DateTime(2025, 1, 1),
        isCompleted: true,
      );
      expect(incomplete.toMap()['is_completed'], 0);
      expect(complete.toMap()['is_completed'], 1);
    });

    test('fromMap reads is_completed=1 as true', () {
      final wl = Wordlist.fromMap({
        'id': 1,
        'name': 'x',
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
        'is_completed': 1,
      });
      expect(wl.isCompleted, isTrue);
    });

    test('fromMap treats missing is_completed as false', () {
      final wl = Wordlist.fromMap({
        'id': 1,
        'name': 'x',
        'created_at': DateTime(2025, 1, 1).toIso8601String(),
      });
      expect(wl.isCompleted, isFalse);
    });

    test('copyWith preserves and overrides isCompleted', () {
      final wl = Wordlist(
        name: 'x',
        createdAt: DateTime(2025, 1, 1),
        isCompleted: true,
      );
      expect(wl.copyWith().isCompleted, isTrue);
      expect(wl.copyWith(isCompleted: false).isCompleted, isFalse);
    });
  });
}
