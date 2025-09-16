// lib/screens/create_food_screen.dart (Final & De-Materialisiert)

import 'package:flutter/material.dart';
import 'package:lightweight/data/product_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_item.dart';

class CreateFoodScreen extends StatefulWidget {
  const CreateFoodScreen({super.key});

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

      final newFoodItem = FoodItem(
        barcode: "user_created_${DateTime.now().millisecondsSinceEpoch}",
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

      await ProductDatabaseHelper.instance.insertProduct(newFoodItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.snackbarSaveSuccess(newFoodItem.name))),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // KORREKTUR 1: AppBar entfernt, Titel und Save-Button direkt in die ListView
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header-Bereich mit Titel und Save-Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.createFoodScreenTitle,
                      style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900, fontSize: 28)),
                  ElevatedButton(
                    onPressed: _saveFoodItem,
                    child: Text(l10n.buttonSave),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Formularfelder
              _buildFoodInputField(
                  controller: _nameController,
                  label: l10n.formFieldName,
                  isRequired: true),
              _buildFoodInputField(
                  controller: _brandController, label: l10n.formFieldBrand),

              const SizedBox(height: 24),
              _buildSectionTitle(context,
                  l10n.formSectionMainNutrients), // KORREKTUR 2: Sektionstitel
              const SizedBox(height: 16),
              _buildFoodInputField(
                  controller: _caloriesController,
                  label: l10n.formFieldCalories),
              _buildFoodInputField(
                  controller: _proteinController, label: l10n.formFieldProtein),
              _buildFoodInputField(
                  controller: _carbsController, label: l10n.formFieldCarbs),
              _buildFoodInputField(
                  controller: _fatController, label: l10n.formFieldFat),

              const SizedBox(height: 24),
              _buildSectionTitle(context,
                  l10n.formSectionOptionalNutrients), // KORREKTUR 2: Sektionstitel
              const SizedBox(height: 16),
              _buildFoodInputField(
                  controller: _sugarController, label: l10n.formFieldSugar),
              _buildFoodInputField(
                  controller: _fiberController, label: l10n.formFieldFiber),
              _buildFoodInputField(
                  controller: _saltController, label: l10n.formFieldSalt),

              const SizedBox(height: 32), // Abstand zum Ende
            ],
          ),
        ),
      ),
    );
  }

  // KORREKTUR 3: Helfer-Methode für konsistente Sektionstitel
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

  // KORREKTUR 4: Angepasstes Input-Feld, das auf globale Themes reagiert
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
        decoration: InputDecoration(
          labelText: label,
          // Wir lassen die globalen Themes greifen
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return l10n.validatorPleaseEnterName; // Oder spezifischer Text
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
