import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/database_helper.dart';

/// Current backup envelope schema version. Bump when the on-disk JSON shape
/// changes in a way that needs explicit migration in [BackupService].
const int kBackupSchemaVersion = 1;

/// Magic identifier stored in the envelope so we can refuse unrelated files
/// that happen to be valid gzip+JSON.
const String kBackupFormatMagic = 'snazzy-spelling-backup';

/// App version baked into exports. Kept as a `const` for now — bumped
/// alongside `pubspec.yaml` at release time. The UI doesn't rely on this
/// for anything load-bearing; it's purely informational in the envelope.
const String kBackupAppVersion = '1.0.10+11';

/// Thrown by [BackupService.importFromBytes] when the supplied bytes are
/// not a valid `.ssbk` payload we can restore.
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);
  @override
  String toString() => 'BackupFormatException: $message';
}

/// Row counts written to the DB by a successful import. Handy for the UI
/// to show a "restored X wordlists, Y words…" toast.
class BackupImportSummary {
  final int wordlists;
  final int words;
  final int sessions;
  final int results;
  final int views;

  const BackupImportSummary({
    required this.wordlists,
    required this.words,
    required this.sessions,
    required this.results,
    required this.views,
  });
}

/// Resolves the [Database] the service should operate on. Production code
/// passes `DatabaseHelper().database`; tests pass an in-memory ffi DB.
typedef DatabaseResolver = Future<Database> Function();

/// Produces and consumes `.ssbk` files — a gzipped JSON envelope containing
/// everything in the user DB except the `settings` table.
class BackupService {
  final DatabaseResolver _resolve;

  BackupService({DatabaseHelper? dbHelper, DatabaseResolver? databaseResolver})
      : _resolve = databaseResolver ??
            (() => (dbHelper ?? DatabaseHelper()).database);

  Future<String> currentAppVersion() async => kBackupAppVersion;

  /// Reads every table except `settings`, builds the versioned envelope,
  /// and returns the gzipped UTF-8 JSON bytes the caller should write to
  /// disk with a `.ssbk` extension.
  Future<Uint8List> exportToBytes() async {
    final db = await _resolve();

    final wordlists = await db.query('wordlists', orderBy: 'id ASC');
    final words = await db.query('words', orderBy: 'wordlist_id ASC, id ASC');
    final sessions = await db.query('test_sessions', orderBy: 'id ASC');
    final results = await db.query('test_results', orderBy: 'id ASC');
    final views =
        await db.query('flashcard_views', orderBy: 'wordlist_id ASC, word ASC');

    // Group words by wordlist_id so each wordlist carries its own list —
    // matches the envelope shape documented in the card.
    final wordsByList = <int, List<String>>{};
    for (final w in words) {
      final wid = w['wordlist_id'] as int;
      wordsByList.putIfAbsent(wid, () => []).add(w['word'] as String);
    }

    final wordlistsOut = wordlists.map((wl) {
      final id = wl['id'] as int;
      return {
        'id': id,
        'name': wl['name'],
        'created_at': wl['created_at'],
        'require_full_flashcard_view':
            (wl['require_full_flashcard_view'] as int? ?? 0),
        'is_completed': (wl['is_completed'] as int? ?? 0),
        'words': wordsByList[id] ?? const <String>[],
      };
    }).toList();

    final envelope = <String, dynamic>{
      'format': kBackupFormatMagic,
      'schema_version': kBackupSchemaVersion,
      'app_version': await currentAppVersion(),
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'data': {
        'wordlists': wordlistsOut,
        'test_sessions': sessions.map((s) => {
              'id': s['id'],
              'wordlist_id': s['wordlist_id'],
              'completed_at': s['completed_at'],
              'total_words': s['total_words'],
              'correct_count': s['correct_count'],
            }).toList(),
        'test_results': results.map((r) => {
              'id': r['id'],
              'session_id': r['session_id'],
              'word': r['word'],
              'status': r['status'],
              'child_answer': r['child_answer'],
              'first_attempt': r['first_attempt'],
            }).toList(),
        'flashcard_views': views.map((v) => {
              'wordlist_id': v['wordlist_id'],
              'word': v['word'],
              'viewed_at': v['viewed_at'],
            }).toList(),
      },
    };

    final jsonBytes = utf8.encode(jsonEncode(envelope));
    final gzipped = gzip.encode(jsonBytes);
    return Uint8List.fromList(gzipped);
  }

