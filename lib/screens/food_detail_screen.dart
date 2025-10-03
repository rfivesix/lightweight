// lib/screens/food_detail_screen.dart (Final & De-Materialisiert - OLED Ready)

import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/tracked_food_item.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/off_attribution_widget.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

// Dev-Flag: später einfach auf false setzen oder die Dev-Blöcke entfernen.
const bool kDevEditEnabled = true;

class FoodDetailScreen extends StatefulWidget {
  final TrackedFoodItem? trackedItem;
  final FoodItem? foodItem;

  const FoodDetailScreen({super.key, this.trackedItem, this.foodItem})
      : assert(trackedItem != null || foodItem != null);

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  bool _isFavorite = false;
  bool _showPer100g = false;

  late FoodItem _displayItem;
  int? _trackedQuantity;
  bool get _hasPortionInfo => _trackedQuantity != null;

  // ---------- DEV: Inline-Editing ----------
  bool _devEditing = false; // via Secret-Tap toggeln

  final _deCtrl = TextEditingController();
  final _enCtrl = TextEditingController();
  final _catCtrl = TextEditingController();

  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _kjCtrl = TextEditingController();
  final _fibCtrl = TextEditingController();
  final _sugCtrl = TextEditingController();
  final _saltCtrl = TextEditingController();
  final _sodCtrl = TextEditingController();
  final _calciumCtrl = TextEditingController();

  void _fillControllers(FoodItem item, {Map<String, dynamic>? rawRow}) {
    _deCtrl.text = (rawRow?['name_de'] as String?) ?? item.name;
    _enCtrl.text = (rawRow?['name_en'] as String?) ?? '';
    _catCtrl.text = (rawRow?['category_key'] as String?) ?? '';

    _calCtrl.text = (item.calories).toString();
    _proCtrl.text = (item.protein).toString();
    _carbCtrl.text = (item.carbs).toString();
    _fatCtrl.text = (item.fat).toString();
    _kjCtrl.text = (rawRow?['kj_100g'] as num?)?.toString() ?? '';
    _fibCtrl.text = (rawRow?['fiber_100g'] as num?)?.toString() ?? '';
    _sugCtrl.text = (rawRow?['sugar_100g'] as num?)?.toString() ?? '';
    _saltCtrl.text = (rawRow?['salt_100g'] as num?)?.toString() ?? '';
    _sodCtrl.text = (rawRow?['sodium_100g'] as num?)?.toString() ?? '';
    _calciumCtrl.text = (rawRow?['calcium_100g'] as num?)?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    if (widget.trackedItem != null) {
      _displayItem = widget.trackedItem!.item;
      _trackedQuantity = widget.trackedItem!.entry.quantityInGrams;
    } else {
      _displayItem = widget.foodItem!;
      _trackedQuantity = null;
      _showPer100g = true;
    }
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _deCtrl.dispose(); _enCtrl.dispose(); _catCtrl.dispose();
    _calCtrl.dispose(); _proCtrl.dispose(); _carbCtrl.dispose(); _fatCtrl.dispose();
    _kjCtrl.dispose(); _fibCtrl.dispose(); _sugCtrl.dispose(); _saltCtrl.dispose();
    _sodCtrl.dispose(); _calciumCtrl.dispose();
    super.dispose();
  }

  // ---------- DEV: Basis-DB Hilfen ----------

  Future<String> _getBaseDbPath() async {
    // Versuche erst den bekannten Namen der Base-DB im App-DB-Verzeichnis
    final dbDir = await getDatabasesPath();
    return p.join(dbDir, 'vita_base_foods.db');
  }

  Future<Database> _openBaseDb({bool readOnly = false}) async {
    final path = await _getBaseDbPath();
    return openDatabase(path, readOnly: readOnly);
  }

  Future<Map<String, dynamic>?> _loadRawRow(String barcode) async {
    final base = await _openBaseDb(readOnly: true);
    try {
      final rows = await base.query('products', where: 'barcode = ?', whereArgs: [barcode], limit: 1);
      return rows.isNotEmpty ? rows.first : null;
    } finally {
      await base.close();
    }
  }

