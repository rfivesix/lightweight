// lib/screens/goals_screen.dart (Der umbenannte "Meine Ziele"-Screen)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lightweight/generated/app_localizations.dart';

// KORREKTUR: Der Klassenname wurde zu GoalsScreen geändert
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

// KORREKTUR: Der State-Klassenname wurde zu _GoalsScreenState geändert
class _GoalsScreenState extends State<GoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _waterController = TextEditingController();
  final _heightController = TextEditingController();

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
    _sugarController.dispose();
    _fiberController.dispose();
    _saltController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _heightController.text = (prefs.getInt('userHeight') ?? 180).toString();
      _caloriesController.text =
          (prefs.getInt('targetCalories') ?? 2500).toString();
      _proteinController.text =
          (prefs.getInt('targetProtein') ?? 180).toString();
      _carbsController.text = (prefs.getInt('targetCarbs') ?? 250).toString();
      _fatController.text = (prefs.getInt('targetFat') ?? 80).toString();
      _waterController.text = (prefs.getInt('targetWater') ?? 3000).toString();
      _sugarController.text = (prefs.getInt('targetSugar') ?? 50).toString();
      _fiberController.text = (prefs.getInt('targetFiber') ?? 30).toString();
      _saltController.text = (prefs.getInt('targetSalt') ?? 6).toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('userHeight', int.parse(_heightController.text));
    await prefs.setInt('targetCalories', int.parse(_caloriesController.text));
    await prefs.setInt('targetProtein', int.parse(_proteinController.text));
    await prefs.setInt('targetCarbs', int.parse(_carbsController.text));
    await prefs.setInt('targetFat', int.parse(_fatController.text));
    await prefs.setInt('targetWater', int.parse(_waterController.text));
    await prefs.setInt('targetSugar', int.parse(_sugarController.text));
    await prefs.setInt('targetFiber', int.parse(_fiberController.text));
    await prefs.setInt('targetSalt', int.parse(_saltController.text));

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.snackbarGoalsSaved)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: true,
    elevation: 0,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    scrolledUnderElevation: 0,
    centerTitle: false,
    title: Text(
      "Goals",
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    ),
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
                    Text("Persönliche Daten",
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    _buildSettingsField(
                        controller: _heightController,
                        label: l10n.profileUserHeight),
                    const SizedBox(height: 24),
                    Text(l10n.profileDailyGoals,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    _buildSettingsField(
                        controller: _caloriesController, label: l10n.calories),
                    _buildSettingsField(
                        controller: _proteinController, label: l10n.protein),
                    _buildSettingsField(
                        controller: _carbsController, label: l10n.carbs),
                    _buildSettingsField(
                        controller: _fatController, label: l10n.fat),
                    _buildSettingsField(
                        controller: _waterController, label: l10n.water),
                    const SizedBox(height: 24),
                    Text("Detail-Nährwerte",
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    _buildSettingsField(
                        controller: _sugarController, label: l10n.sugar),
                    _buildSettingsField(
                        controller: _fiberController, label: l10n.fiber),
                    _buildSettingsField(
                        controller: _saltController, label: l10n.salt),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(l10n.buttonSave,
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSettingsField(
      {required TextEditingController controller, required String label}) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty || num.tryParse(value) == null) {
            return l10n.validatorPleaseEnterNumber;
          }
          return null;
        },
      ),
    );
  }
}
