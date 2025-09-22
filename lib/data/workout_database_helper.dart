// lib/data/workout_database_helper.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:lightweight/util/mapping_prefs.dart';
import 'package:path/path.dart';
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

    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join('assets/db', fileName));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        rethrow;
      }
    }

    // FINALE LÖSUNG: Wir verwenden NUR onUpgrade.
    return await openDatabase(
      path,
      version: 9,
      onUpgrade: _upgradeDB,
    );
  }

  // Diese Methode bringt eine alte, existierende DB auf den neuesten Stand.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print("Führe DB-Upgrade von v$oldVersion auf v$newVersion aus...");
    // Gestaffeltes Upgrade. catchError fängt Fehler ab, falls Spalte schon existiert.
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
              "ALTER TABLE workout_logs ADD COLUMN status TEXT NOT NULL DEFAULT 'completed'")
          .catchError((_) {});
    }
    if (oldVersion < 4) {
      await db
          .execute(
              "ALTER TABLE routine_exercises ADD COLUMN pause_seconds INTEGER")
          .catchError((_) {});
    }
    if (oldVersion < 5) {
      await db
          .execute("ALTER TABLE set_logs ADD COLUMN log_order INTEGER")
          .catchError((_) {});
    }
    // NEUE MIGRATION
    if (oldVersion < 6) {
      print("Upgrade DB auf v6: Entferne set_index aus set_logs...");
      await db.transaction((txn) async {
        // Schritt 1: Umbenennen
        await txn.execute('ALTER TABLE set_logs RENAME TO set_logs_old');

        // Schritt 2: Neu erstellen
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

        // Schritt 3: Daten kopieren
        await txn.execute('''
          INSERT INTO set_logs (id, workout_log_id, exercise_name, set_type, weight_kg, reps, rest_time_seconds, is_completed, log_order)
          SELECT id, workout_log_id, exercise_name, set_type, weight_kg, reps, rest_time_seconds, is_completed, log_order FROM set_logs_old
        ''');

        // Schritt 4: Alte Tabelle löschen
        await txn.execute('DROP TABLE set_logs_old');
      });
    }
    // NEUE MIGRATION
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

      // Migriere bestehende Mappings aus SharedPreferences
      final oldMappings = await MappingPrefs.load();
      if (oldMappings.isNotEmpty) {
        print("Migriere ${oldMappings.length} bestehende Mappings...");
        final batch = db.batch();
        for (final entry in oldMappings.entries) {
          batch.insert(
            'exercise_mapping',
            {'external_name': entry.key, 'target_name': entry.value},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        print("Migration abgeschlossen.");
      }
    }

    print("DB-Upgrade auf v$newVersion erfolgreich abgeschlossen.");
  }

  // 3. NEUE METHODE
  /// Ruft alle gespeicherten Übungs-Mappings aus der Datenbank ab.
  Future<Map<String, String>> getExerciseMappings() async {
    final db = await database;
    final maps = await db.query('exercise_mapping');
    return {
      for (var map in maps)
        (map['external_name'] as String): (map['target_name'] as String)
    };
  }

  // --- EXERCISE MANAGEMENT ---
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('exercises',
        columns: ['category_name'],
        distinct: true,
        orderBy: 'category_name ASC');
    return maps
        .map((map) => map['category_name'] as String?)
        .where((category) => category != null && category.isNotEmpty)
        .cast<String>()
        .toList();
  }

  Future<List<Exercise>> searchExercises(
      {String query = '', List<String> selectedCategories = const []}) async {
    final db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];
    if (query.isNotEmpty) {
      whereClauses.add('(name_de LIKE ? OR name_en LIKE ?)');
      whereArgs.addAll(['%$query%', '%$query%']);
    }
    if (selectedCategories.isNotEmpty) {
      String placeholders =
          List.filled(selectedCategories.length, '?').join(', ');
      whereClauses.add('category_name IN ($placeholders)');
      whereArgs.addAll(selectedCategories);
    }
    String finalWhere =
        whereClauses.isNotEmpty ? whereClauses.join(' AND ') : '';
    final String sql = '''
      SELECT e.*, CASE WHEN sl.id IS NOT NULL THEN 0 ELSE 1 END as sort_priority
      FROM exercises e
      LEFT JOIN (SELECT exercise_name, MAX(id) as id FROM set_logs GROUP BY exercise_name) sl 
      ON e.name_de = sl.exercise_name OR e.name_en = sl.exercise_name
      ${finalWhere.isNotEmpty ? 'WHERE $finalWhere' : ''}
      ORDER BY sort_priority ASC, e.name_de ASC
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, whereArgs);
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }

  Future<Exercise> insertExercise(Exercise exercise) async {
    final db = await database;
    final id = await db.insert('exercises', exercise.toMap());
    return exercise.copyWith(id: id);
  }

  Future<Exercise?> getExerciseByName(String name) async {
    final db = await database;
    final maps = await db.query('exercises',
        where: 'name_de = ? OR name_en = ?', whereArgs: [name, name], limit: 1);
    if (maps.isNotEmpty) {
      return Exercise.fromMap(maps.first);
    }
    return null;
  }

  // --- ROUTINE MANAGEMENT ---
  Future<Routine> createRoutine(String name) async {
    final db = await database;
    final id = await db.insert('routines', {'name': name},
        conflictAlgorithm: ConflictAlgorithm.replace);
    return Routine(id: id, name: name);
  }

  Future<void> updateRoutineName(int routineId, String newName) async {
    final db = await database;
    await db.update('routines', {'name': newName},
        where: 'id = ?', whereArgs: [routineId]);
  }

  Future<RoutineExercise?> addExerciseToRoutine(
      int routineId, int exerciseId) async {
    final db = await database;
    final exerciseMaps =
        await db.query('exercises', where: 'id = ?', whereArgs: [exerciseId]);
    if (exerciseMaps.isEmpty) return null;
    final result = await db.rawQuery(
        'SELECT MAX(exercise_order) as max_order FROM routine_exercises WHERE routine_id = ?',
        [routineId]);
    final maxOrder = (result.first['max_order'] as int?) ?? -1;
    final routineExerciseId = await db.insert('routine_exercises', {
      'routine_id': routineId,
      'exercise_id': exerciseId,
      'exercise_order': maxOrder + 1
    });
    final List<SetTemplate> newTemplates = [];
    for (int i = 0; i < 3; i++) {
      final setId = await db.insert('routine_set_templates', {
        'routine_exercise_id': routineExerciseId,
        'set_index': i,
        'set_type': 'normal'
      });
      newTemplates
          .add(SetTemplate(id: setId, setType: 'normal', targetReps: '8-12'));
    }
    return RoutineExercise(
        id: routineExerciseId,
        exercise: Exercise.fromMap(exerciseMaps.first),
        setTemplates: newTemplates);
  }

  Future<void> removeExerciseFromRoutine(int routineExerciseId) async {
    final db = await database;
    await db.delete('routine_exercises',
        where: 'id = ?', whereArgs: [routineExerciseId]);
  }

  Future<void> updateExerciseOrder(
      int routineId, List<RoutineExercise> orderedExercises) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < orderedExercises.length; i++) {
      final routineExercise = orderedExercises[i];
      batch.update('routine_exercises', {'exercise_order': i},
          where: 'id = ?', whereArgs: [routineExercise.id]);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Routine>> getAllRoutines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('routines', orderBy: 'name ASC');
    return List.generate(
        maps.length, (i) => Routine(id: maps[i]['id'], name: maps[i]['name']));
  }

  Future<Routine?> getRoutineById(int id) async {
    final db = await database;
    final routineMaps =
        await db.query('routines', where: 'id = ?', whereArgs: [id]);
    if (routineMaps.isEmpty) return null;
    final routineExerciseMaps = await db.query('routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [id],
        orderBy: 'exercise_order ASC');
    final List<RoutineExercise> routineExercises = [];
    for (final reMap in routineExerciseMaps) {
      final routineExerciseId = reMap['id'] as int;
      final exerciseId = reMap['exercise_id'] as int;
      final exerciseMaps =
          await db.query('exercises', where: 'id = ?', whereArgs: [exerciseId]);
      if (exerciseMaps.isEmpty) continue;
      final setTemplateMaps = await db.query('routine_set_templates',
          where: 'routine_exercise_id = ?',
          whereArgs: [routineExerciseId],
          orderBy: 'set_index ASC');
      final setTemplates =
          setTemplateMaps.map((stMap) => SetTemplate.fromMap(stMap)).toList();
      routineExercises.add(RoutineExercise(
          id: routineExerciseId,
          exercise: Exercise.fromMap(exerciseMaps.first),
          setTemplates: setTemplates,
          pauseSeconds: reMap['pause_seconds'] as int?));
    }
    return Routine(
        id: id,
        name: routineMaps.first['name'] as String,
        exercises: routineExercises);
  }

  Future<void> updateSetTemplate(SetTemplate setTemplate) async {
    final db = await database;
    await db.update(
        'routine_set_templates',
        {
          'set_type': setTemplate.setType,
          'target_reps': setTemplate.targetReps,
          'target_weight': setTemplate.targetWeight
        },
        where: 'id = ?',
        whereArgs: [setTemplate.id]);
  }

  Future<void> replaceSetTemplatesForExercise(
      int routineExerciseId, List<SetTemplate> newTemplates) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('routine_set_templates',
          where: 'routine_exercise_id = ?', whereArgs: [routineExerciseId]);
      for (int i = 0; i < newTemplates.length; i++) {
        final set = newTemplates[i];
        await txn.insert('routine_set_templates', {
          'routine_exercise_id': routineExerciseId,
          'set_index': i,
          'set_type': set.setType,
          'target_reps': set.targetReps,
          'target_weight': set.targetWeight
        });
      }
    });
  }

  Future<void> deleteRoutine(int routineId) async {
    final db = await database;
    await db.transaction((txn) async {
      final reMaps = await txn.query('routine_exercises',
          where: 'routine_id = ?', whereArgs: [routineId]);
      for (var reMap in reMaps) {
        await txn.delete('routine_set_templates',
            where: 'routine_exercise_id = ?', whereArgs: [reMap['id']]);
      }
      await txn.delete('routine_exercises',
          where: 'routine_id = ?', whereArgs: [routineId]);
      await txn.delete('routines', where: 'id = ?', whereArgs: [routineId]);
    });
  }

  Future<void> duplicateRoutine(int routineId) async {
    final db = await database;
    final originalRoutine = await getRoutineById(routineId);
    if (originalRoutine == null) return;
    await db.transaction((txn) async {
      final newRoutineId = await txn
          .insert('routines', {'name': '${originalRoutine.name} (Kopie)'});
      for (var re in originalRoutine.exercises) {
        final newRoutineExerciseId = await txn.insert('routine_exercises', {
          'routine_id': newRoutineId,
          'exercise_id': re.exercise.id,
          'exercise_order': originalRoutine.exercises.indexOf(re),
          'pause_seconds': re.pauseSeconds
        });
        for (var st in re.setTemplates) {
          await txn.insert('routine_set_templates', {
            'routine_exercise_id': newRoutineExerciseId,
            'set_index': re.setTemplates.indexOf(st),
            'set_type': st.setType,
            'target_reps': st.targetReps,
            'target_weight': st.targetWeight
          });
        }
      }
    });
  }

  Future<void> updatePauseTime(int routineExerciseId, int? seconds) async {
    final db = await database;
    await db.update('routine_exercises', {'pause_seconds': seconds},
        where: 'id = ?', whereArgs: [routineExerciseId]);
  }

  // --- WORKOUT LOGGING ---
  Future<WorkoutLog> startWorkout({String? routineName}) async {
    final db = await database;
    final now = DateTime.now();
    final id = await db.insert('workout_logs', {
      'routine_name': routineName,
      'start_time': now.toIso8601String(),
      'status': 'ongoing'
    });
    return WorkoutLog(
        id: id, routineName: routineName, startTime: now, status: 'ongoing');
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
      conflictAlgorithm: ConflictAlgorithm.replace, // <- statt ignore
    );
    print(
        "--- DEBUG: Insert SetLog (${setLog.exerciseName}, ${setLog.weightKg}kg x ${setLog.reps}) → ID=$id ---");
    return id;
  }

  Future<void> finishWorkout(int workoutLogId) async {
    final db = await database;
    await db.update('workout_logs',
        {'end_time': DateTime.now().toIso8601String(), 'status': 'completed'},
        where: 'id = ?', whereArgs: [workoutLogId]);
  }

  Future<SetLog?> getLastPerformance(String exerciseName) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT * FROM set_logs
      WHERE exercise_name = ? AND set_type != 'warmup' AND reps IS NOT NULL AND weight_kg IS NOT NULL
      ORDER BY id DESC LIMIT 1
    ''', [exerciseName]);
    if (maps.isNotEmpty) return SetLog.fromMap(maps.first);
    return null;
  }

  // --- WORKOUT HISTORY ---
  Future<void> deleteWorkoutLog(int logId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn
          .delete('set_logs', where: 'workout_log_id = ?', whereArgs: [logId]);
      await txn.delete('workout_logs', where: 'id = ?', whereArgs: [logId]);
    });
  }

  Future<List<WorkoutLog>> getWorkoutLogs() async {
    final db = await database;
    final maps = await db.query('workout_logs',
        where: "status = 'completed'", orderBy: 'start_time DESC');
    return maps.map((map) => WorkoutLog.fromMap(map)).toList();
  }

  Future<WorkoutLog?> getWorkoutLogById(int id) async {
    final db = await database;
    print("--- DEBUG: getWorkoutLogById gestartet für ID: $id ---");

    final logMaps =
        await db.query('workout_logs', where: 'id = ?', whereArgs: [id]);
    if (logMaps.isEmpty) {
      print("--- DEBUG: KEINEN WorkoutLog für ID $id gefunden. Breche ab.");
      return null;
    }
    print("--- DEBUG: WorkoutLog gefunden: ${logMaps.first}");

    final setMaps = await db.query('set_logs',
        where: 'workout_log_id = ?', whereArgs: [id], orderBy: 'id ASC');

    // *** DER ENTSCHEIDENDE DEBUG-PUNKT ***
    print(
        "--- DEBUG: Für workout_log_id $id wurden ${setMaps.length} Sätze in der DB gefunden.");
    if (setMaps.isNotEmpty) {
      print("--- DEBUG: Erster gefundener Satz: ${setMaps.first}");
    }

    final sets = setMaps.map((map) => SetLog.fromMap(map)).toList();

    return WorkoutLog.fromMap(logMaps.first, sets: sets);
  }

  Future<WorkoutLog?> getOngoingWorkout() async {
    final db = await database;
    final maps = await db.query('workout_logs',
        where: "status = 'ongoing'", orderBy: 'start_time DESC', limit: 1);
    if (maps.isNotEmpty) {
      return getWorkoutLogById(maps.first['id'] as int);
    }
    return null;
  }

  Future<WorkoutLog?> getLatestWorkoutLog() async {
    final db = await database;
    final maps =
        await db.query('workout_logs', orderBy: 'start_time DESC', limit: 1);
    if (maps.isNotEmpty) {
      return WorkoutLog.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'workout_logs',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
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
    final maps = await db.query('routines',
        where: 'name = ?', whereArgs: [name], limit: 1);
    if (maps.isNotEmpty) {
      return getRoutineById(maps.first['id'] as int);
    }
    return null;
  }

  Future<void> updateWorkoutLogDetails(
      int logId, DateTime startTime, String? notes) async {
    final db = await database;
    await db.update('workout_logs',
        {'start_time': startTime.toIso8601String(), 'notes': notes},
        where: 'id = ?', whereArgs: [logId]);
  }

  Future<void> updateSetLogs(List<SetLog> updatedSets) async {
    if (updatedSets.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final setLog in updatedSets) {
      batch.update('set_logs', setLog.toMap(),
          where: 'id = ?', whereArgs: [setLog.id]);
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
      // KORREKTUR 1: Prüfe auf Null, bevor die ID verwendet wird.
      if (routine.id != null) {
        final detailedRoutine =
            await getRoutineById(routine.id!); // routine.id! ist jetzt sicher
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

  Future<void> clearAllWorkoutData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('set_logs');
      await txn.delete('workout_logs');
      await txn.delete('routine_set_templates');
      await txn.delete('routine_exercises');
      await txn.delete('routines');
    });
  }

  Future<void> importWorkoutData({
    required List<Routine> routines,
    required List<WorkoutLog> workoutLogs,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      // Routinen importieren
      for (final routine in routines) {
        final newRoutineId =
            await txn.insert('routines', {'name': routine.name});
        for (final re in routine.exercises) {
          final newReId = await txn.insert('routine_exercises', {
            'routine_id': newRoutineId,
            'exercise_id': re.exercise.id,
            'exercise_order': routine.exercises.indexOf(re),
            'pause_seconds': re.pauseSeconds,
          });
          for (final st in re.setTemplates) {
            // KORREKTUR: Map erstellen und alte ID entfernen
            final stMap = st.toMap();
            stMap.remove('id');
            stMap['routine_exercise_id'] = newReId;
            stMap['set_index'] =
                re.setTemplates.indexOf(st); // Index für die Reihenfolge setzen
            await txn.insert('routine_set_templates', stMap);
          }
        }
      }

      // Workout Logs importieren
      for (final log in workoutLogs) {
        // KORREKTUR 1: Erstelle eine neue Map aus dem WorkoutLog-Objekt.
        final logMap = log.toMap();

        // KORREKTUR 2: Entferne die alte ID. Dies ist SEHR WICHTIG,
        // damit die Datenbank eine neue, eindeutige ID per AUTOINCREMENT vergeben kann.
        logMap.remove('id');

        // KORREKTUR 3: Setze den Status explizit auf 'completed'.
        // Das stellt sicher, dass importierte Workouts im Verlauf erscheinen,
        // da der Verlauf nur Einträge mit diesem Status anzeigt.
        logMap['status'] = 'completed';

        final newLogId = await txn.insert('workout_logs', logMap);

        for (final setLog in log.sets) {
          // Wiederhole den Prozess für jeden Satz (SetLog).
          final setMap = setLog.toMap();
          setMap.remove('id'); // Alte ID entfernen

          // Die workout_log_id MUSS auf die ID des GERADE ERSTELLTEN Logs zeigen.
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

  /// Speichert die Mappings dauerhaft UND wendet sie auf bestehende Logs an.
  Future<void> applyExerciseNameMapping(Map<String, String> map) async {
    if (map.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      // Schritt 1: Mappings in der neuen Tabelle speichern/aktualisieren
      final batch = txn.batch();
      for (final e in map.entries) {
        batch.insert(
          'exercise_mapping',
          {'external_name': e.key, 'target_name': e.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);

      // Schritt 2: Mappings auf die bestehenden set_logs anwenden
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

  /// Ruft alle einzigartigen Muskelgruppen aus der Datenbank ab.
  Future<List<String>> getAllMuscleGroups() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exercises',
      columns: ['primaryMuscles', 'secondaryMuscles'],
      distinct: true,
    );

    final Set<String> allMuscles = {};

    // Helferfunktion zum sicheren Parsen des JSON-Strings
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

  /// Gibt ein Set von Tagen (1-31) zurück, an denen im gegebenen Monat Workouts geloggt wurden.
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
        lastDayOfMonth.toIso8601String()
      ],
    );

    if (maps.isEmpty) return {};

    return maps
        .map((map) => DateTime.parse(map['start_time'] as String).day)
        .toSet();
  }
}
