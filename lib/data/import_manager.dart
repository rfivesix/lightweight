// lib/data/import_manager.dart

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/models/set_log.dart';

class ImportManager {
  Future<int> importHevyCsv() async {
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
        if (row.length != header.length) continue; // Skip malformed rows
        final rowMap = Map<String, dynamic>.fromIterables(header, row);
        final key = "${rowMap['title']}_${rowMap['start_time']}";
        if (workoutGroups.containsKey(key)) {
          workoutGroups[key]!.add(rowMap);
        } else {
          workoutGroups[key] = [rowMap];
        }
      }

      final db = WorkoutDatabaseHelper.instance;
      int importedWorkouts = 0;
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
              'notes': firstRow['description']
            },
            where: 'id = ?',
            whereArgs: [newLog.id]);

        for (var row in group) {
          // KORREKTUR: Der 'setIndex'-Parameter wurde entfernt, da er im
          // SetLog-Konstruktor nicht mehr existiert.
          final setLog = SetLog(
            workoutLogId: newLog.id!,
            exerciseName: row['exercise_title'],
            setType: row['set_type'] ?? 'normal',
            weightKg: double.tryParse(row['weight_kg']?.toString() ?? ''),
            reps: int.tryParse(row['reps']?.toString() ?? ''),
          );
          await db.insertSetLog(setLog);
        }
        importedWorkouts++;
      }
      return importedWorkouts;
    } catch (e) {
      // ignore: avoid_print
      print("Hevy Import Error: $e");
      return -1; // Fehlercode
    }
  }

  DateTime _parseHevyDate(String dateString) {
    try {
      return DateFormat("dd MMM yyyy, HH:mm", "en_US").parse(dateString);
    } catch (e) {
      // Versuche ein alternatives, häufiges Format
      try {
        return DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateString);
      } catch (e2) {
        print("Konnte Datum nicht parsen: $dateString");
        return DateTime.now();
      }
    }
  }
}