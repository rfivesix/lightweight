import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../data/product_database_helper.dart';
import '../models/chart_data_point.dart';
import '../models/food_entry.dart';
import '../models/fluid_entry.dart';

class DailyValuePoint {
  final DateTime day;
  final double value;

  const DailyValuePoint({required this.day, required this.value});
}

enum BodyNutritionInsightType {
  notEnoughData,
  stableWeightCaloriesUp,
  weightUpCaloriesUp,
  caloriesDownWeightNotYetChanged,
  weightDownCaloriesDown,
  mixed,
}

class BodyNutritionAnalyticsResult {
  final DateTimeRange range;
  final int totalDays;
  final double? currentWeightKg;
  final double? weightChangeKg;
  final double avgDailyCalories;
  final int weightDays;
  final int loggedCalorieDays;
  final List<DailyValuePoint> weightDaily;
  final List<DailyValuePoint> smoothedWeight;
  final List<DailyValuePoint> caloriesDaily;
  final List<DailyValuePoint> smoothedCalories;
  final BodyNutritionInsightType insightType;

  const BodyNutritionAnalyticsResult({
    required this.range,
    required this.totalDays,
    required this.currentWeightKg,
    required this.weightChangeKg,
    required this.avgDailyCalories,
    required this.weightDays,
    required this.loggedCalorieDays,
    required this.weightDaily,
    required this.smoothedWeight,
    required this.caloriesDaily,
    required this.smoothedCalories,
    required this.insightType,
  });

  bool get hasAnyData => weightDays > 0 || loggedCalorieDays > 0;

  bool get hasEnoughForInsight =>
      insightType != BodyNutritionInsightType.notEnoughData;
}

class BodyNutritionAnalyticsUtils {
  static DateTime normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  static int daysFromRangeIndex(int index) {
    switch (index) {
      case 0:
        return 7;
      case 1:
        return 30;
      case 2:
        return 90;
      case 3:
        return 180;
      default:
        return 30;
    }
  }

  static Future<BodyNutritionAnalyticsResult> build({
    required int rangeIndex,
  }) async {
    final db = DatabaseHelper.instance;
    final now = normalizeDay(DateTime.now());

    final range = await _resolveRange(db: db, rangeIndex: rangeIndex, now: now);

    final weightFuture = db.getChartDataForTypeAndRange('weight', range);
    final foodEntriesFuture = db.getEntriesForDateRange(range.start, range.end);
    final fluidEntriesFuture =
        db.getFluidEntriesForDateRange(range.start, range.end);

    final results = await Future.wait([
      weightFuture,
      foodEntriesFuture,
      fluidEntriesFuture,
    ]);

    final weightPoints = (results[0] as List<ChartDataPoint>);
    final foodEntries = results[1] as List<FoodEntry>;
    final fluidEntries = (results[2] as List<FluidEntry>);

    final weightByDay = _latestWeightPerDay(weightPoints);
    final caloriesByDay = await _dailyCaloriesMap(
      foodEntries: foodEntries,
      fluidEntries: fluidEntries,
    );

    final allDays = _enumerateDays(range.start, range.end);

    final weightDaily = <DailyValuePoint>[];
    final caloriesDaily = <DailyValuePoint>[];
    int loggedCalorieDays = 0;

    for (final day in allDays) {
      final calories = caloriesByDay[day] ?? 0.0;
      if (calories > 0) {
        loggedCalorieDays += 1;
      }
      caloriesDaily.add(DailyValuePoint(day: day, value: calories));

      final weight = weightByDay[day];
      if (weight != null) {
        weightDaily.add(DailyValuePoint(day: day, value: weight));
      }
    }

    final smoothedWeight = _movingAverage(
      series: weightDaily,
      windowSize: weightDaily.length >= 14 ? 5 : 3,
    );
    final smoothedCalories = _movingAverage(
      series: caloriesDaily,
      windowSize: caloriesDaily.length >= 30 ? 7 : 3,
    );

    final totalDays = allDays.length;
    final avgDailyCalories = totalDays <= 0
        ? 0.0
        : caloriesDaily.fold<double>(0.0, (sum, p) => sum + p.value) /
            totalDays;

    final currentWeightKg = weightDaily.isEmpty ? null : weightDaily.last.value;
    final weightChangeKg = _weightChange(smoothedWeight, weightDaily);

    final insightType = _deriveInsight(
      range: range,
      totalDays: totalDays,
      weightDaily: weightDaily,
      smoothedWeight: smoothedWeight,
      caloriesDaily: caloriesDaily,
      smoothedCalories: smoothedCalories,
      loggedCalorieDays: loggedCalorieDays,
      weightChangeKg: weightChangeKg,
    );

    return BodyNutritionAnalyticsResult(
      range: range,
      totalDays: totalDays,
      currentWeightKg: currentWeightKg,
      weightChangeKg: weightChangeKg,
      avgDailyCalories: avgDailyCalories,
      weightDays: weightDaily.length,
      loggedCalorieDays: loggedCalorieDays,
      weightDaily: weightDaily,
      smoothedWeight: smoothedWeight,
      caloriesDaily: caloriesDaily,
      smoothedCalories: smoothedCalories,
      insightType: insightType,
    );
  }

