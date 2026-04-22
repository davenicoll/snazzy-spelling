import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'snazzy_spelling.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE test_results ADD COLUMN first_attempt TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE wordlists ADD COLUMN require_full_flashcard_view INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('''
        CREATE TABLE flashcard_views (
          wordlist_id INTEGER NOT NULL,
          word TEXT NOT NULL,
          viewed_at TEXT NOT NULL,
          PRIMARY KEY (wordlist_id, word),
          FOREIGN KEY (wordlist_id) REFERENCES wordlists(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE wordlists ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0',
      );
    }
  }
}
