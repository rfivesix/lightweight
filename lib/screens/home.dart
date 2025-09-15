// lib/screens/home.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/dialogs/quantity_dialog_content.dart';
import 'package:lightweight/dialogs/water_dialog_content.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/chart_data_point.dart';
import 'package:lightweight/models/daily_nutrition.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/screens/add_food_screen.dart';
import 'package:lightweight/screens/data_management_screen.dart';
import 'package:lightweight/screens/exercise_catalog_screen.dart';
import 'package:lightweight/screens/food_explorer_screen.dart';
import 'package:lightweight/screens/live_workout_screen.dart';
import 'package:lightweight/screens/measurements_screen.dart';
import 'package:lightweight/screens/nutrition_screen.dart';
import 'package:lightweight/screens/profile_screen.dart';
import 'package:lightweight/screens/routines_screen.dart';
import 'package:lightweight/screens/add_measurement_screen.dart';
import 'package:lightweight/screens/workout_history_screen.dart';
import 'package:lightweight/services/workout_session_manager.dart';
import 'package:lightweight/widgets/add_menu_sheet.dart';
import 'package:lightweight/widgets/measurement_chart_widget.dart';
import 'package:lightweight/widgets/nutrition_summary_widget.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/services/workout_session_manager.dart';
import 'package:lightweight/screens/live_workout_screen.dart';
import 'package:provider/provider.dart';



