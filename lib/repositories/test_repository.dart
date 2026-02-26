import '../database/database_helper.dart';
import '../models/test_session.dart';
import '../models/test_result.dart';

class TestRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<TestSession> saveSession({
    required int wordlistId,
    required int totalWords,
    required int correctCount,
    required List<TestResult> results,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final sessionId = await db.insert('test_sessions', {
      'wordlist_id': wordlistId,
      'completed_at': now.toIso8601String(),
      'total_words': totalWords,
      'correct_count': correctCount,
    });

    final savedResults = <TestResult>[];
    for (final result in results) {
      final resultId = await db.insert('test_results', {
        'session_id': sessionId,
        'word': result.word,
        'status': result.status.toDbString(),
        'child_answer': result.childAnswer,
        'first_attempt': result.firstAttempt,
      });
      savedResults.add(TestResult(
        id: resultId,
        sessionId: sessionId,
        word: result.word,
        status: result.status,
        childAnswer: result.childAnswer,
        firstAttempt: result.firstAttempt,
      ));
    }

    return TestSession(
      id: sessionId,
      wordlistId: wordlistId,
      completedAt: now,
      totalWords: totalWords,
      correctCount: correctCount,
      results: savedResults,
    );
  }

  Future<List<TestSession>> getSessionsForWordlist(int wordlistId) async {
    final db = await _dbHelper.database;
    final sessions = await db.query(
      'test_sessions',
      where: 'wordlist_id = ?',
      whereArgs: [wordlistId],
      orderBy: 'completed_at DESC',
    );

    return sessions.map((s) => TestSession.fromMap(s)).toList();
  }

  Future<TestSession?> getSessionWithResults(int sessionId) async {
    final db = await _dbHelper.database;
    final sessions = await db.query(
      'test_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    if (sessions.isEmpty) return null;

    final results = await db.query(
      'test_results',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    return TestSession.fromMap(
      sessions.first,
      results: results.map((r) => TestResult.fromMap(r)).toList(),
    );
  }
}
