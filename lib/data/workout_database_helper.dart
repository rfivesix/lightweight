// lib/data/workout_database_helper.dart
// VOLLSTÄNDIGER CODE

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:lightweight/util/mapping_prefs.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/models/routine.dart';
import 'package:lightweight/models/routine_exercise.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/models/set_template.dart';
import 'package:lightweight/models/workout_log.dart';

class WorkoutDatabaseHelper {
  static final WorkoutDatabaseHelper instance = WorkoutDatabaseHelper._init();
  static Database? _database;
  WorkoutDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vita_training.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    // --- KORREKTUR START: Versionierungslogik für Asset-DB ---
    const int currentAssetVersion =
        9; // Erhöhe diese Zahl, wenn du die vita_training.db in den Assets aktualisierst
    const String assetVersionKey = 'training_db_asset_version';

    final prefs = await SharedPreferences.getInstance();
    final lastCopiedVersion = prefs.getInt(assetVersionKey) ?? 0;
    final exists = await databaseExists(path);

    if (!exists || lastCopiedVersion < currentAssetVersion) {
      print(
        "Datenbank '$fileName' ist veraltet (Lokal: v$lastCopiedVersion, Asset: v$currentAssetVersion) oder nicht vorhanden. Kopiere neu...",
      );
      try {
        // Alte DB löschen, falls vorhanden, um eine saubere Kopie zu gewährleisten
        if (exists) {
          await deleteDatabase(path);
        }
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join('assets/db', fileName));
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);

