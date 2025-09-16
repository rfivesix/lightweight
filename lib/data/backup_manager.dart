// lib/data/backup_manager.dart (Finale Version)

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/lightweight_backup.dart';
import 'package:sqflite/sqflite.dart'; // KORREKTUR: Importiert das neue Modell
import 'package:shared_preferences/shared_preferences.dart';

class BackupManager {
  final _userDb = DatabaseHelper.instance;
  final _productDb = ProductDatabaseHelper.instance;
  final _workoutDb = WorkoutDatabaseHelper.instance;

  static const int currentSchemaVersion = 1;

  Future<bool> exportFullBackup() async {
    try {
      // ... (Logik zum Sammeln der Daten bleibt identisch)
      final foodEntries = await _userDb.getAllFoodEntries();
      final waterEntries = await _userDb.getAllWaterEntries();
      final favoriteBarcodes = await _userDb.getFavoriteBarcodes();
      final measurementSessions = await _userDb.getMeasurementSessions();
      final productDb = await _productDb.offDatabase;
      final customFoodMaps = await productDb?.query('products',
              where: 'barcode LIKE ?', whereArgs: ['user_created_%']) ??
          [];
      final customFoodItems = customFoodMaps
          .map((map) => FoodItem.fromMap(map, source: FoodItemSource.user))
          .toList();
      final routines = await _workoutDb.getAllRoutinesWithDetails();
      final workoutLogs = await _workoutDb.getFullWorkoutLogs();
      // --- HINZUGEFÜGT: Benutzereinstellungen auslesen ---
      final prefs = await SharedPreferences.getInstance();
      final userPrefs = <String, dynamic>{};
      final keys = prefs.getKeys();
      for (String key in keys) {
        userPrefs[key] = prefs.get(key);
      }

      final backup = LightweightBackup(
        // KORREKTUR: Nutzt das neue Modell
        schemaVersion: currentSchemaVersion,
        foodEntries: foodEntries,
        waterEntries: waterEntries,
        favoriteBarcodes: favoriteBarcodes,
        customFoodItems: customFoodItems,
        measurementSessions: measurementSessions,
        routines: routines,
        workoutLogs: workoutLogs,
        userPreferences: userPrefs,
      );
      final jsonString = jsonEncode(backup.toJson());

      // ... (Logik zum Speichern und Teilen der Datei bleibt identisch)
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final tempFile = File(
          '${tempDir.path}/lightweight_backup_v$currentSchemaVersion-[$timestamp].json');
      await tempFile.writeAsString(jsonString);
      final result = await Share.shareXFiles(
          [XFile(tempFile.path, mimeType: 'application/json')],
          subject: 'Lightweight App Backup - $timestamp');
      await tempFile.delete();
      return result.status == ShareResultStatus.success;
    } catch (e) {
      print("Fehler beim Exportieren der Daten: $e");
      return false;
    }
  }

  Future<bool> importFullBackup(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString);

      final backup = LightweightBackup.fromJson(
          jsonMap); // KORREKTUR: Nutzt das neue Modell

      if (backup.schemaVersion > currentSchemaVersion) {
        print(
            "Backup-Version (${backup.schemaVersion}) ist neuer als die App-Version ($currentSchemaVersion). Import abgebrochen.");
        return false;
      }

      // ... (Logik zum Löschen und Einfügen der Daten bleibt identisch)
      // HINZUGEFÜGT: Alte Einstellungen löschen
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await _userDb.clearAllUserData();
      await _workoutDb.clearAllWorkoutData();
      await _userDb.clearAllUserData();
      await _workoutDb.clearAllWorkoutData();
      final productDb = await _productDb.offDatabase;
      await productDb?.delete('products',
          where: 'barcode LIKE ?', whereArgs: ['user_created_%']);
      // HINZUGEFÜGT: Neue Einstellungen wiederherstellen
      for (final entry in backup.userPreferences.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }
      await _userDb.importUserData(
        foodEntries: backup.foodEntries,
        waterEntries: backup.waterEntries,
        favoriteBarcodes: backup.favoriteBarcodes,
        measurementSessions: backup.measurementSessions,
      );
      if (productDb != null) {
        final batch = productDb.batch();
        for (final item in backup.customFoodItems) {
          batch.insert('products', item.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      }
      await _workoutDb.importWorkoutData(
        routines: backup.routines,
        workoutLogs: backup.workoutLogs,
      );

      print("Import erfolgreich abgeschlossen.");
      return true;
    } catch (e) {
      print("Fehler beim Importieren der Daten: $e");
      return false;
    }
  }
  // --- NEUE METHODEN FÜR CSV-EXPORT ---

