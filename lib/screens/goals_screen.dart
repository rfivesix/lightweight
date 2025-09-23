// lib/screens/goals_screen.dart

import 'package:flutter/material.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lightweight/generated/app_localizations.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

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

  double _proteinPercent = 40;
  double _carbsPercent = 40;
  double _fatPercent = 20;

  // KORREKTUR: Farben zentral definieren, passend zum NutritionSummaryWidget
  final Map<String, Color> _macroColors = {
    'protein': Colors.red.shade400,
    'carbs': Colors.green.shade400,
    'fat': Colors.purple.shade300,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _caloriesController.addListener(_recalculateGramsFromSliders);
  }

  @override
  void dispose() {
    _caloriesController.removeListener(_recalculateGramsFromSliders);
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

  void _recalculateGramsFromSliders() {
    final totalCalories = int.tryParse(_caloriesController.text) ?? 0;
    if (totalCalories <= 0) return;

    final proteinGrams = (totalCalories * (_proteinPercent / 100)) / 4;
    final carbsGrams = (totalCalories * (_carbsPercent / 100)) / 4;
    final fatGrams = (totalCalories * (_fatPercent / 100)) / 9;

    _proteinController.text = proteinGrams.round().toString();
    _carbsController.text = carbsGrams.round().toString();
    _fatController.text = fatGrams.round().toString();
  }

  void _updateSliderValues(String changedMacro, double value) {
    setState(() {
      if (changedMacro == 'protein') {
        _proteinPercent = value;
      } else if (changedMacro == 'carbs') {
        _carbsPercent = value;
      } else if (changedMacro == 'fat') {
        _fatPercent = value;
      }

      double sum = _proteinPercent + _carbsPercent + _fatPercent;
      if (sum.round() != 100) {
        double diff = 100 - sum;
        if (changedMacro == 'protein') {
          _carbsPercent += diff / 2;
          _fatPercent += diff / 2;
        } else if (changedMacro == 'carbs') {
          _proteinPercent += diff / 2;
          _fatPercent += diff / 2;
        } else {
          _proteinPercent += diff / 2;
          _carbsPercent += diff / 2;
        }
      }

      // Clamp values between 0 and 100
      _proteinPercent = _proteinPercent.clamp(0, 100);
      _carbsPercent = _carbsPercent.clamp(0, 100);
      _fatPercent = _fatPercent.clamp(0, 100);
    });
    _recalculateGramsFromSliders();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.my_goals,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        // KORREKTUR: Save-Button in die AppBar verschoben
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              l10n.buttonSave,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: DesignConstants.cardPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.personalData,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: DesignConstants.spacingL),
                    _buildSettingsField(
                        controller: _heightController,
                        label: l10n.profileUserHeight),
                    const SizedBox(height: DesignConstants.spacingXL),
                    Text(l10n.profileDailyGoals,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: DesignConstants.spacingL),
                    _buildSettingsField(
                        controller: _caloriesController, label: l10n.calories),
                    const SizedBox(height: DesignConstants.spacingL),
                    _buildMacroCalculator(),
                    const SizedBox(height: DesignConstants.spacingL),
                    _buildSettingsField(
                        controller: _proteinController, label: l10n.protein),
                    _buildSettingsField(
                        controller: _carbsController, label: l10n.carbs),
                    _buildSettingsField(
                        controller: _fatController, label: l10n.fat),
                    _buildSettingsField(
                        controller: _waterController, label: l10n.water),
                    const SizedBox(height: DesignConstants.spacingXL),
                    Text(l10n.detailedNutrientGoals, // HIER DIE ÄNDERUNG
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: DesignConstants.spacingL),
                    _buildSettingsField(
                        controller: _sugarController, label: l10n.sugar),
                    _buildSettingsField(
                        controller: _fiberController, label: l10n.fiber),
                    _buildSettingsField(
                        controller: _saltController, label: l10n.salt),

                    // KORREKTUR: Der untere Button wurde entfernt
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMacroCalculator() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(l10n.macroDistribution,
              style: Theme.of(context).textTheme.titleMedium),
          _buildMacroSliderRow(
              l10n.protein, _proteinPercent, _macroColors['protein']!),
          _buildMacroSliderRow(
              l10n.carbs, _carbsPercent, _macroColors['carbs']!),
          _buildMacroSliderRow(l10n.fat, _fatPercent, _macroColors['fat']!),
        ],
      ),
    );
  }

  // KORREKTUR: Das ist die neue Methode zum Stylen der Slider
  Widget _buildMacroSliderRow(String macro, double value, Color color) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text("${macro.capitalize()}:")),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12.0, // Dicke des Sliders
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8.0), // Kleinerer Kreis
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
              activeTrackColor: color, // Farbe für den aktiven Teil
              inactiveTrackColor: color.withOpacity(0.2), // Hintergrundfarbe
              thumbColor: color, // Farbe des Kreises
              trackShape:
                  const RoundedRectSliderTrackShape(), // Abgerundete Ecken
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              label: '${value.round()}%',
              onChanged: (newValue) {
                _updateSliderValues(macro, newValue);
              },
            ),
          ),
        ),
        SizedBox(
            width: 50,
            child: Text("${value.round()}%", textAlign: TextAlign.right)),
      ],
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