        // Neue Version in SharedPreferences speichern
        await prefs.setInt(assetVersionKey, currentAssetVersion);
        print(
            "Datenbank '$fileName' erfolgreich auf v$currentAssetVersion kopiert.");
      } catch (e) {
        print("Fehler beim Kopieren der Datenbank '$fileName': $e");
        rethrow;
      }
    } else {
      print(
          "Bestehende und aktuelle Datenbank '$fileName' (v$lastCopiedVersion) gefunden.");
    }
    // --- KORREKTUR ENDE ---

    return await openDatabase(path, version: 10, onUpgrade: _upgradeDB);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print("Führe DB-Upgrade von v$oldVersion auf v$newVersion aus...");
    if (oldVersion < 2) {
      await db
          .execute('ALTER TABLE set_logs ADD COLUMN rest_time_seconds INTEGER')
          .catchError((_) {});
      await db
          .execute('ALTER TABLE set_logs ADD COLUMN is_completed INTEGER')
          .catchError((_) {});
    }
    if (oldVersion < 3) {
      await db
          .execute(
            "ALTER TABLE workout_logs ADD COLUMN status TEXT NOT NULL DEFAULT 'completed'",
          )
          .catchError((_) {});
    }
    if (oldVersion < 4) {
      await db
          .execute(
            "ALTER TABLE routine_exercises ADD COLUMN pause_seconds INTEGER",
          )
          .catchError((_) {});
    }
    if (oldVersion < 5) {
      await db
          .execute("ALTER TABLE set_logs ADD COLUMN log_order INTEGER")
          .catchError((_) {});
    }
    if (oldVersion < 6) {
      print("Upgrade DB auf v6: Entferne set_index aus set_logs...");
      await db.transaction((txn) async {
        await txn.execute('ALTER TABLE set_logs RENAME TO set_logs_old');
        await txn.execute('''
          CREATE TABLE set_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workout_log_id INTEGER,
            exercise_name TEXT,
            set_type TEXT,
            weight_kg REAL,
            reps INTEGER,
            rest_time_seconds INTEGER,
            is_completed INTEGER,
            log_order INTEGER
          )
        ''');
        await txn.execute('''
          INSERT INTO set_logs (id, workout_log_id, exercise_name, set_type, weight_kg, reps, rest_time_seconds, is_completed, log_order)
          SELECT id, workout_log_id, exercise_name, set_type, weight_kg, reps, rest_time_seconds, is_completed, log_order FROM set_logs_old
        ''');
        await txn.execute('DROP TABLE set_logs_old');
      });
    }
    if (oldVersion < 7) {
      print("Upgrade DB auf v7: Füge Detail-Spalten zu set_logs hinzu...");
      await db
          .execute("ALTER TABLE set_logs ADD COLUMN notes TEXT")
          .catchError((_) {});
      await db
          .execute("ALTER TABLE set_logs ADD COLUMN distance_km REAL")
          .catchError((_) {});
      await db
          .execute("ALTER TABLE set_logs ADD COLUMN duration_seconds INTEGER")
          .catchError((_) {});
      await db
          .execute("ALTER TABLE set_logs ADD COLUMN rpe INTEGER")
          .catchError((_) {});
    }
    if (oldVersion < 8) {
      print("Upgrade DB auf v8: Füge superset_id zu set_logs hinzu...");
      await db
          .execute("ALTER TABLE set_logs ADD COLUMN superset_id INTEGER")
          .catchError((_) {});
    }
    if (oldVersion < 9) {
      print("Upgrade DB auf v9: Erstelle exercise_mapping Tabelle...");
      await db.execute('''
        CREATE TABLE exercise_mapping (
          external_name TEXT PRIMARY KEY COLLATE NOCASE,
          target_name TEXT NOT NULL
        )
      ''');
      final oldMappings = await MappingPrefs.load();
      if (oldMappings.isNotEmpty) {
        print("Migriere ${oldMappings.length} bestehende Mappings...");
        final batch = db.batch();
        for (final entry in oldMappings.entries) {
          batch.insert(
              'exercise_mapping',
              {
                'external_name': entry.key,
                'target_name': entry.value,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
        print("Migration abgeschlossen.");
      }
    }
    if (oldVersion < 10) {
      print("Upgrade DB auf v10: Füge is_custom zu exercises hinzu...");
      try {
        // Füge die neue Spalte hinzu, Standardwert 0 (nicht custom)
        await db.execute(
          'ALTER TABLE exercises ADD COLUMN is_custom INTEGER NOT NULL DEFAULT 0',
        );
        print("Spalte 'is_custom' erfolgreich zu 'exercises' hinzugefügt.");
      } catch (e) {
        print(
            "Fehler beim Hinzufügen der Spalte 'is_custom' (evtl. existiert sie schon): $e");
      }
    }
    print("DB-Upgrade auf v$newVersion erfolgreich abgeschlossen.");
  }

  // HINZUGEFÜGT: Neue Methode zur Wiederherstellung
  /// Sucht nach einem laufenden Workout in der DB. Es sollte immer nur eines geben.
  Future<WorkoutLog?> getOngoingWorkout() async {
    final db = await database;
    final maps = await db.query(
      'workout_logs',
      where: "status = 'ongoing'",
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      // Wenn ein laufendes Workout gefunden wird, holen wir auch alle zugehörigen Sätze.
      final logId = maps.first['id'] as int;
      return getWorkoutLogById(logId);
    }

    return null;
  }

  Future<Map<String, String>> getExerciseMappings() async {
    final db = await database;
    final maps = await db.query('exercise_mapping');
    return {
      for (var map in maps)
        (map['external_name'] as String): (map['target_name'] as String),
    };
  }

  // --- EXERCISE MANAGEMENT ---
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exercises_flat', // WAR: 'exercises'
      columns: ['category_name'],
      distinct: true,
      orderBy: 'category_name ASC',
    );
    return maps
        .map((map) => map['category_name'] as String?)
        .where((category) => category != null && category.isNotEmpty)
        .cast<String>()
        .toList();
  }

  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> selectedCategories = const [],
  }) async {
    final db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];
    if (query.isNotEmpty) {
      whereClauses.add('(name_de LIKE ? OR name_en LIKE ?)');
      whereArgs.addAll(['%$query%', '%$query%']);
    }
    if (selectedCategories.isNotEmpty) {
      String placeholders = List.filled(
        selectedCategories.length,
        '?',
      ).join(', ');
      whereClauses.add('category_name IN ($placeholders)');
      whereArgs.addAll(selectedCategories);
    }
    String finalWhere =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : '';
    final String sql = '''
      SELECT e.*, CASE WHEN sl.id IS NOT NULL THEN 0 ELSE 1 END as sort_priority
      FROM exercises_flat e -- WAR: 'exercises e'
      LEFT JOIN (SELECT exercise_name, MAX(id) as id FROM set_logs GROUP BY exercise_name) sl
      ON e.name_de = sl.exercise_name OR e.name_en = sl.exercise_name
      ${finalWhere.isNotEmpty ? 'WHERE $finalWhere' : ''}
      ORDER BY sort_priority ASC, e.name_de ASC
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, whereArgs);
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<Exercise?> getExerciseByName(String name) async {
    final db = await database;
    // --- HIER IST DIE ÄNDERUNG ---
    final maps = await db.query(
      'exercises_flat', // WAR: 'exercises'
      where: 'name_de = ? OR name_en = ?',
      whereArgs: [name, name],
      limit: 1,
    );
    // --- ENDE DER ÄNDERUNG ---
    if (maps.isNotEmpty) {
      return Exercise.fromMap(maps.first);
    }
    return null;
  }

  // --- ROUTINE MANAGEMENT ---
  Future<Routine> createRoutine(String name) async {
    final db = await database;
    final id = await db.insert(
        'routines',
        {
          'name': name,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
    return Routine(id: id, name: name);
  }

  Future<void> updateRoutineName(int routineId, String newName) async {
    final db = await database;
    await db.update(
      'routines',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [routineId],
    );
  }

  Future<RoutineExercise?> addExerciseToRoutine(
    int routineId,
    int exerciseId,
  ) async {
    final db = await database;
    // --- START FIX ---
    // Query the VIEW 'exercises_flat' instead of the TABLE 'exercises'
    // to ensure all necessary fields (like muscle groups) are correctly loaded.
    final exerciseMaps = await db.query(
      'exercises_flat', // CORRECT: Use the view
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
    // --- END FIX ---

    if (exerciseMaps.isEmpty) return null;
    final result = await db.rawQuery(
      'SELECT MAX(exercise_order) as max_order FROM routine_exercises WHERE routine_id = ?',
      [routineId],
    );
    final maxOrder = (result.first['max_order'] as int?) ?? -1;
    final routineExerciseId = await db.insert('routine_exercises', {
      'routine_id': routineId,
      'exercise_id': exerciseId,
      'exercise_order': maxOrder + 1,
    });
    final List<SetTemplate> newTemplates = [];
    for (int i = 0; i < 3; i++) {
      final setId = await db.insert('routine_set_templates', {
        'routine_exercise_id': routineExerciseId,
        'set_index': i,
        'set_type': 'normal',
      });
      newTemplates.add(
        SetTemplate(id: setId, setType: 'normal', targetReps: '8-12'),
      );
    }
    return RoutineExercise(
      id: routineExerciseId,
      exercise: Exercise.fromMap(exerciseMaps.first),
      setTemplates: newTemplates,
    );
  }

  Future<void> removeExerciseFromRoutine(int routineExerciseId) async {
    final db = await database;
    await db.delete(
      'routine_exercises',
      where: 'id = ?',
      whereArgs: [routineExerciseId],
    );
  }

  Future<void> updateExerciseOrder(
    int routineId,
    List<RoutineExercise> orderedExercises,
  ) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < orderedExercises.length; i++) {
      final routineExercise = orderedExercises[i];
      batch.update(
        'routine_exercises',
        {'exercise_order': i},
        where: 'id = ?',
        whereArgs: [routineExercise.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Routine>> getAllRoutines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'routines',
      orderBy: 'name ASC',
    );
    return List.generate(
      maps.length,
      (i) => Routine(id: maps[i]['id'], name: maps[i]['name']),
    );
  }

  Future<Routine?> getRoutineById(int id) async {
    final db = await database;
    final routineMaps = await db.query(
      'routines',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (routineMaps.isEmpty) return null;
    final routineExerciseMaps = await db.query(
      'routine_exercises',
      where: 'routine_id = ?',
      whereArgs: [id],
      orderBy: 'exercise_order ASC',
    );
    final List<RoutineExercise> routineExercises = [];
    for (final reMap in routineExerciseMaps) {
      final routineExerciseId = reMap['id'] as int;
      final exerciseId = reMap['exercise_id'] as int;
      // --- FIX IS HERE ---
      final exerciseMaps = await db.query(
        'exercises_flat', // Use the view that has all the data
        where: 'id = ?',
        whereArgs: [exerciseId],
      );
      // --- END FIX ---
      if (exerciseMaps.isEmpty) continue;
      final setTemplateMaps = await db.query(
        'routine_set_templates',
        where: 'routine_exercise_id = ?',
        whereArgs: [routineExerciseId],
        orderBy: 'set_index ASC',
      );
      final setTemplates =
          setTemplateMaps.map((stMap) => SetTemplate.fromMap(stMap)).toList();
      routineExercises.add(
        RoutineExercise(
          id: routineExerciseId,
          exercise: Exercise.fromMap(exerciseMaps.first),
          setTemplates: setTemplates,
          pauseSeconds: reMap['pause_seconds'] as int?,
        ),
      );
    }
    return Routine(
      id: id,
      name: routineMaps.first['name'] as String,
      exercises: routineExercises,
    );
  }

  Future<void> updateSetTemplate(SetTemplate setTemplate) async {
    final db = await database;
    await db.update(
      'routine_set_templates',
      {
        'set_type': setTemplate.setType,
        'target_reps': setTemplate.targetReps,
        'target_weight': setTemplate.targetWeight,
      },
      where: 'id = ?',
      whereArgs: [setTemplate.id],
    );
  }

  Future<void> replaceSetTemplatesForExercise(
    int routineExerciseId,
    List<SetTemplate> newTemplates,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'routine_set_templates',
        where: 'routine_exercise_id = ?',
        whereArgs: [routineExerciseId],
      );
      for (int i = 0; i < newTemplates.length; i++) {
        final set = newTemplates[i];
        await txn.insert('routine_set_templates', {
          'routine_exercise_id': routineExerciseId,
          'set_index': i,
          'set_type': set.setType,
          'target_reps': set.targetReps,
          'target_weight': set.targetWeight,
        });
      }
    });
  }

  Future<void> deleteRoutine(int routineId) async {
    final db = await database;
    await db.transaction((txn) async {
      final reMaps = await txn.query(
        'routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [routineId],
      );
      for (var reMap in reMaps) {
        await txn.delete(
          'routine_set_templates',
          where: 'routine_exercise_id = ?',
          whereArgs: [reMap['id']],
        );
      }
      await txn.delete(
        'routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [routineId],
      );
      await txn.delete('routines', where: 'id = ?', whereArgs: [routineId]);
    });
  }

  Future<void> duplicateRoutine(int routineId) async {
    final db = await database;
    final originalRoutine = await getRoutineById(routineId);
    if (originalRoutine == null) return;
    await db.transaction((txn) async {
      final newRoutineId = await txn.insert('routines', {
        'name': '${originalRoutine.name} (Kopie)',
      });
      for (var re in originalRoutine.exercises) {
        final newRoutineExerciseId = await txn.insert('routine_exercises', {
          'routine_id': newRoutineId,
          'exercise_id': re.exercise.id,
          'exercise_order': originalRoutine.exercises.indexOf(re),
          'pause_seconds': re.pauseSeconds,
        });
        for (var st in re.setTemplates) {
          await txn.insert('routine_set_templates', {
            'routine_exercise_id': newRoutineExerciseId,
            'set_index': re.setTemplates.indexOf(st),
            'set_type': st.setType,
            'target_reps': st.targetReps,
            'target_weight': st.targetWeight,
          });
        }
      }
    });
  }

  Future<void> updatePauseTime(int routineExerciseId, int? seconds) async {
    final db = await database;
    await db.update(
      'routine_exercises',
      {'pause_seconds': seconds},
      where: 'id = ?',
      whereArgs: [routineExerciseId],
    );
  }

  // --- WORKOUT LOGGING ---
  Future<WorkoutLog> startWorkout({String? routineName}) async {
    final db = await database;
    final now = DateTime.now();
    final id = await db.insert('workout_logs', {
      'routine_name': routineName,
      'start_time': now.toIso8601String(),
      'status': 'ongoing',
    });
    return WorkoutLog(id: id, routineName: routineName, startTime: now);
  }

  Future<int> insertSetLog(SetLog setLog) async {
    final db = await database;

    if (setLog.id != null) {
      print("--- DEBUG: Update SetLog ID=${setLog.id} ---");
      return await db.update(
        'set_logs',
        setLog.toMap(),
        where: 'id = ?',
        whereArgs: [setLog.id],
      );
    }

    final id = await db.insert(
      'set_logs',
      setLog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print(
      "--- DEBUG: Insert SetLog (${setLog.exerciseName}, ${setLog.weightKg}kg x ${setLog.reps}) → ID=$id ---",
    );
    return id;
  }

  Future<void> finishWorkout(int workoutLogId) async {
    final db = await database;
    await db.update(
      'workout_logs',
      {'end_time': DateTime.now().toIso8601String(), 'status': 'completed'},
      where: 'id = ?',
      whereArgs: [workoutLogId],
    );
  }

  Future<SetLog?> getLastPerformance(String exerciseName) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT * FROM set_logs
      WHERE exercise_name = ? AND set_type != 'warmup' AND reps IS NOT NULL AND weight_kg IS NOT NULL
      ORDER BY id DESC LIMIT 1
    ''',
      [exerciseName],
    );
    if (maps.isNotEmpty) return SetLog.fromMap(maps.first);
    return null;
  }

  // --- WORKOUT HISTORY ---
  Future<void> deleteWorkoutLog(int logId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'set_logs',
        where: 'workout_log_id = ?',
        whereArgs: [logId],
      );
      await txn.delete('workout_logs', where: 'id = ?', whereArgs: [logId]);
    });
  }

  Future<List<WorkoutLog>> getWorkoutLogs() async {
    final db = await database;
    final maps = await db.query(
      'workout_logs',
      where: "status = 'completed'",
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => WorkoutLog.fromMap(map)).toList();
  }

  Future<WorkoutLog?> getWorkoutLogById(int id) async {
    final db = await database;
    print("--- DEBUG: getWorkoutLogById gestartet für ID: $id ---");

    final logMaps = await db.query(
      'workout_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (logMaps.isEmpty) {
      print("--- DEBUG: KEINEN WorkoutLog für ID $id gefunden. Breche ab.");
      return null;
    }
    print("--- DEBUG: WorkoutLog gefunden: ${logMaps.first}");

    final setMaps = await db.query(
      'set_logs',
      where: 'workout_log_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );

    print(
      "--- DEBUG: Für workout_log_id $id wurden ${setMaps.length} Sätze in der DB gefunden.",
    );
    if (setMaps.isNotEmpty) {
      print("--- DEBUG: Erster gefundener Satz: ${setMaps.first}");
    }

    final sets = setMaps.map((map) => SetLog.fromMap(map)).toList();

    return WorkoutLog.fromMap(logMaps.first, sets: sets);
  }

  Future<WorkoutLog?> getLatestWorkoutLog() async {
    final db = await database;
    final maps = await db.query(
      'workout_logs',
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return WorkoutLog.fromMap(maps.first);
    }
    return null;
  }
// lib/data/workout_database_helper.dart

  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;

    // HIER IST DIE KORREKTUR: Erzeuge einen validen Datumsbereich für den ganzen Tag.
    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final maps = await db.query(
      'workout_logs',
      where: 'start_time >= ? AND start_time <= ? AND status = ?',
      whereArgs: [
        effectiveStart.toIso8601String(),
        effectiveEnd.toIso8601String(),
        'completed'
      ],
      orderBy: 'start_time DESC',
    );

    List<WorkoutLog> logs = [];
    for (final map in maps) {
      final sets = await getSetLogsForWorkout(map['id'] as int);
      logs.add(WorkoutLog.fromMap(map, sets: sets));
    }
    return logs;
  }

  Future<Routine?> getRoutineByName(String name) async {
    final db = await database;
    final maps = await db.query(
      'routines',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return getRoutineById(maps.first['id'] as int);
    }
    return null;
  }

  Future<void> updateWorkoutLogDetails(
    int logId,
    DateTime startTime,
    String? notes,
  ) async {
    final db = await database;
    await db.update(
      'workout_logs',
      {'start_time': startTime.toIso8601String(), 'notes': notes},
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  Future<void> updateSetLogs(List<SetLog> updatedSets) async {
    if (updatedSets.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final setLog in updatedSets) {
      batch.update(
        'set_logs',
        setLog.toMap(),
        where: 'id = ?',
        whereArgs: [setLog.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteSetLogs(List<int> idsToDelete) async {
    if (idsToDelete.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final id in idsToDelete) {
      batch.delete('set_logs', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) async {
    final db = await database;
    final maps = await db.query(
      'set_logs',
      where: 'workout_log_id = ?',
      whereArgs: [workoutLogId],
      orderBy: 'log_order ASC',
    );

    return maps.map((map) => SetLog.fromMap(map)).toList();
  }
  // --- NEUE METHODEN FÜR BACKUP & RESTORE ---

  Future<List<Routine>> getAllRoutinesWithDetails() async {
    final routines = await getAllRoutines();
    final detailedRoutines = <Routine>[];
    for (final routine in routines) {
      if (routine.id != null) {
        final detailedRoutine = await getRoutineById(routine.id!);
        if (detailedRoutine != null) {
          detailedRoutines.add(detailedRoutine);
        }
      }
    }
    return detailedRoutines;
  }

  Future<List<WorkoutLog>> getFullWorkoutLogs() async {
    final db = await database;
    final maps = await db.query('workout_logs', orderBy: 'start_time DESC');
    final logs = <WorkoutLog>[];
    for (final map in maps) {
      final log = await getWorkoutLogById(map['id'] as int);
      if (log != null) {
        logs.add(log);
      }
    }
    return logs;
  }

  Future<void> importWorkoutData({
    required List<Routine> routines,
    required List<WorkoutLog> workoutLogs,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      // Routinen importieren
      for (final routine in routines) {
        final newRoutineId = await txn.insert('routines', {
          'name': routine.name,
        });
        for (final re in routine.exercises) {
          final newReId = await txn.insert('routine_exercises', {
            'routine_id': newRoutineId,
            'exercise_id': re.exercise.id,
            'exercise_order': routine.exercises.indexOf(re),
            'pause_seconds': re.pauseSeconds,
          });
          for (final st in re.setTemplates) {
            final stMap = st.toMap();
            stMap.remove('id');
            stMap['routine_exercise_id'] = newReId;
            stMap['set_index'] = re.setTemplates.indexOf(st);
            await txn.insert('routine_set_templates', stMap);
          }
        }
      }

      // Workout Logs importieren
      for (final log in workoutLogs) {
        final logMap = log.toMap();
        logMap.remove('id');
        logMap['status'] = 'completed';
        final newLogId = await txn.insert('workout_logs', logMap);

        for (final setLog in log.sets) {
          final setMap = setLog.toMap();
          setMap.remove('id');
          setMap['workout_log_id'] = newLogId;
          await txn.insert('set_logs', setMap);
        }
      }
    });
  }

  Future<List<String>> findUnknownExerciseNames() async {
    final db = await database;
    final rows = await db.rawQuery('''
    SELECT DISTINCT sl.exercise_name
    FROM set_logs sl
    LEFT JOIN exercises e
      ON e.name_de = sl.exercise_name OR e.name_en = sl.exercise_name
    WHERE e.id IS NULL
    ORDER BY sl.exercise_name COLLATE NOCASE ASC
  ''');
    return rows
        .map((r) => (r['exercise_name'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> applyExerciseNameMapping(Map<String, String> map) async {
    if (map.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final e in map.entries) {
        batch.insert(
            'exercise_mapping',
            {
              'external_name': e.key,
              'target_name': e.value,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);

      for (final e in map.entries) {
        await txn.update(
          'set_logs',
          {'exercise_name': e.value},
          where: 'exercise_name = ?',
          whereArgs: [e.key],
        );
      }
    });
  }

  Future<List<String>> getAllMuscleGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exercises',
      columns: ['primaryMuscles', 'secondaryMuscles'],
      distinct: true,
    );

    final Set<String> allMuscles = {};

    List<String> parseMuscles(String? jsonString) {
      if (jsonString == null || jsonString.isEmpty) return [];
      try {
        return (jsonDecode(jsonString) as List)
            .map((item) => item.toString())
            .toList();
      } catch (e) {
        return [];
      }
    }

    for (final map in maps) {
      final primary = parseMuscles(map['primaryMuscles'] as String?);
      final secondary = parseMuscles(map['secondaryMuscles'] as String?);
      allMuscles.addAll(primary);
      allMuscles.addAll(secondary);
    }

    final sortedList = allMuscles.toList()..sort();
    return sortedList;
  }

  Future<Set<int>> getWorkoutDaysInMonth(DateTime month) async {
    final db = await database;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final maps = await db.query(
      'workout_logs',
      columns: ['start_time'],
      where: 'start_time BETWEEN ? AND ?',
      whereArgs: [
        firstDayOfMonth.toIso8601String(),
        lastDayOfMonth.toIso8601String(),
      ],
    );

    if (maps.isEmpty) return {};

    return maps
        .map((map) => DateTime.parse(map['start_time'] as String).day)
        .toSet();
  }

  /// Findet das letzte Workout, das eine bestimmte Übung enthielt,
  /// und gibt alle Sätze dieser Übung aus jenem Workout zurück.
  Future<List<SetLog>> getLastSetsForExercise(String exerciseName) async {
    final db = await database;

    // Schritt 1: Finde die ID des letzten Workout-Logs, das diese Übung enthält.
    final latestLogResult = await db.rawQuery(
      '''
      SELECT l.id
      FROM workout_logs l
      INNER JOIN set_logs s ON l.id = s.workout_log_id
      WHERE s.exercise_name = ? AND l.status = 'completed'
      ORDER BY l.start_time DESC
      LIMIT 1
    ''',
      [exerciseName],
    );

    if (latestLogResult.isEmpty) {
      return []; // Kein vorheriges Workout mit dieser Übung gefunden.
    }

    final logId = latestLogResult.first['id'] as int;

    // Schritt 2: Hole alle Sätze für diese Übung aus genau diesem Workout-Log.
    final setMaps = await db.query(
      'set_logs',
      where: 'workout_log_id = ? AND exercise_name = ?',
      whereArgs: [logId, exerciseName],
      orderBy: 'id ASC', // Sortiert nach der Reihenfolge der Erstellung
    );

    return setMaps.map((map) => SetLog.fromMap(map)).toList();
  }

  Future<Exercise> insertExercise(Exercise exercise) async {
    final db = await database;
    // Setze is_custom auf 1 für alle hier eingefügten Übungen
    final Map<String, Object?> exerciseMap = exercise.toMap();
    exerciseMap['is_custom'] = 1; // Markiere als benutzerdefiniert

    // Entferne die ID, falls sie versehentlich gesetzt wurde,
    // damit die DB eine neue generiert.
    exerciseMap.remove('id');

    final id = await db.insert(
      'exercises',
      exerciseMap,
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Falls Name schon existiert (sollte nicht)
    );
    print(
        "Benutzerdefinierte Übung '${exercise.nameDe}' mit ID $id eingefügt.");
    return exercise.copyWith(id: id);
  }

  // *** NEU: Methode zum Abrufen benutzerdefinierter Übungen für das Backup ***
  Future<List<Exercise>> getCustomExercises() async {
    final db = await database;
    final maps = await db.query(
      'exercises',
      where: 'is_custom = ?',
      whereArgs: [1], // Nur benutzerdefinierte
    );
    // Wichtig: 'is_custom' wird von fromMap nicht direkt gelesen, aber das ist ok.
    return maps.map((map) => Exercise.fromMap(map)).toList();
  }

  // *** NEU: Methode zum Importieren benutzerdefinierter Übungen aus dem Backup ***
  Future<void> importCustomExercises(List<Exercise> exercises) async {
    if (exercises.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final exercise in exercises) {
        final exerciseMap = exercise.toMap();
        exerciseMap['is_custom'] =
            1; // Sicherstellen, dass sie als custom markiert sind
        exerciseMap.remove('id'); // ID wird von der DB neu vergeben
        batch.insert(
          'exercises',
          exerciseMap,
          conflictAlgorithm:
              ConflictAlgorithm.ignore, // Ignoriere, falls Name schon existiert
        );
      }
      await batch.commit(noResult: true);
      print(
          "${exercises.length} benutzerdefinierte Übungen erfolgreich importiert.");
    });
  }

  // *** WICHTIG: Methode 'clearAllWorkoutData' anpassen ***
  Future<void> clearAllWorkoutData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('set_logs');
      await txn.delete('workout_logs');
      await txn.delete('routine_set_templates');
      await txn.delete('routine_exercises');
      await txn.delete('routines');
      // *** NEU: Lösche NUR benutzerdefinierte Übungen ***
      await txn.delete('exercises', where: 'is_custom = ?', whereArgs: [1]);
      print("Alle Trainingsdaten (Logs, Routinen, Custom Exercises) gelöscht.");
    });
  }
}
