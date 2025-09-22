// lib/models/lightweight_backup.dart

import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/measurement.dart';
import 'package:lightweight/models/measurement_session.dart';
import 'package:lightweight/models/routine.dart';
import 'package:lightweight/models/routine_exercise.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/models/set_template.dart';
import 'package:lightweight/models/water_entry.dart';
import 'package:lightweight/models/workout_log.dart';

class LightweightBackup {
  final int schemaVersion;
  final List<FoodEntry> foodEntries;
  final List<WaterEntry> waterEntries;
  final List<String> favoriteBarcodes;
  final List<FoodItem> customFoodItems;
  final List<MeasurementSession> measurementSessions;
  final List<Routine> routines;
  final List<WorkoutLog> workoutLogs;
  // HINZUGEFÜGT: Ein Feld für die Benutzereinstellungen
  final Map<String, dynamic> userPreferences;

  LightweightBackup({
    required this.schemaVersion,
    required this.foodEntries,
    required this.waterEntries,
    required this.favoriteBarcodes,
    required this.customFoodItems,
    required this.measurementSessions,
    required this.routines,
    required this.workoutLogs,
    required this.userPreferences, // HINZUGEFÜGT
  });

  // KORRIGIERTE VERSION
  factory LightweightBackup.fromJson(Map<String, dynamic> json) {
    return LightweightBackup(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      foodEntries: (json['foodEntries'] as List<dynamic>?)
              ?.map((e) => FoodEntry(
                    id: e['id'],
                    barcode: e['barcode'],
                    timestamp: DateTime.parse(e['timestamp']),
                    quantityInGrams: e['quantity_in_grams'],
                    mealType: e['meal_type'],
                  ))
              .toList() ??
          [],
      waterEntries: (json['waterEntries'] as List<dynamic>?)
              ?.map((e) => WaterEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      favoriteBarcodes: List<String>.from(json['favoriteBarcodes'] ?? []),
      customFoodItems: (json['customFoodItems'] as List<dynamic>?)
              ?.map((e) => FoodItem.fromMap(e as Map<String, dynamic>,
                  source: FoodItemSource.user))
              .toList() ??
          [],
      measurementSessions: (json['measurementSessions'] as List<dynamic>?)
              ?.map((s) {
            final sessionMap = s as Map<String, dynamic>;
            final measurements = (sessionMap['measurements'] as List<dynamic>?)
                    ?.map((m) => Measurement.fromMap(m as Map<String, dynamic>))
                    .toList() ??
                [];
            return MeasurementSession(
              id: sessionMap['id'],
              timestamp: DateTime.parse(sessionMap['timestamp']),
              measurements: measurements,
            );
          }).toList() ??
          [],

      // KORRIGIERT: Detaillierte Deserialisierung für Routinen
      routines: (json['routines'] as List<dynamic>?)?.map((r) {
            final routineMap = r as Map<String, dynamic>;
            return Routine(
              id: routineMap['id'],
              name: routineMap['name'],
              exercises: (routineMap['exercises'] as List<dynamic>?)?.map((re) {
                    final reMap = re as Map<String, dynamic>;
                    return RoutineExercise(
                      id: reMap['id'],
                      // Rekursiver Aufruf der .fromMap Konstruktoren
                      exercise: Exercise.fromMap(
                          reMap['exercise'] as Map<String, dynamic>),
                      setTemplates: (reMap['setTemplates'] as List<dynamic>?)
                              ?.map((st) => SetTemplate.fromMap(
                                  st as Map<String, dynamic>))
                              .toList() ??
                          [],
                      pauseSeconds: reMap['pause_seconds'],
                    );
                  }).toList() ??
                  [],
            );
          }).toList() ??
          [],

      workoutLogs: (json['workoutLogs'] as List<dynamic>?)?.map((log) {
            final logMap = log as Map<String, dynamic>;
            final sets = (logMap['sets'] as List<dynamic>?)
                    ?.map((set) => SetLog.fromMap(set as Map<String, dynamic>))
                    .toList() ??
                [];
            return WorkoutLog.fromMap(logMap, sets: sets);
          }).toList() ??
          [],
      userPreferences: Map<String, dynamic>.from(json['userPreferences'] ?? {}),
    );
  }

  // Diese Methode nutzt jetzt die .toMap() Methoden deiner Modelle
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'foodEntries': foodEntries.map((e) => e.toMap()).toList(),
      'waterEntries': waterEntries.map((e) => e.toMap()).toList(),
      'favoriteBarcodes': favoriteBarcodes,
      'customFoodItems': customFoodItems.map((e) => e.toMap()).toList(),
      'measurementSessions': measurementSessions
          .map((s) => {
                'id': s.id,
                'timestamp': s.timestamp.toIso8601String(),
                'measurements': s.measurements.map((m) => m.toMap()).toList(),
              })
          .toList(),
      // Platzhalter für die komplexe Serialisierung von Routinen
      'routines': routines.map((r) => r.toMap()).toList(),
      'workoutLogs': workoutLogs
          .map((log) => {
                ...log.toMap(), // Nutzt die existierende toMap-Methode
                'sets': log.sets
                    .map((s) => s.toMap())
                    .toList(), // Hängt die Sets an
              })
          .toList(),
      'userPreferences': userPreferences,
    };
  }
}
