// lib/models/supplement.dart
class Supplement {
  final int? id;
  final String? code; // <— NEU, optional
  final String name;
  final double defaultDose;
  final String unit;
  final double? dailyGoal;
  final double? dailyLimit;
  final String? notes;
  final bool isBuiltin; // <— NEU

  Supplement({
    this.id,
    this.code,
    required this.name,
    required this.defaultDose,
    required this.unit,
    this.dailyGoal,
    this.dailyLimit,
    this.notes,
    this.isBuiltin = false,
  });

  factory Supplement.fromMap(Map<String, dynamic> map) {
    return Supplement(
      id: map['id'] as int?,
      code: map['code'] as String?, // NEU
      name: map['name'] as String,
      defaultDose: (map['default_dose'] as num).toDouble(),
      unit: map['unit'] as String,
      dailyGoal: (map['daily_goal'] as num?)?.toDouble(),
      dailyLimit: (map['daily_limit'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      isBuiltin: (map['is_builtin'] as int? ?? 0) == 1, // NEU
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code, // NEU
      'name': name,
      'default_dose': defaultDose,
      'unit': unit,
      'daily_goal': dailyGoal,
      'daily_limit': dailyLimit,
      'notes': notes,
      'is_builtin': isBuiltin ? 1 : 0, // NEU
    };
  }
}
