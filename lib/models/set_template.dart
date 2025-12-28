// lib/models/set_template.dart

class SetTemplate {
  final int? id;
  final String setType;
  final String? targetReps;
  final double? targetWeight;
  final int? targetRir;

  SetTemplate({
    this.id,
    required this.setType,
    this.targetReps,
    this.targetWeight,
    this.targetRir
  });

  factory SetTemplate.fromMap(Map<String, dynamic> map) {
    return SetTemplate(
      id: map['id'],
      setType: map['set_type'] ?? 'normal',
      targetReps: map['target_reps'],
      targetWeight: map['target_weight'],
      targetRir: map['target_rir'],
    );
  }

  // In lib/models/set_template.dart
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'set_type': setType,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'target_rir': targetRir,
    };
  }

  // NEUE, BENÖTIGTE METHODE
  // Erstellt eine Kopie des Objekts und überschreibt nur die übergebenen Werte.
  SetTemplate copyWith({
    int? id,
    String? setType,
    String? targetReps,
    double? targetWeight,
    int? targetRir,
  }) {
    return SetTemplate(
      id: id ?? this.id,
      setType: setType ?? this.setType,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetRir: targetRir ?? this.targetRir,
    );
  }
}
