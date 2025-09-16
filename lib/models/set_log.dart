// lib/models/set_log.dart

class SetLog {
  final int? id;
  final int workoutLogId;
  final String exerciseName;
  final String setType;
  final double? weightKg;
  final int? reps;
  final int? restTimeSeconds;
  final bool? isCompleted;
  final int? log_order;
  final String? notes;
  final double? distanceKm;
  final int? durationSeconds;
  final int? rpe;
  final int? supersetId;

  SetLog({
    this.id,
    required this.workoutLogId,
    required this.exerciseName,
    required this.setType,
    this.weightKg,
    this.reps,
    this.restTimeSeconds,
    this.isCompleted,
    this.log_order,
    this.notes,
    this.distanceKm,
    this.durationSeconds,
    this.rpe,
    this.supersetId,
  });

  factory SetLog.fromMap(Map<String, dynamic> map) {
    return SetLog(
      id: map['id'],
      workoutLogId: map['workout_log_id'],
      exerciseName: map['exercise_name'],
      setType: map['set_type'],
      weightKg: map['weight_kg'],
      reps: map['reps'],
      restTimeSeconds: map['rest_time_seconds'],
      isCompleted: map['is_completed'] == 1,
      log_order: map['log_order'],
      notes: map['notes'],
      distanceKm: map['distance_km'],
      durationSeconds: map['duration_seconds'],
      rpe: map['rpe'],
      supersetId: map['superset_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_log_id': workoutLogId,
      'exercise_name': exerciseName,
      'set_type': setType,
      'weight_kg': weightKg,
      'reps': reps,
      'rest_time_seconds': restTimeSeconds,
      'is_completed': isCompleted == true ? 1 : 0,
      'log_order': log_order,
      'notes': notes,
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      'rpe': rpe,
      'superset_id': supersetId,
    };
  }

  SetLog copyWith({
    int? id,
    int? workoutLogId,
    String? exerciseName,
    String? setType,
    double? weightKg,
    int? reps,
    int? restTimeSeconds,
    bool? isCompleted,
    int? log_order,
    String? notes,
    double? distanceKm,
    int? durationSeconds,
    int? rpe,
    int? supersetId,
  }) {
    return SetLog(
      id: id ?? this.id,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      exerciseName: exerciseName ?? this.exerciseName,
      setType: setType ?? this.setType,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      log_order: log_order ?? this.log_order,
      notes: notes ?? this.notes,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      rpe: rpe ?? this.rpe,
      supersetId: supersetId ?? this.supersetId,
    );
  }
}
