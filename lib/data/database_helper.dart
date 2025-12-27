// lib/data/database_helper.dart

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
// Import mit Prefix
import 'package:lightweight/data/drift_database.dart' as db;
import 'package:lightweight/data/drift_database.dart' show FavoritesCompanion;

import 'package:lightweight/models/chart_data_point.dart';
import 'package:lightweight/models/fluid_entry.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/measurement.dart';
import 'package:lightweight/models/measurement_session.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/models/supplement_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static db.AppDatabase? _driftDb;

  DatabaseHelper._init();

  Future<db.AppDatabase> get database async {
    if (_driftDb != null) return _driftDb!;
    _driftDb = db.AppDatabase();
    return _driftDb!;
  }

  // --- INIT: STANDARD SUPPLEMENTS ---
  Future<void> ensureStandardSupplements() async {
    final dbInstance = await database;

    // Prüfen, ob Koffein (Code 'caffeine') schon existiert
    final exists = await (dbInstance.select(dbInstance.supplements)
          ..where((t) => t.code.equals('caffeine')))
        .getSingleOrNull();

    if (exists == null) {
      // Koffein anlegen
      await insertSupplement(Supplement(
        code: 'caffeine', // WICHTIG: Code muss exakt stimmen für die Logik
        name: 'Koffein',
        defaultDose: 0, // Hängt vom Getränk ab
        unit: 'mg',
        dailyGoal: null,
        dailyLimit: 400,
        isBuiltin: true,
      ));
      debugPrint("✅ Standard-Supplement 'Koffein' wurde angelegt.");
    }
  }

  // ===========================================================================
  // 1. CLEAR & IMPORT (DIE FEHLENDEN TEILE!)
  // ===========================================================================
  Future<void> clearAllUserData() async {
    final dbInstance = await database;

    // Wir deaktivieren kurzzeitig Foreign Keys, um sicher alles löschen zu können
    await dbInstance.customStatement('PRAGMA foreign_keys = OFF');

    try {
      // 1. Kind-Tabellen (Logs) zuerst
      await dbInstance.delete(dbInstance.supplementLogs).go();
      await dbInstance.delete(dbInstance.fluidLogs).go();
      await dbInstance.delete(dbInstance.nutritionLogs).go();
      await dbInstance.delete(dbInstance.measurements).go();
      await dbInstance.delete(dbInstance.mealItems).go();

      // 2. Eltern-Tabellen (Definitionen) danach
      await dbInstance.delete(dbInstance.favorites).go();
      await dbInstance.delete(dbInstance.supplements).go();
      await dbInstance.delete(dbInstance.meals).go();

      // 3. User-Produkte
      await (dbInstance.delete(dbInstance.products)
            ..where((t) => t.source.equals('user')))
          .go();
    } finally {
      // Foreign Keys wieder aktivieren
      await dbInstance.customStatement('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> importUserData({
    required List<FoodEntry> foodEntries,
    required List<FluidEntry> fluidEntries,
    required List<String> favoriteBarcodes,
    required List<MeasurementSession> measurementSessions,
    required List<Supplement> supplements,
    required List<SupplementLog> supplementLogs,
  }) async {
    final dbInstance = await database;

    await dbInstance.batch((batch) {
      // A. FAVORITEN
      for (final barcode in favoriteBarcodes) {
        batch.insert(
          dbInstance.favorites,
          FavoritesCompanion(
            barcode: drift.Value(barcode),
            createdAt: drift.Value(DateTime.now()),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }

      // B. NUTRITION LOGS (Essen)
      for (final entry in foodEntries) {
        batch.insert(
          dbInstance.nutritionLogs,
          db.NutritionLogsCompanion(
            legacyBarcode: drift.Value(entry.barcode),
            consumedAt: drift.Value(entry.timestamp),
            amount: drift.Value(entry.quantityInGrams.toDouble()),
            mealType: drift.Value(entry.mealType),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }

      // C. FLUID LOGS (Trinken)
      for (final entry in fluidEntries) {
        batch.insert(
          dbInstance.fluidLogs,
          db.FluidLogsCompanion(
            consumedAt: drift.Value(entry.timestamp),
            amountMl: drift.Value(entry.quantityInMl),
            name: drift.Value(entry.name),
            kcal: drift.Value(entry.kcal),
            sugarPer100ml: drift.Value(entry.sugarPer100ml),
            caffeinePer100ml: drift.Value(entry.caffeinePer100ml),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }

      // D. MEASUREMENTS
      for (final session in measurementSessions) {
        final legacyId = session.timestamp.millisecondsSinceEpoch;
        for (final m in session.measurements) {
          batch.insert(
            dbInstance.measurements,
            db.MeasurementsCompanion(
              date: drift.Value(session.timestamp),
              type: drift.Value(m.type),
              value: drift.Value(m.value),
              unit: drift.Value(m.unit),
              legacySessionId: drift.Value(legacyId),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        }
      }

      // E. SUPPLEMENTS (Mit ID-Fix)
      for (final s in supplements) {
        // Konvertiere int-ID zu String, falls nötig, oder erstelle neue UUID
        final String fixedId =
            s.id != null ? s.id.toString() : const Uuid().v4();

        batch.insert(
          dbInstance.supplements,
          db.SupplementsCompanion(
            id: drift.Value(fixedId), // Explizite ID setzen!
            code: drift.Value(s.code),
            name: drift.Value(s.name),
            dose: drift.Value(s.defaultDose),
            unit: drift.Value(s.unit),
            dailyGoal: drift.Value(s.dailyGoal),
            dailyLimit: drift.Value(s.dailyLimit),
            notes: drift.Value(s.notes),
            isBuiltin: drift.Value(s.isBuiltin),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });

    // F. SUPPLEMENT LOGS (Separat, um Referenzfehler zu vermeiden)
    await dbInstance.batch((batch) {
      for (final log in supplementLogs) {
        // Hier referenzieren wir die ID, die wir oben erzwungen haben (String)
        final String refId = log.supplementId.toString();

        batch.insert(
          dbInstance.supplementLogs,
          db.SupplementLogsCompanion(
            supplementId: drift.Value(refId),
            amount: drift.Value(log.dose),
            takenAt: drift.Value(log.timestamp),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
  }
  // ===========================================================================
  // NUTRITION LOGS (FoodEntry)
  // ===========================================================================

  Future<int> insertFoodEntry(FoodEntry entry) async {
    final dbInstance = await database;

    final companion = db.NutritionLogsCompanion(
      legacyBarcode: drift.Value(entry.barcode),
      consumedAt: drift.Value(entry.timestamp),
      amount: drift.Value(entry.quantityInGrams.toDouble()),
      mealType: drift.Value(entry.mealType),
    );

    final row = await dbInstance
        .into(dbInstance.nutritionLogs)
        .insertReturning(companion);
    return row.localId;
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    if (entry.id == null) return;
    final dbInstance = await database;

    final companion = db.NutritionLogsCompanion(
      legacyBarcode: drift.Value(entry.barcode),
      consumedAt: drift.Value(entry.timestamp),
      amount: drift.Value(entry.quantityInGrams.toDouble()),
      mealType: drift.Value(entry.mealType),
    );

    await (dbInstance.update(dbInstance.nutritionLogs)
          ..where((tbl) => tbl.localId.equals(entry.id!)))
        .write(companion);
  }

  Future<List<FoodEntry>> getEntriesForDate(DateTime date) async {
    final dbInstance = await database;

    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.nutritionLogs)
      ..where((tbl) => tbl.consumedAt.isBetweenValues(start, end));

    final rows = await query.get();

    return rows.map((row) {
      return FoodEntry(
        id: row.localId,
        barcode: row.legacyBarcode ?? 'UNKNOWN',
        timestamp: row.consumedAt,
        quantityInGrams: row.amount.toInt(),
        mealType: row.mealType,
      );
    }).toList();
  }

  Future<List<FoodEntry>> getEntriesForDateRange(
      DateTime start, DateTime end) async {
    final dbInstance = await database;

    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.nutritionLogs)
      ..where((tbl) =>
          tbl.consumedAt.isBetweenValues(effectiveStart, effectiveEnd));

    final rows = await query.get();

    return rows.map((row) {
      return FoodEntry(
        id: row.localId,
        barcode: row.legacyBarcode ?? 'UNKNOWN',
        timestamp: row.consumedAt,
        quantityInGrams: row.amount.toInt(),
        mealType: row.mealType,
      );
    }).toList();
  }

  Future<void> deleteFoodEntry(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.nutritionLogs)
          ..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  Future<List<FoodEntry>> getAllFoodEntries() async {
    final dbInstance = await database;
    final rows = await dbInstance.select(dbInstance.nutritionLogs).get();
    return rows
        .map((row) => FoodEntry(
              id: row.localId,
              barcode: row.legacyBarcode ?? 'UNKNOWN',
              timestamp: row.consumedAt,
              quantityInGrams: row.amount.toInt(),
              mealType: row.mealType,
            ))
        .toList();
  }

  // ===========================================================================
  // FLUID LOGS
  // ===========================================================================

  Future<int> insertFluidEntry(FluidEntry entry) async {
    final dbInstance = await database;

    // 1. Getränk speichern
    final companion = db.FluidLogsCompanion(
      consumedAt: drift.Value(entry.timestamp),
      amountMl: drift.Value(entry.quantityInMl),
      name: drift.Value(entry.name),
      kcal: drift.Value(entry.kcal),
      sugarPer100ml: drift.Value(entry.sugarPer100ml),
      caffeinePer100ml: drift.Value(entry.caffeinePer100ml),
    );

    final row =
        await dbInstance.into(dbInstance.fluidLogs).insertReturning(companion);

    // 2. AUTOMATIK: Koffein-Log erstellen
    if (entry.caffeinePer100ml != null && entry.caffeinePer100ml! > 0) {
      try {
        // Suche das Supplement mit dem Code 'caffeine'
        final caffeineSupp = await (dbInstance.select(dbInstance.supplements)
              ..where((t) => t.code.equals('caffeine')))
            .getSingleOrNull();

        if (caffeineSupp != null) {
          // Berechne Dosis: (Menge / 100) * mg_pro_100ml
          final double totalCaffeine =
              (entry.quantityInMl / 100.0) * entry.caffeinePer100ml!;

          if (totalCaffeine > 0) {
            // Log erstellen
            // HINWEIS: Wir konvertieren ID zu String, passend zu deiner neuen Logik
            final String supplementIdString = caffeineSupp.id.toString();

            await dbInstance
                .into(dbInstance.supplementLogs)
                .insert(db.SupplementLogsCompanion(
                  supplementId: drift.Value(supplementIdString),
                  amount: drift.Value(totalCaffeine),
                  takenAt: drift.Value(entry.timestamp),
                ));
            debugPrint(
                "☕️ Automatisch ${totalCaffeine.round()}mg Koffein geloggt.");
          }
        }
      } catch (e) {
        debugPrint("⚠️ Fehler beim automatischen Koffein-Log: $e");
      }
    }

    return row.localId;
  }

  Future<List<FluidEntry>> getFluidEntriesForDate(DateTime date) async {
    final dbInstance = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final rows = await (dbInstance.select(dbInstance.fluidLogs)
          ..where((tbl) => tbl.consumedAt.isBetweenValues(start, end)))
        .get();

    return rows
        .map((row) => FluidEntry(
              id: row.localId,
              timestamp: row.consumedAt,
              quantityInMl: row.amountMl,
              name: row.name,
              kcal: row.kcal,
              sugarPer100ml: row.sugarPer100ml,
              caffeinePer100ml: row.caffeinePer100ml,
              carbsPer100ml: row.sugarPer100ml,
              linked_food_entry_id: null,
            ))
        .toList();
  }

  Future<List<FluidEntry>> getFluidEntriesForDateRange(
      DateTime start, DateTime end) async {
    final dbInstance = await database;
    final effectiveStart = DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final rows = await (dbInstance.select(dbInstance.fluidLogs)
          ..where((tbl) =>
              tbl.consumedAt.isBetweenValues(effectiveStart, effectiveEnd)))
        .get();

    return rows
        .map((row) => FluidEntry(
              id: row.localId,
              timestamp: row.consumedAt,
              quantityInMl: row.amountMl,
              name: row.name,
              kcal: row.kcal,
              sugarPer100ml: row.sugarPer100ml,
              caffeinePer100ml: row.caffeinePer100ml,
              carbsPer100ml: row.sugarPer100ml,
              linked_food_entry_id: null,
            ))
        .toList();
  }

  Future<void> updateFluidEntry(FluidEntry entry) async {
    if (entry.id == null) return;
    final dbInstance = await database;

    await (dbInstance.update(dbInstance.fluidLogs)
          ..where((tbl) => tbl.localId.equals(entry.id!)))
        .write(db.FluidLogsCompanion(
      consumedAt: drift.Value(entry.timestamp),
      amountMl: drift.Value(entry.quantityInMl),
      name: drift.Value(entry.name),
      kcal: drift.Value(entry.kcal),
      sugarPer100ml: drift.Value(entry.sugarPer100ml),
      caffeinePer100ml: drift.Value(entry.caffeinePer100ml),
    ));
  }

  Future<void> deleteFluidEntry(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.fluidLogs)
          ..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  Future<void> deleteFluidEntryByLinkedFoodId(int foodEntryId) async {
    final dbInstance = await database;
    final nutritionLog = await (dbInstance.select(dbInstance.nutritionLogs)
          ..where((tbl) => tbl.localId.equals(foodEntryId)))
        .getSingleOrNull();

    if (nutritionLog != null) {
      await (dbInstance.delete(dbInstance.fluidLogs)
            ..where((tbl) => tbl.linkedNutritionLogId.equals(nutritionLog.id)))
          .go();
    }
  }

  Future<List<FluidEntry>> getAllFluidEntries() async {
    final dbInstance = await database;
    final rows = await dbInstance.select(dbInstance.fluidLogs).get();
    return rows
        .map((row) => FluidEntry(
              id: row.localId,
              timestamp: row.consumedAt,
              quantityInMl: row.amountMl,
              name: row.name,
              kcal: row.kcal,
              sugarPer100ml: row.sugarPer100ml,
              caffeinePer100ml: row.caffeinePer100ml,
              carbsPer100ml: row.sugarPer100ml,
              linked_food_entry_id: null,
            ))
        .toList();
  }

  // ===========================================================================
  // MEASUREMENTS
  // ===========================================================================

  Future<void> insertMeasurementSession(MeasurementSession session) async {
    final dbInstance = await database;
    final legacySessionId = session.timestamp.millisecondsSinceEpoch;

    await dbInstance.batch((batch) {
      for (final m in session.measurements) {
        batch.insert(
            dbInstance.measurements,
            db.MeasurementsCompanion(
              date: drift.Value(session.timestamp),
              type: drift.Value(m.type),
              value: drift.Value(m.value),
              unit: drift.Value(m.unit),
              legacySessionId: drift.Value(legacySessionId),
            ));
      }
    });
  }

  Future<List<MeasurementSession>> getMeasurementSessions() async {
    final dbInstance = await database;

    final rows = await (dbInstance.select(dbInstance.measurements)
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.date, mode: drift.OrderingMode.desc)
          ]))
        .get();

    final Map<String, List<Measurement>> grouped = {};
    final Map<String, DateTime> timestamps = {};
    final Map<String, int> ids = {};

    for (final row in rows) {
      final key = row.legacySessionId?.toString() ?? row.date.toIso8601String();

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
        timestamps[key] = row.date;
        ids[key] = row.legacySessionId ?? row.localId;
      }

      grouped[key]!.add(Measurement(
        id: row.localId,
        sessionId: ids[key]!,
        type: row.type,
        value: row.value,
        unit: row.unit,
      ));
    }

    return grouped.entries.map((entry) {
      return MeasurementSession(
        id: ids[entry.key],
        timestamp: timestamps[entry.key]!,
        measurements: entry.value,
      );
    }).toList();
  }

  Future<void> deleteMeasurementSession(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.measurements)
          ..where((tbl) => tbl.legacySessionId.equals(id)))
        .go();
  }

  Future<DateTime?> getEarliestMeasurementDate() async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.measurements)
      ..orderBy([
        (t) =>
            drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.asc)
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.date;
  }

  Future<List<ChartDataPoint>> getChartDataForType(String type) async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.measurements)
      ..where((tbl) => tbl.type.equals(type))
      ..orderBy([
        (t) =>
            drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.asc)
      ]);

    final rows = await query.get();
    return rows
        .map((r) => ChartDataPoint(date: r.date, value: r.value))
        .toList();
  }

  Future<List<ChartDataPoint>> getChartDataForTypeAndRange(
      String type, DateTimeRange range) async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.measurements)
      ..where((tbl) => tbl.type.equals(type))
      ..where((tbl) => tbl.date.isBetweenValues(range.start, range.end))
      ..orderBy([
        (t) =>
            drift.OrderingTerm(expression: t.date, mode: drift.OrderingMode.asc)
      ]);

    final rows = await query.get();
    return rows
        .map((r) => ChartDataPoint(date: r.date, value: r.value))
        .toList();
  }

  // ===========================================================================
  // SUPPLEMENTS
  // ===========================================================================

  Future<Supplement> insertSupplement(Supplement s) async {
    final dbInstance = await database;
    final companion = db.SupplementsCompanion(
      code: drift.Value(s.code),
      name: drift.Value(s.name),
      dose: drift.Value(s.defaultDose),
      unit: drift.Value(s.unit),
      dailyGoal: drift.Value(s.dailyGoal),
      dailyLimit: drift.Value(s.dailyLimit),
      notes: drift.Value(s.notes),
      isBuiltin: drift.Value(s.isBuiltin),
    );

    final row = await dbInstance
        .into(dbInstance.supplements)
        .insertReturning(companion);

    return Supplement(
      id: row.localId,
      code: row.code,
      name: row.name,
      defaultDose: row.dose,
      unit: row.unit,
      dailyGoal: row.dailyGoal,
      dailyLimit: row.dailyLimit,
      notes: row.notes,
      isBuiltin: row.isBuiltin,
    );
  }

  Future<List<Supplement>> getAllSupplements() async {
    final dbInstance = await database;
    final rows = await (dbInstance.select(dbInstance.supplements)
          ..orderBy([(t) => drift.OrderingTerm(expression: t.name)]))
        .get();

    return rows
        .map((row) => Supplement(
              id: row.localId,
              code: row.code,
              name: row.name,
              defaultDose: row.dose,
              unit: row.unit,
              dailyGoal: row.dailyGoal,
              dailyLimit: row.dailyLimit,
              notes: row.notes,
              isBuiltin: row.isBuiltin,
            ))
        .toList();
  }

  Future<void> updateSupplement(Supplement s) async {
    if (s.id == null) return;
    final dbInstance = await database;

    final companion = db.SupplementsCompanion(
      code: drift.Value(s.code),
      name: drift.Value(s.name),
      dose: drift.Value(s.defaultDose),
      unit: drift.Value(s.unit),
      dailyGoal: drift.Value(s.dailyGoal),
      dailyLimit: drift.Value(s.dailyLimit),
      notes: drift.Value(s.notes),
      isBuiltin: drift.Value(s.isBuiltin),
    );

    await (dbInstance.update(dbInstance.supplements)
          ..where((tbl) => tbl.localId.equals(s.id!)))
        .write(companion);
  }

  Future<void> deleteSupplement(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.supplements)
          ..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  // ===========================================================================
  // SUPPLEMENT LOGS
  // ===========================================================================

  Future<SupplementLog> insertSupplementLog(SupplementLog log) async {
    final dbInstance = await database;

    final supplementRow = await (dbInstance.select(dbInstance.supplements)
          ..where((tbl) => tbl.localId.equals(log.supplementId)))
        .getSingle();

    final companion = db.SupplementLogsCompanion(
      supplementId: drift.Value(supplementRow.id),
      amount: drift.Value(log.dose),
      takenAt: drift.Value(log.timestamp),
    );

    final row = await dbInstance
        .into(dbInstance.supplementLogs)
        .insertReturning(companion);

    return SupplementLog(
      id: row.localId,
      supplementId: log.supplementId,
      dose: row.amount,
      unit: 'mg',
      timestamp: row.takenAt,
    );
  }

  Future<List<SupplementLog>> getSupplementLogsForDate(DateTime date) async {
    final dbInstance = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = dbInstance.select(dbInstance.supplementLogs).join([
      drift.innerJoin(
          dbInstance.supplements,
          dbInstance.supplements.id
              .equalsExp(dbInstance.supplementLogs.supplementId))
    ])
      ..where(dbInstance.supplementLogs.takenAt.isBetweenValues(start, end))
      ..orderBy([
        drift.OrderingTerm(
            expression: dbInstance.supplementLogs.takenAt,
            mode: drift.OrderingMode.desc)
      ]);

    final rows = await query.get();

    return rows.map((row) {
      final log = row.readTable(dbInstance.supplementLogs);
      final supp = row.readTable(dbInstance.supplements);
      return SupplementLog(
        id: log.localId,
        supplementId: supp.localId,
        dose: log.amount,
        unit: supp.unit,
        timestamp: log.takenAt,
      );
    }).toList();
  }

  Future<void> updateSupplementLog(SupplementLog log) async {
    if (log.id == null) return;
    final dbInstance = await database;

    await (dbInstance.update(dbInstance.supplementLogs)
          ..where((tbl) => tbl.localId.equals(log.id!)))
        .write(db.SupplementLogsCompanion(
      amount: drift.Value(log.dose),
      takenAt: drift.Value(log.timestamp),
    ));
  }

  Future<void> deleteSupplementLog(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.supplementLogs)
          ..where((tbl) => tbl.localId.equals(id)))
        .go();
  }

  Future<List<SupplementLog>> getAllSupplementLogs() async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.supplementLogs).join([
      drift.innerJoin(
          dbInstance.supplements,
          dbInstance.supplements.id
              .equalsExp(dbInstance.supplementLogs.supplementId))
    ]);
    final rows = await query.get();

    return rows.map((row) {
      final log = row.readTable(dbInstance.supplementLogs);
      final supp = row.readTable(dbInstance.supplements);
      return SupplementLog(
        id: log.localId,
        supplementId: supp.localId,
        dose: log.amount,
        unit: supp.unit,
        timestamp: log.takenAt,
      );
    }).toList();
  }

  // ===========================================================================
  // MEALS
  // ===========================================================================

  Future<int> insertMeal({required String name, String? notes}) async {
    final dbInstance = await database;
    final row = await dbInstance
        .into(dbInstance.meals)
        .insertReturning(db.MealsCompanion(
          name: drift.Value(name),
          notes: drift.Value(notes),
        ));
    return row.localId;
  }

  Future<void> updateMeal(int id, {required String name, String? notes}) async {
    final dbInstance = await database;
    await (dbInstance.update(dbInstance.meals)
          ..where((t) => t.localId.equals(id)))
        .write(db.MealsCompanion(
      name: drift.Value(name),
      notes: drift.Value(notes),
    ));
  }

  Future<void> deleteMeal(int id) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.meals)
          ..where((t) => t.localId.equals(id)))
        .go();
  }

  Future<List<Map<String, dynamic>>> getMeals() async {
    final dbInstance = await database;
    final rows = await dbInstance.select(dbInstance.meals).get();

    return rows
        .map((r) => {
              'id': r.localId,
              'name': r.name,
              'notes': r.notes,
            })
        .toList();
  }

  Future<int> addMealItem(int mealLocalId,
      {required String barcode, required int grams}) async {
    final dbInstance = await database;

    final mealRow = await (dbInstance.select(dbInstance.meals)
          ..where((t) => t.localId.equals(mealLocalId)))
        .getSingle();

    final row = await dbInstance
        .into(dbInstance.mealItems)
        .insertReturning(db.MealItemsCompanion(
          mealId: drift.Value(mealRow.id),
          productBarcode: drift.Value(barcode),
          quantityInGrams: drift.Value(grams),
        ));
    return row.localId;
  }

  Future<List<Map<String, dynamic>>> getMealItems(int mealLocalId) async {
    final dbInstance = await database;

    final mealRow = await (dbInstance.select(dbInstance.meals)
          ..where((t) => t.localId.equals(mealLocalId)))
        .getSingleOrNull();
    if (mealRow == null) return [];

    final rows = await (dbInstance.select(dbInstance.mealItems)
          ..where((t) => t.mealId.equals(mealRow.id)))
        .get();

    return rows
        .map((r) => {
              'id': r.localId,
              'meal_id': mealLocalId,
              'barcode': r.productBarcode,
              'quantity_in_grams': r.quantityInGrams,
            })
        .toList();
  }

  Future<void> removeMealItem(int itemLocalId) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.mealItems)
          ..where((t) => t.localId.equals(itemLocalId)))
        .go();
  }

  Future<void> clearMealItems(int mealLocalId) async {
    final dbInstance = await database;
    final mealRow = await (dbInstance.select(dbInstance.meals)
          ..where((t) => t.localId.equals(mealLocalId)))
        .getSingleOrNull();
    if (mealRow != null) {
      await (dbInstance.delete(dbInstance.mealItems)
            ..where((t) => t.mealId.equals(mealRow.id)))
          .go();
    }
  }

  // ===========================================================================
  // MISC
  // ===========================================================================

  Future<DateTime?> getEarliestFoodEntryDate() async {
    final dbInstance = await database;
    final query = dbInstance.select(dbInstance.nutritionLogs)
      ..orderBy([
        (t) => drift.OrderingTerm(
            expression: t.consumedAt, mode: drift.OrderingMode.asc)
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.consumedAt;
  }

  Future<Set<int>> getNutritionLogDaysInMonth(DateTime month) async {
    final dbInstance = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final rows = await (dbInstance.selectOnly(dbInstance.nutritionLogs)
          ..addColumns([dbInstance.nutritionLogs.consumedAt])
          ..where(
              dbInstance.nutritionLogs.consumedAt.isBetweenValues(start, end)))
        .get();

    return rows
        .map((r) => r.read(dbInstance.nutritionLogs.consumedAt)!.day)
        .toSet();
  }

  Future<Set<int>> getSupplementLogDaysInMonth(DateTime month) async {
    final dbInstance = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final rows = await (dbInstance.selectOnly(dbInstance.supplementLogs)
          ..addColumns([dbInstance.supplementLogs.takenAt])
          ..where(
              dbInstance.supplementLogs.takenAt.isBetweenValues(start, end)))
        .get();

    return rows
        .map((r) => r.read(dbInstance.supplementLogs.takenAt)!.day)
        .toSet();
  }

  // Diese Methode wird vom BackupManager vielleicht aufgerufen, kann aber leer bleiben,
  // da wir die Logik direkt im Fluid-Insert handeln können oder gar nicht brauchen.
  Future<void> upsertCaffeineForFoodEntry({
    required int foodEntryId,
    required DateTime timestamp,
    required double? caffeinePer100ml,
    required double quantityInMl,
  }) async {
    // Implementierung optional, wenn du automatische Caffeine-Logs willst
  }

  // ===========================================================================
  // FAVORITEN (Fehlende Methoden für BackupManager)
  // ===========================================================================

  Future<void> addFavorite(String barcode) async {
    final dbInstance = await database;
    await dbInstance.into(dbInstance.favorites).insert(
          FavoritesCompanion(barcode: drift.Value(barcode)),
          mode: drift.InsertMode.insertOrReplace,
        );
  }

  Future<void> removeFavorite(String barcode) async {
    final dbInstance = await database;
    await (dbInstance.delete(dbInstance.favorites)
          ..where((t) => t.barcode.equals(barcode)))
        .go();
  }

  Future<bool> isFavorite(String barcode) async {
    final dbInstance = await database;
    final count = await (dbInstance.select(dbInstance.favorites)
          ..where((t) => t.barcode.equals(barcode)))
        .get();
    return count.isNotEmpty;
  }

  Future<List<String>> getFavoriteBarcodes() async {
    final dbInstance = await database;
    final rows = await dbInstance.select(dbInstance.favorites).get();
    return rows.map((r) => r.barcode).toList();
  }

  Future<List<String>> getRecentlyUsedBarcodes() async {
    final dbInstance = await database;

    final maxDate = dbInstance.nutritionLogs.consumedAt.max();
    final query = dbInstance.selectOnly(dbInstance.nutritionLogs)
      ..addColumns([dbInstance.nutritionLogs.legacyBarcode, maxDate])
      ..groupBy([dbInstance.nutritionLogs.legacyBarcode])
      ..orderBy([
        drift.OrderingTerm(expression: maxDate, mode: drift.OrderingMode.desc)
      ])
      ..limit(20);

    final result = await query.get();

    return result
        .map((row) => row.read(dbInstance.nutritionLogs.legacyBarcode))
        .where((bc) => bc != null)
        .cast<String>()
        .toList();
  }
  // ===========================================================================
  // ONBOARDING & PROFILE HELPER (FIXED)
  // ===========================================================================

  Future<db.Profile?> getUserProfile() async {
    final dbInstance = await database;
    return await dbInstance.select(dbInstance.profiles).getSingleOrNull();
  }

  Future<db.AppSetting?> getAppSettings() async {
    final dbInstance = await database;
    return await dbInstance.select(dbInstance.appSettings).getSingleOrNull();
  }

  /// Erstellt oder aktualisiert das Basis-Profil
  Future<void> saveUserProfile({
    required String name,
    required DateTime? birthday,
    required int? height,
    required String? gender,
  }) async {
    final dbInstance = await database;

    final existing =
        await dbInstance.select(dbInstance.profiles).getSingleOrNull();

    if (existing == null) {
      // NEU anlegen
      await dbInstance.into(dbInstance.profiles).insert(db.ProfilesCompanion(
            username: drift.Value(name),
            birthday: drift.Value(birthday),
            height: drift.Value(height),
            gender: drift.Value(gender),
            isCoach: const drift.Value(false),
            visibility: const drift.Value('private'),
          ));
    } else {
      // UPDATE
      await (dbInstance.update(dbInstance.profiles)
            ..where((t) => t.id.equals(existing.id)))
          .write(db.ProfilesCompanion(
        username: drift.Value(name),
        birthday: drift.Value(birthday),
        height: drift.Value(height),
        gender: drift.Value(gender),
      ));
    }
  }

  /// Speichert die Ziele (AppSettings) - ROBUSTERE VERSION
  Future<void> saveUserGoals({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required int water,
  }) async {
    final dbInstance = await database;

    // 1. Prüfen, ob schon Settings da sind
    final existingSettings =
        await dbInstance.select(dbInstance.appSettings).getSingleOrNull();

    if (existingSettings != null) {
      // UPDATE
      await (dbInstance.update(dbInstance.appSettings)
            ..where((t) => t.id.equals(existingSettings.id)))
          .write(db.AppSettingsCompanion(
        targetCalories: drift.Value(calories),
        targetProtein: drift.Value(protein),
        targetCarbs: drift.Value(carbs),
        targetFat: drift.Value(fat),
        targetWater: drift.Value(water),
      ));
    } else {
      // INSERT (Falls saveUserProfile die Settings noch nicht angelegt hat)
      // Wir brauchen die User-ID
      final profile =
          await dbInstance.select(dbInstance.profiles).getSingleOrNull();
      if (profile != null) {
        await dbInstance
            .into(dbInstance.appSettings)
            .insert(db.AppSettingsCompanion(
              userId: drift.Value(profile.id),
              targetCalories: drift.Value(calories),
              targetProtein: drift.Value(protein),
              targetCarbs: drift.Value(carbs),
              targetFat: drift.Value(fat),
              targetWater: drift.Value(water),
              themeMode: const drift.Value('system'), // Defaults
              unitSystem: const drift.Value('metric'),
            ));
      } else {
        debugPrint(
            "⚠️ FEHLER: Kein Profil gefunden, kann Ziele nicht speichern!");
      }
    }
  }

  /// Speichert das Startgewicht als Messung
  Future<void> saveInitialWeight(double weightKg) async {
    final dbInstance = await database;
    final now = DateTime.now();

    await dbInstance
        .into(dbInstance.measurements)
        .insert(db.MeasurementsCompanion(
          date: drift.Value(now),
          type: const drift.Value('weight'),
          value: drift.Value(weightKg),
          unit: const drift.Value('kg'),
          legacySessionId: drift.Value(now.millisecondsSinceEpoch),
        ));
  }
}
