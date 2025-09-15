// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lightweight/generated/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  // Controller für Hauptziele
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _waterController = TextEditingController();
  final _heightController = TextEditingController();
  
  // DOC: NEUE CONTROLLER FÜR WEITERE ZIELE
  final _sugarController = TextEditingController();
  final _fiberController = TextEditingController();
  final _saltController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    _heightController.dispose();
    _sugarController.dispose(); // DOC: Controller freigeben
    _fiberController.dispose(); // DOC: Controller freigeben
    _saltController.dispose();  // DOC: Controller freigeben
    super.dispose();
  }

  // Methode zum Laden der gespeicherten Werte
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Persönliche Daten
      _heightController.text = (prefs.getInt('userHeight') ?? 180).toString();
      
      // Hauptziele
      _caloriesController.text = (prefs.getInt('targetCalories') ?? 2500).toString();
      _proteinController.text = (prefs.getInt('targetProtein') ?? 180).toString();
      _carbsController.text = (prefs.getInt('targetCarbs') ?? 250).toString();
      _fatController.text = (prefs.getInt('targetFat') ?? 80).toString();
      _waterController.text = (prefs.getInt('targetWater') ?? 3000).toString();

      // DOC: ZIELE FÜR SEKUNDÄR-NÄHRWERTE LADEN (Standardwert 0 oder z.B. 50, 30, 6)
      _sugarController.text = (prefs.getInt('targetSugar') ?? 50).toString();
      _fiberController.text = (prefs.getInt('targetFiber') ?? 30).toString();
      _saltController.text = (prefs.getInt('targetSalt') ?? 6).toString();

      _isLoading = false;
    });
  }

  // Methode zum Speichern der neuen Werte
  Future<void> _saveSettings() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    
    // Persönliche Daten speichern
    await prefs.setInt('userHeight', int.parse(_heightController.text));

    // Hauptziele speichern
    await prefs.setInt('targetCalories', int.parse(_caloriesController.text));
    await prefs.setInt('targetProtein', int.parse(_proteinController.text));
    await prefs.setInt('targetCarbs', int.parse(_carbsController.text));
    await prefs.setInt('targetFat', int.parse(_fatController.text));
    await prefs.setInt('targetWater', int.parse(_waterController.text));

    // DOC: ZIELE FÜR SEKUNDÄR-NÄHRWERTE SPEICHERN
    await prefs.setInt('targetSugar', int.parse(_sugarController.text));
    await prefs.setInt('targetFiber', int.parse(_fiberController.text));
    await prefs.setInt('targetSalt', int.parse(_saltController.text));

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackbarGoalsSaved)),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.profileScreenTitle),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Persönliche Daten", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    _buildSettingsField(controller: _heightController, label: l10n.profileUserHeight),
                    
                    const SizedBox(height: 24),

                    Text(l10n.profileDailyGoals, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    _buildSettingsField(controller: _caloriesController, label: l10n.calories),
                    _buildSettingsField(controller: _proteinController, label: l10n.protein),
                    _buildSettingsField(controller: _carbsController, label: l10n.carbs),
                    _buildSettingsField(controller: _fatController, label: l10n.fat),
                    _buildSettingsField(controller: _waterController, label: l10n.water),

                    const SizedBox(height: 24),
                    Text("Detail-Nährwerte", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    // DOC: NEUE FELDER
                    _buildSettingsField(controller: _sugarController, label: l10n.sugar),
                    _buildSettingsField(controller: _fiberController, label: l10n.fiber),
                    _buildSettingsField(controller: _saltController, label: l10n.salt),
                    
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary, 
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16)
                      ),
                      child: Text(l10n.buttonSave, style: const TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helfer-Widget bleibt unverändert
  Widget _buildSettingsField({required TextEditingController controller, required String label}) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty || num.tryParse(value) == null) { // num.tryParse erlaubt auch Dezimalzahlen
            return l10n.validatorPleaseEnterNumber;
          }
          return null;
        },
      ),
    );
  }
}