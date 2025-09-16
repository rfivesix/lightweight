// lib/screens/workout_log_detail_screen.dart (Final & Korrigiert - Edit Mode)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/screens/exercise_detail_screen.dart';
import 'package:lightweight/widgets/set_type_chip.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/widgets/wger_attribution_widget.dart';
import 'package:lightweight/widgets/workout_summary_bar.dart';

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
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};
  DateTime? _editedStartTime;
  Map<String, double> _categoryVolume = {};

  // ENTFERNT: Die _editedSetValues Map wird nicht mehr benötigt.
  // final Map<int, Map<String, String>> _editedSetValues = {};

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _clearControllers();
    super.dispose();
  }

  void _clearControllers() {
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    for (var controller in _repsControllers.values) {
      controller.dispose();
    }
    _weightControllers.clear();
    _repsControllers.clear();
  }

  Future<void> _loadDetails({bool preserveEditState = false}) async {
    if (!preserveEditState) {
      setState(() => _isLoading = true);
    }

    final data =
        await WorkoutDatabaseHelper.instance.getWorkoutLogById(widget.logId);
    if (data == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final groups = <String, List<SetLog>>{};
    for (var set in data.sets) {
      groups.putIfAbsent(set.exerciseName, () => []).add(set);
    }

    final Map<String, double> categoryVolume = {};
    for (final set in data.sets) {
      final exercise = await WorkoutDatabaseHelper.instance
          .getExerciseByName(set.exerciseName);
      if (exercise != null) {
        final volumeForSet = (set.weightKg ?? 0) * (set.reps ?? 0);
        categoryVolume.update(
            exercise.categoryName, (value) => value + volumeForSet,
            ifAbsent: () => volumeForSet);
      }
    }

    final tempExerciseDetails = <String, Exercise>{};
    for (var name in groups.keys) {
      final exercise =
          await WorkoutDatabaseHelper.instance.getExerciseByName(name);
      if (exercise != null) tempExerciseDetails[name] = exercise;
    }

    _notesController.text = data.notes ?? '';
    _editedStartTime = data.startTime;
    // KORREKTUR: Controller mit den aktuellen Werten befüllen.
    _clearControllers(); // Sicherstellen, dass alte Controller disposed sind.
    for (final setLog in data.sets) {
      _weightControllers[setLog.id!] = TextEditingController(
          text: setLog.weightKg?.toStringAsFixed(1).replaceAll('.0', '') ?? '');
      _repsControllers[setLog.id!] =
          TextEditingController(text: setLog.reps?.toString() ?? '');
    }

    if (!mounted) return;
    setState(() {
      _log = data;
      _groupedSets = groups;
      _exerciseDetails = tempExerciseDetails;
      _categoryVolume = categoryVolume;
      if (!preserveEditState) {
        _isLoading = false;
      }
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      // WICHTIG: Wenn der Bearbeitungsmodus eingeschaltet wird, die Controller neu befüllen.
      if (_isEditMode) {
        _loadDetails(
            preserveEditState:
                true); // Lade Daten neu, um Controller zu befüllen
      } else {
        _loadDetails(); // Änderungen verwerfen, wenn man den Modus verlässt
      }
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
      _editedStartTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context)!;
    final dbHelper = WorkoutDatabaseHelper.instance;

    final initialSetIds = _log!.sets.map((s) => s.id!).toSet();
    final currentSetIds =
        _groupedSets.values.expand((sets) => sets).map((s) => s.id!).toSet();
    final idsToDelete = initialSetIds.difference(currentSetIds).toList();

    final List<SetLog> setsToUpdate = [];
    final List<SetLog> setsToInsert =
        []; // HINZUGEFÜGT: Für neue Sätze im Bearbeitungsmodus

    for (final setGroup in _groupedSets.values) {
      for (final setLog in setGroup) {
        final weight = double.tryParse(
                _weightControllers[setLog.id!]?.text.replaceAll(',', '.') ??
                    '0') ??
            0.0;
        final reps =
            int.tryParse(_repsControllers[setLog.id!]?.text ?? '0') ?? 0;

        final updatedSet = setLog.copyWith(weightKg: weight, reps: reps);

        if (setLog.id == null) {
          setsToInsert.add(updatedSet); // Neue Sätze sammeln
        } else {
          setsToUpdate.add(updatedSet);
        }
      }
    }

    await dbHelper.updateWorkoutLogDetails(
        widget.logId, _editedStartTime!, _notesController.text);
    if (idsToDelete.isNotEmpty) await dbHelper.deleteSetLogs(idsToDelete);
    if (setsToUpdate.isNotEmpty) await dbHelper.updateSetLogs(setsToUpdate);
    // HINZUGEFÜGT: Neue Sätze einfügen
    for (final set in setsToInsert) {
      await dbHelper.insertSetLog(set.copyWith(workoutLogId: widget.logId));
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.snackbarGoalsSaved)));
    }

    setState(() => _isEditMode = false);
    _loadDetails();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    double totalVolume = 0.0;
    if (_log != null) {
      for (final set in _log!.sets) {
        totalVolume += (set.weightKg ?? 0) * (set.reps ?? 0);
      }
    }
    final Duration duration =
        _log?.endTime?.difference(_log!.startTime) ?? Duration.zero;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true, // Zurück-Pfeil
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          l10n.workoutDetailsTitle,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          if (!_isLoading && _log != null)
            _isEditMode
                ? TextButton(
                    onPressed: _saveChanges,
                    child: Text(l10n.save,
                        style:
                            TextStyle(color: Theme.of(context).primaryColor)),
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _toggleEditMode,
                  ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _log == null
              ? Center(child: Text(l10n.workoutNotFound))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    WorkoutSummaryBar(
                      duration: duration,
                      volume: totalVolume,
                      sets: _log!.sets.length,
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _log!.routineName ?? l10n.freeWorkoutTitle,
                            style: textTheme.headlineMedium,
                          ),
                          Row(
                            children: [
                              Text(DateFormat.yMMMMd(locale)
                                  .add_Hm()
                                  .format(_editedStartTime ?? _log!.startTime)),
                              if (_isEditMode)
                                IconButton(
                                  icon: Icon(Icons.calendar_today,
                                      size: 18, color: colorScheme.primary),
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
                                  ),
                                  maxLines: 3,
                                )
                              : (_log!.notes != null && _log!.notes!.isNotEmpty
                                  ? Text('${l10n.notesLabel}: ${_log!.notes!}',
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic))
                                  : const SizedBox.shrink()),
                          Divider(
                              height: 32,
                              thickness: 1,
                              color: colorScheme.onSurfaceVariant
                                  .withOpacity(0.1)),
                          if (_categoryVolume.isNotEmpty) ...[
                            Text(l10n.muscleSplitLabel,
                                style: textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ..._buildCategoryBars(context),
                            Divider(
                                height: 32,
                                thickness: 1,
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.1)),
                          ],
                          ..._buildSetList(context, l10n),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 24.0, bottom: 8.0),
                            child: WgerAttributionWidget(
                              textStyle: textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // HINZUGEFÜGT: Die Helfer-Methode für die Balken ist wieder da
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
                child: Text(entry.key, style: const TextStyle(fontSize: 12))),
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
    final colorScheme = Theme.of(context).colorScheme; // colorScheme hier holen
    final textTheme = Theme.of(context).textTheme; // textTheme hier holen

    return _groupedSets.entries.map((entry) {
      final String exerciseName = entry.key;
      final Exercise? exercise = _exerciseDetails[exerciseName];
      final List<SetLog> sets = entry.value;
      int workingSetIndex = 0;

      return SummaryCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              title: InkWell(
                onTap: () {
                  if (exercise != null) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          ExerciseDetailScreen(exercise: exercise),
                    ));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    exercise?.getLocalizedName(context) ?? exerciseName,
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              trailing: _isEditMode ? null : const Icon(Icons.chevron_right),
            ),
            Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.onSurfaceVariant.withOpacity(0.1),
                indent: 16,
                endIndent: 16),
            ...sets.asMap().entries.map((setEntry) {
              final int listIndex = setEntry.key;
              final SetLog setLog = setEntry.value;
              if (setLog.setType != 'warmup') workingSetIndex++;

              if (!_isEditMode) {
                return ListTile(
                  leading: SetTypeChip(
                      setType: setLog.setType,
                      setIndex: workingSetIndex,
                      isCompleted: true),
                  title: Text(
                      "${setLog.weightKg?.toStringAsFixed(2).replaceAll('.00', '') ?? 0} kg x ${setLog.reps ?? 0} ${l10n.repsLabelShort}"),
                  dense: true,
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SetTypeChip(
                          setType: setLog.setType, setIndex: workingSetIndex),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weightControllers[setLog.id!],
                          decoration: InputDecoration(
                            labelText: l10n.kgLabel,
                            isDense: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) => (value == null ||
                                  value.trim().isEmpty ||
                                  double.tryParse(value.replaceAll(',', '.')) ==
                                      null)
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
                          decoration: InputDecoration(
                            labelText: l10n.repsLabel,
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => (value == null ||
                                  value.trim().isEmpty ||
                                  int.tryParse(value) == null)
                              ? "!"
                              : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        tooltip: l10n.delete,
                        onPressed: () {
                          setState(() {
                            entry.value.removeAt(listIndex);
                            _weightControllers.remove(setLog.id!)?.dispose();
                            _repsControllers.remove(setLog.id!)?.dispose();
                          });
                        },
                      ),
                    ],
                  ),
                );
              }
            }),
            if (_isEditMode)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextButton.icon(
                  onPressed: () {
                    final newSet = SetLog(
                        id: DateTime.now().millisecondsSinceEpoch,
                        workoutLogId: _log!.id!,
                        exerciseName: exerciseName,
                        setType: 'normal');
                    setState(() {
                      entry.value.add(newSet);
                      // KORREKTUR: Neue Controller für den neuen Satz erstellen
                      _weightControllers[newSet.id!] = TextEditingController();
                      _repsControllers[newSet.id!] = TextEditingController();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addSetButton),
                ),
              ),
            Divider(
                height: 16,
                thickness: 1,
                color: colorScheme.onSurfaceVariant.withOpacity(0.1)),
          ],
        ),
      );
    }).toList();
  }
}
