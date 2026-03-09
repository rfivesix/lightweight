// lib/data/backup_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

// Eigene Imports
import 'database_helper.dart';
import 'drift_database.dart'; // Zugriff auf Tabellen & Companions
import 'product_database_helper.dart';
import 'workout_database_helper.dart';
import '../models/food_item.dart';
import '../models/hypertrack_backup.dart';
import '../util/encryption_util.dart';

/// Manager responsible for application backup, restoration, and data export.
///
/// Supports full JSON backups with optional encryption and CSV exports for
/// nutrition, workouts, and measurements.
class BackupManager {
  // Singleton Pattern
  /// Singleton instance of [BackupManager].
  static final BackupManager instance = BackupManager._init();
  BackupManager._init();

  final _userDb = DatabaseHelper.instance;
  final _productDb = ProductDatabaseHelper.instance;
  final _workoutDb = WorkoutDatabaseHelper.instance;

  static const int currentSchemaVersion = 1;

  // ---------------------------------------------------------------------------
  // EXPORT (JSON / FULL BACKUP)
  // ---------------------------------------------------------------------------

  /// Exports a complete application backup as an unencrypted JSON file and shares it.
  Future<bool> exportFullBackup() async {
    try {
      final jsonString = await _generateBackupJson();
      return await _writeAndShareFile(jsonString, 'hypertrack_backup');
    } catch (e) {
      debugPrint("Fehler beim Exportieren: $e");
      return false;
    }
  }

  /// Exports a complete application backup as an encrypted JSON file and shares it.
  ///
  /// Uses [passphrase] for AES-256 encryption.
  Future<bool> exportFullBackupEncrypted(String passphrase) async {
    try {
      final jsonString = await _generateBackupJson();

      // Verschlüsseln
      final wrapper =
          await EncryptionUtil.encryptString(jsonString, passphrase);
      final wrappedJson = jsonEncode(wrapper);

      return await _writeAndShareFile(wrappedJson, 'hypertrack_backup_enc');
    } catch (e) {
      debugPrint("Fehler beim verschlüsselten Export: $e");
      return false;
    }
  }

  /// Hilfsmethode: Sammelt alle Daten und baut das JSON
  Future<String> _generateBackupJson() async {
    // 1. Daten aus den Helpern sammeln
    final foodEntries = await _userDb.getAllFoodEntries();
    final fluidEntries = await _userDb.getAllFluidEntries();
    final favoriteBarcodes = await _userDb.getFavoriteBarcodes();
    final measurementSessions = await _userDb.getMeasurementSessions();

    // 2. Custom Products direkt aus Drift laden
    final db = await _userDb.database;
    final customProductRows = await (db.select(db.products)
          ..where((t) => t.source.equals('user')))
        .get();

    final customFoodItems = customProductRows.map((row) {
      return FoodItem(
        barcode: row.barcode,
        name: row.name,
        brand: row.brand ?? '',
        calories: row.calories,
        protein: row.protein,
        carbs: row.carbs,
        fat: row.fat,
        source: FoodItemSource.user,
        sugar: row.sugar ?? 0.0,
        fiber: row.fiber ?? 0.0,
        salt: row.salt ?? 0.0,
        isLiquid: row.isLiquid,
        category: row.category,
      );
    }).toList();

    final routines = await _workoutDb.getAllRoutinesWithDetails();
    final workoutLogs = await _workoutDb.getFullWorkoutLogs();

    final supplements = await _userDb.getAllSupplements();
    final supplementLogs = await _userDb.getAllSupplementLogs();
    final customExercises = await _workoutDb.getCustomExercises();

    // 3. User Preferences
    final prefs = await SharedPreferences.getInstance();
    final userPrefs = <String, dynamic>{};
    for (String key in prefs.getKeys()) {
      userPrefs[key] = prefs.get(key);
    }

    // 4. Backup Objekt erstellen
    final backup = HypertrackBackup(
      schemaVersion: currentSchemaVersion,
      foodEntries: foodEntries,
      fluidEntries: fluidEntries,
      favoriteBarcodes: favoriteBarcodes,
      customFoodItems: customFoodItems,
      measurementSessions: measurementSessions,
      routines: routines,
      workoutLogs: workoutLogs,
      userPreferences: userPrefs,
      supplements: supplements,
      supplementLogs: supplementLogs,
      customExercises: customExercises,
    );

    return jsonEncode(backup.toJson());
  }

  Future<bool> _writeAndShareFile(String content, String baseName) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final tempFile = File(
        '${tempDir.path}/$baseName-v$currentSchemaVersion-[$timestamp].json');
    await tempFile.writeAsString(content);

