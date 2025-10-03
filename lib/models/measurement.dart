// lib/models/measurement.dart

class Measurement {
  final int? id;
  final int sessionId;
  final String type;
  final double value;
  final String unit;

  Measurement({
    this.id,
    required this.sessionId,
    required this.type,
    required this.value,
    required this.unit,
  });

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'],
      sessionId: map['session_id'],
      type: map['type'],
      value: map['value'],
      unit: map['unit'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'type': type,
      'value': value,
      'unit': unit,
    };
  }
}
