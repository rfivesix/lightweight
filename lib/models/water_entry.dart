class WaterEntry {
  final int? id;
  final DateTime timestamp;
  final int quantityInMl;

  WaterEntry({
    this.id,
    required this.timestamp,
    required this.quantityInMl,
  });

  factory WaterEntry.fromMap(Map<String, dynamic> map) {
    return WaterEntry(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      quantityInMl: map['quantity_in_ml'],
    );
  }
  // DOC: DIESE METHODE HINZUFÜGEN
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'quantity_in_ml': quantityInMl,
    };
  }
}
