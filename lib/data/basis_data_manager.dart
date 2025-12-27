import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/drift_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:drift/drift.dart' as drift;

class BasisDataManager {
  static final BasisDataManager instance = BasisDataManager._init();
  BasisDataManager._init();

  static const String _keyVersionTraining = 'installed_training_version';
  static const String _keyVersionFood = 'installed_food_version';
  static const String _keyVersionOff = 'installed_off_version';
  static const String _keyVersionCats =
      'installed_cats_version'; // Neuer Key für Kategorien

  int _parseInt(dynamic value) => (value as num?)?.toInt() ?? 0;
  double _parseDouble(dynamic value) => (value as num?)?.toDouble() ?? 0.0;
  String _parseString(dynamic value) => value?.toString() ?? '';

  Future<void> checkForBasisDataUpdate({bool force = false}) async {
    debugPrint("BasisDataManager: Starte Check (Force: $force)...");
    final prefs = await SharedPreferences.getInstance();

    if (force) {
      await prefs.remove(_keyVersionTraining);
      await prefs.remove(_keyVersionFood);
      await prefs.remove(_keyVersionOff);
      await prefs.remove(_keyVersionCats); // Cache für Kategorien auch leeren
      debugPrint("Cache geleert. Import wird erzwungen.");
    }

    // 1. Übungen
    await _updateDatabaseFromAsset(
      assetPath: 'assets/db/vita_training.db',
      prefKey: _keyVersionTraining,
      prefs: prefs,
      tableName: 'exercises',
      mapFunction: _mapExerciseRow,
    );

    // 2a. Base Foods (Produkte)
    await _updateDatabaseFromAsset(
      assetPath: 'assets/db/vita_base_foods.db',
      prefKey: _keyVersionFood,
      prefs: prefs,
      tableName: 'products',
      mapFunction: (row) => _mapProductRow(row, sourceLabel: 'base'),
    );

    // 2b. KATEGORIEN (Das hat gefehlt!)
    // Wir holen aus derselben Datei 'vita_base_foods.db' die Tabelle 'categories'
    await _updateDatabaseFromAsset(
      assetPath: 'assets/db/vita_base_foods.db',
      prefKey: _keyVersionCats,
      prefs: prefs,
      tableName: 'categories', // So heißt die Tabelle in deiner SQLite Datei
      driftTableName: 'food_categories', // So heißt sie in Drift (siehe Logs)
      mapFunction: _mapCategoryRow,
    );

    // 3. OFF Datenbank
    await _updateDatabaseFromAsset(
      assetPath: 'assets/db/vita_prep_de.db',
      prefKey: _keyVersionOff,
      prefs: prefs,
      tableName: 'products',
      mapFunction: (row) => _mapProductRow(row, sourceLabel: 'off'),
    );
  }

  Future<void> _updateDatabaseFromAsset({
    required String assetPath,
    required String prefKey,
    required SharedPreferences prefs,
    required String tableName, // Name in der Quell-Datei
    String? driftTableName, // Optional: Name in der Ziel-DB (falls anders)
    required Function(Map<String, dynamic>) mapFunction,
  }) async {
    File? tempFile;
    sqflite.Database? assetDb;

    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(tempDir.path, p.basename(assetPath));

      try {
        final byteData = await rootBundle.load(assetPath);
        tempFile = File(tempPath);
        await tempFile.writeAsBytes(byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      } catch (e) {
        debugPrint("Asset fehlt: $assetPath");
        return;
      }

      assetDb = await sqflite.openDatabase(tempPath, readOnly: true);

      // Check ob Quell-Tabelle existiert
      var checkTable = tableName;
      if (tableName == 'exercises') {
        final tables = await assetDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='exercises'");
        if (tables.isEmpty) checkTable = 'exercise';
      } else {
        // Genereller Check
        final tables = await assetDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
        if (tables.isEmpty) {
          debugPrint(
              "WARNUNG: Quell-Tabelle '$tableName' nicht in $assetPath gefunden. Überspringe.");
          return;
        }
      }

      String assetVersion = '0';
      try {
        final metaRows = await assetDb
            .query('metadata', where: 'key = ?', whereArgs: ['version']);
        if (metaRows.isNotEmpty) {
          assetVersion = metaRows.first['value'] as String;
        }
      } catch (_) {}

      final String installedVersion = prefs.getString(prefKey) ?? '0';

      if (assetVersion.compareTo(installedVersion) > 0 ||
          installedVersion == '0') {
        debugPrint(
            ">>> IMPORT START: $checkTable -> ${driftTableName ?? 'Default'} (v$assetVersion)...");
        await _performBatchImport(assetDb, checkTable, mapFunction);
        await prefs.setString(prefKey, assetVersion);
        debugPrint(">>> IMPORT FERTIG: $checkTable gespeichert.");
      } else {
        debugPrint("Aktuell: $checkTable (v$installedVersion).");
      }
    } catch (e) {
      debugPrint("!!! FEHLER bei $assetPath ($tableName): $e");
    } finally {
      await assetDb?.close();
      if (tempFile != null && await tempFile.exists()) await tempFile.delete();
    }
  }

