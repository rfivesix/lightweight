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

  // BITTE DIESE METHODE HINZUFÜGEN ODER ERSETZEN
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise': exercise.toMap(), // Annahme: Exercise hat eine toMap-Methode
      'setTemplates': setTemplates.map((st) => st.toMap()).toList(),
      'pause_seconds': pauseSeconds,
    };
  }
}
