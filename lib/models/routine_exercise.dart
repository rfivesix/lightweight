// lib/models/routine_exercise.dart

import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/models/set_template.dart';

class RoutineExercise {
  final int? id;
  final Exercise exercise;
  List<SetTemplate> setTemplates;
  final int? pauseSeconds; // NEUES FELD

  RoutineExercise({
    this.id,
    required this.exercise,
    this.setTemplates = const [],
    this.pauseSeconds, // NEUES FELD
  });
}