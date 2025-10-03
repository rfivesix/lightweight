// lib/models/supplement_log.dart

class SupplementLog {
  final int? id;
  final int supplementId;
  final double dose;
  final String unit;
  final DateTime timestamp;

  SupplementLog({
    this.id,
    required this.supplementId,
    required this.dose,
    required this.unit,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplement_id': supplementId,
      'dose': dose,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SupplementLog.fromMap(Map<String, dynamic> map) {
    return SupplementLog(
      id: map['id'],
      supplementId: map['supplement_id'],
      dose: map['dose'],
      unit: map['unit'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
