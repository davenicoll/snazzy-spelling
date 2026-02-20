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

  Future<Wordlist> create(String name, List<String> words) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final id = await db.insert('wordlists', {
      'name': name,
      'created_at': now.toIso8601String(),
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
      words: words.map((w) => w.trim()).toList(),
    );
  }

  Future<void> update(int id, String name, List<String> words) async {
    final db = await _dbHelper.database;

    await db.update(
      'wordlists',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Replace all words
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
    // CASCADE will handle words, test_sessions, and test_results
    await db.delete('wordlists', where: 'id = ?', whereArgs: [id]);
  }
}
