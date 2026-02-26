enum TestResultStatus {
  correctFirst,
  correctSecond,
  incorrect;

  String toDbString() {
    switch (this) {
      case TestResultStatus.correctFirst:
        return 'correct_first';
      case TestResultStatus.correctSecond:
        return 'correct_second';
      case TestResultStatus.incorrect:
        return 'incorrect';
    }
  }

  static TestResultStatus fromDbString(String value) {
    switch (value) {
      case 'correct_first':
        return TestResultStatus.correctFirst;
      case 'correct_second':
        return TestResultStatus.correctSecond;
      case 'incorrect':
        return TestResultStatus.incorrect;
      default:
        throw ArgumentError('Unknown TestResultStatus: $value');
    }
  }

  bool get isCorrect =>
      this == TestResultStatus.correctFirst ||
      this == TestResultStatus.correctSecond;
}

class TestResult {
  final int? id;
  final int sessionId;
  final String word;
  final TestResultStatus status;
  final String? childAnswer;
  final String? firstAttempt;

  TestResult({
    this.id,
    required this.sessionId,
    required this.word,
    required this.status,
    this.childAnswer,
    this.firstAttempt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'word': word,
      'status': status.toDbString(),
      'child_answer': childAnswer,
      'first_attempt': firstAttempt,
    };
  }

  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      id: map['id'] as int,
      sessionId: map['session_id'] as int,
      word: map['word'] as String,
      status: TestResultStatus.fromDbString(map['status'] as String),
      childAnswer: map['child_answer'] as String?,
      firstAttempt: map['first_attempt'] as String?,
    );
  }
}
