import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/dialogs/quantity_dialog_content.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/daily_nutrition.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/supplement_log.dart';
import 'package:lightweight/models/tracked_food_item.dart';
import 'package:lightweight/screens/add_food_screen.dart';
import 'package:lightweight/screens/create_food_screen.dart';
import 'package:lightweight/screens/food_detail_screen.dart';
import 'package:lightweight/screens/scanner_screen.dart';
import 'package:lightweight/screens/supplement_hub_screen.dart';
import 'package:lightweight/util/date_util.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/measurement_chart_widget.dart';
import 'package:lightweight/widgets/nutrition_summary_widget.dart';
import 'package:lightweight/widgets/supplement_summary_widget.dart';
import 'package:lightweight/widgets/swipe_action_background.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => DiaryScreenState();
}

class DiaryScreenState extends State<DiaryScreen> {
  bool _isLoading = true;
  final ValueNotifier<DateTime> selectedDateNotifier =
      ValueNotifier(DateTime.now());
  DateTime get _selectedDate => selectedDateNotifier.value;
  DailyNutrition? _dailyNutrition;
  Map<String, List<TrackedFoodItem>> _entriesByMeal = {};
  List<TrackedSupplement> _trackedSupplements = [];
  String _selectedChartRangeKey = '30D';

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

  Future<void> loadDataForDate(DateTime date) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final targetCalories = prefs.getInt('targetCalories') ?? 2500;
    final targetProtein = prefs.getInt('targetProtein') ?? 180;
    final targetCarbs = prefs.getInt('targetCarbs') ?? 250;
    final targetFat = prefs.getInt('targetFat') ?? 80;
    final targetWater = prefs.getInt('targetWater') ?? 3000;

    final foodEntries = await DatabaseHelper.instance.getEntriesForDate(date);
    final waterIntake = await DatabaseHelper.instance.getWaterForDate(date);

    final summary = DailyNutrition(
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
      targetWater: targetWater,
    );
    summary.water = waterIntake;

    final Map<String, List<TrackedFoodItem>> groupedEntries = {
      'mealtypeBreakfast': [],
      'mealtypeLunch': [],
      'mealtypeDinner': [],
      'mealtypeSnack': []
    };

    for (final entry in foodEntries) {
      final foodItem = await ProductDatabaseHelper.instance
          .getProductByBarcode(entry.barcode);
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
      todaysDoses.update(log.supplementId, (value) => value + log.dose,
          ifAbsent: () => log.dose);
    }

    final trackedSupps = allSupplements
        .map((s) => TrackedSupplement(
              supplement: s,
              totalDosedToday: todaysDoses[s.id] ?? 0.0,
            ))
        .toList();

