// lib/models/set_log.dart

class SetLog {
  final int? id;
  final int workoutLogId;
  final String exerciseName;
  final String setType;
  final double? weightKg;
  final int? reps;
  final int? restTimeSeconds;
  final bool isCompleted;
  final int? logOrder;

  SetLog({
    this.id,
    required this.workoutLogId,
    required this.exerciseName,
    required this.setType,
    this.weightKg,
    this.reps,
    this.restTimeSeconds,
    this.isCompleted = false,
    this.logOrder
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_log_id': workoutLogId,
      'exercise_name': exerciseName,
      'set_type': setType,
      'weight_kg': weightKg,
      'reps': reps,
      'rest_time_seconds': restTimeSeconds,
      'is_completed': isCompleted ? 1 : 0,
      'log_order': logOrder
    };
  }

  factory SetLog.fromMap(Map<String, dynamic> map) {
    final bool completed = (map['is_completed'] != null && map['is_completed'] == 1);
    return SetLog(
      id: map['id'],
      workoutLogId: map['workout_log_id'],
      exerciseName: map['exercise_name'],
      setType: map['set_type'],
      weightKg: map['weight_kg'],
      reps: map['reps'],
      restTimeSeconds: map['rest_time_seconds'],
      isCompleted: completed,
      logOrder: map['log_order']
    );
  }

  SetLog copyWith({
    int? id,
    int? workoutLogId,
    String? exerciseName,
    String? setType,
    double? weightKg,
    int? reps,
    bool? isCompleted,
    int? restTimeSeconds,
    int? logOrder
  }) {
    return SetLog(
      id: id ?? this.id,
      workoutLogId: workoutLogId ?? this.workoutLogId,
      exerciseName: exerciseName ?? this.exerciseName,
      setType: setType ?? this.setType,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      logOrder: logOrder ?? this.logOrder
    );
  }
}