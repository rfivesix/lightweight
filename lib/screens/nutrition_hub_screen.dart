// lib/screens/nutrition_hub_screen.dart (Final, nach deinem Feedback)

import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/dialogs/quantity_dialog_content.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/daily_nutrition.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/tracked_food_item.dart';
import 'package:lightweight/screens/add_food_screen.dart';
import 'package:lightweight/screens/create_food_screen.dart';
import 'package:lightweight/screens/food_detail_screen.dart';
import 'package:lightweight/screens/nutrition_screen.dart';
import 'package:lightweight/screens/scanner_screen.dart';
import 'package:lightweight/widgets/nutrition_summary_widget.dart'; // HINZUGEFÜGT
import 'package:lightweight/widgets/summary_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NutritionHubScreen extends StatefulWidget {
  const NutritionHubScreen({super.key});

  @override
  State<NutritionHubScreen> createState() => _NutritionHubScreenState();
}

class _NutritionHubScreenState extends State<NutritionHubScreen> {
  bool _isLoading = true;
  DailyNutrition? _todaysNutrition;
  Map<String, List<TrackedFoodItem>> _todaysEntriesByMeal = {};

  @override
  void initState() {
    super.initState();
    _loadTodaysData();
  }

  Future<void> _loadTodaysData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final targetCalories = prefs.getInt('targetCalories') ?? 2500;
    final targetProtein = prefs.getInt('targetProtein') ?? 180;
    final targetCarbs = prefs.getInt('targetCarbs') ?? 250;
    final targetFat = prefs.getInt('targetFat') ?? 80;
    final targetWater = prefs.getInt('targetWater') ?? 3000;

    final today = DateTime.now();
    final foodEntries = await DatabaseHelper.instance.getEntriesForDate(today);
    final waterIntake = await DatabaseHelper.instance.getWaterForDate(today);

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

    if (mounted) {
      setState(() {
        _todaysNutrition = summary;
        _todaysEntriesByMeal = groupedEntries;
        _isLoading = false;
      });
    }
  }

  // HINZUGEFÜGT: Methoden für Löschen und Bearbeiten

  Future<void> _deleteFoodEntry(int id) async {
    await DatabaseHelper.instance.deleteFoodEntry(id);
    _loadTodaysData(); // Lade die Daten neu, um die Liste zu aktualisieren
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
      _loadTodaysData(); // Lade die Daten neu
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasEntries =
        _todaysEntriesByMeal.values.any((list) => list.isNotEmpty);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodaysData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionTitle(context, l10n.today_overview_text),
                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (context) => const NutritionScreen()))
                        .then((_) => _loadTodaysData()),
                    // KORREKTUR 1: Die umgebende SummaryCard entfernt.
                    // NutritionSummaryWidget ist bereits eine SummaryCard.
                    child: _todaysNutrition != null
                        ? NutritionSummaryWidget(
                            nutritionData: _todaysNutrition!,
                            l10n: l10n,
                            isExpandedView: false)
                        : const SizedBox(),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, l10n.quick_add_text),
                  _buildQuickAddButton(
                      context,
                      l10n.addFoodOption,
                      Icons.search,
                      () => Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (context) => const AddFoodScreen()))
                          .then((_) => _loadTodaysData())),
                  const SizedBox(height: 8),
                  _buildQuickAddButton(context, l10n.scann_barcode_capslock,
                      Icons.qr_code_scanner, _scanBarcodeAndAddFood),
                  const SizedBox(height: 8),
                  _buildQuickAddButton(
                      context,
                      l10n.fabCreateOwnFood,
                      Icons.add,
                      () => Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (context) => const CreateFoodScreen()))
                          .then((_) => _loadTodaysData())),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, l10n.protocol_today_capslock),
                  hasEntries
                      ? _buildTodaysLog(l10n)
                      : _buildEmptyLogState(l10n),
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

  Widget _buildQuickAddButton(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return SummaryCard(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      ),
    );
  }

  Widget _buildTodaysLog(AppLocalizations l10n) {
    // Diese Methode baut die Liste der Mahlzeiten für heute auf
    const mealOrder = [
      "mealtypeBreakfast",
      "mealtypeLunch",
      "mealtypeDinner",
      "mealtypeSnack"
    ];

    return Column(
      children: mealOrder.map((mealKey) {
        final entries = _todaysEntriesByMeal[mealKey];
        if (entries == null || entries.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
              child: Text(_getLocalizedMealName(l10n, mealKey),
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ...entries.map((item) => _buildFoodEntryTile(l10n, item)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFoodEntryTile(
      AppLocalizations l10n, TrackedFoodItem trackedItem) {
    // KORREKTUR: Das ListTile ist jetzt in einem Dismissible-Widget
    return Dismissible(
      key: Key('food_hub_entry_${trackedItem.entry.id}'),

      // Hintergrund für "Bearbeiten" (nach rechts wischen)
      background: Container(
        color: Colors.blueAccent,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),

      // Hintergrund für "Löschen" (nach links wischen)
      secondaryBackground: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      // Diese Methode wird vor dem Löschen/Bearbeiten aufgerufen
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Nach rechts gewischt -> Bearbeiten
          _editFoodEntry(trackedItem);
          return false; // Verhindert, dass das Element aus der Liste entfernt wird
        } else {
          // Nach links gewischt -> Löschen
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
              false; // Gibt false zurück, wenn der Dialog geschlossen wird
        }
      },

      // Wird nur ausgeführt, wenn confirmDismiss 'true' zurückgibt (also beim Löschen)
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
                .then((_) => _loadTodaysData());
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

  // DIESE METHODE HINZUFÜGEN
  Future<void> _scanBarcodeAndAddFood() async {
    final String? barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (barcode != null && mounted) {
      final foodItem =
          await ProductDatabaseHelper.instance.getProductByBarcode(barcode);

      if (foodItem != null) {
        _addFoodItem(foodItem);
      } else {
        // Produkt nicht gefunden, zeige eine Meldung. Optional kannst du hier anbieten,
        // den `CreateFoodScreen` zu öffnen.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Kein Produkt für Barcode "$barcode" gefunden.')),
          );
        }
      }
    }
  }

  // DIESE METHODE EBENFALLS HINZUFÜGEN (Code-Duplizierung, aber für den Moment am einfachsten)
  Future<void> _addFoodItem(FoodItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final GlobalKey<QuantityDialogContentState> dialogStateKey = GlobalKey();

    final result = await showDialog<(int, DateTime, bool, String)?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          content: QuantityDialogContent(key: dialogStateKey, item: item),
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
                  if (quantity != null && quantity > 0) {
                    Navigator.of(context).pop((
                      quantity,
                      state.selectedDateTime,
                      state.countAsWater,
                      state.selectedMealType
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
        barcode: item.barcode,
        quantityInGrams: result.$1,
        timestamp: result.$2,
        mealType: result.$4,
      );
      await DatabaseHelper.instance.insertFoodEntry(newEntry);

      if (result.$3) {
        // countAsWater
        await DatabaseHelper.instance.insertWaterEntry(result.$1, result.$2);
      }
      _loadTodaysData(); // Lade die Daten neu, um die UI zu aktualisieren
    }
  }
}
