// lib/screens/workout_log_detail_screen.dart (Final & Korrigiert - Edit Mode - Neu mit WorkoutCard)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/screens/exercise_catalog_screen.dart';
import 'package:lightweight/screens/exercise_detail_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/widgets/wger_attribution_widget.dart';
import 'package:lightweight/widgets/workout_summary_bar.dart';
import 'package:lightweight/widgets/workout_card.dart';

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

  /// Gibt den anzuzeigenden Text für den Set zurück
  String _getSetDisplayText(String setType, int setIndex) {
    switch (setType) {
      case 'warmup':
        return 'W';
      case 'failure':
        return 'F';
      case 'dropset':
        return 'D';
      default:
        return '$setIndex';
    }
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

    _clearControllers();
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
      if (_isEditMode) {
        _loadDetails(preserveEditState: true);
      } else {
        _loadDetails();
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
    final currentSets = _groupedSets.values.expand((sets) => sets).toList();

    final idsToDelete = initialSetIds
        .difference(currentSets.map((s) => s.id!).toSet())
        .toList();

    final List<SetLog> setsToUpdate = [];
    final List<SetLog> setsToInsert = [];

    for (final setLog in currentSets) {
      final weight = double.tryParse(
              _weightControllers[setLog.id!]?.text.replaceAll(',', '.') ??
                  '0') ??
          0.0;
      final reps = int.tryParse(_repsControllers[setLog.id!]?.text ?? '0') ?? 0;

      final updatedSet = setLog.copyWith(weightKg: weight, reps: reps);

      if (initialSetIds.contains(setLog.id)) {
        setsToUpdate.add(updatedSet);
      } else {
        setsToInsert.add(updatedSet);
      }
    }

    await dbHelper.updateWorkoutLogDetails(
        widget.logId, _editedStartTime!, _notesController.text);
    if (idsToDelete.isNotEmpty) await dbHelper.deleteSetLogs(idsToDelete);
    if (setsToUpdate.isNotEmpty) await dbHelper.updateSetLogs(setsToUpdate);
    for (final set in setsToInsert) {
      await dbHelper
          .insertSetLog(set.copyWith(id: null, workoutLogId: widget.logId));
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.snackbarRoutineSaved)));
    }

    setState(() => _isEditMode = false);
    _loadDetails();
  }

  Widget _buildHeader(String text) => Expanded(
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.workoutDetailsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        actions: [
          if (!_isLoading && _log != null)
            _isEditMode
                ? TextButton(
                    onPressed: _saveChanges,
                    child: Text(l10n.save,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )),
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
              : Column(
                  children: [
                    WorkoutSummaryBar(
                      duration: duration,
                      volume: totalVolume,
                      sets: _log!.sets.length,
                    ),
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.1)),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // Header Info Section mit SummaryCard
                          Padding(
                            padding: DesignConstants.cardPadding,
                            child: SummaryCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _log!.routineName ??
                                            l10n.freeWorkoutTitle,
                                        style: textTheme.headlineMedium,
                                      ),
                                      Row(
                                        children: [
                                          Text(DateFormat.yMMMMd(locale)
                                              .add_Hm()
                                              .format(_editedStartTime ??
                                                  _log!.startTime)),
                                          if (_isEditMode)
                                            IconButton(
                                              icon: Icon(Icons.calendar_today,
                                                  size: 18,
                                                  color: colorScheme.primary),
                                              onPressed: _pickDateTime,
                                            )
                                        ],
                                      ),
                                      const SizedBox(
                                          height: DesignConstants.spacingM),
                                      _isEditMode
                                          ? TextFormField(
                                              controller: _notesController,
                                              decoration: InputDecoration(
                                                  labelText: l10n.notesLabel),
                                              maxLines: 3,
                                            )
                                          : (_log!.notes != null &&
                                                  _log!.notes!.isNotEmpty
                                              ? Text(
                                                  '${l10n.notesLabel}: ${_log!.notes!}',
                                                  style: const TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic))
                                              : const SizedBox.shrink()),
                                      if (_categoryVolume.isNotEmpty) ...[
                                        const Divider(height: 24),
                                        Text(l10n.muscleSplitLabel,
                                            style: textTheme.titleMedium),
                                        const SizedBox(
                                            height: DesignConstants.spacingS),
                                        ..._buildCategoryBars(context),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Exercise Sets mit WorkoutCard
                          ..._buildSetList(context, l10n),

                          // Add Exercise Button
                          if (_isEditMode)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextButton.icon(
                                onPressed: () async {
                                  final selectedExercise =
                                      await Navigator.of(context)
                                          .push<Exercise>(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ExerciseCatalogScreen(
                                                isSelectionMode: true)),
                                  );
                                  if (selectedExercise != null) {
                                    setState(() {
                                      final newSet = SetLog(
                                          id: DateTime.now()
                                              .millisecondsSinceEpoch,
                                          workoutLogId: _log!.id!,
                                          exerciseName: selectedExercise
                                              .getLocalizedName(context),
                                          setType: 'normal');
                                      _groupedSets[selectedExercise
                                          .getLocalizedName(context)] = [
                                        newSet
                                      ];
                                      _weightControllers[newSet.id!] =
                                          TextEditingController();
                                      _repsControllers[newSet.id!] =
                                          TextEditingController();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: Text(l10n.addExerciseToWorkoutButton),
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16.0, 24.0, 16.0, 8.0),
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

  Widget _buildSetRow(
    SetLog setLog,
    int rowIndex, // Der Index in der Liste der Sätze für DIESE Übung
    int workingSetIndex, // Der "Arbeitssatz"-Index
    String exerciseName,
    AppLocalizations l10n,
  ) {
    final setType = setLog.setType;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    final bool isColoredRow = rowIndex > 0 && rowIndex.isOdd;
    final Color rowColor;
    if (isColoredRow) {
      rowColor = isLightMode
          ? Colors.grey.withOpacity(0.1)
          // HIER DIE ÄNDERUNG: Erhöhte Opazität für Dark Mode
          : Colors.white.withOpacity(0.1);
    } else {
      rowColor = Colors.transparent;
    }

    return Container(
      color: rowColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            // ... restlicher Code der Methode bleibt unverändert
            Expanded(
              flex: 2,
              child: Center(
                child: Builder(
                  builder: (_) {
                    Color textColor;
                    switch (setType) {
                      case 'warmup':
                        textColor = Colors.orange;
                        break;
                      case 'dropset':
                        textColor = Colors.blue;
                        break;
                      case 'failure':
                        textColor = Colors.red;
                        break;
                      default:
                        textColor = Colors.grey;
                    }
                    return GestureDetector(
                      onTap: () {
                        if (_isEditMode) _showSetTypePicker(setLog.id!);
                      },
                      child: Text(
                        _getSetDisplayText(setType, workingSetIndex),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  "-",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _isEditMode
                  ? TextFormField(
                      controller: _weightControllers[setLog.id!],
                      textAlign: TextAlign.center,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          fillColor: Colors.transparent),
                    )
                  : Text(
                      setLog.weightKg
                              ?.toStringAsFixed(1)
                              .replaceAll('.0', '') ??
                          '0',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _isEditMode
                  ? TextFormField(
                      controller: _repsControllers[setLog.id!],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          fillColor: Colors.transparent),
                    )
                  : Text(
                      "${setLog.reps ?? '0'}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 48,
                child: _isEditMode
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _groupedSets[exerciseName]
                                ?.removeWhere((s) => s.id == setLog.id);
                            _weightControllers.remove(setLog.id!)?.dispose();
                            _repsControllers.remove(setLog.id!)?.dispose();
                          });
                        },
                      )
                    : const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSetList(BuildContext context, AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    final entries = _groupedSets.entries.toList();

    if (!_isEditMode) {
      // Normale Liste ohne Reorder-Funktionalität
      return entries
          .map((entry) => _buildExerciseCard(context, l10n, entry, -1))
          .toList();
    } else {
      // ReorderableListView für Edit-Modus
      return [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = entries.removeAt(oldIndex);
              entries.insert(newIndex, item);

              // Gruppierte Sets Map neu aufbauen
              _groupedSets.clear();
              for (var entry in entries) {
                _groupedSets[entry.key] = entry.value;
              }
            });
          },
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return _buildExerciseCard(context, l10n, entries[index], index);
          },
        ),
      ];
    }
  }

  Widget _buildExerciseCard(BuildContext context, AppLocalizations l10n,
      MapEntry<String, List<SetLog>> entry, int index) {
    final String exerciseName = entry.key;
    final Exercise? exercise = _exerciseDetails[exerciseName];
    final List<SetLog> sets = entry.value;
    final textTheme = Theme.of(context).textTheme;

    return WorkoutCard(
      key: _isEditMode ? ValueKey(exerciseName) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            leading: _isEditMode
                ? ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  )
                : null,
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
            trailing: _isEditMode
                ? IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    tooltip: l10n.removeExercise,
                    onPressed: () {
                      setState(() {
                        for (var set in sets) {
                          _weightControllers.remove(set.id!)?.dispose();
                          _repsControllers.remove(set.id!)?.dispose();
                        }
                        _groupedSets.remove(exerciseName);
                      });
                    },
                  )
                : const Icon(Icons.info_outline),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Center(
                          child: Text(
                        l10n.setLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    Expanded(
                      flex: 3,
                      child: Center(
                          child: Text(
                        l10n.lastTimeLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                          child: Text(
                        l10n.kgLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                          child: Text(
                        l10n.repsLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                // Set Rows
                ...sets.asMap().entries.map((setEntry) {
                  final setLog = setEntry.value;
                  final rowIndex = setEntry
                      .key; // Der Index in der Liste der Sätze für DIESE Übung

                  // Normale Sätze zählen (ohne Warmup)
                  int workingSetIndex = 0;
                  for (int i = 0; i <= rowIndex; i++) {
                    if (sets[i].setType != 'warmup') {
                      workingSetIndex++;
                    }
                  }

                  return _buildSetRow(
                      setLog, rowIndex, workingSetIndex, exerciseName, l10n);
                }),

                // Add Set Button
                if (_isEditMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextButton.icon(
                      onPressed: () {
                        final newSet = SetLog(
                            id: DateTime.now().millisecondsSinceEpoch,
                            workoutLogId: _log!.id!,
                            exerciseName: exerciseName,
                            setType: 'normal');
                        setState(() {
                          sets.add(newSet);
                          _weightControllers[newSet.id!] =
                              TextEditingController();
                          _repsControllers[newSet.id!] =
                              TextEditingController();
                        });
                      },
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
  }

  void _changeSetType(int setLogId, String newType) {
    setState(() {
      // Finde den SetLog und ändere den setType
      for (var entry in _groupedSets.entries) {
        for (var setLog in entry.value) {
          if (setLog.id == setLogId) {
            // Erstelle eine neue Instanz mit geändertem setType
            final index = entry.value.indexOf(setLog);
            entry.value[index] = setLog.copyWith(setType: newType);
            break;
          }
        }
      }
    });
    Navigator.pop(context);
  }

  void _showSetTypePicker(int setLogId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
                title: const Text('Normal'),
                onTap: () => _changeSetType(setLogId, 'normal')),
            ListTile(
                title: const Text('Warmup'),
                onTap: () => _changeSetType(setLogId, 'warmup')),
            ListTile(
                title: const Text('Failure'),
                onTap: () => _changeSetType(setLogId, 'failure')),
            ListTile(
                title: const Text('Dropset'),
                onTap: () => _changeSetType(setLogId, 'dropset')),
          ],
        );
      },
    );
  }
}
