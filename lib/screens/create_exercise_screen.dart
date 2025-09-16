// lib/screens/create_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/generated/app_localizations.dart';

class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key});
  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _primaryMusclesController = TextEditingController();
  final _secondaryMusclesController = TextEditingController();

  final List<String> _categories = ["Kraft", "Cardio", "Dehnen", "Sonstiges"];
  late final l10n = AppLocalizations.of(context)!;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _primaryMusclesController.dispose();
    _secondaryMusclesController.dispose();
    super.dispose();
  }

  void _saveExercise() async {
    if (_formKey.currentState!.validate()) {
      final newExercise = Exercise(
        nameDe: _nameController.text, // Speichern als deutscher Name
        nameEn: _nameController.text, // Und auch als englischer Fallback
        descriptionDe: _descriptionController.text,
        descriptionEn: _descriptionController.text,
        categoryName: _selectedCategory,
        primaryMuscles: _primaryMusclesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        secondaryMuscles: _secondaryMusclesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );

      await WorkoutDatabaseHelper.instance.insertExercise(newExercise);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.create_exercise_screen_title),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveExercise,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.exercise_name_label),
                validator: (value) => value == null || value.isEmpty
                    ? "Bitte einen Namen eingeben."
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(labelText: l10n.category_label),
                items: _categories
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(labelText: l10n.description_optional_label),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _primaryMusclesController,
                decoration: InputDecoration(
                    labelText: l10n.primary_muscles_label,
                    hintText: l10n.primary_muscles_hint),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _secondaryMusclesController,
                decoration: InputDecoration(
                    labelText: l10n.secondary_muscles_label,
                    hintText: l10n.secondary_muscles_hint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
