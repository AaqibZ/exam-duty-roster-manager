
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance =
      DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'exam_duty_roster.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE personnel (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        section TEXT NOT NULL,
        joiningDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE examinations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        examDate TEXT NOT NULL,
        courseName TEXT NOT NULL,
        courseCode TEXT NOT NULL,
        facultyId INTEGER NOT NULL,
        facultyName TEXT NOT NULL,
        venue TEXT NOT NULL
      )
    ''');

    await _createDutyAllocationsTable(db);
  }

  Future<void> _createDutyAllocationsTable(
    Database db,
  ) async {
    await db.execute('''
      CREATE TABLE duty_allocations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        examinationId INTEGER NOT NULL,
        personnelId INTEGER NOT NULL,
        personnelName TEXT NOT NULL,
        role TEXT NOT NULL,
        allocatedAt TEXT NOT NULL,
        UNIQUE(examinationId, personnelId)
      )
    ''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE examinations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          examDate TEXT NOT NULL,
          courseName TEXT NOT NULL,
          courseCode TEXT NOT NULL,
          facultyId INTEGER NOT NULL,
          facultyName TEXT NOT NULL,
          venue TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await _createDutyAllocationsTable(db);
    }
  }

  // PERSONNEL METHODS

  Future<int> insertPersonnel(
    Map<String, dynamic> personnel,
  ) async {
    final db = await database;

    return await db.insert(
      'personnel',
      personnel,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Map<String, dynamic>>> getAllPersonnel() async {
    final db = await database;

    return await db.query(
      'personnel',
      orderBy: 'id DESC',
    );
  }

  Future<int> deletePersonnel(int id) async {
    final db = await database;

    return await db.delete(
      'personnel',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // EXAMINATION METHODS

  Future<int> insertExamination(
    Map<String, dynamic> examination,
  ) async {
    final db = await database;

    return await db.insert(
      'examinations',
      examination,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Map<String, dynamic>>> getAllExaminations() async {
    final db = await database;

    return await db.query(
      'examinations',
      orderBy: 'examDate ASC',
    );
  }

  Future<int> deleteExamination(int id) async {
    final db = await database;

    return await db.delete(
      'examinations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DUTY ALLOCATION METHODS

  Future<int> insertDutyAllocation(
    Map<String, dynamic> allocation,
  ) async {
    final db = await database;

    return await db.insert(
      'duty_allocations',
      allocation,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Map<String, dynamic>>> getAllDutyAllocations() async {
    final db = await database;

    return await db.query(
      'duty_allocations',
      orderBy: 'allocatedAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllocationsForExamination(
    int examinationId,
  ) async {
    final db = await database;

    return await db.query(
      'duty_allocations',
      where: 'examinationId = ?',
      whereArgs: [examinationId],
      orderBy: 'id ASC',
    );
  }

  Future<int> deleteAllocationsForExamination(
    int examinationId,
  ) async {
    final db = await database;

    return await db.delete(
      'duty_allocations',
      where: 'examinationId = ?',
      whereArgs: [examinationId],
    );
  }

  Future<int> getDutyCountForPersonnel(
    int personnelId,
  ) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS dutyCount
      FROM duty_allocations
      WHERE personnelId = ?
      ''',
      [personnelId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getDutyCounts() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT personnelId, COUNT(*) AS dutyCount
      FROM duty_allocations
      GROUP BY personnelId
    ''');
  }
}
