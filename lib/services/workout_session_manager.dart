// lib/services/workout_session_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:vibration/vibration.dart';
import 'package:lightweight/models/routine_exercise.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/models/set_template.dart';

class WorkoutSessionManager extends ChangeNotifier {
  static final WorkoutSessionManager _instance =
      WorkoutSessionManager._internal();
  factory WorkoutSessionManager() => _instance;
  WorkoutSessionManager._internal();

  WorkoutLog? _workoutLog;
  List<RoutineExercise> _exercises = [];
  final Map<int, SetLog> _setLogs = {};

  // Speichert die Pausenzeit pro RoutineExercise-ID
  final Map<int, int?> pauseTimes = {};

  Timer? _restTimer;
  int _remainingRestSeconds = 0;
  Timer? _restDoneBannerTimer;
  bool _showRestDone = false;

  Timer? _workoutDurationTimer;
  Duration _elapsedDuration = Duration.zero;
  double _totalVolume = 0.0;
  int _totalSets = 0;

  double get totalVolume => _totalVolume;
  int get totalSets => _totalSets;
  WorkoutLog? get workoutLog => _workoutLog;
  List<RoutineExercise> get exercises => _exercises;
  int get remainingRestSeconds => _remainingRestSeconds;
  bool get showRestDone => _showRestDone;
  Duration get elapsedDuration => _elapsedDuration;
  Map<int, SetLog> get setLogs => _setLogs;

  bool get isActive => _workoutLog != null && _workoutLog!.endTime == null;

  // ===========================================================================
  // INIT & RESTORE
  // ===========================================================================

  Future<void> startWorkout(
      WorkoutLog log, List<RoutineExercise> routineExercises) async {
    _workoutLog = log;
    _exercises = List.from(routineExercises);
    _setLogs.clear();
    pauseTimes.clear();

    // Pause-Zeiten initialisieren
    for (var re in _exercises) {
      if (re.id != null) {
        pauseTimes[re.id!] = re.pauseSeconds;
      }
    }

    _createInitialSetLogs();
    _startWorkoutTimer();
    notifyListeners();
  }

  /// Versucht, ein laufendes Workout aus der Datenbank wiederherzustellen.
  /// Wird in main.dart aufgerufen.
  Future<void> tryRestoreSession() async {
    final db = WorkoutDatabaseHelper.instance;
    final ongoingWorkout = await db.getOngoingWorkout();

    if (ongoingWorkout != null) {
      // ignore: avoid_print
      print("Laufendes Workout gefunden (ID: ${ongoingWorkout.id}). Stelle Session wieder her...");
      await restoreWorkoutSession(ongoingWorkout);
    }
  }

  void _createInitialSetLogs() async {
    final db = WorkoutDatabaseHelper.instance;
    _totalVolume = 0;
    _totalSets = 0;

    for (var re in _exercises) {
      for (var template in re.setTemplates) {
        if (template.id == null) continue;

        final initialWeight = template.targetWeight ?? 0.0;
        final initialReps = int.tryParse(template.targetReps ?? '0') ?? 0;

        final newSetLog = SetLog(
          workoutLogId: _workoutLog!.id!,
          exerciseName: re.exercise.nameEn,
          setType: template.setType,
          weightKg: initialWeight,
          reps: initialReps,
          restTimeSeconds: re.pauseSeconds,
          isCompleted: false,
          rir: template.targetRir, // Ziel-RIR als Startwert übernehmen
        );

        final id = await db.insertSetLog(newSetLog);

        _setLogs[template.id!] = newSetLog.copyWith(id: id);
        _totalSets++;
        _totalVolume += (initialWeight * initialReps);
      }
    }
    notifyListeners();
  }

