// lib/models/food_item.dart

enum FoodItemSource {
  off, // Open Food Facts
  base, // Grundnahrungsmittel-DB
  user // Vom Benutzer erstellt (Standard)
}

class FoodItem {
  final String barcode;
  final String name;
  final String brand;
  final int calories; // pro 100g
  final double protein; // pro 100g
  final double carbs; // pro 100g
  final double fat; // pro 100g
  final FoodItemSource source;

  final double? kj;
  final double? fiber;
  final double? sugar;
  final double? salt;
  final double? sodium;
  final double? calcium;
  final bool? isLiquid; // NEW (nullable)
  final double? caffeineMgPer100ml; // NEW (nullable)

  FoodItem({
    required this.barcode,
    required this.name,
    this.brand = '',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.source = FoodItemSource.user,
    this.kj,
    this.fiber,
    this.sugar,
    this.salt,
    this.sodium,
    this.calcium,
    this.isLiquid,
    this.caffeineMgPer100ml,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map,
      {required FoodItemSource source}) {
    return FoodItem(
      barcode: map['barcode'] ?? '',
      // KORREKTUR: Kein hartcodierter Fallback mehr. Die UI kümmert sich darum.
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      calories: (map['calories_100g'] as num?)?.round() ?? 0,
      protein: (map['protein_100g'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs_100g'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat_100g'] as num?)?.toDouble() ?? 0.0,
      source: source,
      kj: (map['kj_100g'] as num?)?.toDouble(),
      fiber: (map['fiber_100g'] as num?)?.toDouble(),
      sugar: (map['sugar_100g'] as num?)?.toDouble(),
      salt: (map['salt_100g'] as num?)?.toDouble(),
      sodium: (map['sodium_100g'] as num?)?.toDouble(),
      calcium: (map['calcium_100g'] as num?)?.toDouble(),
      isLiquid: _readBool(map['is_liquid']),
      caffeineMgPer100ml: _toDoubleOrNull(map['caffeine_mg_per_100ml']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'calories_100g': calories,
      'protein_100g': protein,
      'carbs_100g': carbs,
      'fat_100g': fat,
      'kj_100g': kj,
      'fiber_100g': fiber,
      'sugar_100g': sugar,
      'salt_100g': salt,
      'sodium_100g': sodium,
      'calcium_100g': calcium,
      'is_liquid': (isLiquid == null) ? null : (isLiquid! ? 1 : 0),
      'caffeine_mg_per_100ml': caffeineMgPer100ml,
    };
  }

  static bool? _readBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == '1' || s == 'true' || s == 'yes';
    }
    return null;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }
}
