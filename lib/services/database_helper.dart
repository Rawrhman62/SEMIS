import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/livestock.dart';
import '../models/records.dart';

/// Mengelola local SQLite database untuk seluruh kebutuhan operasional peternakan (FR-01 s/d FR-14).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'semis_livestock.db';
  static const int _dbVersion = 2;

  static const String tableLivestock = 'livestock';
  static const String tableHealth = 'health_records';
  static const String tableGrowth = 'growth_records';
  static const String tablePens = 'pens';
  static const String tableBreeding = 'breeding_records';
  static const String tableUsers = 'users';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTables(db);
          // Tambahkan kolom baru jika belum ada
          try {
            await db.execute('ALTER TABLE $tableLivestock ADD COLUMN sire_id TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE $tableLivestock ADD COLUMN dam_id TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE $tableLivestock ADD COLUMN weight REAL');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE $tableLivestock ADD COLUMN notes TEXT');
          } catch (_) {}
          await _seedData(db);
        }
      },
    );

    // Pastikan data awal selalu ada jika tabel masih kosong
    await _checkAndSeedIfEmpty(db);

    return db;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableLivestock (
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
        is_deleted INTEGER NOT NULL DEFAULT 0,
        sire_id TEXT,
        dam_id TEXT,
        weight REAL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableHealth (
        id TEXT PRIMARY KEY,
        livestock_id TEXT NOT NULL,
        date TEXT NOT NULL,
        condition TEXT NOT NULL,
        diagnosis TEXT NOT NULL,
        treatment TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableGrowth (
        id TEXT PRIMARY KEY,
        livestock_id TEXT NOT NULL,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        height REAL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePens (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        location TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableBreeding (
        id TEXT PRIMARY KEY,
        sire_id TEXT NOT NULL,
        dam_id TEXT NOT NULL,
        mating_date TEXT NOT NULL,
        expected_birth_date TEXT NOT NULL,
        actual_birth_date TEXT,
        status TEXT NOT NULL,
        offspring_count INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableUsers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<void> _checkAndSeedIfEmpty(Database db) async {
    final rows = await db.rawQuery('SELECT 1 FROM $tableLivestock WHERE is_deleted = 0 LIMIT 1');
    if (rows.isEmpty) {
      await _seedData(db);
    }
  }

  Future<void> _seedData(Database db) async {
    final batch = db.batch();

    // 1. Seed Kandang (Pens)
    final initialPens = [
      const Pen(id: 'PEN-01', name: 'Kandang A', capacity: 10, location: 'Blok Barat (Domba Garut)', notes: 'Kandang pejantan dan indukan laktasi'),
      const Pen(id: 'PEN-02', name: 'Kandang B', capacity: 8, location: 'Blok Timur (Texel)', notes: 'Kandang koloni betina dara'),
      const Pen(id: 'PEN-03', name: 'Kandang C', capacity: 12, location: 'Blok Utara (Dorper)', notes: 'Kandang penggemukan (fattening)'),
    ];
    for (final p in initialPens) {
      batch.insert(tablePens, p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 2. Seed Ternak (Livestock) dengan relasi Silsilah
    final now = DateTime.now();
    final initialLivestock = [
      Livestock(
        id: 'SM-001',
        name: 'Garuda',
        species: 'Domba',
        breed: 'Domba Garut',
        sex: 'Jantan',
        birthDate: now.subtract(const Duration(days: 36 * 30)),
        healthStatus: 'Sehat',
        pen: 'Kandang A',
        weight: 68.5,
        notes: 'Pejantan unggul bertanduk simetris, performa pemuliaan sangat baik',
        updatedAt: now,
      ),
      Livestock(
        id: 'SM-002',
        name: 'Melati',
        species: 'Domba',
        breed: 'Domba Garut',
        sex: 'Betina',
        birthDate: now.subtract(const Duration(days: 30 * 30)),
        healthStatus: 'Sehat',
        pen: 'Kandang A',
        weight: 48.0,
        notes: 'Indukan produktif, sifat keibuan baik',
        updatedAt: now,
      ),
      Livestock(
        id: 'SM-003',
        name: 'Bimo',
        species: 'Domba',
        breed: 'Domba Garut',
        sex: 'Jantan',
        birthDate: now.subtract(const Duration(days: 18 * 30)),
        healthStatus: 'Sehat',
        pen: 'Kandang A',
        sireId: 'SM-001',
        damId: 'SM-002',
        weight: 44.0,
        notes: 'Anakan F1 dari Garuda x Melati, postur tegap',
        updatedAt: now,
      ),
      Livestock(
        id: 'SM-004',
        name: 'Luna',
        species: 'Domba',
        breed: 'Domba Garut',
        sex: 'Betina',
        birthDate: now.subtract(const Duration(days: 14 * 30)),
        healthStatus: 'Sehat',
        pen: 'Kandang A',
        sireId: 'SM-001',
        damId: 'SM-002',
        weight: 38.0,
        notes: 'Adik dari Bimo, calon bibit unggul',
        updatedAt: now,
      ),
      Livestock(
        id: 'SM-005',
        name: 'Moka',
        species: 'Domba',
        breed: 'Texel',
        sex: 'Betina',
        birthDate: now.subtract(const Duration(days: 11 * 30)),
        healthStatus: 'Pantau',
        pen: 'Kandang B',
        weight: 32.5,
        notes: 'Nafsu makan menurun sedikit setelah vaksinasi, dalam pemantauan',
        updatedAt: now,
      ),
      Livestock(
        id: 'SM-006',
        name: 'Raja',
        species: 'Domba',
        breed: 'Dorper',
        sex: 'Jantan',
        birthDate: now.subtract(const Duration(days: 22 * 30)),
        healthStatus: 'Sehat',
        pen: 'Kandang C',
        weight: 58.0,
        notes: 'Pejantan pedaging tipe dorper murni',
        updatedAt: now,
      ),
    ];
    for (final l in initialLivestock) {
      batch.insert(tableLivestock, l.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 3. Seed Riwayat Kesehatan (Health Records)
    final initialHealth = [
      HealthRecord(
        id: 'HLT-01',
        livestockId: 'SM-005',
        date: now.subtract(const Duration(days: 3)),
        condition: 'Pantau',
        diagnosis: 'Gejala lesu ringan pasca vaksinasi',
        treatment: 'Vitamin B-Complex & elektrolit oral 5ml',
        notes: 'Dipantau suhu tiap pagi, suhu stabil 39.0°C',
      ),
      HealthRecord(
        id: 'HLT-02',
        livestockId: 'SM-001',
        date: now.subtract(const Duration(days: 20)),
        condition: 'Sehat',
        diagnosis: 'Pemberian obat cacing berkala',
        treatment: 'Albendazole oral 10ml',
        notes: 'Kondisi fisik prima pasca pengobatan',
      ),
    ];
    for (final h in initialHealth) {
      batch.insert(tableHealth, h.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 4. Seed Riwayat Pertumbuhan (Growth Records)
    final initialGrowth = [
      GrowthRecord(
        id: 'GRW-01',
        livestockId: 'SM-003',
        date: now.subtract(const Duration(days: 60)),
        weight: 39.0,
        height: 60.0,
        notes: 'Penimbangan rutin 2 bulan lalu',
      ),
      GrowthRecord(
        id: 'GRW-02',
        livestockId: 'SM-003',
        date: now.subtract(const Duration(days: 30)),
        weight: 41.5,
        height: 62.0,
        notes: 'ADG mencapai 83 gram/hari',
      ),
      GrowthRecord(
        id: 'GRW-03',
        livestockId: 'SM-003',
        date: now,
        weight: 44.0,
        height: 63.5,
        notes: 'Penimbangan terkini',
      ),
    ];
    for (final g in initialGrowth) {
      batch.insert(tableGrowth, g.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 5. Seed Riwayat Perkembangbiakan (Breeding Records)
    final initialBreeding = [
      BreedingRecord(
        id: 'BRD-01',
        sireId: 'SM-001',
        damId: 'SM-002',
        matingDate: now.subtract(const Duration(days: 30 * 19)),
        expectedBirthDate: now.subtract(const Duration(days: 30 * 14)),
        actualBirthDate: now.subtract(const Duration(days: 30 * 14)),
        status: 'Melahirkan',
        offspringCount: 2,
        notes: 'Kelahiran kembar sehat: Bimo (Jantan) & Luna (Betina)',
      ),
      BreedingRecord(
        id: 'BRD-02',
        sireId: 'SM-006',
        damId: 'SM-005',
        matingDate: now.subtract(const Duration(days: 75)),
        expectedBirthDate: now.add(const Duration(days: 75)),
        status: 'Bunting',
        offspringCount: 0,
        notes: 'Konfirmasi kebuntingan via palpasi hari ke-60',
      ),
    ];
    for (final b in initialBreeding) {
      batch.insert(tableBreeding, b.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 6. Seed Akun Pengguna (Users) - FR-04
    final initialUsers = [
      const UserAccount(id: 'USR-01', name: 'Dias Ferdian', email: 'admin.semis@gmail.com', role: 'Admin', isActive: true),
      const UserAccount(id: 'USR-02', name: 'Pak Budi Santoso', email: 'budi.peternak@gmail.com', role: 'Peternak', isActive: true),
      const UserAccount(id: 'USR-03', name: 'Siti Rahmawati', email: 'siti.semis@gmail.com', role: 'Peternak', isActive: true),
    ];
    for (final u in initialUsers) {
      batch.insert(tableUsers, u.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    debugPrint('[DB] Seeding data awal SEMIS berhasil diselesaikan.');
  }

  // ─── LIVESTOCK CRUD ────────────────────────────────────────────────────────

  Future<void> insertLivestock(Livestock livestock) async {
    final db = await database;
    await db.insert(
      tableLivestock,
      livestock.copyWith(
        statusSync: SyncStatus.pending,
        updatedAt: DateTime.now(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('[DB] Insert livestock: ${livestock.id}');
  }

  Future<List<Livestock>> getAllLivestock() async {
    final db = await database;
    final rows = await db.query(
      tableLivestock,
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'updated_at DESC',
    );
    return rows.map(Livestock.fromMap).toList();
  }

  Future<Livestock?> getLivestockById(String id) async {
    final db = await database;
    final rows = await db.query(tableLivestock, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Livestock.fromMap(rows.first);
  }

  Future<List<Livestock>> getPendingSync() async {
    final db = await database;
    final rows = await db.query(
      tableLivestock,
      where: 'status_sync = ?',
      whereArgs: ['pending'],
      orderBy: 'updated_at ASC',
    );
    return rows.map(Livestock.fromMap).toList();
  }

  Future<void> updateLivestock(Livestock livestock) async {
    final db = await database;
    await db.update(
      tableLivestock,
      livestock.copyWith(
        statusSync: SyncStatus.pending,
        updatedAt: DateTime.now(),
      ).toMap(),
      where: 'id = ?',
      whereArgs: [livestock.id],
    );
    debugPrint('[DB] Update livestock: ${livestock.id}');
  }

  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      tableLivestock,
      {'status_sync': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> softDeleteLivestock(String id) async {
    final db = await database;
    await db.update(
      tableLivestock,
      {
        'is_deleted': 1,
        'status_sync': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('[DB] Soft delete livestock: $id');
  }

  // ─── HEALTH RECORDS (FR-09) ────────────────────────────────────────────────

  Future<List<HealthRecord>> getHealthRecords(String livestockId) async {
    final db = await database;
    final rows = await db.query(
      tableHealth,
      where: 'livestock_id = ?',
      whereArgs: [livestockId],
      orderBy: 'date DESC',
    );
    return rows.map(HealthRecord.fromMap).toList();
  }

  Future<void> insertHealthRecord(HealthRecord record) async {
    final db = await database;
    await db.insert(tableHealth, record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    // Otomatis sinkronkan status kesehatan di tabel livestock jika diperlukan
    await db.update(
      tableLivestock,
      {
        'health_status': record.condition,
        'updated_at': DateTime.now().toIso8601String(),
        'status_sync': 'pending',
      },
      where: 'id = ?',
      whereArgs: [record.livestockId],
    );
  }

  Future<void> deleteHealthRecord(String id) async {
    final db = await database;
    await db.delete(tableHealth, where: 'id = ?', whereArgs: [id]);
  }

  // ─── GROWTH RECORDS (FR-10) ────────────────────────────────────────────────

  Future<List<GrowthRecord>> getGrowthRecords(String livestockId) async {
    final db = await database;
    final rows = await db.query(
      tableGrowth,
      where: 'livestock_id = ?',
      whereArgs: [livestockId],
      orderBy: 'date DESC',
    );
    return rows.map(GrowthRecord.fromMap).toList();
  }

  Future<void> insertGrowthRecord(GrowthRecord record) async {
    final db = await database;
    await db.insert(tableGrowth, record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    // Perbarui bobot terkini di livestock
    await db.update(
      tableLivestock,
      {
        'weight': record.weight,
        'updated_at': DateTime.now().toIso8601String(),
        'status_sync': 'pending',
      },
      where: 'id = ?',
      whereArgs: [record.livestockId],
    );
  }

  // ─── PENS CRUD (FR-11) ─────────────────────────────────────────────────────

  Future<List<Pen>> getAllPens() async {
    final db = await database;
    final rows = await db.query(tablePens, orderBy: 'name ASC');
    return rows.map(Pen.fromMap).toList();
  }

  Future<void> insertPen(Pen pen) async {
    final db = await database;
    await db.insert(tablePens, pen.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePen(Pen pen) async {
    final db = await database;
    await db.update(tablePens, pen.toMap(), where: 'id = ?', whereArgs: [pen.id]);
  }

  Future<void> deletePen(String id) async {
    final db = await database;
    await db.delete(tablePens, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getLivestockCountInPen(String penName) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $tableLivestock WHERE pen = ? AND is_deleted = 0',
        [penName],
      ),
    );
    return count ?? 0;
  }

  // ─── BREEDING RECORDS (FR-12 & FR-13) ──────────────────────────────────────

  Future<List<BreedingRecord>> getAllBreedingRecords() async {
    final db = await database;
    final rows = await db.query(tableBreeding, orderBy: 'mating_date DESC');
    return rows.map(BreedingRecord.fromMap).toList();
  }

  Future<void> insertBreedingRecord(BreedingRecord record) async {
    final db = await database;
    await db.insert(tableBreeding, record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBreedingRecord(BreedingRecord record) async {
    final db = await database;
    await db.update(tableBreeding, record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<void> deleteBreedingRecord(String id) async {
    final db = await database;
    await db.delete(tableBreeding, where: 'id = ?', whereArgs: [id]);
  }

  // ─── USER MANAGEMENT (FR-04) ───────────────────────────────────────────────

  Future<List<UserAccount>> getAllUsers() async {
    final db = await database;
    final rows = await db.query(tableUsers, orderBy: 'role ASC, name ASC');
    return rows.map(UserAccount.fromMap).toList();
  }

  Future<void> insertUser(UserAccount user) async {
    final db = await database;
    await db.insert(tableUsers, user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUser(UserAccount user) async {
    final db = await database;
    await db.update(tableUsers, user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete(tableUsers, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) await db.close();
    _db = null;
  }
}
