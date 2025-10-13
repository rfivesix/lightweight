// lib/models/routine.dart
import 'package:lightweight/models/routine_exercise.dart';

class Routine {
  final int? id;
  final String name;
  final List<RoutineExercise> exercises;

  Routine({this.id, required this.name, this.exercises = const []});

  // BITTE DIESE METHODE HINZUFÜGEN
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((re) => re.toMap()).toList(),
    };
  }
}
