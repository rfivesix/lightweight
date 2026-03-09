// lib/data/workout_database_helper.dart

import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'database_helper.dart';
import 'drift_database.dart' as db;
import '../models/exercise.dart';
import '../models/routine.dart';
import '../models/routine_exercise.dart';
import '../models/set_log.dart';
import '../models/set_template.dart';
import '../models/workout_log.dart';

/// Helper class for managing workout-specific data in the Drift database.
///
/// Handles routines, exercises, set templates, and historical workout logs.
class WorkoutDatabaseHelper {
  /// Singleton instance of [WorkoutDatabaseHelper].
  static final WorkoutDatabaseHelper instance = WorkoutDatabaseHelper._init();

  WorkoutDatabaseHelper._init();

  // Zugriff auf die zentrale Drift-Instanz aus DatabaseHelper
  Future<db.AppDatabase> get database async => DatabaseHelper.instance.database;

  // ===========================================================================
  // HILFSMETHODEN (Mapping & IDs)
  // ===========================================================================

  /// Wandelt eine lokale ID (int) in die UUID (String) um, die für Relationen benötigt wird.
  Future<String?> _getUuidFromLocalId<T extends drift.Table, D>(
    drift.TableInfo<T, D> table,
    int localId,
  ) async {
    final dbInstance = await database;
    // Annahme: Alle unsere Tabellen haben 'localId' und 'id' (UUID) via HybridId Mixin
    final query = dbInstance.select(table)
      ..where((tbl) => (tbl as dynamic).localId.equals(localId));
    final row = await query.getSingleOrNull();
    return (row as dynamic)?.id;
  }

  /// Wandelt eine UUID in die lokale ID um (falls nötig)
  Future<int?> _getLocalIdFromUuid<T extends drift.Table, D>(
    drift.TableInfo<T, D> table,
    String uuid,
  ) async {
    final dbInstance = await database;
    final query = dbInstance.select(table)
      ..where((tbl) => (tbl as dynamic).id.equals(uuid));
    final row = await query.getSingleOrNull();
    return (row as dynamic)?.localId;
  }

