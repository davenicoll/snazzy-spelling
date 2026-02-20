import 'package:flutter/foundation.dart';
import '../models/test_session.dart';
import '../models/test_result.dart';
import '../repositories/test_repository.dart';

class TestProvider extends ChangeNotifier {
  final TestRepository _repo = TestRepository();

  Future<TestSession> saveSession({
    required int wordlistId,
    required int totalWords,
    required int correctCount,
    required List<TestResult> results,
  }) async {
    return await _repo.saveSession(
      wordlistId: wordlistId,
      totalWords: totalWords,
      correctCount: correctCount,
      results: results,
    );
  }

  Future<List<TestSession>> getSessionsForWordlist(int wordlistId) async {
    return await _repo.getSessionsForWordlist(wordlistId);
  }

  Future<TestSession?> getSessionWithResults(int sessionId) async {
    return await _repo.getSessionWithResults(sessionId);
  }
}
