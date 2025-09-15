// lib/data/backup_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/vita_backup.dart';
import 'package:lightweight/models/water_entry.dart';

class BackupManager {
  final _userDb = DatabaseHelper.instance;
  final _productDb = ProductDatabaseHelper.instance;

  Future<bool> exportData() async {
    try {
      print("Sammle Daten für den Export...");
      final foodDb = await _userDb.database;
      final foodEntriesMaps = await foodDb.query('food_entries');
      final foodEntries = foodEntriesMaps.map((map) => FoodEntry(id: map['id'] as int?, barcode: map['barcode'] as String, timestamp: DateTime.parse(map['timestamp'] as String), quantityInGrams: map['quantity_in_grams'] as int, mealType: map['meal_type'] as String)).toList();
      final waterEntriesMaps = await foodDb.query('water_entries');
      final waterEntries = waterEntriesMaps.map((map) => WaterEntry.fromMap(map)).toList();
      final favoriteBarcodes = await _userDb.getFavoriteBarcodes();

      // KORREKTUR: Zugriff auf den neuen Getter 'offDatabase'
      final productDb = await _productDb.offDatabase;
      if (productDb == null) {
        print("Produktdatenbank nicht gefunden. Export der eigenen Lebensmittel nicht möglich.");
        return false;
      }
      final customFoodMaps = await productDb.query('products', where: 'barcode LIKE ?', whereArgs: ['user_created_%']);
      // KORREKTUR: Fehlender 'source' Parameter hinzugefügt
      final customFoodItems = customFoodMaps.map((map) => FoodItem.fromMap(map, source: FoodItemSource.user)).toList();

      final backup = VitaBackup(
        foodEntries: foodEntries,
        waterEntries: waterEntries,
        favoriteBarcodes: favoriteBarcodes,
        customFoodItems: customFoodItems,
      );
      final jsonString = jsonEncode(backup.toJson());

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final tempFile = File('${tempDir.path}/vita_backup_$timestamp.json');
      await tempFile.writeAsString(jsonString);

      print("Temporäre Backup-Datei erstellt unter: ${tempFile.path}");

      final result = await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'application/json')],
        subject: 'Vita App Backup - $timestamp',
      );
      
      await tempFile.delete();

      if (result.status == ShareResultStatus.success) {
        print("Backup erfolgreich geteilt/gespeichert.");
        return true;
      } else {
        print("Nutzer hat den Speichern/Teilen-Dialog abgebrochen.");
        return false;
      }

    } catch (e) {
      print("Fehler beim Exportieren der Daten: $e");
      return false;
    }
  }

  Future<bool> importData(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString);

      final backup = VitaBackup.fromJson(jsonMap);

      print("Lösche alte Nutzerdaten...");
      final userDb = await _userDb.database;
      await userDb.transaction((txn) async {
        await txn.delete('food_entries');
        await txn.delete('water_entries');
        await txn.delete('favorites');
      });

      print("Lösche alte eigene Lebensmittel...");
      // KORREKTUR: Zugriff auf den neuen Getter 'offDatabase'
      final productDb = await _productDb.offDatabase;
       if (productDb == null) {
        print("Produktdatenbank nicht gefunden. Import der eigenen Lebensmittel nicht möglich.");
        return false;
      }
      await productDb.delete('products', where: 'barcode LIKE ?', whereArgs: ['user_created_%']);

      print("Füge neue Daten ein...");
      await userDb.transaction((txn) async {
        for (final entry in backup.foodEntries) {
          await txn.insert('food_entries', entry.toMap());
        }
        for (final entry in backup.waterEntries) {
          await txn.insert('water_entries', entry.toMap());
        }
        for (final barcode in backup.favoriteBarcodes) {
          await txn.insert('favorites', {'barcode': barcode});
        }
      });
      
      await productDb.transaction((txn) async {
        for (final item in backup.customFoodItems) {
          await txn.insert('products', item.toMap());
        }
      });

      print("Import erfolgreich abgeschlossen.");
      return true;

    } catch (e) {
      print("Fehler beim Importieren der Daten: $e");
      return false;
    }
  }
}