class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  DailyNutrition? _nutritionData;
  String _recommendationText = "";
  bool _isLoading = true;

  List<ChartDataPoint> _weightChartData = [];
  WorkoutLog? _latestWorkoutLog;
  DateTimeRange _currentDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 29)),
    end: DateTime.now(),
  );
  final String _chartType = 'weight';
  final String _chartUnit = 'kg';
  bool _isFirstLoad = true;

  Map<String, int> _workoutStats = {
    'count': 0,
    'duration': 0,
    'volume': 0,
  };


  @override
  void initState() {
    super.initState();
    // Die Daten werden jetzt in didChangeDependencies geladen, um den Kontext sicherzustellen.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _loadAllHomeScreenData();
      _isFirstLoad = false;
    }
  }

  Future<void> _loadAllHomeScreenData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    final targetCalories = prefs.getInt('targetCalories') ?? 2500;
    final targetProtein = prefs.getInt('targetProtein') ?? 180;
    final targetCarbs = prefs.getInt('targetCarbs') ?? 250;
    final targetFat = prefs.getInt('targetFat') ?? 80;
    final targetWater = prefs.getInt('targetWater') ?? 3000;
    
    final entries = await DatabaseHelper.instance.getEntriesForDate(DateTime.now());
    final waterIntake = await DatabaseHelper.instance.getWaterForDate(DateTime.now());
    final todaysNutrition = DailyNutrition(targetCalories: targetCalories, targetProtein: targetProtein, targetCarbs: targetCarbs, targetFat: targetFat, targetWater: targetWater);
    todaysNutrition.water = waterIntake;

    await _loadWorkoutStats();

    for (final entry in entries) {
      final foodItem = await ProductDatabaseHelper.instance.getProductByBarcode(entry.barcode);
      if (foodItem != null) {
        // KORREKTUR: Typsicherheit für num -> int
        todaysNutrition.calories += (foodItem.calories / 100 * entry.quantityInGrams).round();
        todaysNutrition.protein += (foodItem.protein / 100 * entry.quantityInGrams).round();
        todaysNutrition.carbs += (foodItem.carbs / 100 * entry.quantityInGrams).round();
        todaysNutrition.fat += (foodItem.fat / 100 * entry.quantityInGrams).round();
      }
    }

    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final recentEntries = await DatabaseHelper.instance.getEntriesForDateRange(sevenDaysAgo, today);
    String recommendation = l10n.recommendationDefault;
    if (recentEntries.isNotEmpty) {
      final uniqueDaysTracked = recentEntries.map((e) => DateFormat.yMd().format(e.timestamp)).toSet();
      final numberOfTrackedDays = uniqueDaysTracked.length;
      int totalRecentCalories = 0;
      for (final entry in recentEntries) {
        final foodItem = await ProductDatabaseHelper.instance.getProductByBarcode(entry.barcode);
        if (foodItem != null) {
          // KORREKTUR: Typsicherheit für num -> int
          totalRecentCalories += (foodItem.calories / 100 * entry.quantityInGrams).round();
        }
      }
      final totalTargetCalories = targetCalories * numberOfTrackedDays;
      final difference = totalRecentCalories - totalTargetCalories;
      if (numberOfTrackedDays > 1) {
        final tolerance = totalTargetCalories * 0.05;
        if (difference > tolerance) {
          recommendation = l10n.recommendationOverTarget(numberOfTrackedDays, difference.round());
        } else if (difference < -tolerance) {
          recommendation = l10n.recommendationUnderTarget(numberOfTrackedDays, (-difference).round());
        } else {
          recommendation = l10n.recommendationOnTarget(numberOfTrackedDays);
        }
      } else {
        recommendation = l10n.recommendationFirstEntry;
      }
    }

    
    
    // Lade alle Daten, bevor der Ladezustand beendet wird
    await Future.wait([_loadChartData(), _loadLatestWorkout()]);

    if (mounted) {
      setState(() {
        _nutritionData = todaysNutrition;
        _recommendationText = recommendation;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChartData() async {
    final data = await DatabaseHelper.instance.getChartDataForTypeAndRange(_chartType, _currentDateRange);
    if (mounted) setState(() => _weightChartData = data);
  }

  Future<void> _loadWorkoutStats() async {
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

    if (mounted) {
      setState(() {
        _workoutStats = {
          'count': count,
          'duration': duration,
          'volume': volume,
        };
      });
    }
  }


  Future<void> _loadLatestWorkout() async {
    final log = await WorkoutDatabaseHelper.instance.getLatestWorkoutLog();
    if (mounted) setState(() => _latestWorkoutLog = log);
  }

  void _navigateTimeRange(bool forward) {
    setState(() {
      final duration = _currentDateRange.duration;
      DateTime newStart;
      DateTime newEnd;
      if (forward) {
        newStart = _currentDateRange.start.add(duration);
        newEnd = _currentDateRange.end.add(duration);
        if (newEnd.isAfter(DateTime.now())) {
          newEnd = DateTime.now();
          newStart = newEnd.subtract(duration);
        }
      } else {
        newStart = _currentDateRange.start.subtract(duration);
        newEnd = _currentDateRange.end.subtract(duration);
      }
      _currentDateRange = DateTimeRange(start: newStart, end: newEnd);
    });
    _loadChartData();
  }

  void _addFoodItem(FoodItem item) async {
    final result = await _showQuantityDialog(item);
    if (result != null) {
      final quantity = result.$1;
      final timestamp = result.$2;
      final countAsWater = result.$3;
      final mealType = result.$4;

      final newEntry = FoodEntry(
        barcode: item.barcode,
        timestamp: timestamp,
        quantityInGrams: quantity,
        mealType: mealType,
      );

      await DatabaseHelper.instance.insertFoodEntry(newEntry);
      if (countAsWater) {
        await DatabaseHelper.instance.insertWaterEntry(quantity, timestamp);
      }
      await _loadAllHomeScreenData();
    }
  }

  void _addWater(int quantityInMl, DateTime timestamp) async {
    await DatabaseHelper.instance.insertWaterEntry(quantityInMl, timestamp);
    await _loadAllHomeScreenData();
  }

  void _navigateToNutritionScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NutritionScreen())).then((_) => _loadAllHomeScreenData());
  }

  // LOGIK, UM EIN WORKOUT VOM DASHBOARD ZU WIEDERHOLEN
  void _repeatWorkout(WorkoutLog log) async {
    if (log.routineName == null) {
      // Starte ein leeres Workout
      final newLog = await WorkoutDatabaseHelper.instance.startWorkout(routineName: "Freies Training");
      if(mounted) Navigator.of(context).push(MaterialPageRoute(builder: (context) => LiveWorkoutScreen(workoutLog: newLog)));
      return;
    }
    
    // Finde die Routine und starte sie
    final routine = await WorkoutDatabaseHelper.instance.getRoutineByName(log.routineName!);
    if (routine != null) {
      final newLog = await WorkoutDatabaseHelper.instance.startWorkout(routineName: routine.name);
      if(mounted) Navigator.of(context).push(MaterialPageRoute(builder: (context) => LiveWorkoutScreen(routine: routine, workoutLog: newLog)));
    }
  }

  void _showAddMenu() async {
    final colorScheme = Theme.of(context).colorScheme;
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colorScheme.surface,
      elevation: 8.0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) => const AddMenuSheet(),
    );

    if (!mounted) return;

    switch (result) {
      case 'start_workout':
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RoutinesScreen()));
        break;
      case 'add_measurement':
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddMeasurementScreen())).then((success) {
          if (success == true) _loadAllHomeScreenData(); // Lade Dashboard neu, um Graphen zu aktualisieren
        });
        break;
      case 'add_food':
        final selectedFoodItem = await Navigator.of(context).push<FoodItem>(MaterialPageRoute(builder: (context) => const AddFoodScreen()));
        if (selectedFoodItem != null) _addFoodItem(selectedFoodItem);
        break;
      case 'add_liquid':
        final waterResult = await _showWaterDialog();
        if (waterResult != null) _addWater(waterResult.$1, waterResult.$2);
        break;
    }
  }

