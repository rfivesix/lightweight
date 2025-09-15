// lib/models/routine.dart
import 'package:lightweight/models/routine_exercise.dart';

class Routine {
  final int? id;
  final String name;
  final List<RoutineExercise> exercises;

  Routine({
    this.id,
    required this.name,
    this.exercises = const [],
  });
}