  Future<void> _performBatchImport(sqflite.Database assetDb, String tableName,
      Function(Map<String, dynamic>) mapRowToCompanion) async {
    final mainDb = await DatabaseHelper.instance.database;
    const int batchSize = 2000;
    int offset = 0;

    while (true) {
      final rows =
          await assetDb.query(tableName, limit: batchSize, offset: offset);
      if (rows.isEmpty) break;

      await mainDb.batch((batch) {
        for (final row in rows) {
          try {
            final companion = mapRowToCompanion(row);
            if (companion is ProductsCompanion) {
              batch.insert(mainDb.products, companion,
                  mode: drift.InsertMode.insertOrReplace);
            } else if (companion is ExercisesCompanion) {
              batch.insert(mainDb.exercises, companion,
                  mode: drift.InsertMode.insertOrReplace);
            } else if (companion is FoodCategoriesCompanion) {
              // HIER landen die Kategorien!
              batch.insert(mainDb.foodCategories, companion,
                  mode: drift.InsertMode.insertOrReplace);
            }
          } catch (e) {
            // debugPrint("Fehler Zeile: $e");
          }
        }
      });
      offset += batchSize;
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  // --- MAPPING FUNKTIONEN ---

  dynamic _mapProductRow(Map<String, dynamic> row,
      {required String sourceLabel}) {
    final barcode = _parseString(row['barcode']);
    String id;
    if (row['id'] != null) {
      id = _parseString(row['id']);
    } else if (barcode.isNotEmpty) {
      id = 'manual_$barcode';
    } else {
      id = 'manual_${_parseString(row['name']).replaceAll(RegExp(r'\s+'), '')}';
    }

    return ProductsCompanion(
      id: drift.Value(id),
      barcode: drift.Value(barcode),
      name: drift.Value(_parseString(row['name_de'] ?? row['name'])),
      brand: drift.Value(_parseString(row['brand'])),
      calories: drift.Value(_parseInt(row['calories'])),
      protein: drift.Value(_parseDouble(row['protein'])),
      carbs: drift.Value(_parseDouble(row['carbs'])),
      fat: drift.Value(_parseDouble(row['fat'])),
      sugar: drift.Value(_parseDouble(row['sugar'])),
      fiber: drift.Value(_parseDouble(row['fiber'])),
      salt: drift.Value(_parseDouble(row['salt'])),
      source: drift.Value(sourceLabel),
      isLiquid: drift.Value(_parseInt(row['is_liquid']) == 1),
      category: drift.Value(row['category']?.toString()),
    );
  }

  // NEU: Mapping für Kategorien
  dynamic _mapCategoryRow(Map<String, dynamic> row) {
    return FoodCategoriesCompanion(
      key: drift.Value(_parseString(row['key'])),
      nameDe: drift.Value(row['name_de'] as String?),
      nameEn: drift.Value(row['name_en'] as String?),
      emoji: drift.Value(row['emoji'] as String?),
    );
  }

  dynamic _mapExerciseRow(Map<String, dynamic> row) {
    return ExercisesCompanion(
      id: drift.Value(_parseString(row['id'])),
      nameDe: drift.Value(_parseString(row['name_de'] ?? row['name_en'])),
      nameEn: drift.Value(_parseString(row['name_en'])),
      descriptionDe: drift.Value(_parseString(row['description_de'])),
      descriptionEn: drift.Value(_parseString(row['description_en'])),
      categoryName: drift.Value(_parseString(row['category_name'])),
      musclesPrimary: drift.Value(_parseString(row['muscles_primary'])),
      musclesSecondary: drift.Value(_parseString(row['muscles_secondary'])),
      isCustom: const drift.Value(false),
      createdBy: const drift.Value('system'),
      source: const drift.Value('base'),
    );
  }
}
