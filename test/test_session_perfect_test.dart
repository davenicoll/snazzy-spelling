import 'package:flutter_test/flutter_test.dart';
import 'package:snazzy_spelling/models/test_result.dart';
import 'package:snazzy_spelling/models/test_session.dart';

/// `TestSession.isPerfect` is the trigger predicate for the confetti overlay
/// on `TestSummaryScreen`. These tests lock in the intended behaviour: the
/// overlay fires when every word was ultimately correct (including words
/// that needed a second attempt) and stays quiet whenever any word was
/// never corrected.
TestResult _r(int sessionId, String word, TestResultStatus status) =>
    TestResult(sessionId: sessionId, word: word, status: status);

TestSession _session(List<TestResult> results) {
  final correct = results.where((r) => r.status.isCorrect).length;
  return TestSession(
    wordlistId: 1,
    completedAt: DateTime(2026, 1, 1),
    totalWords: results.length,
    correctCount: correct,
    results: results,
  );
}

void main() {
  group('TestSession.isPerfect (confetti trigger)', () {
    test('all words correct on first attempt → perfect', () {
      final s = _session([
        _r(1, 'apple', TestResultStatus.correctFirst),
        _r(1, 'banana', TestResultStatus.correctFirst),
      ]);
      expect(s.isPerfect, isTrue);
    });

    test('mix of first- and second-attempt correct → still perfect', () {
      final s = _session([
        _r(1, 'apple', TestResultStatus.correctFirst),
        _r(1, 'banana', TestResultStatus.correctSecond),
        _r(1, 'cherry', TestResultStatus.correctSecond),
      ]);
      expect(s.isPerfect, isTrue);
    });

    test('any incorrect word suppresses the perfect flag', () {
      final s = _session([
        _r(1, 'apple', TestResultStatus.correctFirst),
        _r(1, 'banana', TestResultStatus.correctSecond),
        _r(1, 'cherry', TestResultStatus.incorrect),
      ]);
      expect(s.isPerfect, isFalse);
    });

    test('all incorrect → not perfect', () {
      final s = _session([
        _r(1, 'apple', TestResultStatus.incorrect),
        _r(1, 'banana', TestResultStatus.incorrect),
      ]);
      expect(s.isPerfect, isFalse);
    });
  });
}
