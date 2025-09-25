// lib/services/workout_session_manager.dart
// VOLLSTÄNDIGER CODE (FINAL)

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
  bool get isActive => _workoutLog != null && _workoutLog!.endTime == null;
  bool get showRestDone => _showRestDone;
  Duration get elapsedDuration => _elapsedDuration;
  Map<int, SetLog> get setLogs => _setLogs;

// Ersetze diese Methode in lib/services/workout_session_manager.dart

// Ersetze diese Methode in lib/services/workout_session_manager.dart

  Future<void> restoreWorkoutSession(WorkoutLog logToRestore) async {
    final db = WorkoutDatabaseHelper.instance;
    _workoutLog = logToRestore;
    _exercises = [];
    pauseTimes.clear();
    _setLogs.clear();

    // 1. Hole alle einzigartigen Übungen, sortiert nach ihrem ersten Auftreten (log_order)
    final sortedSets = logToRestore.sets
      ..sort((a, b) => (a.log_order ?? 999).compareTo(b.log_order ?? 999));
    final orderedUniqueExerciseNames =
        sortedSets.map((s) => s.exerciseName).toSet().toList();

    // 2. Baue die _exercises-Liste in der korrekten Reihenfolge auf
    for (final name in orderedUniqueExerciseNames) {
      final exerciseDetail = await db.getExerciseByName(name);
      if (exerciseDetail != null) {
        final setsForThisExercise =
            sortedSets.where((s) => s.exerciseName == name).toList();

        final routineExercise = RoutineExercise(
          id: DateTime.now().millisecondsSinceEpoch + _exercises.length,
          exercise: exerciseDetail,
          setTemplates: setsForThisExercise
              .map((s) => SetTemplate(id: s.id!, setType: s.setType))
              .toList(),
        );
        _exercises.add(routineExercise);

        // Fülle die _setLogs Map und die Pausenzeiten
        for (final setLog in setsForThisExercise) {
          _setLogs[setLog.id!] = setLog;
        }
        if (setsForThisExercise.isNotEmpty) {
          pauseTimes[routineExercise.id!] =
              setsForThisExercise.first.restTimeSeconds;
        }
      }
    }

    _recalculateStats();
    _startWorkoutTimer();
    notifyListeners();
  }

  void startWorkout(WorkoutLog log, List<RoutineExercise> routineExercises) {
    _workoutLog = log;
    _exercises = routineExercises;
    _setLogs.clear();
    pauseTimes.clear();

    for (var re in routineExercises) {
      pauseTimes[re.id!] = re.pauseSeconds;
      final exerciseIndex = routineExercises.indexOf(re); // Index als log_order
      for (final template in re.setTemplates) {
        _setLogs[template.id!] = SetLog(
          workoutLogId: _workoutLog!.id!,
          exerciseName: re.exercise.nameEn,
          setType: template.setType,
          isCompleted: false,
          log_order: exerciseIndex, // Index hier setzen
        );
      }
    }

    _recalculateStats();
    _startWorkoutTimer();
    notifyListeners();
  }

// Ersetze diese Methode in lib/services/workout_session_manager.dart

  Future<void> updateSet(int templateId,
      {double? weight, int? reps, String? setType, bool? isCompleted}) async {
    if (_workoutLog == null || !_setLogs.containsKey(templateId)) return;

    SetLog currentLog = _setLogs[templateId]!;
    final exerciseIndex = _exercises
        .indexWhere((e) => e.setTemplates.any((t) => t.id == templateId));

    // Hole die aktuelle Pausenzeit für diese Übung
    int? currentRestTime;
    if (exerciseIndex != -1) {
      currentRestTime = pauseTimes[_exercises[exerciseIndex].id!];
    }

    _setLogs[templateId] = currentLog.copyWith(
      weightKg: weight,
      reps: reps,
      setType: setType,
      isCompleted: isCompleted,
      log_order: exerciseIndex,
      restTimeSeconds:
          currentRestTime, // KORREKTUR: Speichere die Pause immer mit
    );

    final db = WorkoutDatabaseHelper.instance;
    final logToSave = _setLogs[templateId]!;

    if (logToSave.id != null && logToSave.id! > 0) {
      await db.insertSetLog(logToSave);
    } else {
      final newId = await db.insertSetLog(logToSave);
      _setLogs[templateId] = logToSave.copyWith(id: newId);
    }

    if (isCompleted != null) {
      _recalculateStats();
      if (isCompleted) {
        if (exerciseIndex != -1) {
          final re = _exercises[exerciseIndex];
          final restTime = pauseTimes[re.id!];
          if (restTime != null && restTime > 0) {
            _startRestTimer(restTime);
          }
        }
      }
    }
    notifyListeners();
  }

// Ersetze diese Methode in lib/services/workout_session_manager.dart

  void reorderExercise(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _exercises.removeAt(oldIndex);
    _exercises.insert(newIndex, item);

    // Aktualisiere den log_order für alle Sätze basierend auf der neuen Reihenfolge der Übungen
    for (int i = 0; i < _exercises.length; i++) {
      final re = _exercises[i];
      for (final template in re.setTemplates) {
        if (_setLogs.containsKey(template.id!)) {
          // Hier rufen wir direkt updateSet auf, um die Änderung auch in die DB zu schreiben
          updateSet(template.id!,
              isCompleted: _setLogs[template.id!]!.isCompleted);
        }
      }
    }
    notifyListeners();
  }

  void updatePauseTime(int routineExerciseId, int newSeconds) {
    pauseTimes[routineExerciseId] = newSeconds;
    // Finde die zugehörigen Sätze und speichere die neue Pausezeit in der DB
    final exercise = _exercises.firstWhere((e) => e.id == routineExerciseId);
    for (final template in exercise.setTemplates) {
      if (_setLogs.containsKey(template.id!)) {
        updateSet(template.id!,
            isCompleted: _setLogs[template.id!]!.isCompleted);
      }
    }
    notifyListeners();
  }

  void removeExercise(int routineExerciseId) {
    final exerciseToRemove =
        _exercises.firstWhere((e) => e.id == routineExerciseId);
    for (final template in exerciseToRemove.setTemplates) {
      _setLogs.remove(template.id!);
    }
    _exercises.removeWhere((e) => e.id == routineExerciseId);
    pauseTimes.remove(routineExerciseId);
    _recalculateStats();
    notifyListeners();
  }

