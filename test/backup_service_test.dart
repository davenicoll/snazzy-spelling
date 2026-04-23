import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:snazzy_spelling/services/backup_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mirrors `DatabaseHelper._onCreate` at schema v4 so the backup service
/// sees the same tables it does in production, without us having to refactor
/// the singleton to accept an injected path.
Future<Database> _openTestDb() async {
  final db = await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE wordlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            require_full_flashcard_view INTEGER NOT NULL DEFAULT 0,
            is_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            wordlist_id INTEGER NOT NULL,
            word TEXT NOT NULL,
            FOREIGN KEY (wordlist_id) REFERENCES wordlists(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE test_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            wordlist_id INTEGER NOT NULL,
            completed_at TEXT NOT NULL,
            total_words INTEGER NOT NULL,
            correct_count INTEGER NOT NULL,
            FOREIGN KEY (wordlist_id) REFERENCES wordlists(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE test_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            word TEXT NOT NULL,
            status TEXT NOT NULL,
            child_answer TEXT,
            first_attempt TEXT,
            FOREIGN KEY (session_id) REFERENCES test_sessions(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE flashcard_views (
            wordlist_id INTEGER NOT NULL,
            word TEXT NOT NULL,
            viewed_at TEXT NOT NULL,
            PRIMARY KEY (wordlist_id, word),
            FOREIGN KEY (wordlist_id) REFERENCES wordlists(id) ON DELETE CASCADE
          )
        ''');
      },
    ),
  );
  return db;
}

Future<void> _seedFixtureData(Database db) async {
  // Two wordlists: one completed, one not.
  final wl1 = await db.insert('wordlists', {
    'name': 'Animals',
    'created_at': '2026-01-01T00:00:00.000Z',
    'require_full_flashcard_view': 1,
    'is_completed': 0,
  });
  final wl2 = await db.insert('wordlists', {
    'name': 'Fruits',
    'created_at': '2026-01-02T00:00:00.000Z',
    'require_full_flashcard_view': 0,
    'is_completed': 1,
  });

  for (final w in ['cat', 'dog', 'fish']) {
    await db.insert('words', {'wordlist_id': wl1, 'word': w});
  }
  for (final w in ['apple', 'banana']) {
    await db.insert('words', {'wordlist_id': wl2, 'word': w});
  }

  final s1 = await db.insert('test_sessions', {
    'wordlist_id': wl1,
    'completed_at': '2026-01-03T10:00:00.000Z',
    'total_words': 3,
    'correct_count': 2,
  });
  final s2 = await db.insert('test_sessions', {
    'wordlist_id': wl2,
    'completed_at': '2026-01-04T10:00:00.000Z',
    'total_words': 2,
    'correct_count': 2,
  });

  await db.insert('test_results', {
    'session_id': s1,
    'word': 'cat',
    'status': 'correctFirst',
    'child_answer': 'cat',
    'first_attempt': 'cat',
  });
  await db.insert('test_results', {
    'session_id': s1,
    'word': 'dog',
    'status': 'correctSecond',
    'child_answer': 'dog',
    'first_attempt': 'dgo',
  });
  await db.insert('test_results', {
    'session_id': s1,
    'word': 'fish',
    'status': 'incorrect',
    'child_answer': 'fsh',
    'first_attempt': 'fsh',
  });
  await db.insert('test_results', {
    'session_id': s2,
    'word': 'apple',
    'status': 'correctFirst',
    'child_answer': 'apple',
    'first_attempt': 'apple',
  });

  await db.insert('flashcard_views', {
    'wordlist_id': wl1,
    'word': 'cat',
    'viewed_at': '2026-01-01T09:00:00.000Z',
  });
  await db.insert('flashcard_views', {
    'wordlist_id': wl1,
    'word': 'dog',
    'viewed_at': '2026-01-01T09:05:00.000Z',
  });
}

Future<Map<String, List<Map<String, Object?>>>> _snapshot(Database db) async {
  return {
    'wordlists': await db.query('wordlists', orderBy: 'id ASC'),
    'words': await db.query('words', orderBy: 'id ASC'),
    'test_sessions': await db.query('test_sessions', orderBy: 'id ASC'),
    'test_results': await db.query('test_results', orderBy: 'id ASC'),
    'flashcard_views':
        await db.query('flashcard_views', orderBy: 'wordlist_id, word'),
  };
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('BackupService', () {
    late Database db;
    late BackupService service;

    setUp(() async {
      db = await _openTestDb();
      service = BackupService(databaseResolver: () async => db);
    });

    tearDown(() async {
      await db.close();
    });

    test('round-trip export -> wipe -> import restores every row', () async {
      await _seedFixtureData(db);
      final before = await _snapshot(db);

      final bytes = await service.exportToBytes();

      // Wipe — same delete order as the service uses internally.
      await db.delete('flashcard_views');
      await db.delete('test_results');
      await db.delete('test_sessions');
      await db.delete('words');
      await db.delete('wordlists');

      final summary = await service.importFromBytes(bytes);

      final after = await _snapshot(db);

      expect(after['wordlists'], before['wordlists']);
      // `words.id` is not carried in the envelope (the spec groups words
      // as plain strings under each wordlist), so compare the meaningful
      // columns only — autoincrement will hand out fresh ids on re-insert.
      List<Map<String, Object?>> stripWordId(List<Map<String, Object?>> rs) =>
          rs.map((r) => {'wordlist_id': r['wordlist_id'], 'word': r['word']})
              .toList();
      expect(stripWordId(after['words']!), stripWordId(before['words']!));
      expect(after['test_sessions'], before['test_sessions']);
      expect(after['test_results'], before['test_results']);
      expect(after['flashcard_views'], before['flashcard_views']);

      expect(summary.wordlists, 2);
      expect(summary.words, 5);
      expect(summary.sessions, 2);
      expect(summary.results, 4);
      expect(summary.views, 2);
    });

    test('malformed bytes throw BackupFormatException', () async {
      final garbage = Uint8List.fromList([0, 1, 2, 3, 4, 5]);
      expect(
        () => service.importFromBytes(garbage),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('unsupported schema_version throws BackupFormatException', () async {
      final envelope = {
        'format': 'snazzy-spelling-backup',
        'schema_version': 2,
        'app_version': 'x',
        'exported_at': '2026-01-01T00:00:00.000Z',
        'data': {
          'wordlists': [],
          'test_sessions': [],
          'test_results': [],
          'flashcard_views': [],
        },
      };
      final bytes =
          Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(envelope))));
      expect(
        () => service.importFromBytes(bytes),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('FK-violating envelope rolls back — prior data survives', () async {
      await _seedFixtureData(db);
      final before = await _snapshot(db);

      // Valid envelope shape but `test_results[0].session_id` points at a
      // session that doesn't exist in `test_sessions`. With PRAGMA
      // foreign_keys=ON the INSERT blows up mid-transaction and sqflite
      // rolls back.
      final envelope = {
        'format': 'snazzy-spelling-backup',
        'schema_version': 1,
        'app_version': 'x',
        'exported_at': '2026-01-01T00:00:00.000Z',
        'data': {
          'wordlists': [
            {
              'id': 10,
              'name': 'X',
              'created_at': '2026-01-01T00:00:00.000Z',
              'require_full_flashcard_view': 0,
              'is_completed': 0,
              'words': ['zzz'],
            },
          ],
          'test_sessions': [],
          'test_results': [
            {
              'id': 99,
              'session_id': 999999, // dangling FK
              'word': 'zzz',
              'status': 'correctFirst',
              'child_answer': null,
              'first_attempt': null,
            },
          ],
          'flashcard_views': [],
        },
      };
      final bytes =
          Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(envelope))));

      expect(
        () => service.importFromBytes(bytes),
        throwsA(isA<Object>()),
      );

      final after = await _snapshot(db);
      expect(after, before,
          reason: 'transactional import must roll back on FK violation');
    });
  });
}