  /// Exportiert das gesamte Ernährungstagebuch als CSV-Datei.
  Future<bool> exportNutritionAsCsv() async {
    try {
      final entries = await _userDb.getAllFoodEntries();
      if (entries.isEmpty) return false; // Nichts zu exportieren

      // Performance-Optimierung: Alle benötigten Produkte auf einmal laden
      final uniqueBarcodes = entries.map((e) => e.barcode).toSet().toList();
      final products = await _productDb.getProductsByBarcodes(uniqueBarcodes);
      final productMap = {for (var p in products) p.barcode: p};

      List<List<dynamic>> rows = [];
      // Header-Zeile
      rows.add([
        'date',
        'time',
        'meal_type',
        'food_name',
        'brand',
        'quantity_grams',
        'calories_kcal',
        'protein_g',
        'carbs_g',
        'fat_g',
        'barcode'
      ]);

      for (final entry in entries) {
        final product = productMap[entry.barcode];
        if (product == null) continue;

        final factor = entry.quantityInGrams / 100.0;
        rows.add([
          DateFormat('yyyy-MM-dd').format(entry.timestamp),
          DateFormat('HH:mm').format(entry.timestamp),
          entry.mealType,
          product.name,
          product.brand,
          entry.quantityInGrams,
          (product.calories * factor).round(),
          (product.protein * factor).toStringAsFixed(1),
          (product.carbs * factor).toStringAsFixed(1),
          (product.fat * factor).toStringAsFixed(1),
          entry.barcode,
        ]);
      }
      return await _createAndShareCsv(rows, 'lightweight_nutrition_export');
    } catch (e) {
      print("Fehler beim CSV-Export der Ernährung: $e");
      return false;
    }
  }

  /// Exportiert alle Messwerte als CSV-Datei.
  Future<bool> exportMeasurementsAsCsv() async {
    try {
      final sessions = await _userDb.getMeasurementSessions();
      if (sessions.isEmpty) return false;

      List<List<dynamic>> rows = [];
      rows.add(['date', 'time', 'measurement_type', 'value', 'unit']);

      for (final session in sessions) {
        for (final measurement in session.measurements) {
          rows.add([
            DateFormat('yyyy-MM-dd').format(session.timestamp),
            DateFormat('HH:mm').format(session.timestamp),
            measurement.type,
            measurement.value,
            measurement.unit,
          ]);
        }
      }
      return await _createAndShareCsv(rows, 'lightweight_measurements_export');
    } catch (e) {
      print("Fehler beim CSV-Export der Messwerte: $e");
      return false;
    }
  }

  /// Exportiert den gesamten Trainingsverlauf als CSV-Datei.
  Future<bool> exportWorkoutsAsCsv() async {
    try {
      final logs = await _workoutDb.getFullWorkoutLogs();
      if (logs.isEmpty) return false;

      List<List<dynamic>> rows = [];
      rows.add([
        'workout_start_time',
        'workout_end_time',
        'routine_name',
        'exercise_name',
        'set_order',
        'set_type',
        'weight_kg',
        'reps',
        'rest_seconds',
        'notes'
      ]);

      for (final log in logs) {
        int setOrder = 1;
        for (final set in log.sets) {
          rows.add([
            log.startTime.toIso8601String(),
            log.endTime?.toIso8601String() ?? '',
            log.routineName ?? 'Freies Training',
            set.exerciseName,
            setOrder++,
            set.setType,
            set.weightKg ?? 0,
            set.reps ?? 0,
            set.restTimeSeconds ?? 0,
            log.notes ?? '',
          ]);
        }
      }
      return await _createAndShareCsv(rows, 'lightweight_workouts_export');
    } catch (e) {
      print("Fehler beim CSV-Export der Workouts: $e");
      return false;
    }
  }

  /// Private Helfer-Methode zum Erstellen, Speichern und Teilen einer CSV-Datei.
  Future<bool> _createAndShareCsv(
      List<List<dynamic>> rows, String baseFileName) async {
    final String csvData = const ListToCsvConverter().convert(rows);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tempFile = File('${tempDir.path}/$baseFileName-$timestamp.csv');
    await tempFile.writeAsString(csvData);

    final result = await Share.shareXFiles(
      [XFile(tempFile.path, mimeType: 'text/csv')],
      subject: baseFileName,
    );

    await tempFile.delete();
    return result.status == ShareResultStatus.success;
  }
}
