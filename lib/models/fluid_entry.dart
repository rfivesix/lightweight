// lib/models/fluid_entry.dart

class FluidEntry {
  final int? id;
  final DateTime timestamp;
  final int quantityInMl;
  final String name;
  final int? kcal;
  final double? sugarPer100ml;
  final double? carbsPer100ml;
  final double? caffeinePer100ml;
  final int? linked_food_entry_id; // *** NEU ***

  FluidEntry({
    this.id,
    required this.timestamp,
    required this.quantityInMl,
    required this.name,
    this.kcal,
    this.sugarPer100ml,
    this.carbsPer100ml,
    this.caffeinePer100ml,
    this.linked_food_entry_id, // *** NEU ***
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'quantity_in_ml': quantityInMl,
      'name': name,
      'kcal': kcal,
      'sugar_per_100ml': sugarPer100ml,
      'carbs_per_100ml': carbsPer100ml,
      'caffeine_per_100ml': caffeinePer100ml,
      'linked_food_entry_id': linked_food_entry_id, // *** NEU ***
    };
  }

  static FluidEntry fromMap(Map<String, dynamic> map) {
    return FluidEntry(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      quantityInMl: map['quantity_in_ml'],
      name: map['name'],
      kcal: map['kcal'],
      sugarPer100ml: map['sugar_per_100ml'],
      carbsPer100ml: map['carbs_per_100ml'],
      caffeinePer100ml: map['caffeine_per_100ml'],
      linked_food_entry_id: map['linked_food_entry_id'], // *** NEU ***
    );
  }
}
