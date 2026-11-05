import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/livestock.dart';

/// Mengelola local SQLite database untuk data hewan ternak (US-02).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'semis_livestock.db';
  static const int _dbVersion = 1;
  static const String _table = 'livestock';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            species TEXT NOT NULL,
            breed TEXT NOT NULL,
            sex TEXT NOT NULL,
            birth_date TEXT NOT NULL,
            health_status TEXT NOT NULL,
            pen TEXT NOT NULL,
            status_sync TEXT NOT NULL DEFAULT 'pending',
            updated_at TEXT NOT NULL,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ─── CREATE ────────────────────────────────────────────────────────────────

  Future<void> insertLivestock(Livestock livestock) async {
    final db = await database;
    await db.insert(
      _table,
      livestock.copyWith(
        statusSync: SyncStatus.pending,
        updatedAt: DateTime.now(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('[DB] Insert: ${livestock.id}');
  }

  // ─── READ ──────────────────────────────────────────────────────────────────

  /// Mengambil semua record aktif (tidak soft-deleted).
  Future<List<Livestock>> getAllLivestock() async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Livestock.fromMap).toList();
  }

  Future<Livestock?> getLivestockById(String id) async {
    final db = await database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Livestock.fromMap(rows.first);
  }

  /// Ambil semua record pending (termasuk soft-deleted) untuk dikirim ke Drive.
  Future<List<Livestock>> getPendingSync() async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'status_sync = ?',
      whereArgs: ['pending'],
      orderBy: 'updated_at ASC',
    );
    return rows.map(Livestock.fromMap).toList();
  }

  // ─── UPDATE ────────────────────────────────────────────────────────────────

  Future<void> updateLivestock(Livestock livestock) async {
    final db = await database;
    await db.update(
      _table,
      livestock.copyWith(
        statusSync: SyncStatus.pending,
        updatedAt: DateTime.now(),
      ).toMap(),
      where: 'id = ?',
      whereArgs: [livestock.id],
    );
    debugPrint('[DB] Update: ${livestock.id}');
  }

  /// Tandai record sebagai synced setelah berhasil diunggah ke Drive.
  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      _table,
      {'status_sync': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── SOFT DELETE ───────────────────────────────────────────────────────────

  /// Soft delete: set is_deleted=1 dan status_sync=pending agar tersinkron ke Drive.
  Future<void> softDeleteLivestock(String id) async {
    final db = await database;
    await db.update(
      _table,
      {
        'is_deleted': 1,
        'status_sync': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('[DB] Soft delete: $id');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) await db.close();
    _db = null;
  }
}