  static List<DailyValuePoint> normalizedSeries(List<DailyValuePoint> points) {
    if (points.isEmpty) return const [];
    final minValue = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxValue = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final span = (maxValue - minValue).abs();
    if (span < 0.0001) {
      return points
          .map((p) => DailyValuePoint(day: p.day, value: 0.5))
          .toList(growable: false);
    }

    return points
        .map(
          (p) => DailyValuePoint(
            day: p.day,
            value: (p.value - minValue) / span,
          ),
        )
        .toList(growable: false);
  }

  static Future<DateTimeRange> _resolveRange({
    required DatabaseHelper db,
    required int rangeIndex,
    required DateTime now,
  }) async {
    if (rangeIndex == 4) {
      final earliest = await _earliestRelevantDate(db);
      final start = earliest ?? now;
      return DateTimeRange(start: start, end: endOfDay(now));
    }

    final days = daysFromRangeIndex(rangeIndex);
    final start = now.subtract(Duration(days: days - 1));
    return DateTimeRange(start: start, end: endOfDay(now));
  }

  static Future<DateTime?> _earliestRelevantDate(DatabaseHelper db) async {
    final results = await Future.wait<DateTime?>([
      db.getEarliestMeasurementDate(),
      db.getEarliestFoodEntryDate(),
      db.getEarliestFluidEntryDate(),
    ]);

    final dates = results.whereType<DateTime>().map(normalizeDay).toList();
    if (dates.isEmpty) return null;

    dates.sort();
    return dates.first;
  }

  static Map<DateTime, double> _latestWeightPerDay(
      List<ChartDataPoint> points) {
    final sorted = points.toList()..sort((a, b) => a.date.compareTo(b.date));

    final map = <DateTime, double>{};
    for (final point in sorted) {
      map[normalizeDay(point.date)] = point.value;
    }
    return map;
  }

  static Future<Map<DateTime, double>> _dailyCaloriesMap({
    required List<FoodEntry> foodEntries,
    required List<FluidEntry> fluidEntries,
  }) async {
    final map = <DateTime, double>{};
    final productDb = ProductDatabaseHelper.instance;
    final foodCaloriesPer100gCache = <String, int>{};

    for (final entry in foodEntries) {
      final day = normalizeDay(entry.timestamp);
      final barcode = entry.barcode;
      if (!foodCaloriesPer100gCache.containsKey(barcode)) {
        final product = await productDb.getProductByBarcode(barcode);
        foodCaloriesPer100gCache[barcode] = product?.calories ?? 0;
      }
      final caloriesPer100g = foodCaloriesPer100gCache[barcode] ?? 0;
      final amountGrams = entry.quantityInGrams.toDouble();
      final added = caloriesPer100g * (amountGrams / 100.0);
      map[day] = (map[day] ?? 0.0) + added;
    }

    for (final entry in fluidEntries) {
      final day = normalizeDay(entry.timestamp);
      final added = (entry.kcal ?? 0).toDouble();
      map[day] = (map[day] ?? 0.0) + added;
    }

    return map;
  }

