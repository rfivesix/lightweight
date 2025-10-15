import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/dialogs/fluid_dialog_content.dart';
import 'package:lightweight/dialogs/quantity_dialog_content.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/daily_nutrition.dart';
import 'package:lightweight/models/fluid_entry.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/models/supplement_log.dart';
import 'package:lightweight/models/tracked_food_item.dart';
import 'package:lightweight/screens/add_food_screen.dart';
import 'package:lightweight/screens/food_detail_screen.dart';
import 'package:lightweight/screens/supplement_track_screen.dart';
import 'package:lightweight/util/date_util.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/bottom_content_spacer.dart';
import 'package:lightweight/widgets/glass_bottom_menu.dart';
import 'package:lightweight/widgets/measurement_chart_widget.dart';
import 'package:lightweight/widgets/nutrition_summary_widget.dart';
import 'package:lightweight/widgets/supplement_summary_widget.dart';
import 'package:lightweight/widgets/swipe_action_background.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracked_supplement.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/screens/workout_history_screen.dart';
import 'package:lightweight/widgets/todays_workout_summary_card.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => DiaryScreenState();
}

class DiaryScreenState extends State<DiaryScreen> {
  bool _isLoading = true;
  final ValueNotifier<DateTime> selectedDateNotifier = ValueNotifier(
    DateTime.now(),
  );
  DateTime get _selectedDate => selectedDateNotifier.value;
  DailyNutrition? _dailyNutrition;
  Map<String, List<TrackedFoodItem>> _entriesByMeal = {};
  List<FluidEntry> _fluidEntries = [];
  List<TrackedSupplement> _trackedSupplements = [];

  // NEUE STATE-VARIABLE
  Map<String, dynamic>? _workoutSummary;

  String _selectedChartRangeKey = '30D';
  final Map<String, bool> _mealExpanded = {
    "mealtypeBreakfast": false,
    "mealtypeLunch": false,
    "mealtypeDinner": false,
    "mealtypeSnack": false,
    "fluids": false,
  };

  @override
  void initState() {
    super.initState();
    loadDataForDate(_selectedDate);
  }

  @override
  void dispose() {
    selectedDateNotifier.dispose();
    super.dispose();
  }

  // lib/screens/diary_screen.dart

  // ... (Rest der Datei bleibt unverändert)

  // ERSETZEN SIE DIESE METHODE
  Future<void> loadDataForDate(DateTime date) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final targetCalories = prefs.getInt('targetCalories') ?? 2500;
    final targetProtein = prefs.getInt('targetProtein') ?? 180;
    final targetCarbs = prefs.getInt('targetCarbs') ?? 250;
    final targetFat = prefs.getInt('targetFat') ?? 80;
    final targetWater = prefs.getInt('targetWater') ?? 3000;
    final targetCaffeine = prefs.getInt('targetCaffeine') ?? 400;

