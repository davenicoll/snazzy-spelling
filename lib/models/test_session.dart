import 'test_result.dart';

class TestSession {
  final int? id;
  final int wordlistId;
  final DateTime completedAt;
  final int totalWords;
  final int correctCount;
  final List<TestResult> results;

  TestSession({
    this.id,
    required this.wordlistId,
    required this.completedAt,
    required this.totalWords,
    required this.correctCount,
    this.results = const [],
  });

  bool get isPerfect => correctCount == totalWords;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'wordlist_id': wordlistId,
      'completed_at': completedAt.toIso8601String(),
      'total_words': totalWords,
      'correct_count': correctCount,
    };
  }

  factory TestSession.fromMap(Map<String, dynamic> map,
      {List<TestResult>? results}) {
    return TestSession(
      id: map['id'] as int,
      wordlistId: map['wordlist_id'] as int,
      completedAt: DateTime.parse(map['completed_at'] as String),
      totalWords: map['total_words'] as int,
      correctCount: map['correct_count'] as int,
      results: results ?? [],
    );
  }
}
