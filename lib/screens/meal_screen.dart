import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_entry.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/models/supplement_log.dart';
import 'package:lightweight/screens/food_detail_screen.dart';
import 'package:lightweight/widgets/glass_bottom_menu.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/widgets/swipe_action_background.dart';

class MealScreen extends StatefulWidget {
  final Map<String, dynamic> meal; // erwartet: {id, name, notes}
  final bool startInEdit;

  const MealScreen({super.key, required this.meal, this.startInEdit = false});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  bool _editMode = false;
  bool _saving = false;

  List<Map<String, dynamic>> _items = [];
  bool _loadingItems = true;

  // Totals (werden bei jedem Build aus _items berechnet)
  int _totalKcal = 0;
  double _totalC = 0, _totalF = 0, _totalP = 0;

  @override
  void initState() {
    super.initState();
    _editMode = widget.startInEdit;
    _nameCtrl = TextEditingController(
      text: widget.meal['name'] as String? ?? '',
    );
    _notesCtrl = TextEditingController(
      text: widget.meal['notes'] as String? ?? '',
    );
    _loadItems();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    final id = widget.meal['id'] as int;
    final rows = await DatabaseHelper.instance.getMealItems(id);
    _items = List<Map<String, dynamic>>.from(rows);
    await _recomputeTotals(); // initiale Totals
    if (mounted) setState(() => _loadingItems = false);
  }

