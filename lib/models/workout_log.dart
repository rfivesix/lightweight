// lib/models/workout_log.dart

import 'package:lightweight/models/set_log.dart';

class WorkoutLog {
  final int? id;
  final String? routineName;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final List<SetLog> sets;

  WorkoutLog({
    this.id,
    this.routineName,
    required this.startTime,
    this.endTime,
    this.notes,
    this.sets = const [],
  });

  factory WorkoutLog.fromMap(
    Map<String, dynamic> map, {
    List<SetLog> sets = const [],
  }) {
    return WorkoutLog(
      id: map['id'],
      routineName: map['routine_name'],
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      notes: map['notes'],
      sets: sets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routine_name': routineName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'notes': notes,
    };
  }
}
