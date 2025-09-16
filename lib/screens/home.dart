// lib/screens/home.dart (Final & SWR-Lade-Logik)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/chart_data_point.dart';
import 'package:lightweight/models/daily_nutrition.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/screens/live_workout_screen.dart';
import 'package:lightweight/screens/measurements_screen.dart';
import 'package:lightweight/screens/nutrition_screen.dart';
import 'package:lightweight/widgets/measurement_chart_widget.dart';
import 'package:lightweight/widgets/nutrition_summary_widget.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/util/time_util.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  DailyNutrition? _nutritionData;
  String _recommendationText = "";
  // KORREKTUR: _isLoading wird jetzt nur für den ERSTEN Ladevorgang auf true gesetzt
  bool _isLoading = true; 

  List<ChartDataPoint> _weightChartData = [];
  DateTimeRange _currentDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 29)),
      end: DateTime.now());
  final String _chartType = 'weight';
  Map<String, int> _workoutStats = {};
  bool _isFirstLoad = true;

  List<String> _chartDateRangeKeys = ['30D', '90D', 'All'];
  String _selectedChartRangeKey = '30D';


  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      loadAllHomeScreenData(showLoadingIndicator: true); // KORREKTUR: Zeige Indikator nur beim ersten Mal
      _isFirstLoad = false;
    }
  }

  // KORREKTUR: loadAllHomeScreenData akzeptiert jetzt einen optionalen Parameter
  Future<void> loadAllHomeScreenData({bool showLoadingIndicator = false}) async {
    if (!mounted) return;
    
    // KORREKTUR: Setze _isLoading nur, wenn der Indikator wirklich gezeigt werden soll
    if (showLoadingIndicator) {
      setState(() => _isLoading = true);
    }

    // --- DATEN HIER LADEN ---
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    final targetCalories = prefs.getInt('targetCalories') ?? 2500;
    final targetProtein = prefs.getInt('targetProtein') ?? 180;
    final targetCarbs = prefs.getInt('targetCarbs') ?? 250;
    final targetFat = prefs.getInt('targetFat') ?? 80;
    final targetWater = prefs.getInt('targetWater') ?? 3000;

    final entries = await DatabaseHelper.instance.getEntriesForDate(DateTime.now());
    final waterIntake = await DatabaseHelper.instance.getWaterForDate(DateTime.now());
    final newTodaysNutrition = DailyNutrition(
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        targetCarbs: targetCarbs,
        targetFat: targetFat,
        targetWater: targetWater);
    newTodaysNutrition.water = waterIntake;

    final newWorkoutStats = await _getWorkoutStats(); // KORREKTUR: Methode umbenannt
    await _loadChartData(); // Lädt Chart-Daten und setzt _weightChartData

    for (final entry in entries) {
      final foodItem = await ProductDatabaseHelper.instance.getProductByBarcode(entry.barcode);
      if (foodItem != null) {
        newTodaysNutrition.calories += (foodItem.calories / 100 * entry.quantityInGrams).round();
        newTodaysNutrition.protein += (foodItem.protein / 100 * entry.quantityInGrams).round();
        newTodaysNutrition.carbs += (foodItem.carbs / 100 * entry.quantityInGrams).round();
        newTodaysNutrition.fat += (foodItem.fat / 100 * entry.quantityInGrams).round();
      }
    }

    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final recentEntries = await DatabaseHelper.instance.getEntriesForDateRange(sevenDaysAgo, today);
    String newRecommendation = l10n.recommendationDefault;
    if (recentEntries.isNotEmpty) {
      final uniqueDaysTracked = recentEntries.map((e) => DateFormat.yMd().format(e.timestamp)).toSet();
      final numberOfTrackedDays = uniqueDaysTracked.length;
      int totalRecentCalories = 0;
      for (final entry in recentEntries) {
        final foodItem = await ProductDatabaseHelper.instance.getProductByBarcode(entry.barcode);
        if (foodItem != null) {
          totalRecentCalories += (foodItem.calories / 100 * entry.quantityInGrams).round();
        }
      }
      final totalTargetCalories = targetCalories * numberOfTrackedDays;
      final difference = totalRecentCalories - totalTargetCalories;
      if (numberOfTrackedDays > 1) {
        final tolerance = totalTargetCalories * 0.05;
        if (difference > tolerance) {
          newRecommendation = l10n.recommendationOverTarget(numberOfTrackedDays, difference.round());
        } else if (difference < -tolerance) {
          newRecommendation = l10n.recommendationUnderTarget(numberOfTrackedDays, (-difference).round());
        } else {
          newRecommendation = l10n.recommendationOnTarget(numberOfTrackedDays);
        }
      } else {
        newRecommendation = l10n.recommendationFirstEntry;
      }
    }
    // --- DATEN LADEN ENDE ---

    if (mounted) {
      setState(() {
        _nutritionData = newTodaysNutrition; // Neue Daten
        _recommendationText = newRecommendation; // Neue Daten
        _workoutStats = newWorkoutStats; // Neue Daten
        _isLoading = false; // Ladezustand beenden
      });
    }
  }