    // FIX: Neue API nutzen (Share.shareXFiles ist korrekt, aber wir müssen XFile korrekt importieren)
    final result = await Share.shareXFiles([
      XFile(tempFile.path, mimeType: 'application/json'),
    ], subject: 'Hypertrack Backup $timestamp');

    if (await tempFile.exists()) await tempFile.delete();
    return result.status == ShareResultStatus.success;
  }

  // ---------------------------------------------------------------------------
  // IMPORT
  // ---------------------------------------------------------------------------

  /// Imports a full application backup from the provided [filePath].
  Future<bool> importFullBackup(String filePath) async {
    return importFullBackupAuto(filePath, passphrase: null);
  }

  /// Imports a full application backup from [filePath], auto-detecting encryption.
  ///
  /// If the backup is encrypted, [passphrase] must be provided.
  Future<bool> importFullBackupAuto(String filePath,
      {String? passphrase}) async {
    try {
      final file = File(filePath);
      final rawString = await file.readAsString();
      final jsonMapRaw = jsonDecode(rawString);

      Map<String, dynamic> payload;

      if (jsonMapRaw is Map &&
          (jsonMapRaw['enc'] == EncryptionUtil.wrapperVersionV1 ||
              jsonMapRaw['enc'] == EncryptionUtil.wrapperVersionV2)) {
        final effectivePw = passphrase ?? "";
        try {
          final clearText = await EncryptionUtil.decryptToString(
              Map<String, dynamic>.from(jsonMapRaw), effectivePw);
          payload = jsonDecode(clearText) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Entschlüsselung fehlgeschlagen: $e');
          return false;
        }
      } else {
        payload = (jsonMapRaw as Map).cast<String, dynamic>();
      }

      final backup = HypertrackBackup.fromJson(payload);

      if (backup.schemaVersion > currentSchemaVersion) {
        debugPrint("Backup-Version zu neu.");
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _userDb.clearAllUserData();
      await _workoutDb.clearAllWorkoutData();

      final db = await _userDb.database;
      await (db.delete(db.products)..where((t) => t.source.equals('user')))
          .go();

      for (final entry in backup.userPreferences.entries) {
        final key = entry.key;
        final val = entry.value;
        if (val is bool) {
          await prefs.setBool(key, val);
        } else if (val is int) {
          await prefs.setInt(key, val);
        } else if (val is double) {
          await prefs.setDouble(key, val);
        } else if (val is String) {
          await prefs.setString(key, val);
        } else if (val is List) {
          await prefs.setStringList(key, val.cast<String>());
        }
      }

      await _userDb.importUserData(
        foodEntries: backup.foodEntries,
        fluidEntries: backup.fluidEntries,
        favoriteBarcodes: backup.favoriteBarcodes,
        measurementSessions: backup.measurementSessions,
        supplements: backup.supplements,
        supplementLogs: backup.supplementLogs,
      );

      await db.batch((batch) {
        for (final item in backup.customFoodItems) {
          batch.insert(
              db.products,
              ProductsCompanion(
                barcode: drift.Value(item.barcode),
                name: drift.Value(item.name),
                brand: drift.Value(item.brand),
                calories: drift.Value(item.calories),
                protein: drift.Value(item.protein),
                carbs: drift.Value(item.carbs),
                fat: drift.Value(item.fat),
                sugar: drift.Value(item.sugar),
                fiber: drift.Value(item.fiber),
                salt: drift.Value(item.salt),
                source: const drift.Value('user'),
                // FIX: Fallback '?? false', falls der Wert null ist
                isLiquid: drift.Value(item.isLiquid ?? false),
                category: drift.Value(item.category),
                id: drift.Value(item.barcode.startsWith('user_')
                    ? item.barcode
                    : 'user_${item.barcode}'),
              ),
              mode: drift.InsertMode.insertOrReplace);
        }
      });

      await _workoutDb.importWorkoutData(
        routines: backup.routines,
        workoutLogs: backup.workoutLogs,
      );

      await _workoutDb.importCustomExercises(backup.customExercises);

      debugPrint("Import erfolgreich.");
      return true;
    } catch (e) {
      debugPrint("Fehler beim Importieren: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // AUTO BACKUP
  // ---------------------------------------------------------------------------

  /// Runs an automatic backup if the specified [interval] has passed since the last backup.
  ///
  /// Supports encryption via [passphrase] and keeps [retention] number of old backups.
  Future<bool> runAutoBackupIfDue({
    Duration interval = const Duration(days: 1),
    bool encrypted = false,
    String? passphrase,
    int retention = 7,
    String? dirPath,
    bool force = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt('auto_backup_last_ms') ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (!force && (nowMs - lastMs < interval.inMilliseconds)) {
        return false;
      }

      String content = await _generateBackupJson();
      String fileName = 'hypertrack_auto_v$currentSchemaVersion';

      // FIX: Strenger bool check
      if (encrypted) {
        if (passphrase == null || passphrase.isEmpty) return false;
        final wrapper = await EncryptionUtil.encryptString(content, passphrase);
        content = jsonEncode(wrapper);
        fileName = 'hypertrack_auto_enc_v$currentSchemaVersion';
      }

      final docs = await getApplicationDocumentsDirectory();
      final savedDir = prefs.getString('auto_backup_dir');

      Directory baseDir;
      if (dirPath != null && dirPath.isNotEmpty) {
        baseDir = Directory(dirPath);
      } else if (savedDir != null && savedDir.isNotEmpty) {
        baseDir = Directory(savedDir);
      } else {
        baseDir = Directory(p.join(docs.path, 'Backups'));
      }

      if (!await baseDir.exists()) {
        try {
          await baseDir.create(recursive: true);
        } catch (e) {
          baseDir = Directory(p.join(docs.path, 'Backups'));
          await baseDir.create(recursive: true);
        }
      }

      final ts = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final file = File(p.join(baseDir.path, '$fileName-[$ts].json'));
      await file.writeAsString(content);

      try {
        final files = baseDir
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith('hypertrack_auto'))
            .toList()
          ..sort(
              (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

        if (files.length > retention) {
          for (var i = retention; i < files.length; i++) {
            files[i].deleteSync();
          }
        }
      } catch (_) {}

      await prefs.setInt('auto_backup_last_ms', nowMs);
      return true;
    } catch (e) {
      debugPrint("Auto-Backup Fehler: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // CSV EXPORT
  // ---------------------------------------------------------------------------

  /// Exports all nutrition logs as a CSV file and shares it.
  Future<bool> exportNutritionAsCsv() async {
    try {
      final entries = await _userDb.getAllFoodEntries();
      if (entries.isEmpty) return false;

      final uniqueBarcodes = entries.map((e) => e.barcode).toSet().toList();
      final products = await _productDb.getProductsByBarcodes(uniqueBarcodes);
      final productMap = {for (var p in products) p.barcode: p};

      List<List<dynamic>> rows = [];
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
      return await _createAndShareCsv(rows, 'hypertrack_nutrition_export');
    } catch (e) {
      debugPrint("CSV Export Fehler (Nutrition): $e");
      return false;
    }
  }

  /// Exports all workout logs as a CSV file and shares it.
  Future<bool> exportWorkoutsAsCsv() async {
    try {
      final logs = await _workoutDb.getFullWorkoutLogs();
      if (logs.isEmpty) return false;

      List<List<dynamic>> rows = [];
      rows.add([
        'start_time',
        'end_time',
        'routine',
        'exercise',
        'set_order',
        'type',
        'weight_kg',
        'reps',
        'rest_sec',
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
      return await _createAndShareCsv(rows, 'hypertrack_workouts_export');
    } catch (e) {
      debugPrint("CSV Export Fehler (Workout): $e");
      return false;
    }
  }

  /// Exports all body measurements as a CSV file and shares it.
  Future<bool> exportMeasurementsAsCsv() async {
    try {
      final sessions = await _userDb.getMeasurementSessions();
      if (sessions.isEmpty) return false;

      List<List<dynamic>> rows = [];
      rows.add(['date', 'time', 'type', 'value', 'unit']);

      for (final session in sessions) {
        for (final m in session.measurements) {
          rows.add([
            DateFormat('yyyy-MM-dd').format(session.timestamp),
            DateFormat('HH:mm').format(session.timestamp),
            m.type,
            m.value,
            m.unit
          ]);
        }
      }
      return await _createAndShareCsv(rows, 'hypertrack_measurements_export');
    } catch (e) {
      debugPrint("CSV Export Fehler (Measure): $e");
      return false;
    }
  }

  Future<bool> _createAndShareCsv(
      List<List<dynamic>> rows, String baseName) async {
    final String csvData = const ListToCsvConverter().convert(rows);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tempFile = File('${tempDir.path}/$baseName-$timestamp.csv');
    await tempFile.writeAsString(csvData);

    final result = await Share.shareXFiles([
      XFile(tempFile.path, mimeType: 'text/csv'),
    ], subject: baseName);

    await tempFile.delete();
    return result.status == ShareResultStatus.success;
  }
}
