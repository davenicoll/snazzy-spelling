import 'package:flutter_test/flutter_test.dart';
import 'package:snazzy_spelling/models/wordlist.dart';

void main() {
  group('Wordlist.isTestGated', () {
    final createdAt = DateTime(2026, 1, 1);

    test('returns false when the require-view option is off', () {
      final wl = Wordlist(
        id: 1,
        name: 'list',
        createdAt: createdAt,
        requireFullFlashcardView: false,
        words: const ['apple', 'banana'],
      );
      expect(wl.isTestGated(const {}), isFalse);
      expect(wl.isTestGated(const {'apple'}), isFalse);
    });

    test('returns true when the option is on and some words are unviewed', () {
      final wl = Wordlist(
        id: 1,
        name: 'list',
        createdAt: createdAt,
        requireFullFlashcardView: true,
        words: const ['apple', 'banana', 'cherry'],
      );
      expect(wl.isTestGated(const {}), isTrue);
      expect(wl.isTestGated(const {'apple'}), isTrue);
      expect(wl.isTestGated(const {'apple', 'banana'}), isTrue);
    });

    test('returns false once every word has been viewed', () {
      final wl = Wordlist(
        id: 1,
        name: 'list',
        createdAt: createdAt,
        requireFullFlashcardView: true,
        words: const ['apple', 'banana', 'cherry'],
      );
      expect(
        wl.isTestGated(const {'apple', 'banana', 'cherry'}),
        isFalse,
      );
    });

    test('extra viewed entries do not trip the gate', () {
      // Words that were once in the list but have since been removed may
      // still appear in the viewed set. They should not block anything.
      final wl = Wordlist(
        id: 1,
        name: 'list',
        createdAt: createdAt,
        requireFullFlashcardView: true,
        words: const ['apple', 'banana'],
      );
      expect(
        wl.isTestGated(const {'apple', 'banana', 'stale-word'}),
        isFalse,
      );
    });

    test('an empty wordlist is not gated', () {
      final wl = Wordlist(
        id: 1,
        name: 'list',
        createdAt: createdAt,
        requireFullFlashcardView: true,
        words: const [],
      );
      expect(wl.isTestGated(const {}), isFalse);
    });
  });
}
