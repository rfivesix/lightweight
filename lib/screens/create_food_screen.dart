// lib/screens/create_food_screen.dart (Final & De-Materialisiert)

import 'package:flutter/material.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_item.dart';
import 'package:lightweight/util/design_constants.dart';

class CreateFoodScreen extends StatefulWidget {
  final FoodItem? foodItemToEdit;
  const CreateFoodScreen({super.key, this.foodItemToEdit});

  @override
  State<CreateFoodScreen> createState() => _CreateFoodScreenState();
}

class _CreateFoodScreenState extends State<CreateFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _sugarController = TextEditingController();
  final _fiberController = TextEditingController();
  final _saltController = TextEditingController();

  bool get _isEditing => widget.foodItemToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.foodItemToEdit!;
      _nameController.text = item.name;
      _brandController.text = item.brand;
      _caloriesController.text = item.calories.toString();
      _proteinController.text = item.protein.toString();
      _carbsController.text = item.carbs.toString();
      _fatController.text = item.fat.toString();
      _sugarController.text = item.sugar?.toString() ?? '';
      _fiberController.text = item.fiber?.toString() ?? '';
      _saltController.text = item.salt?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    _fiberController.dispose();
    _saltController.dispose();
    super.dispose();
  }

  Future<void> _saveFoodItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      final l10n = AppLocalizations.of(context)!;

      final foodData = FoodItem(
        barcode: _isEditing
            ? widget.foodItemToEdit!.barcode
            : "user_created_${DateTime.now().millisecondsSinceEpoch}",
        name: _nameController.text,
        brand: _brandController.text,
        calories: int.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0.0,
        carbs: double.tryParse(_carbsController.text) ?? 0.0,
        fat: double.tryParse(_fatController.text) ?? 0.0,
        sugar: double.tryParse(_sugarController.text),
        fiber: double.tryParse(_fiberController.text),
        salt: double.tryParse(_saltController.text),
        source: FoodItemSource.user,
      );

      if (_isEditing) {
        await ProductDatabaseHelper.instance.updateProduct(foodData);
      } else {
        await ProductDatabaseHelper.instance.insertProduct(foodData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.snackbarSaveSuccess(foodData.name))),
        );
        Navigator.of(context).pop(foodData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // KORREKTUR: Eine AppBar hinzugefügt, die den Titel und den Speicher-Button enthält
      appBar: AppBar(
        title: Text(l10n.createFoodScreenTitle),
        actions: [
          TextButton(
            onPressed: _saveFoodItem,
            // Hier stellen wir sicher, dass der Text die Primärfarbe nutzt
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),

            child: Text(
              l10n.buttonSave,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: DesignConstants.cardPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KORREKTUR: Der alte Header wurde aus dem Body entfernt

              // Formularfelder (unverändert)
              _buildFoodInputField(
                controller: _nameController,
                label: l10n.formFieldName,
                isRequired: true,
              ),
              _buildFoodInputField(
                controller: _brandController,
                label: l10n.formFieldBrand,
              ),

              const SizedBox(height: DesignConstants.spacingXL),
              _buildSectionTitle(context, l10n.formSectionMainNutrients),
              const SizedBox(height: DesignConstants.spacingL),
              _buildFoodInputField(
                controller: _caloriesController,
                label: l10n.formFieldCalories,
              ),
              _buildFoodInputField(
                controller: _proteinController,
                label: l10n.formFieldProtein,
              ),
              _buildFoodInputField(
                controller: _carbsController,
                label: l10n.formFieldCarbs,
              ),
              _buildFoodInputField(
                controller: _fatController,
                label: l10n.formFieldFat,
              ),

              const SizedBox(height: DesignConstants.spacingXL),
              _buildSectionTitle(context, l10n.formSectionOptionalNutrients),
              const SizedBox(height: DesignConstants.spacingL),
              _buildFoodInputField(
                controller: _sugarController,
                label: l10n.formFieldSugar,
              ),
              _buildFoodInputField(
                controller: _fiberController,
                label: l10n.formFieldFiber,
              ),
              _buildFoodInputField(
                controller: _saltController,
                label: l10n.formFieldSalt,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ... (die restlichen _build-Methoden bleiben unverändert hier drin)
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

  Widget _buildFoodInputField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return l10n.validatorPleaseEnterName;
          }
          if (value != null &&
              value.isNotEmpty &&
              double.tryParse(value) == null) {
            return l10n.validatorPleaseEnterNumber;
          }
          return null;
        },
      ),
    );
  }
}
