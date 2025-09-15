// lib/models/food_entry.dart

class FoodEntry {
  final int? id;
  final String barcode;
  final DateTime timestamp;
  final int quantityInGrams;
  final String mealType;

  FoodEntry({
    this.id,
    required this.barcode,
    required this.timestamp,
    required this.quantityInGrams,
    required this.mealType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      // DOC: KORRIGIERTE ZEILE (Tippfehler "g" entfernt)
      'timestamp': timestamp.toIso8601String(), 
      'quantity_in_grams': quantityInGrams,
      'meal_type': mealType,
    };
  }
}