    if (mounted) {
      setState(() {
        selectedDateNotifier.value = date;
        _dailyNutrition = summary;
        _entriesByMeal = groupedEntries;
        _trackedSupplements = trackedSupps;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFoodEntry(int id) async {
    await DatabaseHelper.instance.deleteFoodEntry(id);
    loadDataForDate(_selectedDate);
  }

  Future<void> _editFoodEntry(TrackedFoodItem trackedItem) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

    final result = await showDialog<(int, DateTime, bool, String, double?)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(trackedItem.item.name,
              maxLines: 2, overflow: TextOverflow.ellipsis),
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
                onPressed: () => Navigator.of(context).pop()),
            FilledButton(
                child: Text(l10n.save),
                onPressed: () {
                  final state = dialogStateKey.currentState;
                  if (state != null) {
                    final quantity = int.tryParse(state.quantityText);
                    final caffeine = double.tryParse(
                        state.caffeineText.replaceAll(',', '.'));
                    if (quantity != null && quantity > 0) {
                      Navigator.of(context).pop((
                        quantity,
                        state.selectedDateTime,
                        state.countAsWater,
                        state.selectedMealType,
                        caffeine
                      ));
                    }
                  }
                }),
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
        mealType: result.$4,
      );
      await DatabaseHelper.instance.updateFoodEntry(updatedEntry);
      loadDataForDate(_selectedDate);
    }
  }

  Future<void> _addFoodToMeal(String mealType) async {
    final FoodItem? selectedFoodItem = await Navigator.of(context)
        .push<FoodItem>(
            MaterialPageRoute(builder: (context) => const AddFoodScreen()));

    if (selectedFoodItem != null && mounted) {
      final l10n = AppLocalizations.of(context)!;
      final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

      final result = await showDialog<(int, DateTime, bool, String, double?)?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(selectedFoodItem.name,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            content: QuantityDialogContent(
              key: dialogStateKey,
              item: selectedFoodItem,
              initialMealType: mealType, // Pre-select the meal type
              initialTimestamp:
                  _selectedDate, // KORREKTUR: Das ausgewählte Datum übergeben
            ),
            actions: [
              TextButton(
                  child: Text(l10n.cancel),
                  onPressed: () => Navigator.of(context).pop(null)),
              FilledButton(
                child: Text(l10n.add_button),
                onPressed: () {
                  final state = dialogStateKey.currentState;
                  if (state != null) {
                    final quantity = int.tryParse(state.quantityText);
                    final caffeine = double.tryParse(
                        state.caffeineText.replaceAll(',', '.'));
                    if (quantity != null && quantity > 0) {
                      Navigator.of(context).pop((
                        quantity,
                        state.selectedDateTime,
                        state.countAsWater,
                        state.selectedMealType,
                        caffeine
                      ));
                    }
                  }
                },
              ),
            ],
          );
        },
      );

      if (result != null && mounted) {
        final newEntry = FoodEntry(
            barcode: selectedFoodItem.barcode,
            timestamp: result.$2,
            quantityInGrams: result.$1,
            mealType: result.$4);
        await DatabaseHelper.instance.insertFoodEntry(newEntry);

        if (result.$3) {
          await DatabaseHelper.instance.insertWaterEntry(result.$1, result.$2);
        }

        final caffeineDose = result.$5;
        if (caffeineDose != null && caffeineDose > 0) {
          final supplements = await DatabaseHelper.instance.getAllSupplements();
          final caffeineSupplement =
              supplements.firstWhere((s) => s.name.toLowerCase() == 'caffeine');
          final log = SupplementLog(
              supplementId: caffeineSupplement.id!,
              dose: caffeineDose,
              unit: 'mg',
              timestamp: result.$2);
          await DatabaseHelper.instance.insertSupplementLog(log);
        }
        loadDataForDate(_selectedDate);
      }
    }
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
      return 'Gestern'; // TODO: l10n
    } else if (_selectedDate.isSameDate(dayBeforeYesterday)) {
      return 'Vorgestern'; // TODO: l10n
    } else {
      return DateFormat.yMMMMd(Localizations.localeOf(context).toString())
          .format(_selectedDate);
    }
  }

  void navigateDay(bool forward) {
    final newDay = _selectedDate.add(Duration(days: forward ? 1 : -1));
    // Im Gegensatz zum NutritionScreen erlauben wir hier die Navigation in die Zukunft
    // if (forward && newDay.isAfter(DateTime.now())) return;

    loadDataForDate(newDay);
  }

  Widget _buildWeightChartCard(
      BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.weightHistoryTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8.0,
                      alignment: WrapAlignment.end,
                      children: ['30D', '90D', 'All']
                          .map((key) => _buildFilterButton(key, key))
                          .toList(),
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
      // AppBar wird jetzt im MainScreen verwaltet
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => loadDataForDate(_selectedDate),
              child: ListView(
                padding: DesignConstants.cardPadding,
                children: [
                  // Die Datumsnavigation mit Pfeilen wurde in die AppBar verschoben
                  const SizedBox(height: DesignConstants.spacingL),
                  _buildSectionTitle(context, l10n.today_overview_text),
                  if (_dailyNutrition != null)
                    NutritionSummaryWidget(
                        nutritionData: _dailyNutrition!,
                        l10n: l10n,
                        isExpandedView: false),
                  const SizedBox(height: DesignConstants.spacingS),
                  SupplementSummaryWidget(
                    trackedSupplements: _trackedSupplements,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (context) => const SupplementHubScreen()))
                        .then((_) => loadDataForDate(_selectedDate)),
                  ),
                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(context, l10n.protocol_today_capslock),
                  _buildTodaysLog(l10n),
                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(context, l10n.measurementWeightCapslock),
                  _buildWeightChartCard(
                      context, Theme.of(context).colorScheme, l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTodaysLog(AppLocalizations l10n) {
    const mealOrder = [
      "mealtypeBreakfast",
      "mealtypeLunch",
      "mealtypeDinner",
      "mealtypeSnack"
    ];

    return Column(
      children: mealOrder.map((mealKey) {
        final entries = _entriesByMeal[mealKey] ?? [];
        // Calculate macros for this specific meal
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
      }).toList(),
    );
  }

  Widget _buildMealCard(
    String title,
    String mealKey,
    List<TrackedFoodItem> items,
    _MealMacros macros,
    AppLocalizations l10n,
  ) {
    return SummaryCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _addFoodToMeal(mealKey),
              ),
            ],
          ),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroText('${macros.calories} kcal'),
                  _buildMacroText('${macros.protein}g P'),
                  _buildMacroText('${macros.carbs}g C'),
                  _buildMacroText('${macros.fat}g F'),
                ],
              ),
            ),
          if (items.isNotEmpty) const Divider(height: 24),
          ...items.map((item) => _buildFoodEntryTile(l10n, item)),
        ],
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
      AppLocalizations l10n, TrackedFoodItem trackedItem) {
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
                          child: Text(l10n.cancel)),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.delete)),
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
                .push(MaterialPageRoute(
                    builder: (context) =>
                        FoodDetailScreen(trackedItem: trackedItem)))
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
      BuildContext context, AppLocalizations l10n, DateTime selectedDate) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));

    if (selectedDate.isSameDate(today)) {
      return l10n.today;
    } else if (selectedDate.isSameDate(yesterday)) {
      return 'Gestern'; // TODO: l10n
    } else if (selectedDate.isSameDate(dayBeforeYesterday)) {
      return 'Vorgestern'; // TODO: l10n
    } else {
      return DateFormat.yMMMMd(Localizations.localeOf(context).toString())
          .format(selectedDate);
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
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
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
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        );
      },
    );
  }
}