  List<String> _parseMuscleList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      // Fallback für CSV (Legacy Daten)
      if (jsonStr.contains(',')) {
        return jsonStr.split(',').map((e) => e.trim()).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Mappt eine Drift Exercise Row auf das App Model
  Exercise _mapExerciseToModel(db.Exercise row) {
    return Exercise(
      id: row.localId,
      nameDe: row.nameDe,
      nameEn: row.nameEn,
      descriptionDe: row.descriptionDe ?? '',
      descriptionEn: row.descriptionEn ?? '',
      categoryName: row.categoryName ?? 'Other',
      imagePath: row.imagePath,
      primaryMuscles: _parseMuscleList(row.musclesPrimary),
      secondaryMuscles: _parseMuscleList(row.musclesSecondary),
    );
  }

  // ===========================================================================
  // EXERCISES
  // ===========================================================================

  /// Retrieves all unique exercise categories present in the database.
  Future<List<String>> getAllCategories() async {
    final dbInstance = await database;
    final query = dbInstance.selectOnly(dbInstance.exercises, distinct: true)
      ..addColumns([dbInstance.exercises.categoryName]);

    final rows = await query.get();
    final categories = rows
        .map((r) => r.read(dbInstance.exercises.categoryName))
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toList();

    return categories..sort();
  }

  Future<List<String>> getAllMuscleGroups() async {
    final dbInstance = await database;
    final exercises = await dbInstance.select(dbInstance.exercises).get();
    final Set<String> muscles = {};

    for (var ex in exercises) {
      muscles.addAll(_parseMuscleList(ex.musclesPrimary));
      muscles.addAll(_parseMuscleList(ex.musclesSecondary));
    }
    return muscles.toList()..sort();
  }

  /// Searches for exercises matching the [query] and [selectedCategories].
  Future<List<Exercise>> searchExercises({
    String query = '',
    List<String> selectedCategories = const [],
  }) async {
    final dbInstance = await database;

    var stmt = dbInstance.select(dbInstance.exercises);

    if (query.isNotEmpty) {
      stmt = stmt
        ..where(
            (tbl) => tbl.nameDe.like('%$query%') | tbl.nameEn.like('%$query%'));
    }

    if (selectedCategories.isNotEmpty) {
      stmt = stmt..where((tbl) => tbl.categoryName.isIn(selectedCategories));
    }

    stmt = stmt..orderBy([(t) => drift.OrderingTerm(expression: t.nameDe)]);

    final rows = await stmt.get();
    return rows.map(_mapExerciseToModel).toList();
  }

  Future<Exercise?> getExerciseByName(String name) async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.nameDe.equals(name) | tbl.nameEn.equals(name))
          ..limit(1))
        .getSingleOrNull();

    return row != null ? _mapExerciseToModel(row) : null;
  }

  Future<Exercise> insertExercise(Exercise exercise) async {
    final dbInstance = await database;

    final companion = db.ExercisesCompanion(
      nameDe: drift.Value(exercise.nameDe),
      nameEn: drift.Value(exercise.nameEn),
      descriptionDe: drift.Value(exercise.descriptionDe),
      descriptionEn: drift.Value(exercise.descriptionEn),
      categoryName: drift.Value(exercise.categoryName),
      musclesPrimary: drift.Value(jsonEncode(exercise.primaryMuscles)),
      musclesSecondary: drift.Value(jsonEncode(exercise.secondaryMuscles)),
      imagePath: drift.Value(exercise.imagePath),
      isCustom: const drift.Value(true),
    );

    final row =
        await dbInstance.into(dbInstance.exercises).insertReturning(companion);
    return _mapExerciseToModel(row);
  }

  Future<List<Exercise>> getCustomExercises() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.isCustom.equals(true)))
        .get();
    return rows.map(_mapExerciseToModel).toList();
  }

  Future<void> importCustomExercises(List<Exercise> exercises) async {
    final dbInstance = await database;
    await dbInstance.batch((batch) {
      for (final ex in exercises) {
        batch.insert(
          dbInstance.exercises,
          db.ExercisesCompanion(
            nameDe: drift.Value(ex.nameDe),
            nameEn: drift.Value(ex.nameEn),
            descriptionDe: drift.Value(ex.descriptionDe),
            descriptionEn: drift.Value(ex.descriptionEn),
            categoryName: drift.Value(ex.categoryName),
            musclesPrimary: drift.Value(jsonEncode(ex.primaryMuscles)),
            musclesSecondary: drift.Value(jsonEncode(ex.secondaryMuscles)),
            imagePath: drift.Value(ex.imagePath),
            isCustom: const drift.Value(true),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
  }

  // ===========================================================================
  // ROUTINES
  // ===========================================================================

  Future<List<Routine>> getAllRoutines() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(dbInstance.routines)
          ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
        .get();

    return rows.map((r) => Routine(id: r.localId, name: r.name)).toList();
  }

  Future<List<Routine>> getAllRoutinesWithDetails() async {
    final basicRoutines = await getAllRoutines();
    final detailed = <Routine>[];
    for (var r in basicRoutines) {
      if (r.id != null) {
        final d = await getRoutineById(r.id!);
        if (d != null) detailed.add(d);
      }
    }
    return detailed;
  }

  Future<Routine> createRoutine(String name) async {
    final dbInstance = await database;
    final row = await dbInstance.into(dbInstance.routines).insertReturning(
          db.RoutinesCompanion(name: drift.Value(name)),
        );
    return Routine(id: row.localId, name: row.name);
  }

  Future<void> updateRoutineName(int routineId, String newName) async {
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.routines)
          ..where((tbl) => tbl.localId.equals(routineId)))
        .write(db.RoutinesCompanion(name: drift.Value(newName)));
  }

  // FIX: Parameter initialSetCount hinzugefügt
  Future<RoutineExercise?> addExerciseToRoutine(int routineId, int exerciseId,
      {int initialSetCount = 3}) async {
    final dbInstance = await database;

    // UUIDs holen
    final routineUuid =
        await _getUuidFromLocalId(dbInstance.routines, routineId);
    final exerciseUuid =
        await _getUuidFromLocalId(dbInstance.exercises, exerciseId);

    if (routineUuid == null || exerciseUuid == null) return null;

    // Max Order ermitteln
    final maxOrderQuery = dbInstance.selectOnly(dbInstance.routineExercises)
      ..addColumns([dbInstance.routineExercises.orderIndex.max()])
      ..where(dbInstance.routineExercises.routineId.equals(routineUuid));
    final maxOrderResult = await maxOrderQuery.getSingle();
    final maxOrder =
        maxOrderResult.read(dbInstance.routineExercises.orderIndex.max()) ?? -1;

    // RoutineExercise einfügen
    final reRow =
        await dbInstance.into(dbInstance.routineExercises).insertReturning(
              db.RoutineExercisesCompanion(
                routineId: drift.Value(routineUuid),
                exerciseId: drift.Value(exerciseUuid),
                orderIndex: drift.Value(maxOrder + 1),
              ),
            );

    // FIX: Dynamische Anzahl von Sets (statt hardcoded 3)
    final templates = <SetTemplate>[];
    for (int i = 0; i < initialSetCount; i++) {
      final stRow =
          await dbInstance.into(dbInstance.routineSetTemplates).insertReturning(
                db.RoutineSetTemplatesCompanion(
                  routineExerciseId: drift.Value(reRow.id),
                  setType: const drift.Value('normal'),
                  targetReps: const drift.Value('8-12'),
                ),
              );
      templates.add(SetTemplate(
          id: stRow.localId, setType: 'normal', targetReps: '8-12'));
    }

    // Exercise Daten laden für Rückgabe
    final exRow = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) => tbl.id.equals(exerciseUuid)))
        .getSingle();

    return RoutineExercise(
      id: reRow.localId,
      exercise: _mapExerciseToModel(exRow),
      setTemplates: templates,
    );
  }

  Future<void> removeExerciseFromRoutine(int routineExerciseId) async {
    final dbInstance = await database;
    // OnDelete Cascade in DB Definition sollte Kinder löschen
    await (dbInstance.delete(dbInstance.routineExercises)
          ..where((tbl) => tbl.localId.equals(routineExerciseId)))
        .go();
  }

  Future<void> updateExerciseOrder(
      int routineId, List<RoutineExercise> orderedExercises) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      for (int i = 0; i < orderedExercises.length; i++) {
        final re = orderedExercises[i];
        if (re.id != null) {
          await (dbInstance.update(dbInstance.routineExercises)
                ..where((tbl) => tbl.localId.equals(re.id!)))
              .write(db.RoutineExercisesCompanion(orderIndex: drift.Value(i)));
        }
      }
    });
  }

  /// Retrieves a detailed [Routine] including all exercises and set templates.
  Future<Routine?> getRoutineById(int id) async {
    final dbInstance = await database;

    // 1. Routine laden
    final routineRow = await (dbInstance.select(dbInstance.routines)
          ..where((tbl) => tbl.localId.equals(id)))
        .getSingleOrNull();

    if (routineRow == null) return null;

    // 2. RoutineExercises laden
    final routineExercisesQuery = dbInstance
        .select(dbInstance.routineExercises)
        .join([
      drift.innerJoin(
          dbInstance.exercises,
          dbInstance.exercises.id
              .equalsExp(dbInstance.routineExercises.exerciseId))
    ])
      ..where(dbInstance.routineExercises.routineId.equals(routineRow.id))
      ..orderBy([
        drift.OrderingTerm(expression: dbInstance.routineExercises.orderIndex)
      ]);

    final reRows = await routineExercisesQuery.get();
    final List<RoutineExercise> exercisesList = [];

    for (final row in reRows) {
      final reData = row.readTable(dbInstance.routineExercises);
      final exData = row.readTable(dbInstance.exercises);

      // 3. SetTemplates laden
      final templates = await (dbInstance.select(dbInstance.routineSetTemplates)
            ..where((tbl) => tbl.routineExerciseId.equals(reData.id))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.localId)]))
          .get();

      final setTemplates = templates
          .map((t) => SetTemplate(
                id: t.localId,
                setType: t.setType,
                targetReps: t.targetReps,
                targetWeight: t.targetWeight,
                targetRir: t.targetRir, // <--- NEU
              ))
          .toList();

      exercisesList.add(RoutineExercise(
        id: reData.localId,
        exercise: _mapExerciseToModel(exData),
        setTemplates: setTemplates,
        pauseSeconds: reData.pauseSeconds,
      ));
    }

    return Routine(
      id: routineRow.localId,
      name: routineRow.name,
      exercises: exercisesList,
    );
  }

  Future<void> updateSetTemplate(SetTemplate setTemplate) async {
    if (setTemplate.id == null) return;
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.routineSetTemplates)
          ..where((tbl) => tbl.localId.equals(setTemplate.id!)))
        .write(db.RoutineSetTemplatesCompanion(
      setType: drift.Value(setTemplate.setType),
      targetReps: drift.Value(setTemplate.targetReps),
      targetWeight: drift.Value(setTemplate.targetWeight),
      targetRir: drift.Value(setTemplate.targetRir), // <--- NEU
    ));
  }

  Future<void> replaceSetTemplatesForExercise(
      int routineExerciseId, List<SetTemplate> newTemplates) async {
    final dbInstance = await database;
    final reUuid = await _getUuidFromLocalId(
        dbInstance.routineExercises, routineExerciseId);
    if (reUuid == null) return;

    await dbInstance.transaction(() async {
      // Löschen
      await (dbInstance.delete(dbInstance.routineSetTemplates)
            ..where((tbl) => tbl.routineExerciseId.equals(reUuid)))
          .go();

      // Neu einfügen
      for (final t in newTemplates) {
        await dbInstance.into(dbInstance.routineSetTemplates).insert(
              db.RoutineSetTemplatesCompanion(
                routineExerciseId: drift.Value(reUuid),
                setType: drift.Value(t.setType),
                targetReps: drift.Value(t.targetReps),
                targetWeight: drift.Value(t.targetWeight),
                targetRir: drift.Value(t.targetRir), // <--- NEU
              ),
            );
      }
    });
  }

  Future<void> deleteRoutine(int routineId) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.routines)
          ..where((tbl) => tbl.localId.equals(routineId)))
        .go();
  }

  Future<void> duplicateRoutine(int routineId) async {
    final original = await getRoutineById(routineId);
    if (original == null) return;

    final newRoutine = await createRoutine('${original.name} (Kopie)');
    if (newRoutine.id == null) return;

    for (final re in original.exercises) {
      if (re.exercise.id == null) continue;
      // Exercise hinzufügen (erstellt default templates)
      final newRe = await addExerciseToRoutine(newRoutine.id!, re.exercise.id!);

      if (newRe != null) {
        // Templates überschreiben mit den kopierten Werten
        await replaceSetTemplatesForExercise(newRe.id!, re.setTemplates);
        // Pause kopieren
        await updatePauseTime(newRe.id!, re.pauseSeconds);
      }
    }
  }

  Future<void> updatePauseTime(int routineExerciseId, int? seconds) async {
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.routineExercises)
          ..where((tbl) => tbl.localId.equals(routineExerciseId)))
        .write(
            db.RoutineExercisesCompanion(pauseSeconds: drift.Value(seconds)));
  }

  Future<Routine?> getRoutineByName(String name) async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.routines)
          ..where((tbl) => tbl.name.equals(name))
          ..limit(1))
        .getSingleOrNull();

    if (row != null) {
      return getRoutineById(row.localId);
    }
    return null;
  }

  // ===========================================================================
  // WORKOUT LOGGING
  // ===========================================================================

  /// Creates a new [WorkoutLog] and marks it as "ongoing".
  Future<WorkoutLog> startWorkout({String? routineName}) async {
    final dbInstance = await database;
    final now = DateTime.now();

    // Versuche Routine-UUID zu finden für Verknüpfung (optional)
    String? routineId;
    String? routineNameSnapshot = routineName;

    if (routineName != null) {
      final rRow = await (dbInstance.select(dbInstance.routines)
            ..where((tbl) => tbl.name.equals(routineName))
            ..limit(1))
          .getSingleOrNull();
      routineId = rRow?.id;
    }

    final row = await dbInstance
        .into(dbInstance.workoutLogs)
        .insertReturning(db.WorkoutLogsCompanion(
          startTime: drift.Value(now),
          status: const drift.Value('ongoing'),
          routineId: drift.Value(routineId),
          routineNameSnapshot: drift.Value(routineNameSnapshot),
        ));

    return WorkoutLog(
      id: row.localId,
      routineName: routineName,
      startTime: row.startTime,
      // status field removed from WorkoutLog model in UI, handling internally if needed
    );
  }

  Future<void> finishWorkout(int workoutLogId) async {
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.workoutLogs)
          ..where((tbl) => tbl.localId.equals(workoutLogId)))
        .write(db.WorkoutLogsCompanion(
      endTime: drift.Value(DateTime.now()),
      status: const drift.Value('completed'),
    ));
  }

  Future<int> insertSetLog(SetLog setLog) async {
    final dbInstance = await database;
    final workoutLogUuid =
        await _getUuidFromLocalId(dbInstance.workoutLogs, setLog.workoutLogId);

    if (workoutLogUuid == null) {
      throw Exception(
          "WorkoutLog UUID not found for localId ${setLog.workoutLogId}");
    }

    // Exercise UUID suchen
    String? exerciseUuid;
    final exRow = await (dbInstance.select(dbInstance.exercises)
          ..where((tbl) =>
              tbl.nameDe.equals(setLog.exerciseName) |
              tbl.nameEn.equals(setLog.exerciseName))
          ..limit(1))
        .getSingleOrNull();
    exerciseUuid = exRow?.id;

    final companion = db.SetLogsCompanion(
      workoutLogId: drift.Value(workoutLogUuid),
      exerciseId: drift.Value(exerciseUuid),
      exerciseNameSnapshot: drift.Value(setLog.exerciseName),
      weight: drift.Value(setLog.weightKg),
      reps: drift.Value(setLog.reps),
      setType: drift.Value(setLog.setType),
      restTimeSeconds: drift.Value(setLog.restTimeSeconds),
      isCompleted: drift.Value(setLog.isCompleted ?? false),
      logOrder: drift.Value(setLog.log_order ?? 0),
      notes: drift.Value(setLog.notes),
      distance: drift.Value(setLog.distanceKm),
      durationSeconds: drift.Value(setLog.durationSeconds),
      rpe: drift.Value(setLog.rpe),
      rir: drift.Value(setLog.rir), // Jetzt direkt int, perfekt!
    );

    if (setLog.id != null) {
      // Update
      await (dbInstance.update(dbInstance.setLogs)
            ..where((tbl) => tbl.localId.equals(setLog.id!)))
          .write(companion);
      return setLog.id!;
    } else {
      // Insert
      final row =
          await dbInstance.into(dbInstance.setLogs).insertReturning(companion);
      return row.localId;
    }
  }

  Future<WorkoutLog?> getWorkoutLogById(int id) async {
    final dbInstance = await database;
    final logRow = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.localId.equals(id)))
        .getSingleOrNull();

    if (logRow == null) return null;

    final setRows = await (dbInstance.select(dbInstance.setLogs)
          ..where((tbl) => tbl.workoutLogId.equals(logRow.id))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.logOrder)]))
        .get();

    final sets = setRows
        .map((row) => SetLog(
              id: row.localId,
              workoutLogId: id,
              exerciseName: row.exerciseNameSnapshot ?? 'Unknown',
              setType: row.setType,
              weightKg: row.weight,
              reps: row.reps,
              restTimeSeconds: row.restTimeSeconds,
              isCompleted: row.isCompleted,
              log_order: row.logOrder,
              notes: row.notes,
              distanceKm: row.distance,
              durationSeconds: row.durationSeconds,
              rpe: row.rpe,
              rir: row.rir, // Direkt übernehmen
            ))
        .toList();

    return WorkoutLog(
      id: logRow.localId,
      routineName: logRow.routineNameSnapshot,
      startTime: logRow.startTime,
      endTime: logRow.endTime,
      notes: logRow.notes,
      sets: sets,
    );
  }

  Future<void> updateSetLogs(List<SetLog> updatedSets) async {
    if (updatedSets.isEmpty) return;
    final dbInstance = await database;
    await dbInstance.batch((batch) {
      for (final s in updatedSets) {
        if (s.id != null) {
          batch.update(
            dbInstance.setLogs,
            db.SetLogsCompanion(
              weight: drift.Value(s.weightKg),
              reps: drift.Value(s.reps),
              isCompleted: drift.Value(s.isCompleted ?? false),
              notes: drift.Value(s.notes),
              rir: drift.Value(s.rir),
              // FIX: logOrder muss mit aktualisiert werden, damit Reordering gespeichert wird
              logOrder: drift.Value(s.log_order ?? 0),
            ),
            where: (tbl) => tbl.localId.equals(s.id!),
          );
        }
      }
    });
  }

  Future<SetLog?> getLastPerformance(String exerciseName) async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.setLogs)
      ..where((tbl) =>
          tbl.exerciseNameSnapshot.equals(exerciseName) &
          tbl.setType.isNotValue('warmup') &
          tbl.weight.isNotNull() &
          tbl.reps.isNotNull())
      ..orderBy([
        (t) => drift.OrderingTerm(
            expression: t.localId, mode: drift.OrderingMode.desc)
      ])
      ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final wLogId =
        await _getLocalIdFromUuid(dbInstance.workoutLogs, row.workoutLogId);

    return SetLog(
      id: row.localId,
      workoutLogId: wLogId ?? 0,
      exerciseName: row.exerciseNameSnapshot ?? 'Unknown',
      setType: row.setType,
      weightKg: row.weight,
      reps: row.reps,
      isCompleted: row.isCompleted,
      rir: row.rir, // Direkt übernehmen
    );
  }

  // ===========================================================================
  // WORKOUT HISTORY
  // ===========================================================================

  Future<void> deleteWorkoutLog(int logId) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.workoutLogs)
          ..where((tbl) => tbl.localId.equals(logId)))
        .go();
  }

  Future<List<WorkoutLog>> getWorkoutLogs() async {
    // Gibt nur abgeschlossene Logs zurück (Basis-Infos)
    final dbInstance = await database;
    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('completed'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.startTime, mode: drift.OrderingMode.desc)
          ]))
        .get();

    return rows
        .map((r) => WorkoutLog(
              id: r.localId,
              routineName: r.routineNameSnapshot,
              startTime: r.startTime,
              endTime: r.endTime,
              notes: r.notes,
            ))
        .toList();
  }

  Future<List<WorkoutLog>> getFullWorkoutLogs() async {
    final basicLogs = await getWorkoutLogs();
    final fullLogs = <WorkoutLog>[];
    for (var log in basicLogs) {
      if (log.id != null) {
        final full = await getWorkoutLogById(log.id!);
        if (full != null) fullLogs.add(full);
      }
    }
    return fullLogs;
  }

  Future<WorkoutLog?> getLatestWorkoutLog() async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.workoutLogs)
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.startTime, mode: drift.OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();

    if (row != null) {
      return getWorkoutLogById(row.localId);
    }
    return null;
  }

  Future<List<WorkoutLog>> getWorkoutLogsForDateRange(
      DateTime start, DateTime end) async {
    final dbInstance = await database;

    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) =>
              tbl.startTime.isBetweenValues(effectiveStart, effectiveEnd) &
              tbl.status.equals('completed'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.startTime, mode: drift.OrderingMode.desc)
          ]))
        .get();

    final list = <WorkoutLog>[];
    for (var r in rows) {
      final full = await getWorkoutLogById(r.localId);
      if (full != null) list.add(full);
    }
    return list;
  }

  Future<void> updateWorkoutLogDetails(
      int logId, DateTime startTime, String? notes) async {
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.workoutLogs)
          ..where((tbl) => tbl.localId.equals(logId)))
        .write(db.WorkoutLogsCompanion(
      startTime: drift.Value(startTime),
      notes: drift.Value(notes),
    ));
  }

  Future<void> deleteSetLogs(List<int> idsToDelete) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.setLogs)
          ..where((tbl) => tbl.localId.isIn(idsToDelete)))
        .go();
  }

  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) async {
    final full = await getWorkoutLogById(workoutLogId);
    return full?.sets ?? [];
  }

  // ===========================================================================
  // MISC / BACKUP / SPECIALS
  // ===========================================================================

  Future<void> importWorkoutData(
      {required List<Routine> routines,
      required List<WorkoutLog> workoutLogs}) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      // Routines
      for (final r in routines) {
        final rRow = await dbInstance
            .into(dbInstance.routines)
            .insertReturning(db.RoutinesCompanion(name: drift.Value(r.name)));
        final newRoutineId = rRow.id; // UUID

        for (final re in r.exercises) {
          // Exercise Mapping checken (Name -> UUID)
          // Wir suchen die Übung in der DB. Falls custom und im Backup vorhanden, sollte sie bereits importiert sein.
          final exModel = re.exercise;
          final exRow = await (dbInstance.select(dbInstance.exercises)
                ..where((tbl) =>
                    tbl.nameEn.equals(exModel.nameEn) |
                    tbl.nameDe.equals(exModel.nameDe))
                ..limit(1))
              .getSingleOrNull();

          if (exRow == null) continue;

          final reRow = await dbInstance
              .into(dbInstance.routineExercises)
              .insertReturning(db.RoutineExercisesCompanion(
                routineId: drift.Value(newRoutineId),
                exerciseId: drift.Value(exRow.id),
                orderIndex: const drift.Value(
                    0), // Einfachheitshalber, korrekter Index wäre besser
                pauseSeconds: drift.Value(re.pauseSeconds),
              ));

          // Templates
          for (final t in re.setTemplates) {
            await dbInstance
                .into(dbInstance.routineSetTemplates)
                .insert(db.RoutineSetTemplatesCompanion(
                  routineExerciseId: drift.Value(reRow.id),
                  setType: drift.Value(t.setType),
                  targetReps: drift.Value(t.targetReps),
                  targetWeight: drift.Value(t.targetWeight),
                ));
          }
        }
      }

      // WorkoutLogs
      for (final w in workoutLogs) {
        final wRow = await dbInstance
            .into(dbInstance.workoutLogs)
            .insertReturning(db.WorkoutLogsCompanion(
              startTime: drift.Value(w.startTime),
              endTime: drift.Value(w.endTime),
              status: const drift.Value('completed'),
              routineNameSnapshot: drift.Value(w.routineName),
              notes: drift.Value(w.notes),
            ));

        for (final s in w.sets) {
          final exRow = await (dbInstance.select(dbInstance.exercises)
                ..where((tbl) =>
                    tbl.nameEn.equals(s.exerciseName) |
                    tbl.nameDe.equals(s.exerciseName))
                ..limit(1))
              .getSingleOrNull();

          await dbInstance.into(dbInstance.setLogs).insert(db.SetLogsCompanion(
                workoutLogId: drift.Value(wRow.id),
                exerciseNameSnapshot: drift.Value(s.exerciseName),
                exerciseId: drift.Value(exRow?.id),
                weight: drift.Value(s.weightKg),
                reps: drift.Value(s.reps),
                setType: drift.Value(s.setType),
                isCompleted: const drift.Value(true),
                logOrder: drift.Value(s.log_order ?? 0),
              ));
        }
      }
    });
  }

  Future<List<String>> findUnknownExerciseNames() async {
    final dbInstance = await database;
    // Drift hat keinen direkten Weg für dieses komplexe Join + IS NULL Check in Dart-Syntax
    // Daher Custom Query.
    final result = await dbInstance.customSelect('''
      SELECT DISTINCT sl.exercise_name_snapshot
      FROM set_logs sl
      LEFT JOIN exercises e ON sl.exercise_id = e.id
      WHERE e.id IS NULL AND sl.exercise_name_snapshot IS NOT NULL
      ORDER BY sl.exercise_name_snapshot ASC
    ''').get();

    return result.map((r) => r.read<String>('exercise_name_snapshot')).toList();
  }

  Future<void> applyExerciseNameMapping(Map<String, String> map) async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      for (final entry in map.entries) {
        final oldName = entry.key;
        final newName = entry.value;

        // Finde die neue Exercise UUID
        final exRow = await (dbInstance.select(dbInstance.exercises)
              ..where((tbl) =>
                  tbl.nameEn.equals(newName) | tbl.nameDe.equals(newName))
              ..limit(1))
            .getSingleOrNull();

        if (exRow != null) {
          // Update SetLogs
          await (dbInstance.update(dbInstance.setLogs)
                ..where((tbl) => tbl.exerciseNameSnapshot.equals(oldName)))
              .write(db.SetLogsCompanion(
            exerciseId: drift.Value(exRow.id),
            exerciseNameSnapshot: drift.Value(newName),
          ));
        }
      }
    });
  }

  Future<Set<int>> getWorkoutDaysInMonth(DateTime month) async {
    final dbInstance = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final rows = await (dbInstance.selectOnly(dbInstance.workoutLogs)
          ..addColumns([dbInstance.workoutLogs.startTime])
          ..where(dbInstance.workoutLogs.startTime.isBetweenValues(start, end)))
        .get();

    return rows
        .map((r) => r.read(dbInstance.workoutLogs.startTime)!.day)
        .toSet();
  }

  Future<List<SetLog>> getLastSetsForExercise(String exerciseName) async {
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.workoutLogs).join([
      drift.innerJoin(dbInstance.setLogs,
          dbInstance.setLogs.workoutLogId.equalsExp(dbInstance.workoutLogs.id))
    ])
      ..where(dbInstance.setLogs.exerciseNameSnapshot.equals(exerciseName) &
          dbInstance.workoutLogs.status.equals('completed'))
      ..orderBy([
        drift.OrderingTerm(
            expression: dbInstance.workoutLogs.startTime,
            mode: drift.OrderingMode.desc)
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    if (result == null) return [];

    final logUuid = result.readTable(dbInstance.workoutLogs).id;
    final wLogId = result.readTable(dbInstance.workoutLogs).localId;

    final setRows = await (dbInstance.select(dbInstance.setLogs)
          ..where((tbl) =>
              tbl.workoutLogId.equals(logUuid) &
              tbl.exerciseNameSnapshot.equals(exerciseName))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.logOrder)]))
        .get();

    return setRows
        .map((r) => SetLog(
              id: r.localId,
              workoutLogId: wLogId,
              exerciseName: r.exerciseNameSnapshot ?? '',
              setType: r.setType,
              weightKg: r.weight,
              reps: r.reps,
              isCompleted: r.isCompleted,
              rir: r.rir, // Direkt übernehmen
            ))
        .toList();
  }

  Future<void> clearAllWorkoutData() async {
    final dbInstance = await database;
    await dbInstance.transaction(() async {
      await dbInstance.delete(dbInstance.setLogs).go();
      await dbInstance.delete(dbInstance.workoutLogs).go();
      await dbInstance.delete(dbInstance.routineSetTemplates).go();
      await dbInstance.delete(dbInstance.routineExercises).go();
      await dbInstance.delete(dbInstance.routines).go();
      // Lösche nur custom exercises
      await (dbInstance.delete(dbInstance.exercises)
            ..where((tbl) => tbl.isCustom.equals(true)))
          .go();
    });
  }

  Future<WorkoutLog?> getOngoingWorkout() async {
    final dbInstance = await database;
    final row = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('ongoing'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.startTime, mode: drift.OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();

    if (row != null) {
      return getWorkoutLogById(row.localId);
    }
    return null;
  }

  // ===========================================================================
  // ANALYTICS: Personal Records
  // ===========================================================================

  /// Returns all-time personal records (best sets) keyed by exercise name.
  ///
  /// For each exercise, the best set is the one with the highest weight.
  /// If weights are equal, the set with more reps wins.
  Future<Map<String, PersonalRecord>> getPersonalRecords() async {
    final dbInstance = await database;

    // Fetch all completed set logs joined with workout logs
    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id
            .equalsExp(dbInstance.setLogs.workoutLogId),
      ),
    ])
      ..where(
        dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.weight.isNotNull() &
            dbInstance.setLogs.reps.isNotNull(),
      );

    final rows = await query.get();

    final Map<String, PersonalRecord> records = {};

    for (final row in rows) {
      final setRow = row.readTable(dbInstance.setLogs);
      final workoutRow = row.readTable(dbInstance.workoutLogs);
      final name = setRow.exerciseNameSnapshot ?? '';
      if (name.isEmpty) continue;

      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;
      final date = workoutRow.startTime;

      final existing = records[name];
      if (existing == null ||
          weight > existing.weightKg ||
          (weight == existing.weightKg && reps > existing.reps)) {
        records[name] = PersonalRecord(
          exerciseName: name,
          weightKg: weight,
          reps: reps,
          date: date,
        );
      }
    }

    return records;
  }

  /// Returns personal records achieved within the given [since] date.
  ///
  /// A "recent PR" is a set that equals or exceeds the all-time best for its
  /// exercise and was performed on or after [since].
  Future<List<PersonalRecord>> getRecentPersonalRecords(DateTime since) async {
    final allTime = await getPersonalRecords();
    final dbInstance = await database;

    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id
            .equalsExp(dbInstance.setLogs.workoutLogId),
      ),
    ])
      ..where(
        dbInstance.workoutLogs.status.equals('completed') &
            dbInstance.workoutLogs.startTime
                .isBiggerOrEqualValue(since) &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.weight.isNotNull() &
            dbInstance.setLogs.reps.isNotNull(),
      )
      ..orderBy([
        drift.OrderingTerm(
          expression: dbInstance.workoutLogs.startTime,
          mode: drift.OrderingMode.desc,
        ),
      ]);

    final rows = await query.get();
    final List<PersonalRecord> recent = [];

    for (final row in rows) {
      final setRow = row.readTable(dbInstance.setLogs);
      final workoutRow = row.readTable(dbInstance.workoutLogs);
      final name = setRow.exerciseNameSnapshot ?? '';
      if (name.isEmpty) continue;

      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;
      final allTimeBest = allTime[name];

      // It's a recent PR if weight matches or exceeds the all-time best weight
      if (allTimeBest != null && weight >= allTimeBest.weightKg) {
        recent.add(PersonalRecord(
          exerciseName: name,
          weightKg: weight,
          reps: reps,
          date: workoutRow.startTime,
        ));
      }
    }

    // Remove duplicates (keep first occurrence per exercise = most recent)
    final seen = <String>{};
    return recent.where((r) => seen.add(r.exerciseName)).toList();
  }

  // ===========================================================================
  // ANALYTICS: Volume
  // ===========================================================================

  /// Returns weekly tonnage (weight × reps) and set counts for the given range.
  ///
  /// Returns a list of [VolumeDataPoint] ordered by week start (ascending).
  Future<List<VolumeDataPoint>> getWeeklyVolume(
    DateTime start,
    DateTime end,
  ) async {
    final logs = await getWorkoutLogsForDateRange(start, end);

    // Group by ISO week start (Monday)
    final Map<DateTime, _VolumeBucket> buckets = {};

    for (final log in logs) {
      final weekStart = _isoWeekStart(log.startTime);
      final bucket = buckets.putIfAbsent(weekStart, () => _VolumeBucket());

      for (final set in log.sets) {
        if (set.isCompleted != true) continue;
        final w = set.weightKg ?? 0.0;
        final r = set.reps ?? 0;
        bucket.tonnage += w * r;
        if (set.setType != 'warmup') {
          bucket.workSets++;
        }
      }
    }

    final sorted = buckets.keys.toList()..sort();
    return sorted
        .map((d) => VolumeDataPoint(
              date: d,
              tonnage: buckets[d]!.tonnage,
              workSets: buckets[d]!.workSets,
            ))
        .toList();
  }

  /// Returns monthly tonnage and set counts for the given range.
  Future<List<VolumeDataPoint>> getMonthlyVolume(
    DateTime start,
    DateTime end,
  ) async {
    final logs = await getWorkoutLogsForDateRange(start, end);

    final Map<DateTime, _VolumeBucket> buckets = {};

    for (final log in logs) {
      final monthStart =
          DateTime(log.startTime.year, log.startTime.month, 1);
      final bucket = buckets.putIfAbsent(monthStart, () => _VolumeBucket());

      for (final set in log.sets) {
        if (set.isCompleted != true) continue;
        final w = set.weightKg ?? 0.0;
        final r = set.reps ?? 0;
        bucket.tonnage += w * r;
        if (set.setType != 'warmup') {
          bucket.workSets++;
        }
      }
    }

    final sorted = buckets.keys.toList()..sort();
    return sorted
        .map((d) => VolumeDataPoint(
              date: d,
              tonnage: buckets[d]!.tonnage,
              workSets: buckets[d]!.workSets,
            ))
        .toList();
  }

  /// Returns volume aggregated by exercise for the given date range.
  Future<List<ExerciseVolumeEntry>> getVolumeByExercise(
    DateTime start,
    DateTime end,
  ) async {
    final logs = await getWorkoutLogsForDateRange(start, end);
    final Map<String, _VolumeBucket> buckets = {};

    for (final log in logs) {
      for (final set in log.sets) {
        if (set.isCompleted != true) continue;
        final name = set.exerciseName;
        final bucket = buckets.putIfAbsent(name, () => _VolumeBucket());
        final w = set.weightKg ?? 0.0;
        final r = set.reps ?? 0;
        bucket.tonnage += w * r;
        if (set.setType != 'warmup') bucket.workSets++;
      }
    }

    final entries = buckets.entries
        .map((e) => ExerciseVolumeEntry(
              name: e.key,
              tonnage: e.value.tonnage,
              workSets: e.value.workSets,
            ))
        .toList()
      ..sort((a, b) => b.tonnage.compareTo(a.tonnage));

    return entries;
  }

  /// Returns volume aggregated by muscle group for the given date range.
  Future<List<ExerciseVolumeEntry>> getVolumeByMuscleGroup(
    DateTime start,
    DateTime end,
  ) async {
    final logs = await getWorkoutLogsForDateRange(start, end);
    final dbInstance = await database;
    final Map<String, _VolumeBucket> buckets = {};

    for (final log in logs) {
      for (final set in log.sets) {
        if (set.isCompleted != true) continue;
        final w = set.weightKg ?? 0.0;
        final r = set.reps ?? 0;

        // Look up exercise to get muscle groups
        final exRows = await (dbInstance.select(dbInstance.exercises)
              ..where((tbl) =>
                  tbl.nameEn.equals(set.exerciseName) |
                  tbl.nameDe.equals(set.exerciseName))
              ..limit(1))
            .get();

        List<String> muscles = [];
        if (exRows.isNotEmpty) {
          muscles.addAll(_parseMuscleList(exRows.first.musclesPrimary));
        }
        if (muscles.isEmpty) muscles = ['Other'];

        for (final muscle in muscles) {
          final bucket =
              buckets.putIfAbsent(muscle, () => _VolumeBucket());
          bucket.tonnage += w * r;
          if (set.setType != 'warmup') bucket.workSets++;
        }
      }
    }

    final entries = buckets.entries
        .map((e) => ExerciseVolumeEntry(
              name: e.key,
              tonnage: e.value.tonnage,
              workSets: e.value.workSets,
            ))
        .toList()
      ..sort((a, b) => b.tonnage.compareTo(a.tonnage));

    return entries;
  }

  // ===========================================================================
  // ANALYTICS: Consistency
  // ===========================================================================

  /// Returns consistency statistics for all completed workouts.
  Future<ConsistencyStats> getConsistencyStats() async {
    final dbInstance = await database;

    final rows = await (dbInstance.select(dbInstance.workoutLogs)
          ..where((tbl) => tbl.status.equals('completed'))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.startTime, mode: drift.OrderingMode.asc),
          ]))
        .get();

    if (rows.isEmpty) {
      return ConsistencyStats(
        totalWorkouts: 0,
        currentStreakWeeks: 0,
        longestStreakWeeks: 0,
        avgWorkoutsPerWeek: 0.0,
        weeklyWorkoutCounts: [],
        workoutDates: [],
      );
    }

    // Collect unique workout dates (day granularity)
    final Set<DateTime> workoutDays = {};
    for (final row in rows) {
      final d = row.startTime;
      workoutDays.add(DateTime(d.year, d.month, d.day));
    }

    // Group by ISO week
    final Map<DateTime, int> weekCounts = {};
    for (final day in workoutDays) {
      final weekStart = _isoWeekStart(day);
      weekCounts[weekStart] = (weekCounts[weekStart] ?? 0) + 1;
    }

    // Compute weekly workout counts for the last 16 weeks
    final now = DateTime.now();
    final List<WeeklyWorkoutEntry> weeklyEntries = [];
    for (int i = 15; i >= 0; i--) {
      final weekStart = _isoWeekStart(now.subtract(Duration(days: i * 7)));
      weeklyEntries.add(WeeklyWorkoutEntry(
        weekStart: weekStart,
        count: weekCounts[weekStart] ?? 0,
      ));
    }

    // Compute streaks (consecutive weeks with at least 1 workout)
    final allWeeks = weekCounts.keys.toList()..sort();
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final currentWeekStart = _isoWeekStart(now);

    for (int i = 0; i < allWeeks.length; i++) {
      if (i == 0) {
        tempStreak = 1;
      } else {
        final prev = allWeeks[i - 1];
        final curr = allWeeks[i];
        final diff = curr.difference(prev).inDays;
        if (diff <= 7) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
      }
      if (tempStreak > longestStreak) longestStreak = tempStreak;
    }

    // Current streak: weeks counting back from current/most recent week
    if (allWeeks.isNotEmpty) {
      final lastWeek = allWeeks.last;
      final diff = currentWeekStart.difference(lastWeek).inDays;
      if (diff <= 7) {
        // The most recent logged week is current or last week — count back
        currentStreak = 1;
        for (int i = allWeeks.length - 2; i >= 0; i--) {
          final curr = allWeeks[i + 1];
          final prev = allWeeks[i];
          if (curr.difference(prev).inDays <= 7) {
            currentStreak++;
          } else {
            break;
          }
        }
      } else {
        currentStreak = 0;
      }
    }

    // Total spans for avg calculation
    final firstWorkoutWeek = allWeeks.first;
    final totalWeeks = currentWeekStart.difference(firstWorkoutWeek).inDays / 7;
    final avgPerWeek = totalWeeks > 0
        ? workoutDays.length / (totalWeeks + 1)
        : workoutDays.length.toDouble();

    return ConsistencyStats(
      totalWorkouts: workoutDays.length,
      currentStreakWeeks: currentStreak,
      longestStreakWeeks: longestStreak,
      avgWorkoutsPerWeek: double.parse(avgPerWeek.toStringAsFixed(1)),
      weeklyWorkoutCounts: weeklyEntries,
      workoutDates: workoutDays.toList(),
    );
  }

  /// Returns the Monday of the ISO week containing [date].
  static DateTime _isoWeekStart(DateTime date) {
    final weekday = date.weekday; // 1=Mon, 7=Sun
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }
}

