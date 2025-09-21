// lib/screens/exercise_mapping_screen.dart
import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/screens/exercise_catalog_screen.dart';
import 'package:lightweight/util/mapping_prefs.dart';

class ExerciseMappingScreen extends StatefulWidget {
  final List<String> unknownNames;
  const ExerciseMappingScreen({super.key, required this.unknownNames});

  @override
  State<ExerciseMappingScreen> createState() => _ExerciseMappingScreenState();
}

class _ExerciseMappingScreenState extends State<ExerciseMappingScreen> {
  final Map<String, Exercise> _selection = {};
  bool _applying = false;

  Future<void> _pickTarget(String sourceName) async {
    final Exercise? picked = await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExerciseCatalogScreen(isSelectionMode: true)),
    );
    if (picked != null && mounted) {
      setState(() => _selection[sourceName] = picked);
    }
  }

  Future<void> _apply() async {
    if (_selection.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _applying = true);
    final mapping = <String, String>{
      for (final e in _selection.entries)
        e.key: (e.value.nameEn.isNotEmpty ? e.value.nameEn : e.value.nameDe),
    };
// NEU: persistent speichern
    await MappingPrefs.upsert(mapping); // <— hinzufügen
// Bestehendes: DB-Update anwenden
    await WorkoutDatabaseHelper.instance.applyExerciseNameMapping(mapping);
    if (mounted) {
      setState(() => _applying = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Übungen zuordnen')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: widget.unknownNames.length,
              itemBuilder: (context, index) {
                final src = widget.unknownNames[index];
                final picked = _selection[src];
                return ListTile(
                  title: Text(src),
                  subtitle: picked == null
                      ? const Text('Keine Auswahl')
                      : Text('→ ${picked.nameDe} / ${picked.nameEn}'),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Auswählen'),
                    onPressed: () => _pickTarget(src),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _applying ? null : _apply,
                  icon: _applying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(
                      _applying ? 'Wird angewendet...' : 'Zuordnung anwenden'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