Future<void> _loadChartData() async {
  // Hole alle Mess-Sessions und filtere auf den sichtbaren Bereich + Typ "weight"
  final sessions = await DatabaseHelper.instance.getMeasurementSessions();

  // Tagesgrenzen normalisieren (Start 00:00, Ende 23:59:59)
  final start = DateTime(_currentDateRange.start.year, _currentDateRange.start.month, _currentDateRange.start.day);
  final end = DateTime(_currentDateRange.end.year, _currentDateRange.end.month, _currentDateRange.end.day, 23, 59, 59);

  final points = <ChartDataPoint>[];

  for (final s in sessions) {
    if (s.timestamp.isBefore(start) || s.timestamp.isAfter(end)) continue;

    for (final m in s.measurements) {
      if (m.type == _chartType) {
        // Annahme: ChartDataPoint hat Felder/Named-Ctor "date" und "value"
        points.add(ChartDataPoint(date: s.timestamp, value: m.value.toDouble()));
      }
    }
  }

  points.sort((a, b) => a.date.compareTo(b.date));

  if (!mounted) return;
  setState(() {
    _weightChartData = points;
  });
}

  // KORREKTUR: Methode umbenannt, damit sie Daten ZURÜCKGIBT
  Future<Map<String, int>> _getWorkoutStats() async {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final logs = await WorkoutDatabaseHelper.instance
        .getWorkoutLogsForDateRange(sevenDaysAgo, today);

    int count = logs.length;
    int duration = 0;
    int volume = 0;

    for (final log in logs) {
      if (log.endTime != null) {
        duration += log.endTime!.difference(log.startTime).inMinutes;
      }
      for (final set in log.sets) {
        volume += ((set.weightKg ?? 0) * (set.reps ?? 0)).round();
      }
    }
    return {
      'count': count,
      'duration': duration,
      'volume': volume,
    };
  }

Future<void> _loadLatestWorkout() async {
  // Beispiel: hole alle Logs und merke dir das Neueste (falls du es später anzeigen willst)
  final logs = await WorkoutDatabaseHelper.instance.getWorkoutLogs();
  if (logs.isEmpty) return;

  logs.sort((a, b) => b.startTime.compareTo(a.startTime));
  final latest = logs.first;

  // Falls du später etwas im UI mit dem letzten Log machen willst,
  // kannst du hier setState(...) nutzen und z.B. ein Feld speichern.
  // Aktuell: kein sichtbarer Seiteneffekt nötig.
}