@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final session = context.watch<WorkoutSessionManager>(); // ⬅️ Reagiert auf Änderungen

  return Scaffold(
    appBar: _buildAppBar(context, l10n),
    drawer: _buildDrawer(context, l10n),
    body: Stack(
      children: [
        if (!_isLoading || _nutritionData != null)
          RefreshIndicator(
            onRefresh: _loadAllHomeScreenData,
            child: ListView(
              children: [
                _buildBannerCard(l10n),
                GestureDetector(
                    onTap: _navigateToNutritionScreen,
                    child: _buildNutritionCard(l10n)),
                if (_weightChartData.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (context) =>
                                const MeasurementsScreen()))
                        .then((_) => _loadAllHomeScreenData()),
                    child: _buildWeightChartCard(context),
                  ),
                _buildWorkoutStatsCard(l10n), // ⬅️ NEU HIER
              ],
            ),
          ),
        if (_isLoading)
          (_nutritionData == null)
              ? const Center(child: CircularProgressIndicator())
              : Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddMenu,
      child: const Icon(Icons.add),
    ),
bottomNavigationBar: context.watch<WorkoutSessionManager>().isActive
    ? Container(
        color: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ⬅️ Nur Dauer anzeigen
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  "${context.watch<WorkoutSessionManager>().workoutLog?.startTime != null
                      ? DateTime.now().difference(context.watch<WorkoutSessionManager>().workoutLog!.startTime).inMinutes
                      : 0} min",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),

            // ⬅️ Buttons: Weiter + Verwerfen
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red.shade600,
                  ),
                  onPressed: () async {
                    final logId = context.read<WorkoutSessionManager>().workoutLog?.id;
                    if (logId != null) {
                      await WorkoutDatabaseHelper.instance.deleteWorkoutLog(logId);
                    }
                    context.read<WorkoutSessionManager>().finishWorkout();
                  },
                  child: Text(l10n.discardButton),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green.shade600,
                  ),
                  onPressed: () {
                    final log = context.read<WorkoutSessionManager>().workoutLog!;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LiveWorkoutScreen(
                        routine: null,
                        workoutLog: log,
                      ),
                    ));
                  },
                  child: Text(l10n.continueButton),
                ),
              ],
            ),
          ],
        ),
      )
    : null,

  );
}

