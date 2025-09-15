// lib/screens/workout_log_detail_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/screens/exercise_detail_screen.dart';
import 'package:lightweight/widgets/set_type_chip.dart';
import 'package:lightweight/widgets/wger_attribution_widget.dart';

class WorkoutLogDetailScreen extends StatefulWidget {
  final int logId;
  const WorkoutLogDetailScreen({super.key, required this.logId});

  @override
  State<WorkoutLogDetailScreen> createState() => _WorkoutLogDetailScreenState();
}

class _WorkoutLogDetailScreenState extends State<WorkoutLogDetailScreen> {
  bool _isLoading = true;
  WorkoutLog? _log;
  Map<String, List<SetLog>> _groupedSets = {};
  Map<String, Exercise> _exerciseDetails = {};
  double _totalVolume = 0.0;
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};
  DateTime? _editedStartTime;
  Map<String, double> _categoryVolume = {};

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    for (var controller in _repsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);

    final data = await WorkoutDatabaseHelper.instance.getWorkoutLogById(widget.logId);
    if (data == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _weightControllers.clear();
    _repsControllers.clear();

    double volume = 0.0;
    final groups = <String, List<SetLog>>{};
    for (var set in data.sets) {
      if (set.weightKg != null && set.reps != null) {
        volume += set.weightKg! * set.reps!;
      }
      groups.putIfAbsent(set.exerciseName, () => []).add(set);
    }

    final Map<String, double> categoryVolume = {};
    for (var set in data.sets) {
      if (set.weightKg != null && set.reps != null) {
        final exercise = await WorkoutDatabaseHelper.instance.getExerciseByName(set.exerciseName);
        if (exercise != null) {
          categoryVolume.update(
            exercise.categoryName,
            (old) => old + (set.weightKg! * set.reps!),
            ifAbsent: () => set.weightKg! * set.reps!,
          );
        }
      }
    }
    _categoryVolume = categoryVolume;

    final tempExerciseDetails = <String, Exercise>{};
    for (var name in groups.keys) {
      final exercise = await WorkoutDatabaseHelper.instance.getExerciseByName(name);
      if (exercise != null) {
        tempExerciseDetails[name] = exercise;
      }
    }

    _notesController.text = data.notes ?? '';
    _editedStartTime = data.startTime;

    if (!mounted) return;

    setState(() {
      _log = data;
      _groupedSets = groups;
      _exerciseDetails = tempExerciseDetails;
      _totalVolume = volume;
      _isLoading = false;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) _loadDetails();
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _editedStartTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_editedStartTime ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _editedStartTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      final l10n = AppLocalizations.of(context)!;
      final dbHelper = WorkoutDatabaseHelper.instance;

      final initialSetIds = _log!.sets.map((s) => s.id!).toSet();
      final currentSetIds = _groupedSets.values.expand((sets) => sets).map((s) => s.id!).toSet();
      final idsToDelete = initialSetIds.difference(currentSetIds).toList();

      final List<SetLog> setsToUpdate = [];
      final List<SetLog> setsToInsert = [];

      for (final setGroup in _groupedSets.values) {
        for (final setLog in setGroup) {
          final weight = double.tryParse(_weightControllers[setLog.id!]?.text.replaceAll(',', '.') ?? '0') ?? 0.0;
          final reps = int.tryParse(_repsControllers[setLog.id!]?.text ?? '0') ?? 0;

          final updatedSet = setLog.copyWith(weightKg: weight, reps: reps);

          if (setLog.id == null) {
            setsToInsert.add(updatedSet);
          } else {
            setsToUpdate.add(updatedSet);
          }
        }
      }

      await dbHelper.updateWorkoutLogDetails(widget.logId, _editedStartTime!, _notesController.text);
      await dbHelper.deleteSetLogs(idsToDelete);
      await dbHelper.updateSetLogs(setsToUpdate);

      for (final set in setsToInsert) {
        await dbHelper.insertSetLog(set.copyWith(workoutLogId: widget.logId));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.snackbarGoalsSaved)));
      }

      setState(() => _isEditMode = false);
      _loadDetails();
    }
  }

  Future<Map<String, double>> _calculateMuscleSplit() async {
    final Map<String, double> split = {};
    for (final set in _log!.sets) {
      final exercise = _exerciseDetails[set.exerciseName];
      final category = exercise?.categoryName ?? "Other";
      final volume = (set.weightKg ?? 0) * (set.reps ?? 0);
      split[category] = (split[category] ?? 0) + volume;
    }

    final total = split.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return split.map((k, v) => MapEntry(k, 0));
    return split.map((k, v) => MapEntry(k, (v / total) * 100));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workoutDetailsTitle),
        actions: [
          if (!_isLoading && _log != null)
            _isEditMode
                ? IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges, tooltip: l10n.save)
                : IconButton(icon: const Icon(Icons.edit), onPressed: _toggleEditMode, tooltip: l10n.edit),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _log == null
              ? Center(child: Text(l10n.workoutNotFound))
              : Column(
                  children: [
                    // --- Summary-Bar ---
                    Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(l10n.totalVolumeLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text("${_totalVolume.toStringAsFixed(0)} kg", style: Theme.of(context).textTheme.titleMedium),
                              ],
                            ),
                            Column(
                              children: [
                                Text(l10n.durationLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  _log!.endTime != null
                                      ? "${_log!.endTime!.difference(_log!.startTime).inMinutes} min"
                                      : "-",
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(l10n.setsLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text("${_log!.sets.length}", style: Theme.of(context).textTheme.titleMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            Text(_log!.routineName ?? l10n.freeWorkoutTitle,
                                style: Theme.of(context).textTheme.headlineMedium),
                            Row(
                              children: [
                                Text(DateFormat.yMMMMd(locale).add_Hm().format(_editedStartTime ?? _log!.startTime)),
                                if (_isEditMode)
                                  IconButton(
                                    icon: Icon(Icons.calendar_today, size: 18, color: colorScheme.primary),
                                    onPressed: _pickDateTime,
                                  )
                              ],
                            ),
                            const SizedBox(height: 16),
                            _isEditMode
                                ? TextFormField(
                                    controller: _notesController,
                                    decoration: InputDecoration(
                                      labelText: l10n.notesLabel,
                                      border: const OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                  )
                                : (_log!.notes != null && _log!.notes!.isNotEmpty
                                    ? Text('${l10n.notesLabel}: ${_log!.notes!}',
                                        style: const TextStyle(fontStyle: FontStyle.italic))
                                    : const SizedBox.shrink()),
                            const Divider(height: 32),
                            if (_categoryVolume.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                l10n.muscleSplitLabel,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              ..._buildCategoryBars(context),
                              const Divider(height: 32),
                            ],
                            ..._buildSetList(context, l10n),
                          ],
                        ),
                      ),
                    ),
                    const WgerAttributionWidget(),
                  ],
                ),
    );
  }

  List<Widget> _buildCategoryBars(BuildContext context) {
    final total = _categoryVolume.values.fold<double>(0, (a, b) => a + b);
    return _categoryVolume.entries.map((entry) {
      final fraction = total > 0 ? entry.value / total : 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(entry.key, style: const TextStyle(fontSize: 12)),
            ),
            Expanded(
              flex: 5,
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.grey.shade300,
                color: Theme.of(context).colorScheme.primary,
                minHeight: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text("${(fraction * 100).toStringAsFixed(0)}%"),
          ],
        ),
      );
    }).toList();
  }


  List<Widget> _buildSetList(BuildContext context, AppLocalizations l10n) {
    return _groupedSets.entries.map((entry) {
      final String exerciseName = entry.key;
      final Exercise? exercise = _exerciseDetails[exerciseName];
      final List<SetLog> sets = entry.value;
      int workingSetIndex = 0;
      final maxPause = sets.map((s) => s.restTimeSeconds ?? 0).reduce((a, b) => math.max(a, b));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: InkWell(
              onTap: () {
                if (exercise != null) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ExerciseDetailScreen(exercise: exercise),
                  ));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  exercise?.getLocalizedName(context) ?? exerciseName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ),
          if (maxPause > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(l10n.maxPauseDuration(maxPause),
                      style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          ...sets.asMap().entries.map((setEntry) {
            final int listIndex = setEntry.key;
            final SetLog setLog = setEntry.value;
            if (setLog.setType != 'warmup') {
              workingSetIndex++;
            }
            if (!_isEditMode) {
              return ListTile(
                leading: SetTypeChip(
                  setType: setLog.setType,
                  setIndex: workingSetIndex,
                  isCompleted: setLog.isCompleted,
                ),
                title: Text(
                  "${setLog.weightKg?.toStringAsFixed(2) ?? 0} kg x ${setLog.reps ?? 0} ${l10n.repsLabelShort}",
                ),
                dense: true,
              );
            } else {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SetTypeChip(setType: setLog.setType, setIndex: workingSetIndex),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightControllers[setLog.id!],
                        decoration: InputDecoration(labelText: l10n.kgLabel, isDense: true),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => (value == null ||
                                value.trim().isEmpty ||
                                double.tryParse(value.replaceAll(',', '.')) == null)
                            ? "!"
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("x"),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _repsControllers[setLog.id!],
                        decoration: InputDecoration(labelText: l10n.repsLabel, isDense: true),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty || int.tryParse(value) == null) ? "!" : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: l10n.delete,
                      onPressed: () => setState(() => entry.value.removeAt(listIndex)),
                    ),
                  ],
                ),
              );
            }
          }),
          const Divider(height: 16),
        ],
      );
    }).toList();
  }
}
