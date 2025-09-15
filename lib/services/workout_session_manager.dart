import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:lightweight/models/routine_exercise.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/data/workout_database_helper.dart';

/// Singleton-Manager, der eine laufende Workout-Session global verwaltet.
class WorkoutSessionManager extends ChangeNotifier {
  static final WorkoutSessionManager _instance = WorkoutSessionManager._internal();
  factory WorkoutSessionManager() => _instance;
  WorkoutSessionManager._internal();

  WorkoutLog? _workoutLog;
  List<RoutineExercise> _exercises = [];
  final Map<int, int?> pauseTimes = {}; // bleibt öffentlich
  final Set<int> completedSets = {};    // bleibt öffentlich
  final Map<int, int> _templateIdToSetLogId = {};

  Timer? _restTimer;
  int _remainingRestSeconds = 0;
  Timer? _restDoneBannerTimer;
  bool _showRestDone = false;
  // Getter
  WorkoutLog? get workoutLog => _workoutLog;
  List<RoutineExercise> get exercises => _exercises;
  int get remainingRestSeconds => _remainingRestSeconds;
  bool get isActive => _workoutLog != null && _workoutLog!.endTime == null;
  bool get showRestDone => _showRestDone;

  void cancelRest() {
    _restTimer?.cancel();
    _restDoneBannerTimer?.cancel();
    _remainingRestSeconds = 0;
    _showRestDone = false;
    notifyListeners();
  }

  /// Neues Workout starten
  void startWorkout(WorkoutLog log, List<RoutineExercise> routineExercises) {
    _workoutLog = log;
    _exercises = routineExercises;
    pauseTimes.clear();
    for (var re in routineExercises) {
      pauseTimes[re.id!] = re.pauseSeconds;
    }
    completedSets.clear();
    _templateIdToSetLogId.clear();
    notifyListeners();
  }

  /// Satz speichern
  Future<void> logSet(int templateId, RoutineExercise re, double weight, int reps) async {
    final restTime = pauseTimes[re.id!];

    final setLogToSave = SetLog(
      workoutLogId: _workoutLog!.id!,
      exerciseName: re.exercise.nameEn,
      setType: 'normal',
      weightKg: weight,
      reps: reps,
      restTimeSeconds: restTime,
      isCompleted: true,
      logOrder: _exercises.indexOf(re),
    );

    final newSetLogId = await WorkoutDatabaseHelper.instance.insertSetLog(setLogToSave);
    _templateIdToSetLogId[templateId] = newSetLogId;
    completedSets.add(templateId);

    if (restTime != null && restTime > 0) {
      _startRestTimer(restTime);
    }
    notifyListeners();
  }

  /// Satz entfernen
  Future<void> unlogSet(int templateId) async {
    final setLogId = _templateIdToSetLogId[templateId];
    if (setLogId != null) {
      await WorkoutDatabaseHelper.instance.deleteSetLogs([setLogId]);
      completedSets.remove(templateId);
      _templateIdToSetLogId.remove(templateId);
      notifyListeners();
    }
  }

  /// Pause einstellen
  void updatePauseTime(RoutineExercise re, int? seconds) {
    pauseTimes[re.id!] = seconds;
    notifyListeners();
  }

  /// Workout beenden
  Future<void> finishWorkout() async {
    if (_workoutLog == null) return;
    await WorkoutDatabaseHelper.instance.finishWorkout(_workoutLog!.id!);
    _restTimer?.cancel();
    _remainingRestSeconds = 0;
    _workoutLog = null;
    _exercises = [];
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

        // 10s grüner Hinweis „Pause vorbei!“ anzeigen
        _showRestDone = true;
        notifyListeners();

        _restDoneBannerTimer = Timer(const Duration(seconds: 10), () {
          _showRestDone = false;
          notifyListeners();
        });
      }
    });
  }


  /// Resttimer überspringen
  void skipRestTimer() {
    _restTimer?.cancel();
    _remainingRestSeconds = 0;
    notifyListeners();
  }
}