/// Hilfsmethode für die Anzeige der Workout-Dauer
String _formatDuration(WorkoutSessionManager session) {
  if (session.workoutLog == null) return "";
  final duration = DateTime.now().difference(session.workoutLog!.startTime);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return "${minutes}m ${seconds}s";
}


  AppBar _buildAppBar(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 2,
      title: Text(
        l10n.appTitle,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle, size: 32),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen())).then((_) => _loadAllHomeScreenData());
          },
        ),
      ],
    );
  }

  Drawer _buildDrawer(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.primary),
              child: Text(l10n.drawerMenuTitle, style: TextStyle(color: colorScheme.onPrimary, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(l10n.drawerDashboard),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.food_bank),
              title: Text(l10n.drawerFoodExplorer),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const FoodExplorerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: Text(l10n.drawerMeasurements),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MeasurementsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.import_export),
              title: Text(l10n.drawerDataManagement),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DataManagementScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text("Übungskatalog"), // TODO: Lokalisieren
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ExerciseCatalogScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_rounded),
              title: Text(l10n.workoutRoutinesTitle), // Benutze den lokalisierten Titel
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RoutinesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history), // Separater Eintrag für den Verlauf
              title: Text(l10n.workoutHistoryButton),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WorkoutHistoryScreen()));
              },
            ),
          ],
        ),
      );
  }

  Widget _buildBannerCard(AppLocalizations l10n) {
    return SummaryCard(
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.center,
        child: Text(
          _recommendationText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant, 
            fontSize: 22, 
            fontWeight: FontWeight.w500
          ),
        ),
      ),
    );
  }
  
  Widget _buildNutritionCard(AppLocalizations l10n) {
    return _nutritionData == null
        ? const SizedBox.shrink()
        : NutritionSummaryWidget(nutritionData: _nutritionData!, l10n: l10n);
  }
  

// ERSETZE _showWaterDialog
Future<(int, DateTime)?> _showWaterDialog() async {
  final GlobalKey<WaterDialogContentState> dialogStateKey = GlobalKey<WaterDialogContentState>(); // KORREKTUR: Öffentlichen State verwenden
  return showDialog<(int, DateTime)>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Flüssigkeit hinzufügen"),
        content: WaterDialogContent(key: dialogStateKey), // KORREKTUR: Öffentliches Widget verwenden
        actions: [
          TextButton(child: const Text("Abbrechen"), onPressed: () => Navigator.of(context).pop(null)),
          FilledButton(child: const Text("Hinzufügen"), onPressed: () {
              final state = dialogStateKey.currentState;
              if (state != null) {
                final quantity = int.tryParse(state.quantityText);
                if (quantity != null && quantity > 0) {
                  Navigator.of(context).pop((quantity, state.selectedDateTime));
                }
              }
            },
          ),
        ],
      );
    },
  );
}

// ERSETZE _showQuantityDialog
Future<(int, DateTime, bool, String)?> _showQuantityDialog(FoodItem item) async {
  final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey<QuantityDialogContentState>(); // KORREKTUR: Öffentlichen State verwenden
  return showDialog<(int, DateTime, bool, String)?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: QuantityDialogContent(key: dialogStateKey, item: item), // Aufruf war hier schon korrekt
        actions: [
          TextButton(child: const Text("Abbrechen"), onPressed: () => Navigator.of(context).pop(null)),
          FilledButton(child: const Text("Hinzufügen"), onPressed: () {
              final state = dialogStateKey.currentState;
              if (state != null) {
                final quantity = int.tryParse(state.quantityText);
                if (quantity != null && quantity > 0) {
                  Navigator.of(context).pop((quantity, state.selectedDateTime, state.countAsWater, state.selectedMealType));
                }
              }
            },
          ),
        ],
      );
    },
  );
}
  Widget _buildLastWorkoutCard(BuildContext context, WorkoutLog log) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.lastWorkoutTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fitness_center),
              title: Text(log.routineName ?? l10n.freeWorkoutTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat.yMMMMd(locale).format(log.startTime)),
              trailing: ElevatedButton(
                onPressed: () => _repeatWorkout(log),
                child: Text(l10n.repeatButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChartCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Gewichtsverlauf", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _navigateTimeRange(false), splashRadius: 20),
                    Text("${DateFormat.MMMd().format(_currentDateRange.start)} - ${DateFormat.MMMd().format(_currentDateRange.end)}", style: Theme.of(context).textTheme.bodySmall),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _navigateTimeRange(true), splashRadius: 20),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) _navigateTimeRange(false);
                if (details.primaryVelocity! < 0) _navigateTimeRange(true);
              },
              child: MeasurementChartWidget(
                dataPoints: _weightChartData,
                lineColor: colorScheme.secondary,
                unit: "kg",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutStatsCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workoutStatsTitle, // z. B. „Training (7 Tage)“
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
                    Text(l10n.workoutsLabel, style: const TextStyle(fontSize: 12)),
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
                    Text(l10n.durationLabel, style: const TextStyle(fontSize: 12)),
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
                    Text(l10n.volumeLabel, style: const TextStyle(fontSize: 12)),
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
