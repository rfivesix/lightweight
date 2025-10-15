// lib/screens/create_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/util/design_constants.dart';

class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key});
  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  // State-Variablen für die getrennten Logiken
  List<String> _allCategories = []; // Für das Autocomplete-Feld
  List<String> _allMuscleGroups = []; // Für die Chip-Auswahl
  final List<String> _selectedPrimaryMuscles = [];
  final List<String> _selectedSecondaryMuscles = [];
  bool _isLoading = true;

  late final l10n = AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // Lädt BEIDE Listen: Kategorien und alle einzelnen Muskeln
  Future<void> _loadData() async {
    final db = WorkoutDatabaseHelper.instance;
    final categories = await db.getAllCategories();
    final muscles = await db.getAllMuscleGroups();
    if (mounted) {
      setState(() {
        _allCategories = categories;
        _allMuscleGroups = muscles;
        _isLoading = false;
      });
    }
  }

  void _saveExercise() async {
    if (_formKey.currentState!.validate()) {
      final newExercise = Exercise(
        nameDe: _nameController.text.trim(),
        nameEn: _nameController.text.trim(),
        descriptionDe: _descriptionController.text.trim(),
        descriptionEn: _descriptionController.text.trim(),
        // Getrennte Zuweisung der Daten
        categoryName: _categoryController.text.trim(),
        primaryMuscles: _selectedPrimaryMuscles,
        secondaryMuscles: _selectedSecondaryMuscles,
      );

      await WorkoutDatabaseHelper.instance.insertExercise(newExercise);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.create_exercise_screen_title),
        actions: [
          TextButton(
            onPressed: _saveExercise,
            child: Text(
              l10n.save,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.exercise_name_label,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? l10n.validatorPleaseEnterName
                              : null,
                    ),
                    const SizedBox(height: DesignConstants.spacingL),

                    // Feld für die Kategorie (z.B. "Chest")
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return _allCategories.where((String option) {
                          return option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              );
                        });
                      },
                      onSelected: (String selection) {
                        _categoryController.text = selection;
                      },
                      fieldViewBuilder: (
                        context,
                        textEditingController,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        _categoryController.value = textEditingController.value;
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: l10n.category_label,
                            hintText: l10n.categoryHint,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.validatorPleaseEnterCategory;
                            }
                            return null;
                          },
                        );
                      },
                    ),

                    const SizedBox(height: DesignConstants.spacingL),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.description_optional_label,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: DesignConstants.spacingXL),

                    // Auswahl für primäre Muskeln (z.B. "Pectoralis Major")
                    _buildMuscleSelection(
                      title: l10n.primary_muscles_label,
                      allMuscles: _allMuscleGroups,
                      selectedMuscles: _selectedPrimaryMuscles,
                    ),
                    const SizedBox(height: DesignConstants.spacingXL),

                    // Auswahl für sekundäre Muskeln
                    _buildMuscleSelection(
                      title: l10n.secondary_muscles_label,
                      allMuscles: _allMuscleGroups,
                      selectedMuscles: _selectedSecondaryMuscles,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMuscleSelection({
    required String title,
    required List<String> allMuscles,
    required List<String> selectedMuscles,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: DesignConstants.spacingS),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: allMuscles.map((muscle) {
            final isSelected = selectedMuscles.contains(muscle);
            return FilterChip(
              label: Text(muscle),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedMuscles.add(muscle);
                  } else {
                    selectedMuscles.remove(muscle);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
