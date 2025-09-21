// lib/data/import_manager.dart (Final, mit Deutsch-Support)

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/util/mapping_prefs.dart';

class ImportManager {
  Future<int> importHevyCsv() async {
    // ... (Diese Methode bleibt unverändert, sie ist bereits korrekt)
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.single.path == null) return 0;
      final filePath = result.files.single.path!;
      final file = File(filePath);
      final content = await file.readAsString();
      final List<List<dynamic>> rows =
          const CsvToListConverter(shouldParseNumbers: false, eol: '\n')
              .convert(content);

      if (rows.length < 2) return 0;

      final workoutGroups = <String, List<Map<String, dynamic>>>{};
      final header = rows.first.map((e) => e.toString().trim()).toList();

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length != header.length) continue;
        final rowMap = Map<String, dynamic>.fromIterables(header, row);

        if (rowMap['start_time'] == null ||
            rowMap['start_time'].toString().trim().isEmpty) {
          continue;
        }

        final key = "${rowMap['title']}_${rowMap['start_time']}";
        if (workoutGroups.containsKey(key)) {
          workoutGroups[key]!.add(rowMap);
        } else {
          workoutGroups[key] = [rowMap];
        }
      }

      final db = WorkoutDatabaseHelper.instance;
      int importedWorkouts = 0;
      final knownMap = await MappingPrefs.load();
      for (var group in workoutGroups.values) {
        final firstRow = group.first;
        final newLog = await db.startWorkout(routineName: firstRow['title']);

        final dbInstance = await db.database;
        await dbInstance.update(
            'workout_logs',
            {
              'start_time':
                  _parseHevyDate(firstRow['start_time']).toIso8601String(),
              'end_time':
                  _parseHevyDate(firstRow['end_time']).toIso8601String(),
              'notes': firstRow['description'],
              'status': 'completed',
            },
            where: 'id = ?',
            whereArgs: [newLog.id]);

        int setOrder = 0;
        for (var row in group) {
          final rawName = row['exercise_title']?.toString() ?? '';
          final mappedName = knownMap[rawName.trim().toLowerCase()] ?? rawName;

          final setLog = SetLog(
            workoutLogId: newLog.id!,
            exerciseName: mappedName, // <— statt rawName
            setType: row['set_type'] ?? 'normal',
            weightKg: double.tryParse(row['weight_kg']?.toString() ?? ''),
            reps: int.tryParse(row['reps']?.toString() ?? ''),
            log_order: setOrder++,
            notes: row['exercise_notes'],
            distanceKm: double.tryParse(row['distance_km']?.toString() ?? ''),
            durationSeconds:
                int.tryParse(row['duration_seconds']?.toString() ?? ''),
            rpe: int.tryParse(row['rpe']?.toString() ?? ''),
            supersetId: int.tryParse(row['superset_id']?.toString() ?? ''),
          );
          await db.insertSetLog(setLog);
        }
        importedWorkouts++;
      }
      return importedWorkouts;
    } catch (e) {
      print("Hevy Import Error: $e");
      return -1;
    }
  }

  /// KORREKTUR: Die Parser-Funktion unterstützt jetzt explizit deutsche Monatsnamen.
  DateTime _parseHevyDate(dynamic rawDateString) {
    final dateString = rawDateString?.toString().trim();
    if (dateString == null || dateString.isEmpty) {
      print(
          "Leere oder null Datumszeichenfolge erhalten. Fallback auf DateTime.now()");
      return DateTime.now();
    }

    // Die Liste der Formate wurde um das deutsche Locale erweitert.
    final List<DateFormat> formats = [
      DateFormat("dd MMM yyyy, HH:mm",
          "en_US"), // Probiert zuerst Englisch (Jan, Feb, Apr...)
      DateFormat(
          "dd MMM yyyy, HH:mm", "de_DE"), // Dann Deutsch (März, Mai, Juni...)
      DateFormat("yyyy-MM-dd HH:mm:ss"),
      DateFormat("dd.MM.yyyy, HH:mm"),
    ];

    for (final format in formats) {
      try {
        return format.parse(dateString);
      } catch (e) {
        continue;
      }
    }

    print("Konnte Datum nicht mit bekannten Formaten parsen: '$dateString'");
    return DateTime.now();
  }
}
