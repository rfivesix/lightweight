// lib/models/vita_backup.dart

import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/water_entry.dart';

class VitaBackup {
  final List<FoodEntry> foodEntries;
  final List<WaterEntry> waterEntries;
  final List<String> favoriteBarcodes;
  final List<FoodItem> customFoodItems;

  VitaBackup({
    required this.foodEntries,
    required this.waterEntries,
    required this.favoriteBarcodes,
    required this.customFoodItems,
  });

  factory VitaBackup.fromJson(Map<String, dynamic> json) {
    var foodEntriesList = json['foodEntries'] as List? ?? [];
    var waterEntriesList = json['waterEntries'] as List? ?? [];
    var favoriteBarcodesList = json['favoriteBarcodes'] as List? ?? [];
    var customFoodItemsList = json['customFoodItems'] as List? ?? [];

    return VitaBackup(
      foodEntries: foodEntriesList.map((item) {
        return FoodEntry(
          barcode: item['barcode'],
          timestamp: DateTime.parse(item['timestamp']),
          quantityInGrams: item['quantity_in_grams'],
          mealType: item['meal_type'],
        );
      }).toList(),
      waterEntries: waterEntriesList.map((item) => WaterEntry.fromMap(item)).toList(),
      favoriteBarcodes: List<String>.from(favoriteBarcodesList),
      // KORREKTUR: Fehlender 'source' Parameter hinzugefügt.
      // Eigene Lebensmittel aus einem Backup sind immer vom Typ 'user'.
      customFoodItems: customFoodItemsList.map((item) => FoodItem.fromMap(item, source: FoodItemSource.user)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodEntries': foodEntries.map((e) => e.toMap()).toList(),
      'waterEntries': waterEntries.map((e) => e.toMap()).toList(),
      'favoriteBarcodes': favoriteBarcodes,
      'customFoodItems': customFoodItems.map((e) => e.toMap()).toList(),
    };
  }
}