  static List<DateTime> _enumerateDays(DateTime start, DateTime end) {
    final normalizedStart = normalizeDay(start);
    final normalizedEnd = normalizeDay(end);
    final result = <DateTime>[];
    var cursor = normalizedStart;
    while (!cursor.isAfter(normalizedEnd)) {
      result.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  static List<DailyValuePoint> _movingAverage({
    required List<DailyValuePoint> series,
    required int windowSize,
  }) {
    if (series.isEmpty) return const [];
    if (windowSize <= 1) return List<DailyValuePoint>.from(series);

    final values = series.map((p) => p.value).toList(growable: false);
    final result = <DailyValuePoint>[];

    for (var i = 0; i < series.length; i++) {
      final start = (i - windowSize + 1).clamp(0, i);
      final slice = values.sublist(start, i + 1);
      final avg =
          slice.fold<double>(0.0, (sum, value) => sum + value) / slice.length;
      result.add(DailyValuePoint(day: series[i].day, value: avg));
    }

    return result;
  }

  static double? _weightChange(
    List<DailyValuePoint> smoothedWeight,
    List<DailyValuePoint> rawWeight,
  ) {
    final source = smoothedWeight.length >= 2 ? smoothedWeight : rawWeight;
    if (source.length < 2) return null;
    return source.last.value - source.first.value;
  }

  static BodyNutritionInsightType _deriveInsight({
    required DateTimeRange range,
    required int totalDays,
    required List<DailyValuePoint> weightDaily,
    required List<DailyValuePoint> smoothedWeight,
    required List<DailyValuePoint> caloriesDaily,
    required List<DailyValuePoint> smoothedCalories,
    required int loggedCalorieDays,
    required double? weightChangeKg,
  }) {
    final spanDays =
        normalizeDay(range.end).difference(normalizeDay(range.start)).inDays +
            1;

    final hasDataQuality = spanDays >= 14 &&
        totalDays >= 14 &&
        weightDaily.length >= 5 &&
        loggedCalorieDays >= 7;

    if (!hasDataQuality || weightChangeKg == null) {
      return BodyNutritionInsightType.notEnoughData;
    }

    final calorieChange = _seriesHalfDelta(
      smoothedCalories.isNotEmpty ? smoothedCalories : caloriesDaily,
    );

    if (calorieChange == null) {
      return BodyNutritionInsightType.notEnoughData;
    }

    if (weightChangeKg.abs() < 0.35 && calorieChange >= 120) {
      return BodyNutritionInsightType.stableWeightCaloriesUp;
    }

    if (weightChangeKg >= 0.45 && calorieChange >= 80) {
      return BodyNutritionInsightType.weightUpCaloriesUp;
    }

    if (calorieChange <= -120 && weightChangeKg > -0.2) {
      return BodyNutritionInsightType.caloriesDownWeightNotYetChanged;
    }

    if (weightChangeKg <= -0.45 && calorieChange <= -80) {
      return BodyNutritionInsightType.weightDownCaloriesDown;
    }

    return BodyNutritionInsightType.mixed;
  }

  static double? _seriesHalfDelta(List<DailyValuePoint> series) {
    if (series.length < 8) return null;
    final half = (series.length / 2).floor();
    if (half <= 0 || half >= series.length) return null;

    final first = series.sublist(0, half);
    final second = series.sublist(half);

    final firstAvg =
        first.fold<double>(0.0, (sum, p) => sum + p.value) / first.length;
    final secondAvg =
        second.fold<double>(0.0, (sum, p) => sum + p.value) / second.length;

    return secondAvg - firstAvg;
  }
}