// Ersetze diese Methode in lib/services/workout_session_manager.dart

  Future<RoutineExercise?> addExercise(Exercise exercise) async {
    if (_workoutLog == null) return null;

    final newRoutineExercise = RoutineExercise(
      id: DateTime.now().millisecondsSinceEpoch,
      exercise: exercise,
      setTemplates: [
        SetTemplate(
            id: DateTime.now().millisecondsSinceEpoch + 1, setType: 'normal')
      ],
    );

    _exercises.add(newRoutineExercise);
    pauseTimes[newRoutineExercise.id!] = null;

    final newTemplate = newRoutineExercise.setTemplates.first;
    _setLogs[newTemplate.id!] = SetLog(
      workoutLogId: _workoutLog!.id!,
      exerciseName: exercise.nameEn,
      setType: newTemplate.setType,
      isCompleted: false,
      log_order: _exercises.length - 1, // Setze den Index als log_order
    );

    notifyListeners(); // Ersetze diese Methode in lib/services/workout_session_manager.dart

    void reorderExercise(int oldIndex, int newIndex) {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);

      // Aktualisiere den log_order für alle Sätze basierend auf der neuen Reihenfolge der Übungen
      for (int i = 0; i < _exercises.length; i++) {
        final re = _exercises[i];
        for (final template in re.setTemplates) {
          if (_setLogs.containsKey(template.id!)) {
            // Hier rufen wir direkt updateSet auf, um die Änderung auch in die DB zu schreiben
            updateSet(template.id!,
                isCompleted: _setLogs[template.id!]!.isCompleted);
          }
        }
      }
      notifyListeners();
    }

    return newRoutineExercise;
  }

  SetTemplate? addSetToExercise(int routineExerciseId) {
    final exerciseIndex =
        _exercises.indexWhere((e) => e.id == routineExerciseId);
    if (exerciseIndex == -1) return null;

    final newTemplate = SetTemplate(
        id: DateTime.now().millisecondsSinceEpoch, setType: 'normal');
    _exercises[exerciseIndex].setTemplates.add(newTemplate);

    _setLogs[newTemplate.id!] = SetLog(
      workoutLogId: _workoutLog!.id!,
      exerciseName: _exercises[exerciseIndex].exercise.nameEn,
      setType: newTemplate.setType,
      isCompleted: false,
    );

    notifyListeners();
    return newTemplate;
  }

  void removeSet(int templateId) {
    for (final re in _exercises) {
      re.setTemplates.removeWhere((t) => t.id == templateId);
    }
    _setLogs.remove(templateId);
    _recalculateStats();
    notifyListeners();
  }

  Future<void> finishWorkout() async {
    if (_workoutLog == null) return;
    final db = WorkoutDatabaseHelper.instance;
    final emptySetIds = _setLogs.values
        .where((sl) => sl.isCompleted != true && sl.id != null)
        .map((sl) => sl.id!)
        .toList();

    if (emptySetIds.isNotEmpty) {
      await db.deleteSetLogs(emptySetIds);
    }
    await db.finishWorkout(_workoutLog!.id!);
    _stopWorkoutTimer();
    _restTimer?.cancel();
    _workoutLog = null;
    _exercises = [];
    _setLogs.clear();
    _recalculateStats();
    notifyListeners();
  }

  void _recalculateStats() {
    double newVolume = 0.0;
    int newSets = 0;
    for (final setLog in _setLogs.values) {
      if (setLog.isCompleted == true) {
        newVolume += (setLog.weightKg ?? 0.0) * (setLog.reps ?? 0);
        newSets++;
      }
    }
    _totalVolume = newVolume;
    _totalSets = newSets;
    notifyListeners();
  }

  void cancelRest() {
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    _remainingRestSeconds = 0;
    _showRestDone = false;
    notifyListeners();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    _remainingRestSeconds = seconds;
    _showRestDone = false;
    notifyListeners();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingRestSeconds > 0) {
        _remainingRestSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        Vibration.vibrate(duration: 500);
        _showRestDone = true;
        notifyListeners();
        _restDoneBannerTimer = Timer(const Duration(seconds: 10), () {
          _showRestDone = false;
          notifyListeners();
        });
      }
    });
  }

  void skipRestTimer() {
    _restTimer?.cancel();
    _remainingRestSeconds = 0;
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

  void _stopWorkoutTimer() {
    _workoutDurationTimer?.cancel();
  }

  Future<void> tryRestoreSession() async {
    final db = WorkoutDatabaseHelper.instance;
    final WorkoutLog? ongoingWorkout = await db.getOngoingWorkout();

    if (ongoingWorkout != null) {
      print(
          "Laufendes Workout gefunden (ID: ${ongoingWorkout.id}). Stelle Session wieder her...");
      await restoreWorkoutSession(ongoingWorkout);
      print("Session erfolgreich wiederhergestellt.");
    } else {
      print("Kein laufendes Workout gefunden. Starte normal.");
    }
  }
}
