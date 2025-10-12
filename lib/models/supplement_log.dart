// lib/models/supplement_log.dart

class SupplementLog {
  final int? id;
  final int supplementId;
  final double dose;
  final String unit;
  final DateTime timestamp;
  // --- KORREKTUR START ---
  final int? source_food_entry_id;
  final int? source_fluid_entry_id;

  SupplementLog({
    this.id,
    required this.supplementId,
    required this.dose,
    required this.unit,
    required this.timestamp,
    this.source_food_entry_id, // Jetzt als optionaler Parameter verfügbar
    this.source_fluid_entry_id, // Jetzt als optionaler Parameter verfügbar
  });
  // --- KORREKTUR ENDE ---

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplement_id': supplementId,
      'dose': dose,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      // --- KORREKTUR START ---
      'source_food_entry_id': source_food_entry_id,
      'source_fluid_entry_id': source_fluid_entry_id,
      // --- KORREKTUR ENDE ---
    };
  }

  factory SupplementLog.fromMap(Map<String, dynamic> map) {
    return SupplementLog(
      id: map['id'],
      supplementId: map['supplement_id'],
      dose: map['dose'],
      unit: map['unit'],
      timestamp: DateTime.parse(map['timestamp']),
      // --- KORREKTUR START ---
      source_food_entry_id: map['source_food_entry_id'],
      source_fluid_entry_id: map['source_fluid_entry_id'],
      // --- KORREKTUR ENDE ---
    );
  }
}
