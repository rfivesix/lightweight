// lib/data/database_helper.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lightweight/models/measurement.dart';
import 'package:lightweight/models/measurement_session.dart';
import '../models/food_entry.dart';
import '../models/water_entry.dart';
import '../models/chart_data_point.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vita_user.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 10,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Dieser Block beschreibt den Endzustand für eine komplett neue Installation.
    await db.execute(
        'CREATE TABLE food_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, barcode TEXT NOT NULL, timestamp TEXT NOT NULL, quantity_in_grams INTEGER NOT NULL, meal_type TEXT NOT NULL DEFAULT "Snack")');
    await db.execute(
        'CREATE TABLE water_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT NOT NULL, quantity_in_ml INTEGER NOT NULL)');
    await db.execute('CREATE TABLE favorites (barcode TEXT PRIMARY KEY)');
    await db.execute(
        'CREATE TABLE measurement_sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT NOT NULL)');
    await db.execute(
        'CREATE TABLE measurements (id INTEGER PRIMARY KEY AUTOINCREMENT, session_id INTEGER NOT NULL, type TEXT NOT NULL, value REAL NOT NULL, unit TEXT NOT NULL, FOREIGN KEY (session_id) REFERENCES measurement_sessions(id) ON DELETE CASCADE)');
    // NEU: Supplement-Tabellen
    await db.execute(
        'CREATE TABLE supplements (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, default_dose REAL NOT NULL, unit TEXT NOT NULL, daily_goal REAL, daily_limit REAL, notes TEXT)');
    await db.execute(
        'CREATE TABLE supplement_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, supplement_id INTEGER NOT NULL, dose REAL NOT NULL, unit TEXT NOT NULL, timestamp TEXT NOT NULL, FOREIGN KEY (supplement_id) REFERENCES supplements(id) ON DELETE CASCADE)');

    // NEU: Startdaten einfügen
    await db.insert('supplements', {
      'name': 'Caffeine',
      'default_dose': 100,
      'unit': 'mg',
      'daily_limit': 400
    });
    await db.insert('supplements', {
      'name': 'Creatine Monohydrate',
      'default_dose': 5,
      'unit': 'g',
      'daily_goal': 5
    });

    print("Benutzer-DB (v10) neu erstellt.");
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Dieser Block bringt alte Versionen Schritt für Schritt auf den neuesten Stand.
    if (oldVersion < 2) {
      await db.execute(
          'CREATE TABLE water_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT NOT NULL, quantity_in_ml INTEGER NOT NULL)');
    }
    if (oldVersion < 4) {
      await db.execute('CREATE TABLE favorites (barcode TEXT PRIMARY KEY)');
    }
    if (oldVersion < 5) {
      await db.execute(
          'ALTER TABLE food_entries ADD COLUMN meal_type TEXT NOT NULL DEFAULT "Snack"');
    }

    // Upgrade von jedem Zustand vor v9 auf v9 (bereinigt alle alten Measurement-Tabellen)
    if (oldVersion < 9) {
      // Lösche alle möglichen alten Versionen der Tabellen, um sicherzugehen.
      await db.execute('DROP TABLE IF EXISTS measurements');
      await db.execute('DROP TABLE IF EXISTS measurement_sessions');
      // Erstelle die Tabellen in der korrekten, finalen Struktur.
      await db.execute(
          'CREATE TABLE measurement_sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT NOT NULL)');
      await db.execute(
          'CREATE TABLE measurements (id INTEGER PRIMARY KEY AUTOINCREMENT, session_id INTEGER NOT NULL, type TEXT NOT NULL, value REAL NOT NULL, unit TEXT NOT NULL, FOREIGN KEY (session_id) REFERENCES measurement_sessions(id) ON DELETE CASCADE)');
      print(
          "Datenbank auf Version 9 aktualisiert: Measurement-Tabellen sauber erstellt.");
    }
    // NEU: Upgrade auf Version 10
    if (oldVersion < 10) {
      await db.execute(
          'CREATE TABLE supplements (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, default_dose REAL NOT NULL, unit TEXT NOT NULL, daily_goal REAL, daily_limit REAL, notes TEXT)');
      await db.execute(
          'CREATE TABLE supplement_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, supplement_id INTEGER NOT NULL, dose REAL NOT NULL, unit TEXT NOT NULL, timestamp TEXT NOT NULL, FOREIGN KEY (supplement_id) REFERENCES supplements(id) ON DELETE CASCADE)');

      await db.insert('supplements', {
        'name': 'Caffeine',
        'default_dose': 100,
        'unit': 'mg',
        'daily_limit': 400
      });
      await db.insert('supplements', {
        'name': 'Creatine Monohydrate',
        'default_dose': 5,
        'unit': 'g',
        'daily_goal': 5
      });
      print(
          "Datenbank auf Version 10 aktualisiert: Supplement-Tabellen hinzugefügt.");
    }
  }

  // --- FOOD ENTRIES ---
  Future<void> insertFoodEntry(FoodEntry entry) async {
    // DOC: KORREKTUR: Verwende die lokale 'database' Variable anstatt 'instance.database'
    final db = await database;
    await db.insert('food_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    print("Neuer FoodEntry erfolgreich in der Benutzer-DB gespeichert.");
  }

  // Diese Methode ist für den Home Screen. Wir aktualisieren sie auch gleich.
  Future<List<FoodEntry>> getEntriesForDate(DateTime date) async {
    final db = await database;
    final dateString = date.toIso8601String().substring(0, 10);
    final List<Map<String, dynamic>> maps = await db.query(
      'food_entries',
      where: 'timestamp LIKE ?',
      whereArgs: ['$dateString%'],
    );
    return List.generate(maps.length, (i) {
      return FoodEntry(
        id: maps[i]['id'],
        barcode: maps[i]['barcode'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
        quantityInGrams: maps[i]['quantity_in_grams'],
        mealType: maps[i]['meal_type'] ?? 'Snack', // Neues Feld auslesen
      );
    });
  }

  Future<List<FoodEntry>> getEntriesForDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final startDateString = DateFormat('yyyy-MM-dd').format(start);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final endDateString = endDate.toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'food_entries',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startDateString, endDateString],
    );
    return List.generate(maps.length, (i) {
      return FoodEntry(
        id: maps[i]['id'],
        barcode: maps[i]['barcode'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
        quantityInGrams: maps[i]['quantity_in_grams'],
        mealType: maps[i]['meal_type'] ?? 'Snack', // Neues Feld auslesen
      );
    });
  }

  Future<void> deleteFoodEntry(int id) async {
    final db = await database;
    await db.delete('food_entries', where: 'id = ?', whereArgs: [id]);
    print("Eintrag mit ID $id erfolgreich gelöscht.");
  }

  // --- WATER ENTRIES ---
  Future<void> insertWaterEntry(int quantityInMl, DateTime timestamp) async {
    final db = await database;
    await db.insert(
        'water_entries',
        {
          'timestamp': timestamp.toIso8601String(),
          'quantity_in_ml': quantityInMl
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
    print("$quantityInMl ml Wasser erfolgreich gespeichert.");
  }

  Future<int> getWaterForDate(DateTime date) async {
    final db = await database;
    final dateString = date.toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
        'SELECT SUM(quantity_in_ml) as total FROM water_entries WHERE timestamp LIKE ?',
        ['$dateString%']);
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getWaterForDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final startDateString = DateFormat('yyyy-MM-dd').format(start);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final endDateString = endDate.toIso8601String();
    final result = await db.rawQuery(
        'SELECT SUM(quantity_in_ml) as total FROM water_entries WHERE timestamp BETWEEN ? AND ?',
        [startDateString, endDateString]);
    return result.first['total'] as int? ?? 0;
  }

  Future<List<WaterEntry>> getWaterEntriesForDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final startDateString = DateFormat('yyyy-MM-dd').format(start);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final endDateString = endDate.toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'water_entries',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startDateString, endDateString],
    );
    return List.generate(maps.length, (i) => WaterEntry.fromMap(maps[i]));
  }

  Future<void> deleteWaterEntry(int id) async {
    final db = await database;
    await db.delete(
      'water_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    print("Wasser-Eintrag mit ID $id erfolgreich gelöscht.");
  }

  // --- FAVORITES ---
  Future<void> addFavorite(String barcode) async {
    final db = await database;
    await db.insert('favorites', {'barcode': barcode});
    print("Favorit $barcode hinzugefügt.");
  }

  Future<void> removeFavorite(String barcode) async {
    final db = await database;
    await db.delete('favorites', where: 'barcode = ?', whereArgs: [barcode]);
    print("Favorit $barcode entfernt.");
  }

  Future<bool> isFavorite(String barcode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('favorites', where: 'barcode = ?', whereArgs: [barcode]);
    return maps.isNotEmpty;
  }

  Future<List<String>> getFavoriteBarcodes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) => maps[i]['barcode'] as String);
  }

  // DOC: NEUE METHODE für die "Zuletzt verwendet"-Liste
  Future<List<String>> getRecentlyUsedBarcodes() async {
    final db = await database;
    // Dieses SQL-Statement ist etwas komplexer:
    // 1. SELECT DISTINCT barcode: Wähle jeden Barcode nur einmal aus.
    // 2. FROM food_entries: Aus der Tabelle der Einträge.
    // 3. ORDER BY timestamp DESC: Sortiere sie absteigend nach dem Zeitstempel (die neuesten zuerst).
    // 4. LIMIT 20: Gib uns nur die Top 20 zurück.
    final List<Map<String, dynamic>> maps = await db.query(
      'food_entries',
      distinct: true,
      columns: ['barcode'],
      orderBy: 'timestamp DESC',
      limit: 20,
    );
    return List.generate(maps.length, (i) => maps[i]['barcode'] as String);
  }

  // --- MEASUREMENTS (SESSION-BASED) ---
  Future<void> insertMeasurementSession(MeasurementSession session) async {
    final db = await database;
    await db.transaction((txn) async {
      final sessionId = await txn.insert(
        'measurement_sessions',
        {'timestamp': session.timestamp.toIso8601String()},
      );

      for (final measurement in session.measurements) {
        // WICHTIG: Wir erstellen hier eine NEUE Map aus dem Measurement-Objekt,
        // das KEINEN Timestamp mehr hat, und fügen die session_id hinzu.
        final measurementMap = {
          'session_id': sessionId,
          'type': measurement.type,
          'value': measurement.value,
          'unit': measurement.unit,
        };
        await txn.insert('measurements', measurementMap);
      }
    });
    print("Neue Measurement-Session erfolgreich gespeichert.");
  }

  Future<List<MeasurementSession>> getMeasurementSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> sessionMaps = await db.query(
      'measurement_sessions',
      orderBy: 'timestamp DESC',
    );

    if (sessionMaps.isEmpty) return [];

    final List<MeasurementSession> sessions = [];
    for (final sessionMap in sessionMaps) {
      final sessionId = sessionMap['id'] as int;
      final List<Map<String, dynamic>> measurementMaps = await db.query(
        'measurements',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );

      // Die fromMap-Methode im korrigierten Measurement-Modell wird hier verwendet.
      final measurements =
          measurementMaps.map((map) => Measurement.fromMap(map)).toList();

      sessions.add(MeasurementSession(
        id: sessionId,
        timestamp: DateTime.parse(sessionMap['timestamp'] as String),
        measurements: measurements,
      ));
    }
    return sessions;
  }

  Future<void> deleteMeasurementSession(int id) async {
    final db = await database;
    await db.delete('measurement_sessions', where: 'id = ?', whereArgs: [id]);
    print(
        "Measurement-Session mit ID $id (und zugehörige Messwerte) gelöscht.");
  }

  // --- CHART DATA HELPERS ---

  /// Ruft alle Messwerte eines bestimmten Typs ab und gibt sie als
  /// eine Liste von Datenpunkten für einen Graphen zurück.
  Future<List<ChartDataPoint>> getChartDataForType(String type) async {
    final db = await database;

    // Dies ist eine komplexere SQL-Abfrage. Sie verbindet die beiden Tabellen:
    // Sie holt den 'value' aus der 'measurements'-Tabelle und den zugehörigen
    // 'timestamp' aus der 'measurement_sessions'-Tabelle, filtert nach dem
    // gewünschten Typ und sortiert nach Datum.
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        s.timestamp,
        m.value
      FROM measurements m
      INNER JOIN measurement_sessions s ON m.session_id = s.id
      WHERE m.type = ?
      ORDER BY s.timestamp ASC 
    ''', [type]);

    if (maps.isEmpty) {
      return [];
    }

    // Wandle das Ergebnis der Datenbankabfrage in unsere saubere ChartDataPoint-Liste um.
    return maps.map((map) {
      return ChartDataPoint(
        date: DateTime.parse(map['timestamp'] as String),
        value: map['value'] as double,
      );
    }).toList();
  }

  Future<List<ChartDataPoint>> getChartDataForTypeAndRange(
      String type, DateTimeRange range) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        s.timestamp,
        m.value
      FROM measurements m
      INNER JOIN measurement_sessions s ON m.session_id = s.id
      WHERE m.type = ? AND s.timestamp BETWEEN ? AND ?
      ORDER BY s.timestamp ASC 
    ''', [
      type,
      range.start.toIso8601String(),
      range.end.toIso8601String(),
    ]);

    if (maps.isEmpty) {
      return [];
    }

    return maps.map((map) {
      return ChartDataPoint(
        date: DateTime.parse(map['timestamp'] as String),
        value: map['value'] as double,
      );
    }).toList();
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    final db = await database;
    await db.update(
      'food_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    print("Eintrag mit ID ${entry.id} erfolgreich aktualisiert.");
  }

  Future<DateTime?> getEarliestMeasurementDate() async {
    final db = await database;
    final maps = await db.query('measurement_sessions',
        orderBy: 'timestamp ASC', limit: 1);
    if (maps.isNotEmpty) {
      return DateTime.parse(maps.first['timestamp'] as String);
    }
    return null;
  }

  Future<DateTime?> getEarliestFoodEntryDate() async {
    final db = await database;
    final maps =
        await db.query('food_entries', orderBy: 'timestamp ASC', limit: 1);
    if (maps.isNotEmpty) {
      return DateTime.parse(maps.first['timestamp'] as String);
    }
    return null;
  }
