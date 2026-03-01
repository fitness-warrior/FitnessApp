import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ExerciseDb {
  ExerciseDb._init();
  static final ExerciseDb instance = ExerciseDb._init();

  static Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('exercises.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        exer_id INTEGER PRIMARY KEY AUTOINCREMENT,
        exer_name TEXT NOT NULL,
        exer_body_area TEXT,
        exer_type TEXT,
        exer_descrip TEXT,
        exer_vid TEXT,
        exer_equip TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE plan_exercises (
        plan_exer_id INTEGER PRIMARY KEY AUTOINCREMENT,
        work_id INTEGER,
        exer_id INTEGER NOT NULL,
        plan_exer_set INTEGER,
        plan_exer_amount INTEGER,
        FOREIGN KEY (exer_id) REFERENCES exercises (exer_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE workouts (
        work_id   INTEGER PRIMARY KEY AUTOINCREMENT,
        work_name TEXT,
        work_date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_logs (
        log_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        work_id   INTEGER NOT NULL,
        exer_id   INTEGER,
        exer_name TEXT NOT NULL,
        sets_data TEXT NOT NULL,
        FOREIGN KEY (work_id) REFERENCES workouts (work_id)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workouts (
          work_id   INTEGER PRIMARY KEY AUTOINCREMENT,
          work_name TEXT,
          work_date TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workout_logs (
          log_id    INTEGER PRIMARY KEY AUTOINCREMENT,
          work_id   INTEGER NOT NULL,
          exer_id   INTEGER,
          exer_name TEXT NOT NULL,
          sets_data TEXT NOT NULL,
          FOREIGN KEY (work_id) REFERENCES workouts (work_id)
        )
      ''');
    }
  }

  Future<List<Map<String, dynamic>>> listExercises({
    String? name,
    String? area,
    String? type,
    List<String>? equipment,
  }) async {
    final db = await instance.database;
    var query = '''
      SELECT e.exer_id, e.exer_name, e.exer_body_area, e.exer_type,
             e.exer_descrip, e.exer_vid, e.exer_equip,
             pe.plan_exer_set, pe.plan_exer_amount
      FROM exercises e
      LEFT JOIN plan_exercises pe ON e.exer_id = pe.exer_id
      WHERE 1=1
    ''';
    final params = <dynamic>[];

    if (name != null) {
      query += ' AND e.exer_name = ?';
      params.add(name);
    }
    if (area != null) {
      query += ' AND e.exer_body_area = ?';
      params.add(area);
    }
    if (type != null) {
      query += ' AND e.exer_type = ?';
      params.add(type);
    }
    if (equipment != null && equipment.isNotEmpty) {
      final likes = equipment.map((_) => 'e.exer_equip LIKE ?').join(' OR ');
      query += ' AND ($likes)';
      params.addAll(equipment.map((e) => '%$e%'));
    }

    final rows = await db.rawQuery(query, params);
    return rows.map((r) {
      return {
        'exer_id': r['exer_id'],
        'exer_name': r['exer_name'],
        'exer_body_area': r['exer_body_area'],
        'exer_type': r['exer_type'],
        'exer_descrip': r['exer_descrip'],
        'exer_vid': r['exer_vid'],
        'exer_equip': r['exer_equip'],
        'plan': r['plan_exer_set'] == null
            ? null
            : {'sets': r['plan_exer_set'], 'reps': r['plan_exer_amount']}
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getExercise(int id) async {
    final db = await instance.database;
    final row = await db.rawQuery('''
      SELECT e.exer_id, e.exer_name, e.exer_body_area, e.exer_type,
             e.exer_descrip, e.exer_vid, e.exer_equip,
             pe.plan_exer_set, pe.plan_exer_amount
      FROM exercises e
      LEFT JOIN plan_exercises pe ON e.exer_id = pe.exer_id
      WHERE e.exer_id = ?
    ''', [id]);

    if (row.isEmpty) return null;
    final r = row.first;
    return {
      'exer_id': r['exer_id'],
      'exer_name': r['exer_name'],
      'exer_body_area': r['exer_body_area'],
      'exer_type': r['exer_type'],
      'exer_descrip': r['exer_descrip'],
      'exer_vid': r['exer_vid'],
      'exer_equip': r['exer_equip'],
      'plan': r['plan_exer_set'] == null
          ? null
          : {'sets': r['plan_exer_set'], 'reps': r['plan_exer_amount']}
    };
  }

  Future<int> createExercise(Map<String, dynamic> data) async {
    final db = await instance.database;
    final id = await db.insert('exercises', {
      'exer_name': data['exer_name'],
      'exer_body_area': data['exer_body_area'],
      'exer_type': data['exer_type'],
      'exer_descrip': data['exer_descrip'],
      'exer_vid': data['exer_vid'],
      'exer_equip': data['exer_equip'],
    });
    return id;
  }

  Future<int> createPlanExercise(Map<String, dynamic> data) async {
    final db = await instance.database;
    final id = await db.insert('plan_exercises', {
      'work_id': data['work_id'],
      'exer_id': data['exer_id'],
      'plan_exer_set': data['sets'],
      'plan_exer_amount': data['reps'],
    });
    return id;
  }

  Future<int> saveWorkout({
    required List<Map<String, dynamic>> exercisesWithSets,
    String? name,
  }) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    final workId = await db.insert('workouts', {
      'work_name': name ?? 'Workout ${now.substring(0, 10)}',
      'work_date': now,
    });
    for (final ex in exercisesWithSets) {
      await db.insert('workout_logs', {
        'work_id': workId,
        'exer_id': ex['exer_id'],
        'exer_name': ex['exer_name'],
        'sets_data': jsonEncode(ex['sets'] ?? []),
      });
    }
    return workId;
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final db = await instance.database;
    final rows = await db.query('workouts', orderBy: 'work_date DESC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getWorkoutLogs(int workId) async {
    final db = await instance.database;
    final rows = await db.query(
      'workout_logs',
      where: 'work_id = ?',
      whereArgs: [workId],
    );
    return rows.map((r) {
      final sets = (jsonDecode(r['sets_data'] as String) as List)
          .cast<Map<String, dynamic>>();
      return {
        'exer_id': r['exer_id'],
        'exer_name': r['exer_name'],
        'sets': sets,
      };
    }).toList();
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
    _db = null;
  }
}