void _navigateTimeRange(bool forward) {
  // "All" deckt sowieso alles ab – kein Paging
  if (_selectedChartRangeKey == 'All') return;

  final int days = _selectedChartRangeKey == '90D' ? 90 : 30;
  final delta = Duration(days: days);

  final newStart = forward ? _currentDateRange.start.add(delta) : _currentDateRange.start.subtract(delta);
  final newEnd   = forward ? _currentDateRange.end.add(delta)   : _currentDateRange.end.subtract(delta);

  setState(() {
    _currentDateRange = DateTimeRange(start: newStart, end: newEnd);
  });

  // Daten für die neue Range nachladen
  _loadChartData();
}

  void _navigateToNutritionScreen() {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (context) => const NutritionScreen()))
      .then((_) => loadAllHomeScreenData(showLoadingIndicator: false));
}

  void _repeatWorkout(WorkoutLog log) async {
  // Startet ein neues (ggf. leeres) Workout mit dem gleichen Namen wie der Log.
  // (Für 1:1-Übungs-Übernahme bräuchte man mehr Logik; so ist es "lightweight".)
  final newWorkoutLog = await WorkoutDatabaseHelper.instance.startWorkout(
    routineName: log.routineName ?? AppLocalizations.of(context)!.freeWorkoutTitle,
  );

  if (!mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => LiveWorkoutScreen(workoutLog: newWorkoutLog),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // KORREKTUR: Zeige den Ladeindikator nur, wenn _isLoading true UND keine Daten vorhanden sind
    final showLoadingOverlay = _isLoading && _nutritionData == null;

    return Scaffold(
      body: Stack(
        children: [
          // KORREKTUR: Der RefreshIndicator ist immer da, damit man ziehen kann.
          // Der Inhalt wird immer angezeigt, auch wenn _isLoading true ist (alte Daten).
          RefreshIndicator(
            onRefresh: () => loadAllHomeScreenData(showLoadingIndicator: false), // KORREKTUR: Kein Ladeindikator bei manueller Aktualisierung
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                _buildBannerCard(l10n),
                const SizedBox(height: 8),
                GestureDetector(
                    onTap: _navigateToNutritionScreen,
                    child: _nutritionData != null
                        ? NutritionSummaryWidget(nutritionData: _nutritionData!, isExpandedView: false, l10n: l10n)
                        : const SizedBox.shrink()),
                if (_weightChartData.isNotEmpty)
                const SizedBox(height: 8),
                  GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MeasurementsScreen())).then((_) => loadAllHomeScreenData()),
                      child: _buildWeightChartCard(context, colorScheme, l10n)),
                const SizedBox(height: 8),
                _buildWorkoutStatsCard(l10n),
              ],
            ),
          ),
          // KORREKTUR: Lade-Overlay nur anzeigen, wenn showLoadingOverlay true ist
          if (showLoadingOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildBannerCard(AppLocalizations l10n) {
    // KORREKTUR: externalMargin wird jetzt gesetzt
    return SummaryCard(
      //internalPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      //externalMargin: EdgeInsets.zero, // Wichtig, da ListView.separated den Abstand steuert
      child: Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          _recommendationText,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 22,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // KORREKTUR: _buildNutritionCard wickelt jetzt das NutritionSummaryWidget in eine SummaryCard
  Widget _buildNutritionCard(AppLocalizations l10n) {
    return _nutritionData == null
        ? const SizedBox.shrink()
        : SummaryCard( // KORREKTUR: SummaryCard um das Widget
            //internalPadding: const EdgeInsets.all(12.0), // Passender Padding
            //externalMargin: EdgeInsets.zero, // Wichtig
            child: NutritionSummaryWidget(
              nutritionData: _nutritionData!,
              isExpandedView: false,
              l10n: l10n,
            ),
          );
  }

  Widget _buildWeightChartCard(BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
    // KORREKTUR: externalMargin wird jetzt gesetzt
    return SummaryCard(
      //externalMargin: EdgeInsets.zero, // Wichtig
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Gewichtsverlauf", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8.0,
                      alignment: WrapAlignment.end,
                      children: _chartDateRangeKeys.map((key) => _buildFilterButton(key, key)).toList(),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${DateFormat.MMMd().format(_currentDateRange.start)} - ${DateFormat.MMMd().format(_currentDateRange.end)}", style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) _navigateTimeRange(false);
                if (details.primaryVelocity! < 0) _navigateTimeRange(true);
              },
              child: MeasurementChartWidget(
                chartType: _chartType,
                dateRange: _currentDateRange,
                lineColor: colorScheme.secondary,
                unit: "kg",
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFilterButton(String label, String key) {
    final theme = Theme.of(context);
    final isSelected = _selectedChartRangeKey == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartRangeKey = key;
        });
        _loadChartData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutStatsCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    // KORREKTUR: externalMargin wird jetzt gesetzt
    return SummaryCard(
      //externalMargin: EdgeInsets.zero, // Wichtig
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workoutStatsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.fitness_center, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      "${_workoutStats['count'] ?? 0}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(l10n.workoutsLabel,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.timer, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      "${_workoutStats['duration'] ?? 0} min",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(l10n.durationLabel,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.monitor_weight, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      "${_workoutStats['volume'] ?? 0} kg",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(l10n.volumeLabel,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}