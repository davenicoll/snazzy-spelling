import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/database_helper.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  Future<bool> hasPinSet() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['pin_hash'],
    );
    return result.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final db = await _dbHelper.database;
    final hash = _hashPin(pin);
    await db.insert(
      'settings',
      {'key': 'pin_hash', 'value': hash},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> verifyPin(String pin) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['pin_hash'],
    );
    if (result.isEmpty) return false;
    return result.first['value'] == _hashPin(pin);
  }

  Future<String?> getSetting(String key) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