    final foodEntries = await DatabaseHelper.instance.getEntriesForDate(date);
    final fluidEntries = await DatabaseHelper.instance.getFluidEntriesForDate(
      date,
    );
    final waterIntake = fluidEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.quantityInMl,
    );

    final summary = DailyNutrition(
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
      targetWater: targetWater,
      targetCaffeine: targetCaffeine,
    );
    summary.water = waterIntake;

    for (final entry in fluidEntries) {
      summary.calories += entry.kcal ?? 0;
      final factor = entry.quantityInMl / 100.0;
      summary.sugar += (entry.sugarPer100ml ?? 0) * factor;
      summary.carbs += ((entry.carbsPer100ml ?? 0) * factor).round();
    }

    final Map<String, List<TrackedFoodItem>> groupedEntries = {
      'mealtypeBreakfast': [],
      'mealtypeLunch': [],
      'mealtypeDinner': [],
      'mealtypeSnack': [],
    };

    for (final entry in foodEntries) {
      final foodItem = await ProductDatabaseHelper.instance.getProductByBarcode(
        entry.barcode,
      );
      if (foodItem != null) {
        summary.calories +=
            (foodItem.calories / 100 * entry.quantityInGrams).round();
        summary.protein +=
            (foodItem.protein / 100 * entry.quantityInGrams).round();
        summary.carbs += (foodItem.carbs / 100 * entry.quantityInGrams).round();
        summary.fat += (foodItem.fat / 100 * entry.quantityInGrams).round();

        final trackedItem = TrackedFoodItem(entry: entry, item: foodItem);
        groupedEntries[entry.mealType]?.add(trackedItem);
      }
    }

    for (var meal in groupedEntries.values) {
      meal.sort((a, b) => b.entry.timestamp.compareTo(a.entry.timestamp));
    }

    final allSupplements = await DatabaseHelper.instance.getAllSupplements();
    final todaysSupplementLogs =
        await DatabaseHelper.instance.getSupplementLogsForDate(date);

    final Map<int, double> todaysDoses = {};
    for (final log in todaysSupplementLogs) {
      todaysDoses.update(
        log.supplementId,
        (value) => value + log.dose,
        ifAbsent: () => log.dose,
      );
    }

    Supplement? caffeineSupplement;
    try {
      caffeineSupplement = allSupplements.firstWhere(
        (s) => s.code == 'caffeine',
      );
    } catch (e) {
      caffeineSupplement = null;
    }

    if (caffeineSupplement != null && caffeineSupplement.id != null) {
      summary.caffeine = todaysDoses[caffeineSupplement.id] ?? 0.0;
    }

    final trackedSupps = allSupplements
        .map(
          (s) => TrackedSupplement(
            supplement: s,
            totalDosedToday: todaysDoses[s.id] ?? 0.0,
          ),
        )
        .toList();

    final workoutLogs = await WorkoutDatabaseHelper.instance
        .getWorkoutLogsForDateRange(date, date);
    final completedLogs =
        workoutLogs.where((log) => log.endTime != null).toList();
    Map<String, dynamic>? workoutSummary;

    if (completedLogs.isNotEmpty) {
      // --- KORREKTUR START ---
      Duration totalDuration = Duration.zero;
      double totalVolume = 0.0;
      int totalSets = 0;

      for (final log in completedLogs) {
        totalDuration +=
            log.endTime!.difference(log.startTime); // Addiert die volle Dauer
        totalSets += log.sets.length;
        for (final set in log.sets) {
          totalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
        }
      }

      workoutSummary = {
        'duration': totalDuration, // Verwendet die korrekte Summe
        'volume': totalVolume,
        'sets': totalSets,
        'count': completedLogs.length,
      };
      // --- KORREKTUR ENDE ---
    }

    if (mounted) {
      setState(() {
        selectedDateNotifier.value = date;
        _dailyNutrition = summary;
        _entriesByMeal = groupedEntries;
        _fluidEntries = fluidEntries;
        _trackedSupplements = trackedSupps;
        _workoutSummary = workoutSummary;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFoodEntry(int id) async {
    await DatabaseHelper.instance.deleteFoodEntry(id);
    loadDataForDate(_selectedDate);
  }

  Future<void> _deleteFluidEntry(int id) async {
    await DatabaseHelper.instance.deleteFluidEntry(id);
    loadDataForDate(_selectedDate);
  }

  Future<void> _editFoodEntry(TrackedFoodItem trackedItem) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

    final result = await showDialog<(int, DateTime, String, double?)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            trackedItem.item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          content: QuantityDialogContent(
            key: dialogStateKey,
            item: trackedItem.item,
            initialQuantity: trackedItem.entry.quantityInGrams,
            initialTimestamp: trackedItem.entry.timestamp,
            initialMealType: trackedItem.entry.mealType,
          ),
          actions: [
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: Text(l10n.save),
              onPressed: () {
                final state = dialogStateKey.currentState;
                if (state != null) {
                  final quantity = int.tryParse(state.quantityText);
                  final caffeine = double.tryParse(
                    state.caffeineText.replaceAll(',', '.'),
                  );
                  if (quantity != null && quantity > 0) {
                    Navigator.of(context).pop((
                      quantity,
                      state.selectedDateTime,
                      state.selectedMealType,
                      caffeine,
                    ));
                  }
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      final updatedEntry = FoodEntry(
        id: trackedItem.entry.id,
        barcode: trackedItem.item.barcode,
        quantityInGrams: result.$1,
        timestamp: result.$2,
        mealType: result.$3,
      );
      await DatabaseHelper.instance.updateFoodEntry(updatedEntry);
      loadDataForDate(_selectedDate);
    }
  }

  Future<void> _addFoodToMeal(String mealType) async {
    final FoodItem? selectedFoodItem =
        await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(builder: (context) => const AddFoodScreen()),
    );

    if (selectedFoodItem == null || !mounted) return;

    final result = await _showQuantityMenu(selectedFoodItem, mealType);
    if (result == null || !mounted) return;

    final int quantity = result.quantity;
    final DateTime timestamp = result.timestamp;
    final String resultMealType = result.mealType;
    final bool isLiquid = result.isLiquid;
    final double? caffeinePer100 = result.caffeinePer100ml;

    // 1. Immer den FoodEntry mit allen Nährwerten speichern
    final newFoodEntry = FoodEntry(
      barcode: selectedFoodItem.barcode,
      timestamp: timestamp,
      quantityInGrams: quantity,
      mealType: resultMealType,
    );
    final newFoodEntryId = await DatabaseHelper.instance.insertFoodEntry(
      newFoodEntry,
    );

    // 2. Wenn es eine Flüssigkeit ist, ZUSÄTZLICH einen FluidEntry NUR FÜR WASSER erstellen
    if (isLiquid) {
      final newFluidEntry = FluidEntry(
        timestamp: timestamp,
        quantityInMl: quantity,
        name: selectedFoodItem.name,
        kcal: null,
        sugarPer100ml: null,
        carbsPer100ml: null,
        caffeinePer100ml: null,
        linked_food_entry_id: newFoodEntryId,
      );
      await DatabaseHelper.instance.insertFluidEntry(newFluidEntry);
    }

    // 3. Koffein nur loggen, wenn als Flüssigkeit deklariert
    if (isLiquid && caffeinePer100 != null && caffeinePer100 > 0) {
      final totalCaffeine = (caffeinePer100 / 100.0) * quantity;
      await _logCaffeineDose(
        totalCaffeine,
        timestamp,
        foodEntryId: newFoodEntryId,
      );
    }

    loadDataForDate(_selectedDate);
  }

  // FÜGEN SIE DIESE ZWEI NEUEN METHODEN ZUR KLASSE HINZU
  Future<
      ({
        int quantity,
        DateTime timestamp,
        String mealType,
        bool isLiquid,
        double? sugarPer100ml,
        double? caffeinePer100ml,
      })?> _showQuantityMenu(FoodItem item, String mealType) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

    return showGlassBottomMenu<
        ({
          int quantity,
          DateTime timestamp,
          String mealType,
          bool isLiquid,
          double? sugarPer100ml,
          double? caffeinePer100ml,
        })>(
      context: context,
      title: item.name,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuantityDialogContent(
              key: dialogStateKey,
              item: item,
              initialMealType: mealType, // WICHTIG: Mahlzeit vorauswählen
              initialTimestamp: _selectedDate,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(null);
                    },
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final state = dialogStateKey.currentState;
                      if (state != null) {
                        final quantity = int.tryParse(state.quantityText);
                        final sugar = double.tryParse(
                          state.sugarText.replaceAll(',', '.'),
                        );
                        final caffeine = double.tryParse(
                          state.caffeineText.replaceAll(',', '.'),
                        );

                        if (quantity != null && quantity > 0) {
                          close();
                          Navigator.of(ctx).pop((
                            quantity: quantity,
                            timestamp: state.selectedDateTime,
                            mealType: state.selectedMealType,
                            isLiquid: state.isLiquid,
                            sugarPer100ml: sugar,
                            caffeinePer100ml: caffeine,
                          ));
                        }
                      }
                    },
                    child: Text(l10n.add_button),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _logCaffeineDose(
    double doseMg,
    DateTime timestamp, {
    int? foodEntryId,
    int? fluidEntryId,
  }) async {
    if (doseMg <= 0) return;

    final supplements = await DatabaseHelper.instance.getAllSupplements();
    Supplement? caffeineSupplement;
    try {
      caffeineSupplement = supplements.firstWhere((s) => s.code == 'caffeine');
    } catch (e) {
      return;
    }

    if (caffeineSupplement.id == null) return;

    await DatabaseHelper.instance.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineSupplement.id!,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
        source_food_entry_id: foodEntryId,
        source_fluid_entry_id: fluidEntryId,
      ),
    );
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      // Erlaube Auswahl in der Zukunft, z.B. für Vorausplanung
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      loadDataForDate(picked);
    }
  }

  String _getAppBarTitle(AppLocalizations l10n) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));

    if (_selectedDate.isSameDate(today)) {
      return l10n.today;
    } else if (_selectedDate.isSameDate(yesterday)) {
      return l10n.yesterday; // ← NEW
    } else if (_selectedDate.isSameDate(dayBeforeYesterday)) {
      return l10n.dayBeforeYesterday; // ← NEW
    } else {
      return DateFormat.yMMMMd(
        Localizations.localeOf(context).toString(),
      ).format(_selectedDate);
    }
  }

  void navigateDay(bool forward) {
    final newDay = _selectedDate.add(Duration(days: forward ? 1 : -1));
    // Im Gegensatz zum NutritionScreen erlauben wir hier die Navigation in die Zukunft
    // if (forward && newDay.isAfter(DateTime.now())) return;

    loadDataForDate(newDay);
  }

  Widget _buildWeightChartCard(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.weightHistoryTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8.0,
                      alignment: WrapAlignment.end,
                      children: [
                        '30D',
                        '90D',
                        'All',
                      ].map((key) => _buildFilterButton(key, key)).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingL),
            MeasurementChartWidget(
              chartType: 'weight',
              dateRange: _calculateDateRange(),
              unit: "kg",
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
        // Chart wird durch setState im MeasurementChartWidget neu geladen
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  DateTimeRange _calculateDateRange() {
    final now = DateTime.now();
    DateTime start;
    switch (_selectedChartRangeKey) {
      case '90D':
        start = now.subtract(const Duration(days: 89));
        break;
      case 'All':
        // Für "Alle" setzen wir ein sehr frühes Datum,
        // der Chart wird die Daten entsprechend laden
        start = DateTime(2020);
        break;
      case '30D':
      default:
        start = now.subtract(const Duration(days: 29));
    }
    return DateTimeRange(start: start, end: now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasEntries = _entriesByMeal.values.any((list) => list.isNotEmpty);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => loadDataForDate(_selectedDate),
              child: ListView(
                padding: DesignConstants.cardPadding,
                children: [
                  const SizedBox(height: DesignConstants.spacingL),
                  _buildSectionTitle(context, l10n.today_overview_text),
                  if (_dailyNutrition != null)
                    NutritionSummaryWidget(
                      nutritionData: _dailyNutrition!,
                      l10n: l10n,
                      isExpandedView: false,
                    ),

                  const SizedBox(height: DesignConstants.spacingXS),
                  SupplementSummaryWidget(
                    trackedSupplements: _trackedSupplements,
                    onTap: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => const SupplementTrackScreen(),
                          ),
                        )
                        .then((_) => loadDataForDate(_selectedDate)),
                  ),
                  // NEUER TEIL: Workout-Zusammenfassung hier einfügen
                  if (_workoutSummary != null) ...[
                    //const SizedBox(height: DesignConstants.spacingXS),
                    TodaysWorkoutSummaryCard(
                      duration: _workoutSummary!['duration'] as Duration,
                      volume: _workoutSummary!['volume'] as double,
                      sets: _workoutSummary!['sets'] as int,
                      workoutCount: _workoutSummary!['count'] as int,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const WorkoutHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(context, l10n.protocol_today_capslock),
                  _buildTodaysLog(l10n),
                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(context, l10n.measurementWeightCapslock),
                  _buildWeightChartCard(
                    context,
                    Theme.of(context).colorScheme,
                    l10n,
                  ),
                  const BottomContentSpacer(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildMealCard(
    String title,
    String mealKey,
    List<TrackedFoodItem> items,
    _MealMacros macros,
    AppLocalizations l10n,
  ) {
    final isOpen = _mealExpanded[mealKey] ?? false;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge; // Inter, fett wie im Rest

    return SummaryCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Tippen toggelt)
          InkWell(
            onTap: () => setState(() {
              _mealExpanded[mealKey] = !isOpen;
            }),
            child: Row(
              children: [
                Expanded(child: Text(title, style: titleStyle)),
                Icon(isOpen ? Icons.expand_less : Icons.expand_more),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: theme.colorScheme.primary,
                  onPressed: () => _addFoodToMeal(mealKey),
                  tooltip: l10n.addFoodOption,
                ),
              ],
            ),
          ),

          // <<< NEU: Makro-Zeile unter dem Titel (eigene Zeile, linksbündig)
          if (items.isNotEmpty) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${macros.calories} kcal · '
                '${macros.protein}g P · '
                '${macros.carbs}g C · '
                '${macros.fat}g F',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Inhalt (animiert ein-/ausklappen)
          AnimatedCrossFade(
            crossFadeState:
                isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 180),
            firstChild: Column(
              children: [
                if (items.isNotEmpty) const Divider(height: 16),
                ...items.map((item) => _buildFoodEntryTile(l10n, item)),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
// lib/screens/diary_screen.dart

  Future<void> _showAddFluidMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final key = GlobalKey<FluidDialogContentState>();
    await showGlassBottomMenu(
      context: context,
      title: l10n.add_liquid_title,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FluidDialogContent(key: key),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: close,
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final state = key.currentState;
                      if (state == null) return;
                      final quantity = int.tryParse(state.quantityText);
                      if (quantity == null || quantity <= 0) return;

                      final name = state.nameText;
                      final sugarPer100ml = double.tryParse(
                        state.sugarText.replaceAll(',', '.'),
                      );
                      final caffeinePer100ml = double.tryParse(
                        state.caffeineText.replaceAll(',', '.'),
                      );
                      final kcal = (sugarPer100ml != null)
                          ? ((sugarPer100ml / 100) * quantity * 4).round()
                          : null;

                      final newEntry = FluidEntry(
                        timestamp: state.selectedDateTime,
                        quantityInMl: quantity,
                        name: name,
                        kcal: kcal,
                        sugarPer100ml: sugarPer100ml,
                        carbsPer100ml: sugarPer100ml,
                        caffeinePer100ml: caffeinePer100ml,
                      );

                      final newId = await DatabaseHelper.instance
                          .insertFluidEntry(newEntry);

                      if (caffeinePer100ml != null && caffeinePer100ml > 0) {
                        final totalCaffeine =
                            (caffeinePer100ml / 100.0) * quantity;
                        await _logCaffeineDose(
                          totalCaffeine,
                          state.selectedDateTime,
                          fluidEntryId: newId,
                        );
                      }

                      close();
                      loadDataForDate(_selectedDate);
                    },
                    child: Text(l10n.add_button),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodaysLog(AppLocalizations l10n) {
    const mealOrder = [
      "fluids", // AN ERSTER STELLE
      "mealtypeBreakfast",
      "mealtypeLunch",
      "mealtypeDinner",
      "mealtypeSnack",
    ];

    return Column(
      children: [
        ...mealOrder.map((mealKey) {
          if (mealKey == "fluids") {
            return _buildFluidsCard(l10n);
          }

          final entries = _entriesByMeal[mealKey] ?? [];
          final mealMacros = _MealMacros();
          for (var item in entries) {
            final factor = item.entry.quantityInGrams / 100.0;
            mealMacros.calories += (item.item.calories * factor).round();
            mealMacros.protein += (item.item.protein * factor).round();
            mealMacros.carbs += (item.item.carbs * factor).round();
            mealMacros.fat += (item.item.fat * factor).round();
          }

          return _buildMealCard(
            _getLocalizedMealName(l10n, mealKey),
            mealKey,
            entries,
            mealMacros,
            l10n,
          );
        }),
      ],
    );
  }

  Widget _buildFluidsCard(AppLocalizations l10n) {
    final isOpen = _mealExpanded['fluids'] ?? false;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge;

    return SummaryCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() {
              _mealExpanded['fluids'] = !isOpen;
            }),
            child: Row(
              children: [
                Icon(Icons.local_drink_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.waterHeader, style: titleStyle)),
                Icon(isOpen ? Icons.expand_less : Icons.expand_more),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: theme.colorScheme.primary,
                  onPressed: _showAddFluidMenu,
                  tooltip: l10n.addLiquidOption,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            crossFadeState:
                isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 180),
            firstChild: Column(
              children: [
                if (_fluidEntries.isNotEmpty) const Divider(height: 16),
                ..._fluidEntries.map(
                  (entry) => _buildFluidEntryTile(l10n, entry),
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFluidEntryTile(AppLocalizations l10n, FluidEntry entry) {
    final totalSugar = (entry.sugarPer100ml != null)
        ? (entry.sugarPer100ml! / 100 * entry.quantityInMl).toStringAsFixed(1)
        : '0';
    final totalCaffeine = (entry.caffeinePer100ml != null)
        ? (entry.caffeinePer100ml! / 100 * entry.quantityInMl).toStringAsFixed(
            1,
          )
        : '0';

    return Dismissible(
      key: Key('fluid_entry_${entry.id}'),
      background: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(l10n.deleteConfirmTitle),
                  content: Text(l10n.deleteConfirmContent),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.delete),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (direction) {
        _deleteFluidEntry(entry.id!);
      },
      child: SummaryCard(
        child: ListTile(
          title: Text(entry.name),
          subtitle: Text(
            "${entry.quantityInMl}ml · Sugar: ${totalSugar}g · Caffeine: ${totalCaffeine}mg",
          ),
          trailing: Text("${entry.kcal ?? 0} kcal"),
        ),
      ),
    );
  }

  Widget _buildMacroText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFoodEntryTile(
    AppLocalizations l10n,
    TrackedFoodItem trackedItem,
  ) {
    return Dismissible(
      key: Key('food_hub_entry_${trackedItem.entry.id}'),
      background: const SwipeActionBackground(
        color: Colors.blueAccent,
        icon: Icons.edit,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editFoodEntry(trackedItem);
          return false;
        } else {
          return await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(l10n.deleteConfirmTitle),
                    content: Text(l10n.deleteConfirmContent),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.delete),
                      ),
                    ],
                  );
                },
              ) ??
              false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteFoodEntry(trackedItem.entry.id!);
        }
      },
      child: SummaryCard(
        child: ListTile(
          title: Text(trackedItem.item.name),
          subtitle: Text("${trackedItem.entry.quantityInGrams}g"),
          trailing: Text("${trackedItem.calculatedCalories} kcal"),
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) =>
                        FoodDetailScreen(trackedItem: trackedItem),
                  ),
                )
                .then((_) => loadDataForDate(_selectedDate));
          },
        ),
      ),
    );
  }

  Widget _buildEmptyLogState(AppLocalizations l10n) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          l10n.noEntriesForPeriod,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  String _getLocalizedMealName(AppLocalizations l10n, String key) {
    switch (key) {
      case "mealtypeBreakfast":
        return l10n.mealtypeBreakfast;
      case "mealtypeLunch":
        return l10n.mealtypeLunch;
      case "mealtypeDinner":
        return l10n.mealtypeDinner;
      case "mealtypeSnack":
        return l10n.mealtypeSnack;
      default:
        return key;
    }
  }
}

class _MealMacros {
  int calories = 0;
  int protein = 0;
  int carbs = 0;
  int fat = 0;
}

class DiaryAppBar extends StatelessWidget {
  final ValueNotifier<DateTime>? selectedDateNotifier;
  const DiaryAppBar({super.key, required this.selectedDateNotifier});

  String _getAppBarTitle(
    BuildContext context,
    AppLocalizations l10n,
    DateTime selectedDate,
  ) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));

    if (selectedDate.isSameDate(today)) {
      return l10n.today;
    } else if (selectedDate.isSameDate(yesterday)) {
      return l10n.yesterday; // ← NEW
    } else if (selectedDate.isSameDate(dayBeforeYesterday)) {
      return l10n.dayBeforeYesterday; // ← NEW
    } else {
      return DateFormat.yMMMMd(
        Localizations.localeOf(context).toString(),
      ).format(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Gracefully handle the case where the notifier might be null during the first frame
    if (selectedDateNotifier == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          l10n.today, // Default to 'Today'
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      );
    }

    return ValueListenableBuilder<DateTime>(
      valueListenable: selectedDateNotifier!,
      builder: (context, selectedDate, child) {
        final title = _getAppBarTitle(context, l10n, selectedDate);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        );
      },
    );
  }
}