  Future<void> restoreWorkoutSession(WorkoutLog log) async {
    final db = WorkoutDatabaseHelper.instance;
    _workoutLog = log;

    final savedSets = await db.getSetLogsForWorkout(log.id!);

    if (log.routineName != null) {
      final routine = await db.getRoutineByName(log.routineName!);
      if (routine != null) {
        _exercises = routine.exercises;
        for (var re in _exercises) {
          if (re.id != null) pauseTimes[re.id!] = re.pauseSeconds;
        }
      }
    }

    _setLogs.clear();
    _totalVolume = 0;
    _totalSets = 0;

    // Mapping wiederherstellen (Best Effort)
    var setLogIndex = 0;
    for (var re in _exercises) {
      for (var t in re.setTemplates) {
        if (setLogIndex < savedSets.length) {
          final s = savedSets[setLogIndex];
          // Check ob Exercise Name passt (grob)
          if (s.exerciseName == re.exercise.nameEn ||
              s.exerciseName == re.exercise.nameDe) {
            _setLogs[t.id!] = s;
            _totalVolume += (s.weightKg ?? 0) * (s.reps ?? 0);
            _totalSets++;
            setLogIndex++;
          }
        }
      }
    }

    _startWorkoutTimer();
    notifyListeners();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> updateSet(
    int templateId, {
    double? weight,
    int? reps,
    bool? isCompleted,
    String? setType,
    int? rir,
    // FIX: Cardio Parameter
    double? distance,
    int? duration,
  }) async {
    if (!_setLogs.containsKey(templateId)) return;

    final oldLog = _setLogs[templateId]!;
    final db = WorkoutDatabaseHelper.instance;

    // Volumens-Berechnung update (Nur für Krafttraining relevant)
    if (weight != null || reps != null) {
      final oldVol = (oldLog.weightKg ?? 0) * (oldLog.reps ?? 0);
      final newWeight = weight ?? oldLog.weightKg ?? 0;
      final newReps = reps ?? oldLog.reps ?? 0;
      _totalVolume = _totalVolume - oldVol + (newWeight * newReps);
    }

    final newLog = oldLog.copyWith(
      weightKg: weight,
      reps: reps,
      isCompleted: isCompleted,
      setType: setType,
      rir: rir,
      distanceKm: distance, // <--- NEU
      durationSeconds: duration, // <--- NEU
    );

    _setLogs[templateId] = newLog;
    await db.insertSetLog(newLog); // Update in DB

    // Timer Logik (unverändert)
    if (isCompleted == true && oldLog.isCompleted != true) {
      int? pauseTime;
      for (var re in _exercises) {
        if (re.setTemplates.any((t) => t.id == templateId)) {
          pauseTime = pauseTimes[re.id!];
          break;
        }
      }
      if (pauseTime != null && pauseTime > 0) {
        _startRestTimer(pauseTime);
      }
    }

    notifyListeners();
  }

  Future<void> addSetToExercise(int routineExerciseId) async {
    final db = WorkoutDatabaseHelper.instance;

    final reIndex = _exercises.indexWhere((e) => e.id == routineExerciseId);
    if (reIndex == -1) return;
    final re = _exercises[reIndex];

    final tempTemplateId = DateTime.now().millisecondsSinceEpoch;

    final newTemplate = SetTemplate(
      id: tempTemplateId,
      setType: 'normal',
      targetReps: '0',
      targetWeight: 0.0,
      targetRir: 2,
    );

    // KORREKTUR: Manuelle Erstellung statt copyWith
    final updatedRe = RoutineExercise(
      id: re.id,
      exercise: re.exercise,
      setTemplates: [...re.setTemplates, newTemplate],
      pauseSeconds: re.pauseSeconds,
    );
    
    _exercises[reIndex] = updatedRe;

    final prevSet =
        _setLogs.values.where((s) => s.exerciseName == re.exercise.nameEn).lastOrNull;

    final newSetLog = SetLog(
      workoutLogId: _workoutLog!.id!,
      exerciseName: re.exercise.nameEn,
      setType: 'normal',
      weightKg: prevSet?.weightKg ?? 0,
      reps: prevSet?.reps ?? 0,
      restTimeSeconds: re.pauseSeconds,
      isCompleted: false,
      log_order: _setLogs.length,
      rir: null,
    );

    final dbId = await db.insertSetLog(newSetLog);
    _setLogs[tempTemplateId] = newSetLog.copyWith(id: dbId);
    _totalSets++;

    notifyListeners();
  }

  Future<void> removeSet(int templateId) async {
    if (!_setLogs.containsKey(templateId)) return;

    final log = _setLogs[templateId]!;
    final db = WorkoutDatabaseHelper.instance;

    if (log.id != null) {
      await db.deleteSetLogs([log.id!]);
    }

    _setLogs.remove(templateId);

    for (var i = 0; i < _exercises.length; i++) {
      final re = _exercises[i];
      final tIndex = re.setTemplates.indexWhere((t) => t.id == templateId);
      if (tIndex != -1) {
        final newTemplates = List<SetTemplate>.from(re.setTemplates)
          ..removeAt(tIndex);
        
        // KORREKTUR: Manuelle Erstellung statt copyWith
        _exercises[i] = RoutineExercise(
          id: re.id,
          exercise: re.exercise,
          setTemplates: newTemplates,
          pauseSeconds: re.pauseSeconds,
        );
        break;
      }
    }
    
    _totalVolume -= (log.weightKg ?? 0) * (log.reps ?? 0);
    _totalSets--;

    notifyListeners();
  }

  Future<void> addExercise(Exercise exercise) async {
    final tempReId = DateTime.now().millisecondsSinceEpoch;
    
    // FIX: Cardio Check für Anzahl der Sets
    final isCardio = exercise.categoryName?.toLowerCase() == 'cardio';
    final initialSetCount = isCardio ? 1 : 3;
    final initialReps = isCardio ? '' : '10'; // Auch hier: Cardio leer, Kraft 10

    final templates = List.generate(initialSetCount, (index) => SetTemplate(
      id: tempReId + index + 1,
      setType: 'normal',
      targetReps: initialReps,
      targetWeight: 0,
    ));

    final re = RoutineExercise(
      id: tempReId,
      exercise: exercise,
      setTemplates: templates,
      pauseSeconds: 90,
    );

    _exercises.add(re);
    pauseTimes[tempReId] = 90;

    final db = WorkoutDatabaseHelper.instance;
    for (var t in templates) {
      final newSetLog = SetLog(
        workoutLogId: _workoutLog!.id!,
        exerciseName: exercise.nameEn,
        setType: 'normal',
        weightKg: 0,
        reps: 0,
        restTimeSeconds: 90,
        isCompleted: false,
        // Optional: logOrder hier schon setzen, aber Manager macht das nicht explizit bisher
        log_order: _setLogs.length, 
      );
      final dbId = await db.insertSetLog(newSetLog);
      _setLogs[t.id!] = newSetLog.copyWith(id: dbId);
      _totalSets++;
    }
    
    notifyListeners();
  }
  
  Future<void> removeExercise(int routineExerciseId) async {
    final reIndex = _exercises.indexWhere((e) => e.id == routineExerciseId);
    if (reIndex == -1) return;
    
    final re = _exercises[reIndex];
    final db = WorkoutDatabaseHelper.instance;

    final idsToDelete = <int>[];
    for (var t in re.setTemplates) {
      if (_setLogs.containsKey(t.id)) {
        final log = _setLogs[t.id]!;
        if (log.id != null) idsToDelete.add(log.id!);
        _totalVolume -= (log.weightKg ?? 0) * (log.reps ?? 0);
        _totalSets--;
        _setLogs.remove(t.id);
      }
    }
    await db.deleteSetLogs(idsToDelete);

    _exercises.removeAt(reIndex);
    pauseTimes.remove(routineExerciseId);
    
    notifyListeners();
  }
  
  void reorderExercise(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _exercises.removeAt(oldIndex);
    _exercises.insert(newIndex, item);
    notifyListeners();
  }

  // ===========================================================================
  // TIMER LOGIC
  // ===========================================================================

  void updatePauseTime(int routineExerciseId, int seconds) {
    pauseTimes[routineExerciseId] = seconds;
    WorkoutDatabaseHelper.instance.updatePauseTime(routineExerciseId, seconds);

    // Lokale SetLogs updaten
    final exercise = _exercises.firstWhere((e) => e.id == routineExerciseId);
    final db = WorkoutDatabaseHelper.instance;
    
    for(var t in exercise.setTemplates) {
      if (_setLogs.containsKey(t.id)) {
        final log = _setLogs[t.id]!;
        if (log.isCompleted != true) {
          final updatedLog = log.copyWith(restTimeSeconds: seconds);
          _setLogs[t.id!] = updatedLog;
          db.insertSetLog(updatedLog);
        }
      }
    }

    notifyListeners();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    _showRestDone = false;
    _remainingRestSeconds = seconds;

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingRestSeconds > 0) {
        _remainingRestSeconds--;
        if (_remainingRestSeconds == 0) {
           Vibration.vibrate(duration: 500);
        }
        notifyListeners();
      } else {
        timer.cancel();
        _showRestDone = true;
        notifyListeners();
        _restDoneBannerTimer = Timer(const Duration(seconds: 10), () {
          _showRestDone = false;
          notifyListeners();
        });
      }
    });
    notifyListeners();
  }

  void cancelRest() {
    _restTimer?.cancel();
    _remainingRestSeconds = 0;
    _showRestDone = false;
    notifyListeners();
  }

  void _startWorkoutTimer() {
    _workoutDurationTimer?.cancel();
    _elapsedDuration = Duration.zero;
    if (_workoutLog != null) {
      _elapsedDuration = DateTime.now().difference(_workoutLog!.startTime);
    }
    _workoutDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_workoutLog != null) {
        _elapsedDuration = DateTime.now().difference(_workoutLog!.startTime);
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

Future<void> finishWorkout() async {
    _workoutDurationTimer?.cancel();
    _restTimer?.cancel();

    if (_workoutLog != null) {
      final db = WorkoutDatabaseHelper.instance;
      final logId = _workoutLog!.id!;

      // 1. Unvollständige Sets identifizieren und löschen
      // Wir filtern lokal, welche IDs gelöscht werden müssen
      final incompleteSetIds = _setLogs.values
          .where((s) => s.isCompleted == false && s.id != null)
          .map((s) => s.id!)
          .toList();

      if (incompleteSetIds.isNotEmpty) {
        await db.deleteSetLogs(incompleteSetIds);
      }

      // 2. Reihenfolge aktualisieren (Reordering Fix)
      // Wir iterieren durch die aktuelle Übungsliste (die vom User ggf. umsortiert wurde)
      // und vergeben neue logOrder-Indizes für die verbleibenden (completed) Sets.
      int globalOrderCounter = 0;
      final List<SetLog> setsToUpdate = [];

      for (final routineExercise in _exercises) {
        for (final template in routineExercise.setTemplates) {
          final setLog = _setLogs[template.id];
          // Nur completed Sets werden behalten und neu sortiert
          if (setLog != null && setLog.isCompleted == true) {
            setsToUpdate.add(setLog.copyWith(log_order: globalOrderCounter));
            globalOrderCounter++;
          }
        }
      }

      // Batch-Update der Reihenfolge in der DB
      if (setsToUpdate.isNotEmpty) {
        await db.updateSetLogs(setsToUpdate);
      }

      // 3. Workout abschließen
      await db.finishWorkout(logId);

      // Cleanup
      _workoutLog = null;
      _setLogs.clear();
      pauseTimes.clear();
      _exercises.clear();
      
      notifyListeners();
    }
  }
}