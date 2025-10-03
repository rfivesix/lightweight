// lib/data/backup_manager.dart (Finale Version)

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
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
import 'package:lightweight/util/encryption_util.dart';
import 'package:path/path.dart' as p;
import 'dart:typed_data';
import 'package:archive/archive.dart'; // for GZipDecoder (add to pubspec if not present)

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
      final supplements = await _userDb.getAllSupplements();
      final supplementLogs = await _userDb.getAllSupplementLogs();
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
        supplements: supplements,
        supplementLogs: supplementLogs,
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
      final supplements = await _userDb.getAllSupplements();
      final supplementLogs = await _userDb.getAllSupplementLogs();
      await _userDb.importUserData(
        foodEntries: backup.foodEntries,
        waterEntries: backup.waterEntries,
        favoriteBarcodes: backup.favoriteBarcodes,
        measurementSessions: backup.measurementSessions,
        supplements: supplements,
        supplementLogs: supplementLogs,
      );
      if (productDb != null) {
        final cols = await _getTableColumns(productDb, 'products'); // <-- neu
        final batch = productDb.batch();
        for (final item in backup.customFoodItems) {
          final raw = item.toMap();
          final filtered = _filterMapForColumns(raw, cols); // <-- neu
          batch.insert(
            'products',
            filtered,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
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

  Future<bool> exportFullBackupEncrypted(String passphrase) async {
    try {
      // Daten sammeln (wie in exportFullBackup)
      final foodEntries = await _userDb.getAllFoodEntries();
      final waterEntries = await _userDb.getAllWaterEntries();
      final favoriteBarcodes = await _userDb.getFavoriteBarcodes();
      final measurementSessions = await _userDb.getMeasurementSessions();
      final productDb = await _productDb.offDatabase;
      final customFoodMaps = await productDb?.query(
            'products',
            where: 'barcode LIKE ?',
            whereArgs: ['user_created_%'],
          ) ??
          [];
      final customFoodItems = customFoodMaps
          .map((m) => FoodItem.fromMap(m, source: FoodItemSource.user))
          .toList();
      final routines = await _workoutDb.getAllRoutinesWithDetails();
      final workoutLogs = await _workoutDb.getFullWorkoutLogs();
      final prefs = await SharedPreferences.getInstance();
      final userPrefs = <String, dynamic>{};
      for (final k in prefs.getKeys()) {
        userPrefs[k] = prefs.get(k);
      }
      final supplements = await _userDb.getAllSupplements();
      final supplementLogs = await _userDb.getAllSupplementLogs();
      final backup = LightweightBackup(
        schemaVersion: currentSchemaVersion,
        foodEntries: foodEntries,
        waterEntries: waterEntries,
        favoriteBarcodes: favoriteBarcodes,
        customFoodItems: customFoodItems,
        measurementSessions: measurementSessions,
        routines: routines,
        workoutLogs: workoutLogs,
        userPreferences: userPrefs,
        supplements: supplements,
        supplementLogs: supplementLogs,
      );
      final jsonString = jsonEncode(backup.toJson());

      // Verschlüsseln
      final wrapper =
          await EncryptionUtil.encryptString(jsonString, passphrase);
      final wrappedJson = jsonEncode(wrapper);

      final tempDir = await getTemporaryDirectory();
      final ts = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final tempFile = File(
        p.join(tempDir.path,
            'lightweight_backup_enc_v$currentSchemaVersion-[$ts].json'),
      );
      await tempFile.writeAsString(wrappedJson);
      final result = await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'application/json')],
        subject: 'Lightweight Encrypted Backup - $ts',
      );
      await tempFile.delete();
      return result.status == ShareResultStatus.success;
    } catch (e) {
      print('Fehler beim verschlüsselten Export: $e');
      return false;
    }
  }

  Future<bool> importFullBackupAuto(String filePath,
      {String? passphrase}) async {
    try {
      final file = File(filePath);
      final raw = await file.readAsString();
      final top = jsonDecode(raw);

      Map<String, dynamic> payload;
      if (top is Map && top['enc'] == EncryptionUtil.wrapperVersion) {
        // Leeres Passwort zulassen (Legacy-Cases) – EncryptionUtil sollte "" akzeptieren
        final effectivePw = (passphrase ?? "");
        try {
          final clear = await EncryptionUtil.decryptToString(
            Map<String, dynamic>.from(top),
            effectivePw,
          );
          payload = jsonDecode(clear) as Map<String, dynamic>;
        } catch (e) {
          // Falsches/fehlendes Passwort → sauber false zurückgeben,
          // damit der UI-Flow den Dialog zeigen/erneut versuchen kann.
          print('Decrypt failed: $e');
          return false;
        }
      } else {
        // Unverschlüsselt (plain JSON)
        payload = (top as Map).cast<String, dynamic>();
      }

      final backup = LightweightBackup.fromJson(payload);
      if (backup.schemaVersion > currentSchemaVersion) {
        print(
            'Backup-Version (${backup.schemaVersion}) ist neuer als App-Version ($currentSchemaVersion).');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _userDb.clearAllUserData();
      await _workoutDb.clearAllWorkoutData();

      final productDb = await _productDb.offDatabase;
      await productDb?.delete('products',
          where: 'barcode LIKE ?', whereArgs: ['user_created_%']);

      for (final e in backup.userPreferences.entries) {
        final k = e.key;
        final v = e.value;
        if (v is bool) {
          await prefs.setBool(k, v);
        } else if (v is int)
          await prefs.setInt(k, v);
        else if (v is double)
          await prefs.setDouble(k, v);
        else if (v is String)
          await prefs.setString(k, v);
        else if (v is List<String>) await prefs.setStringList(k, v);
      }

      await _userDb.importUserData(
        foodEntries: backup.foodEntries,
        waterEntries: backup.waterEntries,
        favoriteBarcodes: backup.favoriteBarcodes,
        measurementSessions: backup.measurementSessions,
        supplements: backup.supplements, // NEU
        supplementLogs: backup.supplementLogs, // NEU
      );

      if (productDb != null) {
        final cols = await _getTableColumns(productDb, 'products'); // <-- neu
        final batch = productDb.batch();
        for (final item in backup.customFoodItems) {
          final raw = item.toMap();
          final filtered = _filterMapForColumns(raw, cols); // <-- neu
          batch.insert(
            'products',
            filtered,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }

      await _workoutDb.importWorkoutData(
        routines: backup.routines,
        workoutLogs: backup.workoutLogs,
      );

      print('Import erfolgreich (auto).');
      return true;
    } catch (e) {
      print('Fehler beim Auto-Import: $e');
      return false;
    }
  }

// lib/data/backup_manager.dart

  Future<bool> runAutoBackupIfDue({
    Duration interval = const Duration(days: 1),
    bool encrypted = false,
    String? passphrase,
    int retention = 7,
    String? dirPath,
    bool force = false, // NEU
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt('auto_backup_last_ms') ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (!force && (nowMs - lastMs < interval.inMilliseconds)) {
        print('Auto-Backup: nicht fällig (force=false)'); // Hinweis
        return false;
      }

      // 1) Daten sammeln (wie schon implementiert)
      final foodEntries = await _userDb.getAllFoodEntries();
      final waterEntries = await _userDb.getAllWaterEntries();
      final favoriteBarcodes = await _userDb.getFavoriteBarcodes();
      final measurementSessions = await _userDb.getMeasurementSessions();
      final productDb = await _productDb.offDatabase;
      final customFoodMaps = await productDb?.query(
            'products',
            where: 'barcode LIKE ?',
            whereArgs: ['user_created_%'],
          ) ??
          [];
      final customFoodItems = customFoodMaps
          .map((m) => FoodItem.fromMap(m, source: FoodItemSource.user))
          .toList();
      final routines = await _workoutDb.getAllRoutinesWithDetails();
      final workoutLogs = await _workoutDb.getFullWorkoutLogs();
      final userPrefs = <String, dynamic>{};
      for (final k in prefs.getKeys()) {
        userPrefs[k] = prefs.get(k);
      }
      final supplements = await _userDb.getAllSupplements();
      final supplementLogs = await _userDb.getAllSupplementLogs();
      final backup = LightweightBackup(
        schemaVersion: currentSchemaVersion,
        foodEntries: foodEntries,
        waterEntries: waterEntries,
        favoriteBarcodes: favoriteBarcodes,
        customFoodItems: customFoodItems,
        measurementSessions: measurementSessions,
        routines: routines,
        workoutLogs: workoutLogs,
        userPreferences: userPrefs,
        supplements: supplements,
        supplementLogs: supplementLogs,
      );
      final jsonString = jsonEncode(backup.toJson());

      // 2) Zielordner auflösen
      final docs = await getApplicationDocumentsDirectory();
      final saved = prefs.getString('auto_backup_dir');
      Directory baseDir = (dirPath != null && dirPath.trim().isNotEmpty)
          ? Directory(dirPath)
          : ((saved != null && saved.trim().isNotEmpty)
              ? Directory(saved)
              : Directory(p.join(docs.path, 'Backups')));
      await baseDir.create(recursive: true);
      final ts = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());

      // 3) Klar/verschlüsselt vorbereiten
      late final String content;
      late final String name;
      if (encrypted) {
        if (passphrase == null || passphrase.isEmpty) {
          print('Auto-Backup ENC: Passwort fehlt');
          return false;
        }
        final wrapper =
            await EncryptionUtil.encryptString(jsonString, passphrase);
        content = jsonEncode(wrapper);
        name = 'lightweight_auto_enc_v$currentSchemaVersion-[$ts].json';
      } else {
        content = jsonString;
        name = 'lightweight_auto_v$currentSchemaVersion-[$ts].json';
      }

      // 4) Schreiben mit Fallback bei Fehler
      File outFile = File(p.join(baseDir.path, name));
      try {
        await outFile.writeAsString(content);
      } on FileSystemException catch (e) {
        print(
            'Auto-Backup: Schreiben in $baseDir fehlgeschlagen, Fallback → App-Ordner ($e)');
        baseDir = Directory(p.join(docs.path, 'Backups'));
        await baseDir.create(recursive: true);
        outFile = File(p.join(baseDir.path, name));
        await outFile.writeAsString(content);
      }

      print('Auto-Backup geschrieben: ${outFile.path}');

      // 5) Retention
      final files = baseDir
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('lightweight_auto'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      for (var i = retention; i < files.length; i++) {
        try {
          files[i].deleteSync();
        } catch (_) {}
      }

      await prefs.setInt('auto_backup_last_ms', nowMs);
      return true;
    } catch (e) {
      print('Auto-Backup fehlgeschlagen: $e');
      return false;
    }
  }

  Future<Set<String>> _getTableColumns(Database db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((r) => (r['name'] as String)).toSet();
  }

  Map<String, Object?> _filterMapForColumns(
    Map<String, Object?> src,
    Set<String> allowedCols,
  ) {
    final out = <String, Object?>{};
    src.forEach((k, v) {
      if (allowedCols.contains(k)) out[k] = v;
    });
    return out;
  }
}

class ProbeResult {
  final bool encrypted;
  final bool gzipped;
  ProbeResult({required this.encrypted, required this.gzipped});
}

ProbeResult _probeBackup(Uint8List bytes) {
  // 1) Quick JSON sniff
  if (bytes.isNotEmpty &&
      (bytes.first == 0x7B /* '{' */ || bytes.first == 0x5B /* '[' */)) {
    // Looks like plain JSON (very common for unencrypted exports)
    return ProbeResult(encrypted: false, gzipped: false);
  }

  // 2) GZIP magic: 1F 8B
  if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
    // Might be gzipped JSON (unencrypted) or gzipped+encrypted (rare)
    // We'll try inflate first; if it fails later we can still treat as encrypted
    return ProbeResult(encrypted: false, gzipped: true);
  }

  // 3) Optional custom magic headers you may have used
  // e.g., "VITA1" or "ENC1"... adapt if your exporter wrote a header.
  const encHeader = [0x45, 0x4E, 0x43, 0x31]; // "ENC1"
  if (bytes.length >= 4 &&
      bytes[0] == encHeader[0] &&
      bytes[1] == encHeader[1] &&
      bytes[2] == encHeader[2] &&
      bytes[3] == encHeader[3]) {
    return ProbeResult(encrypted: true, gzipped: false);
  }

  // 4) Default: treat as encrypted blob (e.g., {salt|iv|ciphertext} container)
  return ProbeResult(encrypted: true, gzipped: false);
}

class BackupPasswordError implements Exception {}

Future<void> importBackupBytes(Uint8List bytes, {String? password}) async {
  final probe = _probeBackup(bytes);

  Uint8List plainBytes;

  if (!probe.encrypted) {
    // Try direct JSON first
    try {
      final sourceBytes = probe.gzipped
          ? Uint8List.fromList(const GZipDecoder().decodeBytes(bytes))
          : bytes;
      // Basic JSON sanity check
      jsonDecode(utf8.decode(sourceBytes));
      plainBytes = sourceBytes;
    } catch (_) {
      // If JSON/gzip decode failed, fall back to encrypted flow
      plainBytes = await _tryDecryptWithCandidates(bytes,
          passwordCandidates: [password, "", null]);
    }
  } else {
    // Encrypted flow straight away
    plainBytes = await _tryDecryptWithCandidates(bytes,
        passwordCandidates: [password, "", null]);
  }

  final jsonStr = utf8.decode(plainBytes);
  final Map<String, dynamic> payload =
      jsonDecode(jsonStr) as Map<String, dynamic>;

  // ✅ Apply payload to DB (your current restore routine)
  await _applyBackupPayload(payload);
}

/// Tries multiple password candidates in order.
/// If all fail, throws BackupPasswordError.
Future<Uint8List> _tryDecryptWithCandidates(Uint8List encrypted,
    {required List<String?> passwordCandidates}) async {
  for (final cand in passwordCandidates) {
    try {
      final plain = await _decryptPayload(encrypted, cand);
      // Quick sanity check to ensure we actually decrypted JSON
      final s = utf8.decode(plain);
      jsonDecode(s);
      return plain;
    } catch (_) {
      // continue
    }
  }
  throw BackupPasswordError();
}

/// Replace with your real decryption (AES-GCM, etc.)
/// Contract: when `password` is `null` or `""`, handle legacy “no password” backups
Future<Uint8List> _decryptPayload(Uint8List encrypted, String? password) async {
  // Example structure assumption (adjust to your format):
  // [salt(16) | iv(12) | ciphertext(...) | tag(16)]
  // Or if you stored a JSON envelope with base64 fields, parse that here.

  // PSEUDO:
  // final salt = encrypted.sublist(0, 16);
  // final iv = encrypted.sublist(16, 28);
  // final ct = encrypted.sublist(28);
  // final key = await _deriveKey(password ?? "", salt); // treat null == empty string
  // final plain = aesGcmDecrypt(key, iv, ct);
  // return plain;

  // For now we throw to force you to wire this to your actual crypto util:
  throw UnimplementedError(
      "Wire _decryptPayload to your existing AES-GCM routine");
}

/// Your existing apply logic (truncate & insert or merge)
Future<void> _applyBackupPayload(Map<String, dynamic> payload) async {
  // e.g. payload['food_entries'], payload['water_entries'], etc.
  // Make sure to wrap in a transaction & validate shapes.
}