  Future<void> _saveDevEdits() async {
    try {
      final barcode = _displayItem.barcode;
      final Map<String, Object?> fields = {
        // Spiegel beachten: name = name_de
        'name_de': _deCtrl.text.trim(),
        'name_en': _enCtrl.text.trim().isEmpty ? null : _enCtrl.text.trim(),
        'name': _deCtrl.text.trim(),
        'category_key': _catCtrl.text.trim().isEmpty ? null : _catCtrl.text.trim(),
        // Nährwerte
        'calories_100g': int.tryParse(_calCtrl.text.trim()),
        'protein_100g': double.tryParse(_proCtrl.text.trim()),
        'carbs_100g': double.tryParse(_carbCtrl.text.trim()),
        'fat_100g': double.tryParse(_fatCtrl.text.trim()),
        'kj_100g': double.tryParse(_kjCtrl.text.trim()),
        'fiber_100g': double.tryParse(_fibCtrl.text.trim()),
        'sugar_100g': double.tryParse(_sugCtrl.text.trim()),
        'salt_100g': double.tryParse(_saltCtrl.text.trim()),
        'sodium_100g': double.tryParse(_sodCtrl.text.trim()),
        'calcium_100g': double.tryParse(_calciumCtrl.text.trim()),
      };

      // leere Strings zu null; 'barcode' niemals überschreiben
      fields.removeWhere((k, v) => v == null);

      final db = await _openBaseDb();
      try {
        await db.update(
          'products',
          fields,
          where: 'barcode = ?',
          whereArgs: [barcode],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } finally {
        await db.close();
      }
      await ProductDatabaseHelper.instance.reloadBaseDb();

      // Für sichtbares Refresh: Eintrag neu aus Base-DB laden
      final baseDb = await _openBaseDb(readOnly: true);
      Map<String, dynamic>? row;
      try {
        final rows = await baseDb.query('products', where: 'barcode = ?', whereArgs: [barcode], limit: 1);
        if (rows.isNotEmpty) row = rows.first;
      } finally {
        await baseDb.close();
      }
      if (row != null) {
        setState(() {
          _displayItem = FoodItem.fromMap(row!, source: FoodItemSource.base);
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gespeichert (Basis-DB)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  Future<void> _exportBaseDb() async {
    try {
      final path = await _getBaseDbPath();
      final file = XFile(path, name: p.basename(path));
      await Share.shareXFiles([file], subject: 'Export: vita_base_foods.db');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export-Fehler: $e')),
      );
    }
  }

  // ---------- Favoriten / Anzeige ----------

  Future<void> _checkIfFavorite() async {
    final isFav =
        await DatabaseHelper.instance.isFavorite(_displayItem.barcode);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await DatabaseHelper.instance.removeFavorite(_displayItem.barcode);
    } else {
      await DatabaseHelper.instance.addFavorite(_displayItem.barcode);
    }
    _checkIfFavorite();
  }

  double _getDisplayValue(double? valuePer100g) {
    if (valuePer100g == null) return 0.0;
    if (_showPer100g || !_hasPortionInfo) {
      return valuePer100g;
    }
    return (valuePer100g / 100 * _trackedQuantity!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayQuantity =
        _showPer100g || !_hasPortionInfo ? 100 : _trackedQuantity!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: GestureDetector(
          onLongPress: () async {
            if (!kDevEditEnabled) return;
            setState(() => _devEditing = !_devEditing);
            if (_devEditing) {
              final raw = await _loadRawRow(_displayItem.barcode);
              _fillControllers(_displayItem, rawRow: raw);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('DEV-Edit-Modus aktiv')),
                );
              }
            }
          },
          child: Text(
            _displayItem.name,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        actions: [
          if (kDevEditEnabled && _devEditing)
            IconButton(
              tooltip: 'Basis-DB exportieren',
              onPressed: _exportBaseDb,
              icon: const Icon(Icons.ios_share),
            ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color:
                  _isFavorite ? Colors.redAccent : colorScheme.onSurfaceVariant,
            ),
            onPressed: _toggleFavorite,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_displayItem.brand.isNotEmpty)
              Text(
                _displayItem.brand,
                style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
            Divider(
              height: 32,
              thickness: 1,
              color: colorScheme.onSurfaceVariant.withOpacity(0.1),
            ),
            if (_hasPortionInfo)
              SummaryCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildToggleButton(
                          context, l10n.foodDetailSegmentPortion, false),
                      _buildToggleButton(
                          context, l10n.foodDetailSegment100g, true),
                    ],
                  ),
                ),
              ),
            if (_hasPortionInfo)
              const SizedBox(height: DesignConstants.spacingL),
            Text("Nährwerte pro ${displayQuantity}g",
                style: textTheme.titleLarge),
            const SizedBox(height: DesignConstants.spacingS),
            SummaryCard(
              child: Column(
                children: [
                  _buildNutrientRow(l10n.calories,
                      "${_getDisplayValue(_displayItem.calories.toDouble()).round()} kcal"),
                  _buildNutrientRow(l10n.protein,
                      "${_getDisplayValue(_displayItem.protein).toStringAsFixed(1)} g"),
                  _buildNutrientRow(l10n.carbs,
                      "${_getDisplayValue(_displayItem.carbs).toStringAsFixed(1)} g"),
                  _buildNutrientRow(l10n.fat,
                      "${_getDisplayValue(_displayItem.fat).toStringAsFixed(1)} g"),
                ],
              ),
            ),
            if (_displayItem.sugar != null ||
                _displayItem.fiber != null ||
                _displayItem.salt != null) ...[
              const SizedBox(height: DesignConstants.spacingM),
              SummaryCard(
                child: Column(
                  children: [
                    if (_displayItem.sugar != null)
                      _buildNutrientRow(l10n.sugar,
                          "${_getDisplayValue(_displayItem.sugar).toStringAsFixed(1)} g"),
                    if (_displayItem.fiber != null)
                      _buildNutrientRow(l10n.fiber,
                          "${_getDisplayValue(_displayItem.fiber).toStringAsFixed(1)} g"),
                    if (_displayItem.salt != null)
                      _buildNutrientRow(l10n.salt,
                          "${_getDisplayValue(_displayItem.salt).toStringAsFixed(1)} g"),
                  ],
                ),
              ),
            ],

            // ---------- DEV: Inline-Edit Panel ----------
            if (kDevEditEnabled && _devEditing) ...[
              const SizedBox(height: DesignConstants.spacingM),
              SummaryCard(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DEV: Eintrag bearbeiten',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      _row('Name (DE)', _deCtrl),
                      const SizedBox(height: 8),
                      _row('Name (EN)', _enCtrl),
                      const SizedBox(height: 8),
                      _row('Kategorie-Key', _catCtrl),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _num('kcal/100g', _calCtrl),
                          _num('Protein/100g', _proCtrl),
                          _num('Carbs/100g', _carbCtrl),
                          _num('Fett/100g', _fatCtrl),
                          _num('kJ/100g', _kjCtrl),
                          _num('Ballastst./100g', _fibCtrl),
                          _num('Zucker/100g', _sugCtrl),
                          _num('Salz/100g', _saltCtrl),
                          _num('Natrium/100g', _sodCtrl),
                          _num('Calcium/100g', _calciumCtrl),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saveDevEdits,
                            icon: const Icon(Icons.save),
                            label: const Text('Speichern'),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () => setState(() => _devEditing = false),
                            icon: const Icon(Icons.close),
                            label: const Text('Fertig'),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Basis-DB exportieren',
                            onPressed: _exportBaseDb,
                            icon: const Icon(Icons.ios_share),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (!_displayItem.barcode.startsWith('user_created_'))
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: OffAttributionWidget(
                  textStyle:
                      textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
      BuildContext context, String label, bool is100gOption) {
    final theme = Theme.of(context);
    final isSelected = _showPer100g == is100gOption;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _showPer100g = is100gOption),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------- DEV: kleine Helfer-Inputs ----------

  Widget _row(String label, TextEditingController c) => TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );

  Widget _num(String label, TextEditingController c) => SizedBox(
        width: 160,
        child: TextField(
          controller: c,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: false),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );
}