  /// Validates the envelope, wipes user data (except `settings`), and
  /// reinserts the backed-up rows inside a single transaction — so a
  /// mid-restore failure rolls back and leaves the prior DB intact.
  Future<BackupImportSummary> importFromBytes(Uint8List bytes) async {
    final envelope = _decodeEnvelope(bytes);

    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      throw const BackupFormatException('missing or invalid `data` object');
    }

    final wordlists = _asList(data['wordlists'], 'wordlists');
    final sessions = _asList(data['test_sessions'], 'test_sessions');
    final results = _asList(data['test_results'], 'test_results');
    final views = _asList(data['flashcard_views'], 'flashcard_views');

    final db = await _resolve();

    var wordlistCount = 0;
    var wordCount = 0;
    var sessionCount = 0;
    var resultCount = 0;
    var viewCount = 0;

    await db.transaction((txn) async {
      // Order matters: delete children before parents so FKs never scream
      // mid-wipe even without ON DELETE CASCADE help.
      await txn.delete('flashcard_views');
      await txn.delete('test_results');
      await txn.delete('test_sessions');
      await txn.delete('words');
      await txn.delete('wordlists');

      for (final raw in wordlists) {
        final wl = _asMap(raw, 'wordlist');
        await txn.insert('wordlists', {
          'id': wl['id'],
          'name': wl['name'],
          'created_at': wl['created_at'],
          'require_full_flashcard_view':
              wl['require_full_flashcard_view'] ?? 0,
          'is_completed': wl['is_completed'] ?? 0,
        });
        wordlistCount++;
        final wlWords = wl['words'];
        if (wlWords is List) {
          for (final w in wlWords) {
            await txn.insert('words', {
              'wordlist_id': wl['id'],
              'word': w,
            });
            wordCount++;
          }
        }
      }

      for (final raw in sessions) {
        final s = _asMap(raw, 'test_session');
        await txn.insert('test_sessions', {
          'id': s['id'],
          'wordlist_id': s['wordlist_id'],
          'completed_at': s['completed_at'],
          'total_words': s['total_words'],
          'correct_count': s['correct_count'],
        });
        sessionCount++;
      }

      for (final raw in results) {
        final r = _asMap(raw, 'test_result');
        await txn.insert('test_results', {
          'id': r['id'],
          'session_id': r['session_id'],
          'word': r['word'],
          'status': r['status'],
          'child_answer': r['child_answer'],
          'first_attempt': r['first_attempt'],
        });
        resultCount++;
      }

      for (final raw in views) {
        final v = _asMap(raw, 'flashcard_view');
        await txn.insert('flashcard_views', {
          'wordlist_id': v['wordlist_id'],
          'word': v['word'],
          'viewed_at': v['viewed_at'],
        });
        viewCount++;
      }
    });

    return BackupImportSummary(
      wordlists: wordlistCount,
      words: wordCount,
      sessions: sessionCount,
      results: resultCount,
      views: viewCount,
    );
  }

  Map<String, dynamic> _decodeEnvelope(Uint8List bytes) {
    List<int> jsonBytes;
    try {
      jsonBytes = gzip.decode(bytes);
    } catch (e) {
      throw BackupFormatException('gzip decode failed: $e');
    }

    String jsonStr;
    try {
      jsonStr = utf8.decode(jsonBytes);
    } catch (e) {
      throw BackupFormatException('payload is not valid UTF-8: $e');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (e) {
      throw BackupFormatException('payload is not valid JSON: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupFormatException('envelope is not a JSON object');
    }

    if (decoded['format'] != kBackupFormatMagic) {
      throw BackupFormatException(
          'unrecognised format field: ${decoded['format']}');
    }

    final version = decoded['schema_version'];
    if (version is! int) {
      throw const BackupFormatException('schema_version must be an integer');
    }
    if (version < 1) {
      throw BackupFormatException('schema_version $version is too old');
    }
    if (version > kBackupSchemaVersion) {
      throw BackupFormatException(
          'schema_version $version is newer than this app supports '
          '(max $kBackupSchemaVersion) — please update the app');
    }

    return decoded;
  }

  List<dynamic> _asList(Object? v, String field) {
    if (v is List) return v;
    throw BackupFormatException('`$field` must be a list');
  }

  Map<String, dynamic> _asMap(Object? v, String field) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    throw BackupFormatException('`$field` row must be an object');
  }
}
