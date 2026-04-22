import 'package:flutter_test/flutter_test.dart';
import 'package:snazzy_spelling/models/wordlist.dart';

void main() {
  group('Wordlist.isTestGated', () {
    final createdAt = DateTime(2026, 1, 1);

    Wordlist makeList(List<String> words) => Wordlist(
          id: 1,
          name: 'list',
          createdAt: createdAt,
          words: words,
        );

    test('returns false when the global flag is off', () {
      final wl = makeList(const ['apple', 'banana']);
      expect(
        wl.isTestGated(
          requireFullFlashcardView: false,
          viewedWords: const {},
        ),
        isFalse,
      );
      expect(
        wl.isTestGated(
          requireFullFlashcardView: false,
          viewedWords: const {'apple'},
        ),
        isFalse,
      );
    });

    test('returns true when the flag is on and some words are unviewed', () {
      final wl = makeList(const ['apple', 'banana', 'cherry']);
      expect(
        wl.isTestGated(
          requireFullFlashcardView: true,
          viewedWords: const {},
        ),
        isTrue,
      );
      expect(
        wl.isTestGated(
          requireFullFlashcardView: true,
          viewedWords: const {'apple'},
        ),
        isTrue,
      );
      expect(
        wl.isTestGated(
          requireFullFlashcardView: true,
          viewedWords: const {'apple', 'banana'},
        ),
        isTrue,
      );
    });

    test('returns false once every word has been viewed', () {
      final wl = makeList(const ['apple', 'banana', 'cherry']);
      expect(
        wl.isTestGated(
          requireFullFlashcardView: true,
          viewedWords: const {'apple', 'banana', 'cherry'},
        ),
        isFalse,
      );
    });

    test('extra viewed entries do not trip the gate', () {
      // Words that were once in the list but have since been removed may
      // still appear in the viewed set. They should not block anything.
      final wl = makeList(const ['apple', 'banana']);
      expect(
        wl.isTestGated(
          requireFullFlashcardView: true,
          viewedWords: const {'apple', 'banana', 'stale-word'},
        ),
        isFalse,
      );
    });

    test('an empty wordlist is not gated', () {
      final wl = makeList(const []);
      expect(
        wl.isTestGated(
          requireFullFlashcardView: true,
          viewedWords: const {},
        ),
        isFalse,
      );
    });
  });
}
