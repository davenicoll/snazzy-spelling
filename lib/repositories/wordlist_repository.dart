import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/database_helper.dart';
import '../models/wordlist.dart';

class WordlistRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Wordlist>> getAll() async {
    final db = await _dbHelper.database;
    final wordlists = await db.query('wordlists', orderBy: 'created_at DESC');
    final result = <Wordlist>[];

    for (final wl in wordlists) {
      final words = await db.query(
        'words',
        where: 'wordlist_id = ?',
        whereArgs: [wl['id']],
        orderBy: 'word ASC',
      );
      result.add(Wordlist.fromMap(
        wl,
        words: words.map((w) => w['word'] as String).toList(),
      ));
    }

    return result;
  }

  Future<Wordlist?> getById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'wordlists',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;

    final words = await db.query(
      'words',
      where: 'wordlist_id = ?',
      whereArgs: [id],
      orderBy: 'word ASC',
    );

    return Wordlist.fromMap(
      results.first,
      words: words.map((w) => w['word'] as String).toList(),
    );
  }

  Future<Wordlist> create(
    String name,
    List<String> words, {
    bool requireFullFlashcardView = false,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final id = await db.insert('wordlists', {
      'name': name,
      'created_at': now.toIso8601String(),
      'require_full_flashcard_view': requireFullFlashcardView ? 1 : 0,
    });

    for (final word in words) {
      await db.insert('words', {
        'wordlist_id': id,
        'word': word.trim(),
      });
    }

    return Wordlist(
      id: id,
      name: name,
      createdAt: now,
      requireFullFlashcardView: requireFullFlashcardView,
      words: words.map((w) => w.trim()).toList(),
    );
  }

  Future<void> update(
    int id,
    String name,
    List<String> words, {
    bool requireFullFlashcardView = false,
  }) async {
    final db = await _dbHelper.database;

    await db.update(
      'wordlists',
      {
        'name': name,
        'require_full_flashcard_view': requireFullFlashcardView ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Replace all words. Flashcard-view progress is keyed by
    // (wordlist_id, word), so views for words removed from the list become
    // inert but remain on disk — if an admin re-adds a word with the same
    // spelling the prior view still counts.
    await db.delete('words', where: 'wordlist_id = ?', whereArgs: [id]);
    for (final word in words) {
      await db.insert('words', {
        'wordlist_id': id,
        'word': word.trim(),
      });
    }
  }

  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    // CASCADE will handle words, test_sessions, test_results, and
    // flashcard_views.
    await db.delete('wordlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<Set<String>> getViewedWords(int wordlistId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'flashcard_views',
      columns: ['word'],
      where: 'wordlist_id = ?',
      whereArgs: [wordlistId],
    );
    return rows.map((r) => r['word'] as String).toSet();
  }

  Future<void> recordView(int wordlistId, String word) async {
    final db = await _dbHelper.database;
    await db.insert(
      'flashcard_views',
      {
        'wordlist_id': wordlistId,
        'word': word,
        'viewed_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
