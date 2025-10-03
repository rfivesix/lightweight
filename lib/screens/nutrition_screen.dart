// lib/screens/nutrition_screen.dart (Final & De-Materialisiert - Endgültige Korrektur)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/dialogs/water_dialog_content.dart';
import 'package:lightweight/models/water_entry.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/swipe_action_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/dialogs/quantity_dialog_content.dart';
import 'package:lightweight/models/daily_nutrition.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/tracked_food_item.dart';
import 'package:lightweight/models/timeline_entry.dart';
import 'package:lightweight/services/ui_state_service.dart';
import 'package:lightweight/widgets/nutrition_summary_widget.dart';
import 'package:lightweight/widgets/summary_card.dart';
import './food_detail_screen.dart';
import 'package:lightweight/util/date_util.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  DailyNutrition? _nutritionData;
  List<dynamic> _displayItems = [];
  bool _isLoading = true;
  DateTimeRange _selectedDateRange = DateTime.now().isSameDate(DateTime.now())
      ? DateTimeRange(
          start: DateTime.now(), end: DateTime.now()) // Einzeltag für heute
      : DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 6)),
          end: DateTime.now()); // Standard: Letzte 7 Tage
  bool _isSummaryExpanded = UiStateService.instance.isNutritionSummaryExpanded;
  String _selectedRangeKey = '1D';
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    _loadEntriesForDateRange(_selectedDateRange);
  }

  Future<void> _loadEntriesForDateRange(DateTimeRange range) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final targetCalories = prefs.getInt('targetCalories') ?? 2500;
    final targetProtein = prefs.getInt('targetProtein') ?? 180;
    final targetCarbs = prefs.getInt('targetCarbs') ?? 250;
    final targetFat = prefs.getInt('targetFat') ?? 80;
    final targetWater = prefs.getInt('targetWater') ?? 3000;
    final targetSugar = prefs.getInt('targetSugar') ?? 50;
    final targetFiber = prefs.getInt('targetFiber') ?? 30;
    final targetSalt = prefs.getInt('targetSalt') ?? 6;

    final foodEntries = await DatabaseHelper.instance
        .getEntriesForDateRange(range.start, range.end);
    final waterEntries = await DatabaseHelper.instance
        .getWaterEntriesForDateRange(range.start, range.end);

    final numberOfDays = range.duration.inDays + 1;
    final newNutritionSummary = DailyNutrition(
      // KORREKTUR: Neue Variable
      targetCalories: targetCalories * numberOfDays,
      targetProtein: targetProtein * numberOfDays,
      targetCarbs: targetCarbs * numberOfDays,
      targetFat: targetFat * numberOfDays,
      targetWater: targetWater * numberOfDays,
      targetSugar: targetSugar * numberOfDays,
      targetFiber: targetFiber * numberOfDays,
      targetSalt: targetSalt * numberOfDays,
    );

    final List<FoodTimelineEntry> foodTimeline = [];
    for (final entry in foodEntries) {
      final foodItem = await ProductDatabaseHelper.instance
          .getProductByBarcode(entry.barcode);
      if (foodItem != null) {
        newNutritionSummary.calories +=
            (foodItem.calories / 100 * entry.quantityInGrams).round();
        newNutritionSummary.protein +=
            (foodItem.protein / 100 * entry.quantityInGrams).round();
        newNutritionSummary.carbs +=
            (foodItem.carbs / 100 * entry.quantityInGrams).round();
        newNutritionSummary.fat +=
            (foodItem.fat / 100 * entry.quantityInGrams).round();
        newNutritionSummary.sugar +=
            (foodItem.sugar ?? 0) / 100 * entry.quantityInGrams;
        newNutritionSummary.fiber +=
            (foodItem.fiber ?? 0) / 100 * entry.quantityInGrams;
        newNutritionSummary.salt +=
            (foodItem.salt ?? 0) / 100 * entry.quantityInGrams;
        foodTimeline.add(
            FoodTimelineEntry(TrackedFoodItem(entry: entry, item: foodItem)));
      }
    }

    final waterTimeline =
        waterEntries.map((e) => WaterTimelineEntry(e)).toList();
    newNutritionSummary.water =
        waterEntries.fold(0, (sum, entry) => sum + entry.quantityInMl);

    final List<dynamic> finalDisplayList = [];

    if (range.duration.inDays == 0) {
      final Map<String, List<FoodTimelineEntry>> groupedFood = {};
      for (final entry in foodTimeline) {
        final mealType = entry.trackedItem.entry.mealType;
        if (groupedFood.containsKey(mealType)) {
          groupedFood[mealType]!.add(entry);
        } else {
          groupedFood[mealType] = [entry];
        }
      }

      const mealOrder = [
        "mealtypeBreakfast",
        "mealtypeLunch",
        "mealtypeDinner",
        "mealtypeSnack"
      ];
      for (final mealKey in mealOrder) {
        if (groupedFood.containsKey(mealKey)) {
          finalDisplayList.add(mealKey);
          groupedFood[mealKey]!
              .sort((a, b) => b.timestamp.compareTo(a.timestamp));
          finalDisplayList.addAll(groupedFood[mealKey]!);
        }
      }

      if (waterTimeline.isNotEmpty) {
        finalDisplayList.add("waterHeader");
        waterTimeline.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        finalDisplayList.addAll(waterTimeline);
      }
    } else {
      final List<TimelineEntry> combinedList = [
        ...foodTimeline,
        ...waterTimeline
      ];
      combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      DateTime? lastDate;
      for (final entry in combinedList) {
        final entryDate = entry.timestamp;
        if (lastDate == null || !entryDate.isSameDate(lastDate)) {
          finalDisplayList.add(entryDate);
          lastDate = entryDate;
        }
        finalDisplayList.add(entry);
      }
    }

    if (mounted) {
      setState(() {
        _nutritionData =
            newNutritionSummary; // KORREKTUR: Die Variable korrekt zuweisen
        _displayItems = finalDisplayList;
        _isLoading = false;
      });
    }
  }

  void _navigateDay(bool forward) {
    final currentDay = _selectedDateRange.start;
    final newDay = currentDay.add(Duration(days: forward ? 1 : -1));
    // Navigation über den heutigen Tag hinaus verhindern
    if (forward && newDay.isAfter(DateTime.now())) return;

    setState(() {
      _selectedDateRange = DateTimeRange(start: newDay, end: newDay);
      _selectedRangeKey = 'custom'; // De-selektiert die Filter-Chips
    });
    _loadEntriesForDateRange(_selectedDateRange);
  }

  Future<void> _setTimeRange(String key) async {
    setState(() => _selectedRangeKey = key);
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (key) {
      case '1W':
        start = now.subtract(const Duration(days: 6));
        break;
      case '1M':
        start = now.subtract(const Duration(days: 29));
        break;
      case 'All':
        final earliest =
            await DatabaseHelper.instance.getEarliestFoodEntryDate();
        start = earliest ?? now;
        break;
      case '1D':
      default:
        start = now;
    }

    final normalizedStart = DateTime(start.year, start.month, start.day);
    setState(() =>
        _selectedDateRange = DateTimeRange(start: normalizedStart, end: end));
    _loadEntriesForDateRange(_selectedDateRange);
  }

  Future<void> _deleteFoodEntry(int id) async {
    await DatabaseHelper.instance.deleteFoodEntry(id);
    _loadEntriesForDateRange(_selectedDateRange);
  }

  Future<void> _deleteWaterEntry(int id) async {
    await DatabaseHelper.instance.deleteWaterEntry(id);
    _loadEntriesForDateRange(_selectedDateRange);
  }

  Future<void> _editFoodEntry(TrackedFoodItem trackedItem) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

    final result = await showDialog<(int, DateTime, bool, String)?>(
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
                    if (quantity != null && quantity > 0) {
                      Navigator.of(context).pop((
                        quantity,
                        state.selectedDateTime,
                        state.countAsWater,
                        state.selectedMealType
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
      _loadEntriesForDateRange(_selectedDateRange);
    }
  }

  Future<void> _editWaterEntry(WaterEntry waterEntry) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<WaterDialogContentState> dialogStateKey = GlobalKey();

    final result = await showDialog<(int, DateTime)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.waterEntryTitle),
          content: WaterDialogContent(
            key: dialogStateKey,
            initialQuantity: waterEntry.quantityInMl,
            initialTimestamp: waterEntry.timestamp,
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
                    if (quantity != null && quantity > 0) {
                      Navigator.of(context)
                          .pop((quantity, state.selectedDateTime));
                    }
                  }
                }),
          ],
        );
      },
    );

    if (result != null) {
      final updatedEntry = WaterEntry(
        id: waterEntry.id,
        quantityInMl: result.$1,
        timestamp: result.$2,
      );
      await DatabaseHelper.instance.updateWaterEntry(updatedEntry);
      _loadEntriesForDateRange(_selectedDateRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();

    final rangeText = _selectedDateRange.duration.inDays == 0
        ? DateFormat.yMMMMd(locale).format(_selectedDateRange.start)
        : "${DateFormat.yMMMMd(locale).format(_selectedDateRange.start)} - ${DateFormat.yMMMMd(locale).format(_selectedDateRange.end)}";

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          l10n.nutritionScreenTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 0.0),
                    //padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //SizedBox(height: DesignConstants.spacingL), // <- DIESE ZEILE
                        //SizedBox(height: DesignConstants.spacingXL),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () => _navigateDay(false)),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDateRangePicker(
                                      context: context,
                                      initialDateRange: _selectedDateRange,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now());
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDateRange = picked;
                                      _selectedRangeKey = 'custom';
                                    });
                                    _loadEntriesForDateRange(picked);
                                  }
                                },
                                child: Text(
                                  rangeText,
                                  style: textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _selectedDateRange.end
                                        .isSameDate(DateTime.now())
                                    ? null
                                    : () => _navigateDay(true)),
                          ],
                        ),
                        const SizedBox(height: DesignConstants.spacingL),
                        Row(
                          children: [
                            _buildFilterButton(l10n.filterToday, '1D'),
                            _buildFilterButton(l10n.filter7Days, '1W'),
                            _buildFilterButton(l10n.filter30Days, '1M'),
                            _buildFilterButton(l10n.filterAll, 'All'),
                          ],
                        ),
                        const SizedBox(
                            height: DesignConstants.spacingL), // <- DIESE ZEILE
                      ],
                    ),
                  ),
                ),
                Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.1)),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isHeaderVisible
                      ? Column(
                          children: [
                            if (_nutritionData != null)
                              Column(
                                children: [
                                  // KORREKTUR: NutritionSummaryWidget in einem Padding, das dem horizontalen ListView-Padding entspricht.
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            16.0), // <- Dieser Padding ist wichtig!
                                    child: NutritionSummaryWidget(
                                        nutritionData: _nutritionData!,
                                        isExpandedView: _isSummaryExpanded,
                                        l10n: l10n),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isSummaryExpanded =
                                                !_isSummaryExpanded;
                                            UiStateService.instance
                                                    .isNutritionSummaryExpanded =
                                                _isSummaryExpanded;
                                          });
                                        },
                                        child: Text(_isSummaryExpanded
                                            ? l10n.showLess
                                            : l10n.showMoreDetails),
                                      ),
                                      TextButton(
                                        onPressed: () => setState(
                                            () => _isHeaderVisible = false),
                                        child: Text(l10n.hideSummary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _isHeaderVisible = true),
                              child: Text(l10n.showSummary),
                            ),
                          ),
                        ),
                ),
                Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.1)),
                Expanded(
                  child: _displayItems.isEmpty
                      ? Center(child: Text(l10n.noEntriesForPeriod))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          itemCount: _displayItems.length,
                          separatorBuilder: (context, index) => const SizedBox(
                              height: DesignConstants
                                  .spacingM), // KORREKTUR: Trenner
                          itemBuilder: (context, index) {
                            final item = _displayItems[index];

                            String getLocalizedMealName(String key) {
                              switch (key) {
                                case "mealtypeBreakfast":
                                  return l10n.mealtypeBreakfast;
                                case "mealtypeLunch":
                                  return l10n.mealtypeLunch;
                                case "mealtypeDinner":
                                  return l10n.mealtypeDinner;
                                case "mealtypeSnack":
                                  return l10n.mealtypeSnack;
                                case "waterHeader":
                                  return l10n.waterHeader;
                                default:
                                  return key;
                              }
                            }

                            if (item is DateTime) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    top: 24.0, bottom: 8.0, left: 8.0),
                                child: Text(
                                  DateFormat.yMMMMEEEEd(locale).format(item),
                                  style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary),
                                ),
                              );
                            }

                            if (item is String) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    top: 24.0, bottom: 8.0, left: 8.0),
                                child: Text(getLocalizedMealName(item),
                                    style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold)),
                              );
                            }

                            if (item is FoodTimelineEntry) {
                              final trackedItem = item.trackedItem;
                              return Dismissible(
                                key: Key('food_${trackedItem.entry.id}'),
                                direction: DismissDirection.horizontal,
                                background: const SwipeActionBackground(
                                  color: Colors.blueAccent,
                                  icon: Icons.edit,
                                  alignment: Alignment.centerLeft,
                                ),
                                secondaryBackground:
                                    const SwipeActionBackground(
                                  color: Colors.redAccent,
                                  icon: Icons.delete,
                                  alignment: Alignment.centerRight,
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    _editFoodEntry(trackedItem);
                                    return false;
                                  } else {
                                    return await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  Text(l10n.deleteConfirmTitle),
                                              content: Text(
                                                  l10n.deleteConfirmContent),
                                              actions: <Widget>[
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(false),
                                                    child: Text(l10n.cancel)),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true),
                                                    child: Text(l10n.delete)),
                                              ],
                                            );
                                          },
                                        ) ??
                                        false;
                                  }
                                },
                                onDismissed: (direction) {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    _deleteFoodEntry(trackedItem.entry.id!);
                                  }
                                },
                                child: SummaryCard(
                                  //externalMargin: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: const Icon(Icons.restaurant),
                                    title: Text(trackedItem.item.name),
                                    subtitle: Text(l10n.foodListSubtitle(
                                        trackedItem.entry.quantityInGrams,
                                        DateFormat.Hm(locale).format(
                                            trackedItem.entry.timestamp))),
                                    trailing: Text(l10n.foodListTrailingKcal(
                                        trackedItem.calculatedCalories)),
                                    onTap: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (context) =>
                                                FoodDetailScreen(
                                                    trackedItem: trackedItem)))
                                        .then((_) => _loadEntriesForDateRange(
                                            _selectedDateRange)),
                                  ),
                                ),
                              );
                            }

                            if (item is WaterTimelineEntry) {
                              final waterEntry = item.waterEntry;
                              return Dismissible(
                                key: Key('water_${waterEntry.id}'),
                                direction: DismissDirection.horizontal,
                                background: const SwipeActionBackground(
                                  color: Colors.blueAccent,
                                  icon: Icons.edit,
                                  alignment: Alignment.centerLeft,
                                ),
                                secondaryBackground:
                                    const SwipeActionBackground(
                                  color: Colors.redAccent,
                                  icon: Icons.delete,
                                  alignment: Alignment.centerRight,
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    _editWaterEntry(waterEntry);
                                    return false;
                                  } else {
                                    return await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  Text(l10n.deleteConfirmTitle),
                                              content: Text(
                                                  l10n.deleteConfirmContent),
                                              actions: <Widget>[
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(false),
                                                    child: Text(l10n.cancel)),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true),
                                                    child: Text(l10n.delete)),
                                              ],
                                            );
                                          },
                                        ) ??
                                        false;
                                  }
                                },
                                onDismissed: (direction) {
                                  if (direction ==
                                      DismissDirection.endToStart) {
                                    _deleteWaterEntry(waterEntry.id!);
                                  }
                                },
                                child: SummaryCard(
                                  //externalMargin: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: Icon(Icons.local_drink,
                                        color: colorScheme.primary),
                                    title: Text(l10n.waterEntryTitle),
                                    subtitle: Text(DateFormat.Hm(locale)
                                        .format(waterEntry.timestamp)),
                                    trailing: Text(
                                        l10n.waterListTrailingMl(
                                            waterEntry.quantityInMl),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                ),
              ],
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String key) {
    final theme = Theme.of(context);
    final isSelected = _selectedRangeKey == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setTimeRange(key),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
