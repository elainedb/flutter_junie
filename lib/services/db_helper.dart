import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Simple SQLite helper to cache YouTube videos and last refresh time.
class DbHelper {
  static const _dbName = 'videos_cache.db';
  static const _dbVersion = 1;

  static const tableVideos = 'videos';
  static const tableMeta = 'metadata';

  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableVideos (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            channel_id TEXT NOT NULL,
            channel_title TEXT NOT NULL,
            published_at TEXT NOT NULL,
            thumbnail_url TEXT NOT NULL,
            tags TEXT,
            country TEXT,
            city TEXT,
            latitude REAL,
            longitude REAL,
            recording_date TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE $tableMeta (
            key TEXT PRIMARY KEY,
            value TEXT
          );
        ''');
      },
    );
    return _db!;
  }

  Future<void> clearVideos() async {
    final db = await database;
    await db.delete(tableVideos);
  }

  Future<void> upsertVideos(List<Map<String, Object?>> rows) async {
    final db = await database;
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(
        tableVideos,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, Object?>>> getAllVideos() async {
    final db = await database;
    return db.query(tableVideos);
  }

  Future<void> setLastRefresh(DateTime dt) async {
    final db = await database;
    await db.insert(
      tableMeta,
      {'key': 'last_refresh', 'value': dt.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DateTime?> getLastRefresh() async {
    final db = await database;
    final rows = await db.query(tableMeta, where: 'key = ?', whereArgs: ['last_refresh']);
    if (rows.isEmpty) return null;
    final value = rows.first['value'] as String?;
    return value != null ? DateTime.tryParse(value) : null;
  }
}
