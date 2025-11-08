// lib/screens/edit_routine_screen.dart (Final & De-Materialisiert - Endgültig)

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
import 'package:lightweight/widgets/global_app_bar.dart';
import 'package:lightweight/widgets/set_type_chip.dart';
// HINZUGEFÜGT
import 'package:lightweight/widgets/wger_attribution_widget.dart'; // HINZUGEFÜGT
import 'package:lightweight/widgets/workout_card.dart'; // NEUER IMPORT

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
          _weightControllers[st.id!] = TextEditingController(
            text: st.targetWeight?.toString() ?? '',
          );
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
            const ExerciseCatalogScreen(isSelectionMode: true),
      ),
    );

    if (selectedExercise != null && _routineId != null) {
      final newRoutineExercise = await WorkoutDatabaseHelper.instance
          .addExerciseToRoutine(_routineId!, selectedExercise.id!);
      if (newRoutineExercise != null) {
        for (var st in newRoutineExercise.setTemplates) {
          _repsControllers[st.id!] = TextEditingController(text: st.targetReps);
          _weightControllers[st.id!] = TextEditingController(
            text: st.targetWeight?.toString() ?? '',
          );
        }
        setState(() {
          // KORREKTUR: Erstelle eine neue Liste, um den Rebuild des Widgets zu erzwingen.
          _routineExercises = [..._routineExercises, newRoutineExercise];
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
          SnackBar(content: Text(l10n.validatorPleaseEnterRoutineName)),
        );
      }
      return false;
    }

    int? currentRoutineId = _routineId;

    if (_isNewRoutine) {
      final newRoutine = await WorkoutDatabaseHelper.instance.createRoutine(
        _nameController.text.trim(),
      );
      currentRoutineId = newRoutine.id;
      if (mounted) {
        setState(() {
          _routineId = newRoutine.id;
          _isNewRoutine = false;
          _originalName = newRoutine.name;
        });
      }
      if (mounted && !isAddingExercise) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineCreated)));
      }
    } else {
      if (_nameController.text.trim() != _originalName) {
        await WorkoutDatabaseHelper.instance.updateRoutineName(
          currentRoutineId!,
          _nameController.text.trim(),
        );
      }
    }

    final db = WorkoutDatabaseHelper.instance;
    for (var re in _routineExercises) {
      final List<SetTemplate> currentTemplates = [];
      for (var set in re.setTemplates) {
        currentTemplates.add(
          set.copyWith(
            targetReps: _repsControllers[set.id!]?.text,
            targetWeight: double.tryParse(
              _weightControllers[set.id!]!.text.replaceAll(',', '.'),
            ),
          ),
        );
      }
      await db.replaceSetTemplatesForExercise(re.id!, currentTemplates);
    }

    if (mounted && !isAddingExercise) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineSaved)));
      Navigator.of(context).pop(true);
    }
    return true;
  }

  void _addSet(RoutineExercise routineExercise) {
    setState(() {
      final newSet = SetTemplate(
        id: DateTime.now().millisecondsSinceEpoch,
        setType: 'normal',
        targetReps: '8-12',
      );

      // --- START FIX ---
      final exerciseIndex = _routineExercises.indexOf(routineExercise);
      if (exerciseIndex == -1) return; // Safety check

      final updatedTemplates = [...routineExercise.setTemplates, newSet];
      final updatedExercise = RoutineExercise(
        id: routineExercise.id,
        exercise: routineExercise.exercise,
        setTemplates: updatedTemplates,
        pauseSeconds: routineExercise.pauseSeconds,
      );
      _routineExercises[exerciseIndex] = updatedExercise;
      // --- END FIX ---

      _repsControllers[newSet.id!] = TextEditingController(
        text: newSet.targetReps,
      );
      _weightControllers[newSet.id!] = TextEditingController();
    });
  }

  void _removeSet(
    RoutineExercise routineExercise,
    int setTemplateId,
    int index,
  ) {
    setState(() {
      // --- START FIX ---
      final exerciseIndex = _routineExercises.indexOf(routineExercise);
      if (exerciseIndex == -1) return;

      final updatedTemplates = [...routineExercise.setTemplates];
      updatedTemplates.removeAt(index);

      final updatedExercise = RoutineExercise(
        id: routineExercise.id,
        exercise: routineExercise.exercise,
        setTemplates: updatedTemplates,
        pauseSeconds: routineExercise.pauseSeconds,
      );
      _routineExercises[exerciseIndex] = updatedExercise;
      // --- END FIX ---

      _repsControllers.remove(setTemplateId)?.dispose();
      _weightControllers.remove(setTemplateId)?.dispose();
    });
  }

  void _changeSetType(SetTemplate setTemplate, String newType) {
    setState(() {
      final reIndex = _routineExercises.indexWhere(
        (re) => re.setTemplates.contains(setTemplate),
      );
      if (reIndex == -1) return;

      final routineExercise = _routineExercises[reIndex];
      final setIndex = routineExercise.setTemplates.indexOf(setTemplate);
      if (setIndex == -1) return;

      // --- START FIX ---
      final updatedTemplates = [...routineExercise.setTemplates];
      updatedTemplates[setIndex] = setTemplate.copyWith(setType: newType);

      _routineExercises[reIndex] = RoutineExercise(
        id: routineExercise.id,
        exercise: routineExercise.exercise,
        setTemplates: updatedTemplates,
        pauseSeconds: routineExercise.pauseSeconds,
      );
      // --- END FIX ---
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
              onTap: () => _changeSetType(setTemplate, 'normal'),
            ),
            ListTile(
              title: const Text('Warmup'),
              onTap: () => _changeSetType(setTemplate, 'warmup'),
            ),
            ListTile(
              title: const Text('Failure'),
              onTap: () => _changeSetType(setTemplate, 'failure'),
            ),
            ListTile(
              title: const Text('Dropset'),
              onTap: () => _changeSetType(setTemplate, 'dropset'),
            ),
          ],
        );
      },
    );
  }

  void _editPauseTime(RoutineExercise routineExercise) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: routineExercise.pauseSeconds?.toString() ?? '',
    );

    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editPauseTimeTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.pauseInSeconds),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final seconds = int.tryParse(controller.text);
              Navigator.of(ctx).pop(seconds);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null) {
      await WorkoutDatabaseHelper.instance.updatePauseTime(
        routineExercise.id!,
        result,
      );
      _loadExercisesForRoutine();
    }
  }

  void _deleteSingleExercise(RoutineExercise exerciseToDelete) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteExerciseConfirmTitle),
        content: Text(
          l10n.deleteExerciseConfirmContent(
            exerciseToDelete.exercise.getLocalizedName(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && _routineId != null) {
      await WorkoutDatabaseHelper.instance.removeExerciseFromRoutine(
        exerciseToDelete.id!,
      );
      _loadExercisesForRoutine();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final RoutineExercise item = _routineExercises.removeAt(oldIndex);
      _routineExercises.insert(newIndex, item);
    });
    if (_routineId != null) {
      WorkoutDatabaseHelper.instance.updateExerciseOrder(
        _routineId!,
        _routineExercises,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(
        title: _isNewRoutine ? l10n.titleNewRoutine : l10n.titleEditRoutine,
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
            padding: DesignConstants.cardPadding.copyWith(
              top: DesignConstants.cardPadding.top + topPadding,
            ),
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
                        padding: EdgeInsets.zero,
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

                          return WorkoutCard(
                            key: ValueKey(routineExercise.id),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  title: InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExerciseDetailScreen(
                                          exercise: routineExercise.exercise,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Text(
                                        routineExercise.exercise
                                            .getLocalizedName(
                                          context,
                                        ),
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: l10n.removeExercise,
                                        onPressed: () => _deleteSingleExercise(
                                            routineExercise),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (routineExercise.pauseSeconds !=
                                              null &&
                                          routineExercise.pauseSeconds! > 0)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            12,
                                            16,
                                            12,
                                          ),
                                          child: Text(
                                            l10n.pauseDuration(
                                              routineExercise.pauseSeconds!,
                                            ),
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      Row(
                                        children: [
                                          _buildHeader(l10n.setLabel, flex: 2),
                                          const Spacer(flex: 3),
                                          _buildHeader(l10n.kgLabel, flex: 2),
                                          const SizedBox(width: 8),
                                          _buildHeader(l10n.repsLabel, flex: 2),
                                          const SizedBox(width: 48),
                                        ],
                                      ),
                                      ...routineExercise.setTemplates
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final setIndex = entry.key;
                                        final setTemplate = entry.value;

                                        // HIER IST DIE NEUE LOGIK
                                        int workingSetIndex = 0;
                                        for (int i = 0; i <= setIndex; i++) {
                                          if (routineExercise
                                                  .setTemplates[i].setType !=
                                              'warmup') {
                                            workingSetIndex++;
                                          }
                                        }

                                        return _buildSetTemplateRow(
                                          workingSetIndex,
                                          setIndex,
                                          routineExercise,
                                          setTemplate,
                                          setIndex,
                                        );
                                      }),
                                      const SizedBox(
                                        height: DesignConstants.spacingS,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                        ),
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _addSet(routineExercise),
                                          icon: const Icon(Icons.add),
                                          label: Text(l10n.addSetButton),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
      // KORRIGIERT: label hinzugefügt
      floatingActionButton: GlassFab(
        label: l10n.fabAddExercise,
        onPressed: _addExercises,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSetTemplateRow(
    int setIndex,
    int rowIndex,
    RoutineExercise re,
    SetTemplate template,
    int listIndex,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool isColoredRow = rowIndex > 0 && rowIndex.isOdd;

    final Color rowColor;
    if (isColoredRow) {
      rowColor = isLightMode
          ? Colors.grey.withOpacity(0.08)
          : Colors.white.withOpacity(0.05);
    } else {
      rowColor = Colors.transparent;
    }

    return Container(
      color: rowColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: SetTypeChip(
                  setType: template.setType,
                  setIndex: (template.setType == 'warmup') ? null : setIndex,
                  onTap: () => _showSetTypePicker(template),
                ),
              ),
            ),
            const Spacer(flex: 3),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _weightControllers[template.id!],
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  fillColor: Colors.transparent,
                  hintText: l10n.kgLabelShort,
                ),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value.replaceAll(',', '.')) == null) {
                    return "!";
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _repsControllers[template.id!],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  fillColor: Colors.transparent,
                  hintText: l10n.set_reps_hint,
                ),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      int.tryParse(value) == null) {
                    return "!";
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 48,
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _removeSet(re, template.id!, listIndex),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