// In lib/data/database_helper.dart (korrigierte Version der neuen Methoden)

  Future<List<FoodEntry>> getAllFoodEntries() async {
    final db = await database;
    final maps = await db.query('food_entries');
    // KORREKTUR: Nutzt den Standard-Konstruktor, da 'fromJson' nicht existiert.
    return maps
        .map((map) => FoodEntry(
              id: map['id'] as int?,
              barcode: map['barcode'] as String,
              timestamp: DateTime.parse(map['timestamp'] as String),
              quantityInGrams: map['quantity_in_grams'] as int,
              mealType: map['meal_type'] as String,
            ))
        .toList();
  }

  Future<List<WaterEntry>> getAllWaterEntries() async {
    final db = await database;
    final maps = await db.query('water_entries');
    // KORREKTUR: Nutzt die korrekte 'fromMap'-Factory.
    return maps.map((map) => WaterEntry.fromMap(map)).toList();
  }

  Future<void> importUserData({
    required List<FoodEntry> foodEntries,
    required List<WaterEntry> waterEntries,
    required List<String> favoriteBarcodes,
    required List<MeasurementSession> measurementSessions,
    required List<Supplement> supplements, // NEU
    required List<SupplementLog> supplementLogs, // NEU
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final entry in foodEntries) {
        await txn.insert('food_entries', entry.toMap());
      }
      for (final entry in waterEntries) {
        await txn.insert('water_entries', entry.toMap());
      }
      for (final barcode in favoriteBarcodes) {
        await txn.insert('favorites', {'barcode': barcode});
      }
      for (final session in measurementSessions) {
        // KORREKTUR: Erstellt die Map für die Session direkt hier.
        final sessionId = await txn.insert('measurement_sessions',
            {'timestamp': session.timestamp.toIso8601String()});
        for (final measurement in session.measurements) {
          // KORREKTUR: Erstellt die Map für das Measurement hier und fügt die NEUE sessionId hinzu.
          await txn.insert('measurements', {
            ...measurement.toMap(), // Nutzt die existierende toMap()
            'session_id': sessionId, // Überschreibt mit der neuen ID
          });
        }
      }
    });
  }

  /// Gibt ein Set von Tagen (1-31) zurück, an denen im gegebenen Monat Ernährungseinträge existieren.
  Future<Set<int>> getNutritionLogDaysInMonth(DateTime month) async {
    final db = await database;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final maps = await db.query(
      'food_entries',
      columns: ['timestamp'],
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [
        firstDayOfMonth.toIso8601String(),
        lastDayOfMonth.toIso8601String()
      ],
    );

    if (maps.isEmpty) return {};

    // Extrahiere den Tag aus jedem Timestamp und füge ihn einem Set hinzu, um Duplikate zu vermeiden.
    return maps
        .map((map) => DateTime.parse(map['timestamp'] as String).day)
        .toSet();
  }

  // --- NEUE METHODEN FÜR SUPPLEMENTS ---

  Future<Supplement> insertSupplement(Supplement supplement) async {
    final db = await database;
    final id = await db.insert('supplements', supplement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    // Erstelle eine neue Instanz mit der zurückgegebenen ID
    return Supplement(
        id: id,
        name: supplement.name,
        defaultDose: supplement.defaultDose,
        unit: supplement.unit,
        dailyGoal: supplement.dailyGoal,
        dailyLimit: supplement.dailyLimit,
        notes: supplement.notes);
  }

  Future<List<Supplement>> getAllSupplements() async {
    final db = await database;
    final maps = await db.query('supplements', orderBy: 'name ASC');
    return maps.map((map) => Supplement.fromMap(map)).toList();
  }

  Future<void> deleteSupplement(int id) async {
    final db = await database;
    // Lösche auch alle zugehörigen Logs, um Datenmüll zu vermeiden
    await db.transaction((txn) async {
      await txn.delete('supplement_logs',
          where: 'supplement_id = ?', whereArgs: [id]);
      await txn.delete('supplements', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<SupplementLog> insertSupplementLog(SupplementLog log) async {
    final db = await database;
    final id = await db.insert('supplement_logs', log.toMap());
    return SupplementLog(
        id: id,
        supplementId: log.supplementId,
        dose: log.dose,
        unit: log.unit,
        timestamp: log.timestamp);
  }

  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) async {
    final db = await database;
    final dateString = date.toIso8601String().substring(0, 10);
    final List<Map<String, dynamic>> maps = await db.query(
      'supplement_logs',
      where: 'timestamp LIKE ?',
      whereArgs: ['$dateString%'],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => SupplementLog.fromMap(map)).toList();
  }

  Future<void> deleteSupplementLog(int id) async {
    final db = await database;
    await db.delete('supplement_logs', where: 'id = ?', whereArgs: [id]);
  }

  // FÜR BACKUP
  Future<List<SupplementLog>> getAllSupplementLogs() async {
    final db = await database;
    final maps = await db.query('supplement_logs');
    return maps.map((map) => SupplementLog.fromMap(map)).toList();
  }

  @override
  Future<void> clearAllUserData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('food_entries');
      await txn.delete('water_entries');
      await txn.delete('favorites');
      await txn.delete('measurements');
      await txn.delete('measurement_sessions');
      await txn.delete('supplement_logs'); // NEU
      await txn.delete('supplements'); // NEU
    });
  }

  // NEUE METHODE
  Future<Set<int>> getSupplementLogDaysInMonth(DateTime month) async {
    final db = await database;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final maps = await db.query(
      'supplement_logs',
      columns: ['timestamp'],
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [
        firstDayOfMonth.toIso8601String(),
        lastDayOfMonth.toIso8601String()
      ],
    );

    if (maps.isEmpty) return {};

    return maps
        .map((map) => DateTime.parse(map['timestamp'] as String).day)
        .toSet();
  }
}
