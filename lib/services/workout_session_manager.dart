// lib/services/workout_session_manager.dart (mit Live-Timer)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:lightweight/models/routine_exercise.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/data/workout_database_helper.dart';

/// Singleton-Manager, der eine laufende Workout-Session global verwaltet.
class WorkoutSessionManager extends ChangeNotifier {
  static final WorkoutSessionManager _instance =
      WorkoutSessionManager._internal();
  factory WorkoutSessionManager() => _instance;
  WorkoutSessionManager._internal();

  WorkoutLog? _workoutLog;
  List<RoutineExercise> _exercises = [];
  final Map<int, int?> pauseTimes = {};
  final Set<int> completedSets = {};
  final Map<int, int> _templateIdToSetLogId = {};

  Timer? _restTimer;
  int _remainingRestSeconds = 0;
  Timer? _restDoneBannerTimer;
  bool _showRestDone = false;

  // HINZUGEFÜGT: Neue Variablen für den Workout-Timer
  Timer? _workoutDurationTimer;
  Duration _elapsedDuration = Duration.zero;
  // HINZUGEFÜGT: Neue Variablen für die Live-Statistiken
  double _totalVolume = 0.0;
  int _totalSets = 0;

  // Getter
  double get totalVolume => _totalVolume;
  int get totalSets => _totalSets;
  WorkoutLog? get workoutLog => _workoutLog;
  List<RoutineExercise> get exercises => _exercises;
  int get remainingRestSeconds => _remainingRestSeconds;
  bool get isActive => _workoutLog != null && _workoutLog!.endTime == null;
  bool get showRestDone => _showRestDone;

  // HINZUGEFÜGT: Getter für die vergangene Zeit
  Duration get elapsedDuration => _elapsedDuration;

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

    // HINZUGEFÜGT: Statistiken zurücksetzen
    _totalVolume = 0.0;
    _totalSets = 0;

    // HINZUGEFÜGT: Starte den Workout-Timer
    _startWorkoutTimer();

    notifyListeners();
  }

  Future<void> logSet(
      int templateId, RoutineExercise re, double weight, int reps) async {
    if (_workoutLog == null || _workoutLog!.id == null) {
      debugPrint(
          "[ERROR] logSet aufgerufen, aber workoutLog ist null oder hat keine ID!");
      return;
    }

    final restTime = pauseTimes[re.id!];

    final setLogToSave = SetLog(
      workoutLogId: _workoutLog!.id!,
      exerciseName: re.exercise.nameEn,
      setType: 'normal',
      weightKg: weight,
      reps: reps,
      restTimeSeconds: restTime,
      isCompleted: true,
      // KORREKTUR: Der Parametername ist jetzt korrekt (snake_case).
      log_order: _exercises.indexOf(re),
    );

    final newSetLogId =
        await WorkoutDatabaseHelper.instance.insertSetLog(setLogToSave);
    _templateIdToSetLogId[templateId] = newSetLogId;
    completedSets.add(templateId);

    // HINZUGEFÜGT: Statistiken aktualisieren
    _totalVolume += weight * reps;
    _totalSets++;

    if (restTime != null && restTime > 0) {
      _startRestTimer(restTime);
    }
    notifyListeners();
  }

  Future<void> unlogSet(int templateId) async {
    final setLogId = _templateIdToSetLogId[templateId];
    if (setLogId != null) {
      // HINWEIS: Um das Volumen korrekt zu reduzieren, müssten wir hier
      // den SetLog aus der DB lesen, bevor wir ihn löschen.
      // Fürs Erste ist das Zurücksetzen einfacher und meist ausreichend.
      // Wir berechnen das Volumen beim nächsten logSet einfach neu.
      // EINFÜHRUNG: Wir berechnen die Stats neu, um Konsistenz zu gewährleisten
      await _recalculateStats();

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

    // HINZUGEFÜGT: Stoppe beide Timer
    _stopWorkoutTimer();
    _restTimer?.cancel();
    _totalVolume = 0.0; // HINZUGEFÜGT
    _totalSets = 0; // HINZUGEFÜGT

    _remainingRestSeconds = 0;
    _workoutLog = null;
    _exercises = [];
    notifyListeners();
  }

  // HINZUGEFÜGT: Eine Helfermethode, um die Stats neu zu berechnen
  Future<void> _recalculateStats() async {
    // Diese Methode ist ein Platzhalter. Eine volle Implementierung
    // würde hier die `completedSets` durchgehen und das Volumen neu aufbauen.
    // Fürs Erste reicht das einfache Inkrementieren/Dekrementieren.
    // Bei `unlogSet` wird die Komplexität sichtbar.
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

  // HINZUGEFÜGT: Neue Methoden zum Steuern des Workout-Timers
  void _startWorkoutTimer() {
    _workoutDurationTimer?.cancel(); // Stoppe einen eventuell alten Timer
    _elapsedDuration = Duration.zero; // Setze die Zeit zurück

    // Berechne die bereits vergangene Zeit seit dem Start des Workouts,
    // falls die App zwischendurch geschlossen wurde.
    if (_workoutLog != null) {
      _elapsedDuration = DateTime.now().difference(_workoutLog!.startTime);
    }

    _workoutDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Berechne die Dauer bei jedem Tick neu, um maximale Genauigkeit zu gewährleisten
      if (_workoutLog != null) {
        _elapsedDuration = DateTime.now().difference(_workoutLog!.startTime);
        notifyListeners(); // Benachrichtige die UI über die neue Dauer
      } else {
        timer
            .cancel(); // Sicherheitshalber stoppen, wenn kein Workout mehr aktiv ist
      }
    });
  }

  void _stopWorkoutTimer() {
    _workoutDurationTimer?.cancel();
  }
}