// ===========================================================================
// ANALYTICS DATA MODELS
// ===========================================================================

/// A personal record for a single exercise.
class PersonalRecord {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final DateTime date;

  const PersonalRecord({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.date,
  });
}

/// A single period's volume data point.
class VolumeDataPoint {
  final DateTime date;
  final double tonnage;
  final int workSets;

  const VolumeDataPoint({
    required this.date,
    required this.tonnage,
    required this.workSets,
  });
}

/// Volume broken down by exercise or muscle group.
class ExerciseVolumeEntry {
  final String name;
  final double tonnage;
  final int workSets;

  const ExerciseVolumeEntry({
    required this.name,
    required this.tonnage,
    required this.workSets,
  });
}

/// Workout count for a single ISO week.
class WeeklyWorkoutEntry {
  final DateTime weekStart;
  final int count;

  const WeeklyWorkoutEntry({required this.weekStart, required this.count});
}

/// Aggregated consistency statistics.
class ConsistencyStats {
  final int totalWorkouts;
  final int currentStreakWeeks;
  final int longestStreakWeeks;
  final double avgWorkoutsPerWeek;
  final List<WeeklyWorkoutEntry> weeklyWorkoutCounts;
  final List<DateTime> workoutDates;

  const ConsistencyStats({
    required this.totalWorkouts,
    required this.currentStreakWeeks,
    required this.longestStreakWeeks,
    required this.avgWorkoutsPerWeek,
    required this.weeklyWorkoutCounts,
    required this.workoutDates,
  });
}

/// Internal mutable bucket used during volume aggregation.
class _VolumeBucket {
  double tonnage = 0.0;
  int workSets = 0;
}
