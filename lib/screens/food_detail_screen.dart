// lib/screens/food_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/models/tracked_food_item.dart';
import 'package:lightweight/widgets/off_attribution_widget.dart';

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
    final isFav = await DatabaseHelper.instance.isFavorite(_displayItem.barcode);
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
    // DOC: l10n-Instanz holen
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final displayQuantity = _showPer100g || !_hasPortionInfo ? 100 : _trackedQuantity!;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(_displayItem.name),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.redAccent : colorScheme.onPrimary),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_displayItem.name, style: Theme.of(context).textTheme.headlineMedium),
            if (_displayItem.brand.isNotEmpty)
              Text(_displayItem.brand, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
            
            const Divider(height: 32),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nährwerte pro ${displayQuantity}g", style: Theme.of(context).textTheme.titleLarge),
                if (_hasPortionInfo) const SizedBox(height: 8),
                if (_hasPortionInfo)
                  SegmentedButton<bool>(
                    segments: [
                      // DOC: Lokalisierte Texte für Segmente
                      ButtonSegment(value: false, label: Text(l10n.foodDetailSegmentPortion)),
                      ButtonSegment(value: true, label: Text(l10n.foodDetailSegment100g)),
                    ],
                    selected: {_showPer100g},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() => _showPer100g = newSelection.first);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),

            _buildNutrientRow(l10n.calories, "${_getDisplayValue(_displayItem.calories.toDouble()).round()} kcal"),
            _buildNutrientRow(l10n.protein, "${_getDisplayValue(_displayItem.protein).toStringAsFixed(1)} g"),
            _buildNutrientRow(l10n.carbs, "${_getDisplayValue(_displayItem.carbs).toStringAsFixed(1)} g"),
            if (_displayItem.sugar != null) _buildNutrientRow("  ${l10n.sugar}", "${_getDisplayValue(_displayItem.sugar).toStringAsFixed(1)} g"),
            _buildNutrientRow(l10n.fat, "${_getDisplayValue(_displayItem.fat).toStringAsFixed(1)} g"),
            if (_displayItem.fiber != null) _buildNutrientRow(l10n.fiber, "${_getDisplayValue(_displayItem.fiber).toStringAsFixed(1)} g"),
            if (_displayItem.salt != null) _buildNutrientRow(l10n.salt, "${_getDisplayValue(_displayItem.salt).toStringAsFixed(1)} g"),
            
            if (!_displayItem.barcode.startsWith('user_created_'))
              const OffAttributionWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}