import 'package:flutter/material.dart';
import 'package:lightweight/constants/colors.dart';
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
  final _kjController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sugarController = TextEditingController();
  final _saltController = TextEditingController();
  final _sodiumController = TextEditingController();
  final _calciumController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _kjController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _saltController.dispose();
    _sodiumController.dispose();
    _calciumController.dispose();
    super.dispose();
  }

  // DOC: VOLLSTÄNDIGE SPEICHER-LOGIK
  void _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    final l10n = AppLocalizations.of(context)!;
    if (!isValid) {
      return;
    }

    // Eindeutigen Barcode generieren
    final barcode = 'user_created_${DateTime.now().millisecondsSinceEpoch}';

    // Helfer-Funktion, um Text sicher in eine Zahl umzuwandeln
    double? toDouble(String text) => text.isEmpty ? null : double.tryParse(text);

    // Erstelle das FoodItem-Objekt mit den Daten aus den Controllern
    final newItem = FoodItem(
      barcode: barcode,
      name: _nameController.text,
      brand: _brandController.text.isEmpty ? 'Eigenes Produkt' : _brandController.text,
      
      // Pflichtfelder
      calories: int.parse(_caloriesController.text),
      protein: double.parse(_proteinController.text),
      carbs: double.parse(_carbsController.text),
      fat: double.parse(_fatController.text),

      // Optionale Felder
      kj: toDouble(_kjController.text),
      fiber: toDouble(_fiberController.text),
      sugar: toDouble(_sugarController.text),
      salt: toDouble(_saltController.text),
      sodium: toDouble(_sodiumController.text),
      calcium: toDouble(_calciumController.text),
    );

    // Rufe die Datenbank-Methode auf, um das Objekt zu speichern.
    await ProductDatabaseHelper.instance.insertProduct(newItem);

    // Zeige eine Bestätigung an
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.snackbarSaveSuccess(newItem.name))));
      // Navigiere zurück
      Navigator.of(context).pop();
    }
  }

  String? _optionalValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (double.tryParse(value) == null) {
      return 'Bitte gib eine gültige Zahl ein.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createFoodScreenTitle),
        backgroundColor: tdBlack,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.formFieldName),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.validatorPleaseEnterName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(labelText: l10n.formFieldBrand),
                ),
                const SizedBox(height: 24),
                Text(l10n.formSectionMainNutrients, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _caloriesController,
                  decoration: InputDecoration(labelText: l10n.formFieldCalories),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty || double.tryParse(value) == null) {
                      return l10n.validatorPleaseEnterNumber;
                    }
                    return null;
                  },
                ),
                 const SizedBox(height: 12),
                TextFormField(
                  controller: _proteinController,
                  decoration: InputDecoration(labelText: l10n.formFieldProtein),
                  keyboardType: TextInputType.number,
                   validator: (value) {
                    if (value == null || value.isEmpty || double.tryParse(value) == null) {
                      return l10n.validatorPleaseEnterNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _carbsController,
                  decoration: InputDecoration(labelText: l10n.formFieldCarbs),
                  keyboardType: TextInputType.number,
                   validator: (value) {
                    if (value == null || value.isEmpty || double.tryParse(value) == null) {
                      return l10n.validatorPleaseEnterNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fatController,
                  decoration: InputDecoration(labelText: l10n.formFieldFat),
                  keyboardType: TextInputType.number,
                   validator: (value) {
                    if (value == null || value.isEmpty || double.tryParse(value) == null) {
                      return l10n.validatorPleaseEnterNumber;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                Text(l10n.formSectionOptionalNutrients, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _sugarController,
                  decoration: InputDecoration(labelText: l10n.formFieldSugar),
                  keyboardType: TextInputType.number,
                  validator: _optionalValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fiberController,
                  decoration: InputDecoration(labelText: l10n.formFieldFiber),
                  keyboardType: TextInputType.number,
                  validator: _optionalValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _kjController,
                  decoration: InputDecoration(labelText: l10n.formFieldKj),
                  keyboardType: TextInputType.number,
                  validator: _optionalValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _saltController,
                  decoration: InputDecoration(labelText: l10n.formFieldSalt),
                  keyboardType: TextInputType.number,
                  validator: _optionalValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sodiumController,
                  decoration: InputDecoration(labelText: l10n.formFieldSodium),
                  keyboardType: TextInputType.number,
                  validator: _optionalValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _calciumController,
                  decoration: InputDecoration(labelText: l10n.formFieldCalcium),
                  keyboardType: TextInputType.number,
                  validator: _optionalValidator,
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tdBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.buttonSave, style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}