  /// Rechnet die Summen für kcal / C / F / P einmal durch.
  Future<void> _recomputeTotals() async {
    int kcal = 0;
    double c = 0, f = 0, p = 0;

    for (final it in _items) {
      final bc = it['barcode'] as String;
      final qty = (it['quantity_in_grams'] as num?)?.toDouble() ?? 0.0;
      final fi = await ProductDatabaseHelper.instance.getProductByBarcode(bc);
      if (fi == null) continue;

      final factor = qty / 100.0;
      final itemKcal = (fi.calories ?? 0) * factor;
      final itemC = (fi.carbs ?? 0) * factor;
      final itemF = (fi.fat ?? 0) * factor;
      final itemP = (fi.protein ?? 0) * factor;

      kcal += itemKcal.round();
      c += itemC;
      f += itemF;
      p += itemP;
    }

    _totalKcal = kcal;
    _totalC = c;
    _totalF = f;
    _totalP = p;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final canSave =
        _nameCtrl.text.trim().isNotEmpty && _items.isNotEmpty && !_saving;

    // Floating Action Button je Modus
    Widget? fab;
    if (_editMode) {
      fab = GlassFab(
        label: l10n.mealAddIngredient, // „Zutat hinzufügen“
        onPressed: _addIngredientFlow,
      );
    } else {
      if (_items.isNotEmpty) {
        fab = GlassFab(
          label: l10n.mealsAddToDiary, // „Zum Tagebuch hinzufügen“
          onPressed: _addMealToDiaryFlow,
        );
      } else {
        fab = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          _editMode
              ? l10n.mealsEdit // (L10n: du kannst das zu „Bearbeiten“ ändern)
              : (_nameCtrl.text.isNotEmpty
                  ? _nameCtrl.text
                  : l10n.mealsViewTitle),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          if (_editMode)
            TextButton(
              onPressed: canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.save,
                      style: TextStyle(
                        color: canSave
                            ? theme.colorScheme.primary
                            : theme.disabledColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            )
          else
            TextButton(
              onPressed: () => setState(() => _editMode = true),
              child: Text(
                l10n.mealsEdit,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _loadingItems
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                // NAME & NOTIZEN
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _editMode
                            ? TextField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: l10n.mealNameLabel,
                                ),
                                onChanged: (_) => setState(() {}),
                              )
                            : Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text
                                    : l10n.unknown,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        const SizedBox(height: 8),
                        _editMode
                            ? TextField(
                                controller: _notesCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: l10n.mealNotesLabel,
                                ),
                              )
                            : Text(
                                _notesCtrl.text.isNotEmpty
                                    ? _notesCtrl.text
                                    : l10n.noNotes,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // === NÄHRWERTE (Gesamtsumme) ===
                _buildSectionTitle(context, l10n.nutritionSectionLabel),
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: FutureBuilder<void>(
                      future: _recomputeTotals(),
                      builder: (_, __) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _items.isEmpty ? '– kcal' : '$_totalKcal kcal',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 16,
                              runSpacing: 6,
                              children: [
                                _MacroChip(
                                  label: 'C',
                                  value:
                                      _items.isEmpty ? '–' : _format1(_totalC),
                                  unit: 'g',
                                ),
                                _MacroChip(
                                  label: 'F',
                                  value:
                                      _items.isEmpty ? '–' : _format1(_totalF),
                                  unit: 'g',
                                ),
                                _MacroChip(
                                  label: 'P',
                                  value:
                                      _items.isEmpty ? '–' : _format1(_totalP),
                                  unit: 'g',
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // === ZUTATEN ===
                _buildSectionTitle(context, l10n.ingredientsCapsLock),

                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.emptyCategory,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    children: List.generate(_items.length, (i) {
                      final it = _items[i];
                      return _IngredientCard(
                        key: ValueKey('ing_$i'),
                        item: it,
                        editMode: _editMode,
                        showPerIngredientMacros: !_editMode,
                        onQtyChanged: (val) async {
                          _items[i]['quantity_in_grams'] = val;
                          await _recomputeTotals();
                          if (mounted) setState(() {});
                        },
                        onDelete: () async {
                          final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n.deleteConfirmTitle),
                                  content: Text(l10n.deleteConfirmContent),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: Text(l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: Text(l10n.delete),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                          if (ok) {
                            setState(() => _items.removeAt(i));
                            await _recomputeTotals();
                            if (mounted) setState(() {});
                          }
                        },
                      );
                    }),
                  ),
              ],
            ),
    );
  }

  String _format1(double v) => v.toStringAsFixed(1);

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _items.isEmpty) return;

    setState(() => _saving = true);
    try {
      final mealId = widget.meal['id'] as int;
      await DatabaseHelper.instance.updateMeal(
        mealId,
        name: name,
        notes: _notesCtrl.text.trim(),
      );
      await DatabaseHelper.instance.clearMealItems(mealId);
      for (final it in _items) {
        final grams = (it['quantity_in_grams'] as int?) ?? 0;
        await DatabaseHelper.instance.addMealItem(
          mealId,
          barcode: it['barcode'] as String,
          grams: grams,
        );
      }
      if (mounted) {
        setState(() => _editMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mealSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Food auswählen & Menge setzen
  Future<void> _addIngredientFlow() async {
    final l10n = AppLocalizations.of(context)!;
    final searchCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '100');

    final picked = await showGlassBottomMenu<(String, int)?>(
      context: context,
      title: l10n.mealAddIngredient,
      contentBuilder: (ctx, close) {
        List<FoodItem> results = [];
        bool loading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> runSearch(String q) async {
              if (q.trim().isEmpty) {
                setState(() => results = []);
                return;
              }
              setState(() => loading = true);
              results =
                  await ProductDatabaseHelper.instance.searchProducts(q.trim());
              setState(() => loading = false);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.searchHintText,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: runSearch,
                ),
                const SizedBox(height: 8),
                if (loading) const LinearProgressIndicator(minHeight: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(l10n.searchInitialHint),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final fi = results[i];
                            return ListTile(
                              dense: true,
                              title: Text(fi.name),
                              subtitle: Text(fi.brand.isNotEmpty
                                  ? fi.brand
                                  : l10n.noBrand),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  final grams = await showGlassBottomMenu<int?>(
                                    context: context,
                                    title: l10n.mealIngredientAmountLabel,
                                    contentBuilder: (ctx2, close2) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: qtyCtrl,
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: false),
                                              decoration: const InputDecoration(
                                                  suffixText: 'g/ml'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          FilledButton(
                                            onPressed: () {
                                              final val = int.tryParse(
                                                  qtyCtrl.text.trim());
                                              close2();
                                              Navigator.of(ctx2).pop(val);
                                            },
                                            child: Text(l10n.add_button),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (grams != null && grams > 0) {
                                    close();
                                    Navigator.of(ctx).pop((fi.barcode, grams));
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      final (barcode, grams) = picked;
      setState(() {
        _items.add({'barcode': barcode, 'quantity_in_grams': grams});
      });
      await _recomputeTotals();
      if (mounted) setState(() {});
    }
  }

  /// Aktuelle Mahlzeit als einzelne FoodEntries ins Tagebuch
  Future<void> _addMealToDiaryFlow() async {
    final l10n = AppLocalizations.of(context)!;

    // Load products
    final Map<String, FoodItem?> products = {};
    for (final it in _items) {
      final bc = it['barcode'] as String;
      products[bc] =
          await ProductDatabaseHelper.instance.getProductByBarcode(bc);
    }

    // Controllers for quantities
    final Map<String, TextEditingController> qtyCtrls = {
      for (final it in _items)
        (it['barcode'] as String): TextEditingController(
          text: '${it['quantity_in_grams']}',
        ),
    };

    const internalTypes = [
      'mealtypeBreakfast',
      'mealtypeLunch',
      'mealtypeDinner',
      'mealtypeSnack',
    ];
    String selectedMealType = internalTypes.first;

    final Map<String, String> mealTypeLabel = {
      'mealtypeBreakfast': l10n.mealtypeBreakfast,
      'mealtypeLunch': l10n.mealtypeLunch,
      'mealtypeDinner': l10n.mealtypeDinner,
      'mealtypeSnack': l10n.mealtypeSnack,
    };

    final ok = await showGlassBottomMenu<bool>(
          context: context,
          title: l10n.mealsAddToDiary,
          contentBuilder: (ctx, close) {
            return StatefulBuilder(
              builder: (ctx, modalSetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_nameCtrl.text,
                        style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMealType,
                      decoration: InputDecoration(
                        labelText: l10n.mealTypeLabel,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: internalTypes
                          .map((key) => DropdownMenuItem(
                                value: key,
                                child: Text(mealTypeLabel[key] ?? key),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          modalSetState(() => selectedMealType = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final it = _items[i];
                          final bc = it['barcode'] as String;
                          final fi = products[bc];
                          final displayName =
                              (fi?.name.isNotEmpty ?? false) ? fi!.name : bc;
                          final unit = (fi?.isLiquid == true) ? 'ml' : 'g';

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 14),
                                child: Icon(Icons.lunch_dining),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: qtyCtrls[bc],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: displayName,
                                    helperText: l10n.amountLabel,
                                    suffixText: unit,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              close();
                              Navigator.of(ctx).pop(false);
                            },
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              close();
                              Navigator.of(ctx).pop(true);
                            },
                            child: Text(l10n.save),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (!ok) return;

    final ts = DateTime.now();
    for (final it in _items) {
      final bc = it['barcode'] as String;
      final ctrl = qtyCtrls[bc]!;
      final qty =
          int.tryParse(ctrl.text.trim()) ?? (it['quantity_in_grams'] as int);

      await DatabaseHelper.instance.insertFoodEntry(
        FoodEntry(
          barcode: bc,
          timestamp: ts,
          quantityInGrams: qty,
          mealType: selectedMealType,
        ),
      );

      final fi = await ProductDatabaseHelper.instance.getProductByBarcode(bc);
      if (fi != null) {
        if (fi.isLiquid == true) {
          // water logging if desired
        }
        final c100 = fi.caffeineMgPer100ml;
        if (fi.isLiquid == true && c100 != null && c100 > 0) {
          await _logCaffeineDose(c100 * (qty / 100.0), ts);
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.mealAddedToDiarySuccess)));
    }
  }

  Future<void> _logCaffeineDose(double doseMg, DateTime timestamp) async {
    if (doseMg <= 0) return;

    final supplements = await DatabaseHelper.instance.getAllSupplements();
    final caffeine = supplements.firstWhere(
      (s) => (s.code == 'caffeine') || s.name.toLowerCase() == 'caffeine',
      orElse: () => Supplement(
        name: 'Caffeine',
        defaultDose: 100,
        unit: 'mg',
        dailyLimit: 400,
        code: 'caffeine',
        isBuiltin: true,
      ),
    );

    final caffeineId = caffeine.id ??
        (await DatabaseHelper.instance.insertSupplement(caffeine)).id!;

    await DatabaseHelper.instance.insertSupplementLog(
      SupplementLog(
        supplementId: caffeineId,
        dose: doseMg,
        unit: 'mg',
        timestamp: timestamp,
      ),
    );
  }
}

/// Kleines “Chip”-Label für C/F/P
class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _MacroChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label  $value$unit',
        style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Einzelne Zutat als SummaryCard
/// - View-Modus: Name (tappable) + kleine kcal rechts + (darunter) C/F/P
/// - Edit-Modus: rechts Mengenfeld; Swipe nach links = Löschen
class _IngredientCard extends StatelessWidget {
  final Map<String, dynamic> item; // { barcode, quantity_in_grams }
  final bool editMode;
  final bool showPerIngredientMacros;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onDelete;

  const _IngredientCard({
    super.key,
    required this.item,
    required this.editMode,
    required this.showPerIngredientMacros,
    required this.onQtyChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final bc = item['barcode'] as String;
    final qty = (item['quantity_in_grams'] as num?)?.toDouble() ?? 0.0;

    Widget buildCard(FoodItem? fi) {
      final name = (fi?.name.isNotEmpty ?? false) ? fi!.name : bc;
      final unit = (fi?.isLiquid == true) ? 'ml' : 'g';

      // per-ingredient macros & kcal
      int kcal = 0;
      double c = 0, f = 0, p = 0;
      if (fi != null) {
        final factor = qty / 100.0;
        kcal = ((fi.calories ?? 0) * factor).round();
        c = (fi.carbs ?? 0) * factor;
        f = (fi.fat ?? 0) * factor;
        p = (fi.protein ?? 0) * factor;
      }

      final title = InkWell(
        onTap: () {
          if (fi != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FoodDetailScreen(foodItem: fi)),
            );
          }
        },
        child: Text(
          name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      final trailingView = Text(
        fi == null ? '–' : '$kcal kcal',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      );

      final trailingEdit = SizedBox(
        width: 96,
        child: TextFormField(
          initialValue: '${qty.toInt()}',
          textAlign: TextAlign.right,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(
            isDense: true,
            suffixText: unit,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) {
            final parsed = int.tryParse(v.trim());
            if (parsed != null && parsed >= 0) onQtyChanged(parsed);
          },
        ),
      );

      return SummaryCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 4),
                  Icon(Icons.local_dining, color: color),
                  const SizedBox(width: 12),
                  Expanded(child: title),
                  if (!editMode) trailingView else trailingEdit,
                ],
              ),
              if (showPerIngredientMacros && fi != null) ...[
                const SizedBox(height: 6),
                Text(
                  'C ${c.toStringAsFixed(1)} g   •   F ${f.toStringAsFixed(1)} g   •   P ${p.toStringAsFixed(1)} g',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final card = FutureBuilder<FoodItem?>(
      future: ProductDatabaseHelper.instance.getProductByBarcode(bc),
      builder: (_, snap) => buildCard(snap.data),
    );

    if (!editMode) return card;

    // Edit-Modus: Swipe links = löschen
    return Dismissible(
      key: ValueKey('ing_${item['barcode']}_${item['quantity_in_grams']}'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
        return false;
      },
      child: card,
    );
  }
}
