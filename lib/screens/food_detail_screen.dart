// lib/screens/food_detail_screen.dart (Final & De-Materialisiert - OLED Ready)

import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/tracked_food_item.dart';
import 'package:lightweight/widgets/off_attribution_widget.dart';
import 'package:lightweight/widgets/summary_card.dart';

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
        title: Text(
          _displayItem.name,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        actions: [
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
        padding: const EdgeInsets.all(16.0),
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
            if (_hasPortionInfo) const SizedBox(height: 16),
            Text("Nährwerte pro ${displayQuantity}g",
                style: textTheme.titleLarge),
            const SizedBox(height: 8),
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
              const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
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
}
