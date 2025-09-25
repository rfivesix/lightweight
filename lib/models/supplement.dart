// lib/models/supplement.dart

class Supplement {
  final int? id;
  final String name;
  final double defaultDose;
  final String unit;
  final double? dailyGoal; // Optionales Tagesziel
  final double? dailyLimit; // Optionales Tageslimit
  final String? notes;

  Supplement({
    this.id,
    required this.name,
    required this.defaultDose,
    required this.unit,
    this.dailyGoal,
    this.dailyLimit,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'default_dose': defaultDose,
      'unit': unit,
      'daily_goal': dailyGoal,
      'daily_limit': dailyLimit,
      'notes': notes,
    };
  }

  factory Supplement.fromMap(Map<String, dynamic> map) {
    return Supplement(
      id: map['id'],
      name: map['name'],
      defaultDose: map['default_dose'],
      unit: map['unit'],
      dailyGoal: map['daily_goal'],
      dailyLimit: map['daily_limit'],
      notes: map['notes'],
    );
  }
}
