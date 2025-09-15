// lib/screens/edit_routine_screen.dart

import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/models/routine.dart';
import 'package:lightweight/models/routine_exercise.dart';
import 'package:lightweight/models/set_template.dart';
import 'package:lightweight/screens/exercise_detail_screen.dart';
import 'package:lightweight/widgets/set_type_chip.dart';
import 'package:lightweight/widgets/wger_attribution_widget.dart';
import 'exercise_catalog_screen.dart';

class EditRoutineScreen extends StatefulWidget {
  final Routine? routine;
  const EditRoutineScreen({super.key, this.routine});

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  final _nameController = TextEditingController();
  List<RoutineExercise> _routineExercises = [];
  bool _isNewRoutine = true;
  int? _routineId;
  String _originalName = '';
  bool _isLoading = false;
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _isNewRoutine = false;
      _routineId = widget.routine!.id;
      _nameController.text = widget.routine!.name;
      _originalName = widget.routine!.name;
      _loadExercisesForRoutine();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _repsControllers.values) {
      c.dispose();
    }
    for (var c in _weightControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExercisesForRoutine() async {
    if (_routineId == null) return;
    setState(() => _isLoading = true);
    final routineWithExercises = await WorkoutDatabaseHelper.instance.getRoutineById(_routineId!);
    if (mounted && routineWithExercises != null) {
      // Bereinige alte Controller, bevor neue erstellt werden
      for (var c in _repsControllers.values) {
        c.dispose();
      }
      for (var c in _weightControllers.values) {
        c.dispose();
      }
      _repsControllers.clear();
      _weightControllers.clear();
      
      for (var re in routineWithExercises.exercises) {
        for (var st in re.setTemplates) {
          _repsControllers[st.id!] = TextEditingController(text: st.targetReps);
          _weightControllers[st.id!] = TextEditingController(text: st.targetWeight?.toString() ?? '');
        }
      }

      setState(() {
        _routineExercises = routineWithExercises.exercises;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addExercises() async {
    if (_isNewRoutine) {
      final success = await _saveRoutine(isAddingExercise: true);
      if (!success) return;
    }
    if (!mounted) return;
    final selectedExercise = await Navigator.of(context).push<Exercise>(
        MaterialPageRoute(builder: (context) => const ExerciseCatalogScreen(isSelectionMode: true)));
    
    if (selectedExercise != null && _routineId != null) {
      // KORREKTUR: Lade nicht die ganze Liste neu. Füge nur die neue Übung zum lokalen State hinzu.
      final newRoutineExercise = await WorkoutDatabaseHelper.instance.addExerciseToRoutine(_routineId!, selectedExercise.id!);
      if (newRoutineExercise != null) {
        // Erstelle die Controller für die neuen Sätze
        for (var st in newRoutineExercise.setTemplates) {
          _repsControllers[st.id!] = TextEditingController(text: st.targetReps);
          _weightControllers[st.id!] = TextEditingController(text: st.targetWeight?.toString() ?? '');
        }
        setState(() {
          _routineExercises.add(newRoutineExercise);
        });
      }
    }
  }

Future<bool> _saveRoutine({bool isAddingExercise = false}) async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.validatorPleaseEnterRoutineName)));
      return false;
    }

    int? currentRoutineId = _routineId;

    if (_isNewRoutine) {
      final newRoutine = await WorkoutDatabaseHelper.instance.createRoutine(_nameController.text.trim());
      currentRoutineId = newRoutine.id;
      if (mounted) {
        setState(() {
          _routineId = newRoutine.id;
          _isNewRoutine = false;
          _originalName = newRoutine.name;
        });
      }
      if (mounted && !isAddingExercise) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineCreated)));
    } else {
      if (_nameController.text.trim() != _originalName) {
        await WorkoutDatabaseHelper.instance.updateRoutineName(currentRoutineId!, _nameController.text.trim());
      }
    }
    
    // KORREKTUR: Robuste Speicherlogik für Sätze
    final db = WorkoutDatabaseHelper.instance;
    for (var re in _routineExercises) {
      // 1. Sammle den aktuellen Zustand der Sätze aus den Controllern
      final List<SetTemplate> currentTemplates = [];
      for(var set in re.setTemplates) {
        currentTemplates.add(set.copyWith(
          targetReps: _repsControllers[set.id!]?.text,
          targetWeight: double.tryParse(_weightControllers[set.id!]!.text.replaceAll(',', '.'))
        ));
      }
      // 2. Ersetze alle Sätze in der DB mit dem aktuellen Zustand
      await db.replaceSetTemplatesForExercise(re.id!, currentTemplates);
    }

    if (mounted && !isAddingExercise) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineSaved)));
      Navigator.of(context).pop(true);
    }
    return true;
  }

  // --- NEUE METHODEN FÜR DIE DIREKTE BEARBEITUNG ---
  void _addSet(RoutineExercise routineExercise) {
    setState(() {
      final newSet = SetTemplate(id: DateTime.now().millisecondsSinceEpoch, setType: 'normal', targetReps: '8-12');
      routineExercise.setTemplates.add(newSet);
      _repsControllers[newSet.id!] = TextEditingController(text: newSet.targetReps);
      _weightControllers[newSet.id!] = TextEditingController();
    });
  }

  void _removeSet(RoutineExercise routineExercise, int setTemplateId, int index) {
    setState(() {
      routineExercise.setTemplates.removeAt(index);
      _repsControllers.remove(setTemplateId)?.dispose();
      _weightControllers.remove(setTemplateId)?.dispose();
      // TODO: Markiere für späteres Löschen aus DB in _saveRoutine
      // _setsToDelete.add(setTemplateId);
    });
  }

  void _changeSetType(SetTemplate setTemplate, String newType) {
    setState(() {
      // Da SetTemplate immutable ist, müssen wir die Liste modifizieren
      final re = _routineExercises.firstWhere((re) => re.setTemplates.contains(setTemplate));
      final setIndex = re.setTemplates.indexOf(setTemplate);
      re.setTemplates[setIndex] = setTemplate.copyWith(setType: newType);
    });
    Navigator.pop(context);
  }

  void _showSetTypePicker(SetTemplate setTemplate) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(title: const Text('Normal'), onTap: () => _changeSetType(setTemplate, 'normal')),
            ListTile(title: const Text('Warmup'), onTap: () => _changeSetType(setTemplate, 'warmup')),
            ListTile(title: const Text('Failure'), onTap: () => _changeSetType(setTemplate, 'failure')),
            ListTile(title: const Text('Dropset'), onTap: () => _changeSetType(setTemplate, 'dropset')),
          ],
        );
      },
    );
  }

  // NEUE METHODE: Zeigt den Dialog zum Bearbeiten der Pausenzeit
  void _editPauseTime(RoutineExercise routineExercise) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: routineExercise.pauseSeconds?.toString() ?? '');

    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editPauseTimeTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.pauseInSeconds,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
          FilledButton(onPressed: () {
            final seconds = int.tryParse(controller.text);
            Navigator.of(ctx).pop(seconds);
          }, child: Text(l10n.save)),
        ],
      ),
    );

    if (result != null) {
      await WorkoutDatabaseHelper.instance.updatePauseTime(routineExercise.id!, result);
      _loadExercisesForRoutine(); // Lade neu, um die Anzeige zu aktualisieren
    }
  }

  // NEUE METHODE: Kapselt die Logik zum Löschen einer Übung
  void _deleteSingleExercise(RoutineExercise exerciseToDelete) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteExerciseConfirmTitle),
        content: Text(l10n.deleteExerciseConfirmContent(exerciseToDelete.exercise.getLocalizedName(context))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );

    if (confirmed == true && _routineId != null) {
      await WorkoutDatabaseHelper.instance.removeExerciseFromRoutine(exerciseToDelete.id!);
      _loadExercisesForRoutine();
    }
  }

  // NEUE METHODE: Behandelt die Neuanordnung der Übungen
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final RoutineExercise item = _routineExercises.removeAt(oldIndex);
      _routineExercises.insert(newIndex, item);
    });

    // Speichere die neue Reihenfolge sofort in der Datenbank
    if (_routineId != null) {
      WorkoutDatabaseHelper.instance.updateExerciseOrder(_routineId!, _routineExercises);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewRoutine ? l10n.titleNewRoutine : l10n.titleEditRoutine),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _saveRoutine, tooltip: l10n.save)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.formFieldRoutineName),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _routineExercises.isEmpty
                    ? Center(child: Text(l10n.emptyStateAddFirstExercise))
                    // KORREKTUR: ListView.builder wird zu ReorderableListView
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _routineExercises.length,
                        onReorder: _onReorder,
                        itemBuilder: (context, index) {
                          final routineExercise = _routineExercises[index];
                          int workingSetIndex = 0;
                          // WICHTIG: Die Card muss eine eindeutige, stabile Key haben
                          return Card(
                            key: ValueKey(routineExercise.id),
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center, // Bessere vertikale Ausrichtung
                                    children: [
                                      // NEU: Drag Handle zum Verschieben
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: const Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(Icons.drag_handle),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ExerciseDetailScreen(exercise: routineExercise.exercise))),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Text(routineExercise.exercise.getLocalizedName(context), style: Theme.of(context).textTheme.titleLarge),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.timer_outlined),
                                        tooltip: l10n.editPauseTime,
                                        onPressed: () => _editPauseTime(routineExercise),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        tooltip: l10n.removeExercise,
                                        onPressed: () => _deleteSingleExercise(routineExercise),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () => _editPauseTime(routineExercise),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 40.0), // Einrücken für bessere Optik
                                      child: Row(
                                        children: [
                                          Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.pauseDuration(routineExercise.pauseSeconds ?? 0),
                                            style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(children: [_buildHeader(l10n.setLabel), const Spacer(), _buildHeader(l10n.kgLabel), _buildHeader(l10n.repsLabel), const SizedBox(width: 48)]),
                                  const Divider(),
                                  ...routineExercise.setTemplates.asMap().entries.map((entry) {
                                    final setIndex = entry.key;
                                    final setTemplate = entry.value;
                                    if (setTemplate.setType != 'warmup') {
                                      workingSetIndex++;
                                    }
                                    return _buildSetRow(workingSetIndex, routineExercise, setTemplate, setIndex);
                                  }),
                                  const SizedBox(height: 8),
                                  TextButton.icon(onPressed: () => _addSet(routineExercise), icon: const Icon(Icons.add), label: Text(l10n.addSetButton)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const WgerAttributionWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercises,
        label: Text(l10n.fabAddExercise),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(String text) => Expanded(child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)));

  Widget _buildSetRow(int setIndex, RoutineExercise re, SetTemplate template, int listIndex) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            child: SetTypeChip(
              setType: template.setType,
              setIndex: setIndex,
              onTap: () => _showSetTypePicker(template),
            ),
          ),
          const Spacer(),
          Expanded(child: TextFormField(controller: _weightControllers[template.id!], textAlign: TextAlign.center, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: l10n.kgLabelShort, border: InputBorder.none, isDense: true))),
          Expanded(child: TextFormField(controller: _repsControllers[template.id!], textAlign: TextAlign.center, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "8-12", border: InputBorder.none, isDense: true))),
          SizedBox(width: 48, child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _removeSet(re, template.id!, listIndex))),
        ],
      ),
    );
  }
}