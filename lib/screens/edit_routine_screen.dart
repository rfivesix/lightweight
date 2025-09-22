// lib/screens/edit_routine_screen.dart (Final & De-Materialisiert)

import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/models/routine.dart';
import 'package:lightweight/models/routine_exercise.dart';
import 'package:lightweight/models/set_template.dart';
import 'package:lightweight/screens/exercise_catalog_screen.dart';
import 'package:lightweight/screens/exercise_detail_screen.dart';
import 'package:lightweight/util/design_constants.dart';
// Zum Starten der Routine
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/widgets/set_type_chip.dart';
// HINZUGEFÜGT
import 'package:lightweight/widgets/wger_attribution_widget.dart'; // HINZUGEFÜGT

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
  // HINZUGEFÜGT: Für die Animation der Übungsblöcke (eingeklappt beim Drag)
  final Map<int, bool> _exerciseExpanded = {};

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
    final routineWithExercises =
        await WorkoutDatabaseHelper.instance.getRoutineById(_routineId!);
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
          _weightControllers[st.id!] =
              TextEditingController(text: st.targetWeight?.toString() ?? '');
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
        MaterialPageRoute(
            builder: (context) =>
                const ExerciseCatalogScreen(isSelectionMode: true)));

    if (selectedExercise != null && _routineId != null) {
      // KORREKTUR: Lade nicht die ganze Liste neu. Füge nur die neue Übung zum lokalen State hinzu.
      final newRoutineExercise = await WorkoutDatabaseHelper.instance
          .addExerciseToRoutine(_routineId!, selectedExercise.id!);
      if (newRoutineExercise != null) {
        // Erstelle die Controller für die neuen Sätze
        for (var st in newRoutineExercise.setTemplates) {
          _repsControllers[st.id!] = TextEditingController(text: st.targetReps);
          _weightControllers[st.id!] =
              TextEditingController(text: st.targetWeight?.toString() ?? '');
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.validatorPleaseEnterRoutineName)));
      }
      return false;
    }

    int? currentRoutineId = _routineId;

    if (_isNewRoutine) {
      final newRoutine = await WorkoutDatabaseHelper.instance
          .createRoutine(_nameController.text.trim());
      currentRoutineId = newRoutine.id;
      if (mounted) {
        setState(() {
          _routineId = newRoutine.id;
          _isNewRoutine = false;
          _originalName = newRoutine.name;
        });
      }
      if (mounted && !isAddingExercise) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineCreated)));
      }
    } else {
      if (_nameController.text.trim() != _originalName) {
        await WorkoutDatabaseHelper.instance
            .updateRoutineName(currentRoutineId!, _nameController.text.trim());
      }
    }

    // KORREKTUR: Robuste Speicherlogik für Sätze
    final db = WorkoutDatabaseHelper.instance;
    for (var re in _routineExercises) {
      // 1. Sammle den aktuellen Zustand der Sätze aus den Controllern
      final List<SetTemplate> currentTemplates = [];
      for (var set in re.setTemplates) {
        currentTemplates.add(set.copyWith(
            targetReps: _repsControllers[set.id!]?.text,
            targetWeight: double.tryParse(
                _weightControllers[set.id!]!.text.replaceAll(',', '.'))));
      }
      // 2. Ersetze alle Sätze in der DB mit dem aktuellen Zustand
      await db.replaceSetTemplatesForExercise(re.id!, currentTemplates);
    }

    if (mounted && !isAddingExercise) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineSaved)));
      Navigator.of(context).pop(true);
    }
    return true;
  }

  // --- NEUE METHODEN FÜR DIE DIREKTE BEARBEITUNG ---
  void _addSet(RoutineExercise routineExercise) {
    setState(() {
      final newSet = SetTemplate(
          id: DateTime.now().millisecondsSinceEpoch,
          setType: 'normal',
          targetReps: '8-12');
      routineExercise.setTemplates.add(newSet);
      _repsControllers[newSet.id!] =
          TextEditingController(text: newSet.targetReps);
      _weightControllers[newSet.id!] = TextEditingController();
    });
  }

  void _removeSet(
      RoutineExercise routineExercise, int setTemplateId, int index) {
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
      final re = _routineExercises
          .firstWhere((re) => re.setTemplates.contains(setTemplate));
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
            ListTile(
                title: const Text('Normal'),
                onTap: () => _changeSetType(setTemplate, 'normal')),
            ListTile(
                title: const Text('Warmup'),
                onTap: () => _changeSetType(setTemplate, 'warmup')),
            ListTile(
                title: const Text('Failure'),
                onTap: () => _changeSetType(setTemplate, 'failure')),
            ListTile(
                title: const Text('Dropset'),
                onTap: () => _changeSetType(setTemplate, 'dropset')),
          ],
        );
      },
    );
  }

  // NEUE METHODE: Zeigt den Dialog zum Bearbeiten der Pausenzeit
  void _editPauseTime(RoutineExercise routineExercise) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
        text: routineExercise.pauseSeconds?.toString() ?? '');

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
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () {
                final seconds = int.tryParse(controller.text);
                Navigator.of(ctx).pop(seconds);
              },
              child: Text(l10n.save)),
        ],
      ),
    );

    if (result != null) {
      await WorkoutDatabaseHelper.instance
          .updatePauseTime(routineExercise.id!, result);
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
        content: Text(l10n.deleteExerciseConfirmContent(
            exerciseToDelete.exercise.getLocalizedName(context))),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.delete)),
        ],
      ),
    );

    if (confirmed == true && _routineId != null) {
      await WorkoutDatabaseHelper.instance
          .removeExerciseFromRoutine(exerciseToDelete.id!);
      _loadExercisesForRoutine();
    }
  }

  // KORREKTUR: onReorder-Logik für Drag-Feedback
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final RoutineExercise item = _routineExercises.removeAt(oldIndex);
      _routineExercises.insert(newIndex, item);
    });
    if (_routineId != null) {
      WorkoutDatabaseHelper.instance
          .updateExerciseOrder(_routineId!, _routineExercises);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          _isNewRoutine ? l10n.titleNewRoutine : l10n.titleEditRoutine,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => _saveRoutine(),
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
      body: Column(
        children: [
          Padding(
            padding: DesignConstants.screenPadding,
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.formFieldRoutineName),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.validatorPleaseEnterRoutineName;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.onSurfaceVariant.withOpacity(0.1),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _routineExercises.isEmpty
                    ? Center(
                        child: Text(
                          l10n.emptyStateAddFirstExercise,
                          style: textTheme.titleMedium,
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: DesignConstants.cardMargin,
                        itemCount: _routineExercises.length,
                        proxyDecorator: (Widget child, int index,
                            Animation<double> animation) {
                          return Material(
                            elevation: 4.0,
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: child,
                          );
                        },
                        onReorder: _onReorder,
                        itemBuilder: (context, index) {
                          final routineExercise = _routineExercises[index];

                          // KORREKTUR: SummaryCard wurde entfernt
                          return Container(
                            key: ValueKey(routineExercise.id),
                            color: Theme.of(context).scaffoldBackgroundColor,
                            margin: DesignConstants.cardMargin,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  title: InkWell(
                                    onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ExerciseDetailScreen(
                                                    exercise: routineExercise
                                                        .exercise))),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Text(
                                          routineExercise.exercise
                                              .getLocalizedName(context),
                                          style: textTheme.titleLarge),
                                    ),
                                  ),
                                  leading: ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.timer_outlined),
                                        tooltip: l10n.editPauseTime,
                                        onPressed: () =>
                                            _editPauseTime(routineExercise),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.redAccent),
                                        tooltip: l10n.removeExercise,
                                        onPressed: () => _deleteSingleExercise(
                                            routineExercise),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.1),
                                    indent: 16,
                                    endIndent: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (routineExercise.pauseSeconds !=
                                              null &&
                                          routineExercise.pauseSeconds! > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 12.0, bottom: 12.0),
                                          child: Text(
                                            l10n.pauseDuration(
                                                routineExercise.pauseSeconds!),
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                    color: Colors.grey[600],
                                                    fontStyle:
                                                        FontStyle.italic),
                                          ),
                                        ),
                                      Row(
                                        children: [
                                          _buildHeader(l10n.setLabel),
                                          const Spacer(),
                                          _buildHeader(l10n.kgLabel),
                                          _buildHeader(l10n.repsLabel),
                                          const SizedBox(width: 48),
                                        ],
                                      ),
                                      const Divider(),
                                      ...routineExercise.setTemplates
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final setIndex = entry.key;
                                        final setTemplate = entry.value;
                                        return _buildSetTemplateRow(
                                            setIndex + 1,
                                            routineExercise,
                                            setTemplate,
                                            setIndex);
                                      }),
                                      const SizedBox(
                                          height: DesignConstants.spacingS),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _addSet(routineExercise),
                                        icon: const Icon(Icons.add),
                                        label: Text(l10n.addSetButton),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
            child: WgerAttributionWidget(
              textStyle: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      floatingActionButton: GlassFab(
        onPressed: _addExercises,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSetTemplateRow(
      int setIndex, RoutineExercise re, SetTemplate template, int listIndex) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SetTypeChip(
              setType: template.setType,
              setIndex: (template.setType == 'warmup') ? null : setIndex,
              onTap: () => _showSetTypePicker(template),
            ),
          ),
          const Spacer(),
          Expanded(
              flex: 3,
              child: TextFormField(
                controller: _weightControllers[template.id!],
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(hintText: l10n.kgLabelShort, isDense: true),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value.replaceAll(',', '.')) == null) {
                    return "!";
                  }
                  return null;
                },
              )),
          const SizedBox(width: 8),
          Expanded(
              flex: 3,
              child: TextFormField(
                controller: _repsControllers[template.id!],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    hintText: l10n.set_reps_hint, isDense: true),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      int.tryParse(value) == null) {
                    return "!";
                  }
                  return null;
                },
              )),
          SizedBox(
              width: 48,
              child: IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _removeSet(re, template.id!, listIndex))),
        ],
      ),
    );
  }

  Widget _buildHeader(String text) => Expanded(
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold)));
}
