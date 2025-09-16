// lib/screens/live_workout_screen.dart (Final & De-Materialisiert - Endgültig)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:vibration/vibration.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/models/routine.dart';
import 'package:lightweight/models/routine_exercise.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/models/set_template.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/services/workout_session_manager.dart';
import 'package:lightweight/widgets/set_type_chip.dart';
import 'package:lightweight/widgets/summary_card.dart'; // HINZUGEFÜGT
import 'package:lightweight/widgets/wger_attribution_widget.dart';
import 'package:lightweight/widgets/workout_summary_bar.dart';
import 'exercise_catalog_screen.dart';
import 'exercise_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:lightweight/util/time_util.dart'; // Für formatDuration

class LiveWorkoutScreen extends StatefulWidget {
  final Routine? routine;
  final WorkoutLog workoutLog;

  const LiveWorkoutScreen({super.key, this.routine, required this.workoutLog});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  late List<RoutineExercise> _liveExercises;
  final Map<int, Map<String, dynamic>> _setUIData = {};
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<String, SetLog?> _lastPerformances = {};
  bool _isLoading = true;
  final Map<int, bool> _exerciseExpanded = {};

  @override
  void initState() {
    super.initState();
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);
    final isContinuing =
        manager.isActive && manager.workoutLog?.id == widget.workoutLog.id;

    if (isContinuing) {
      _liveExercises = manager.exercises;
    } else {
      if (widget.routine != null) {
        _liveExercises = widget.routine!.exercises.map((re) {
          return RoutineExercise(
            id: re.id,
            exercise: re.exercise,
            setTemplates: re.setTemplates
                .map((st) => SetTemplate.fromMap(st.toMap()))
                .toList(),
            pauseSeconds: re.pauseSeconds,
          );
        }).toList();
      } else {
        _liveExercises = [];
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        manager.startWorkout(widget.workoutLog, _liveExercises);
      });
    }
    _initializeScreen();
  }

  @override
  void dispose() {
    for (var c in _weightControllers.values) {
      c.dispose();
    }
    for (var c in _repsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    for (var routineExercise in _liveExercises) {
      final lastPerf = await WorkoutDatabaseHelper.instance
          .getLastPerformance(routineExercise.exercise.nameEn);
      if (mounted)
        setState(() =>
            _lastPerformances[routineExercise.exercise.nameEn] = lastPerf);
      for (final template in routineExercise.setTemplates) {
        final templateId = template.id!;
        String initialReps =
            template.targetReps ?? (lastPerf?.reps?.toString() ?? '');
        String initialWeight = (template.targetWeight ?? lastPerf?.weightKg)
                ?.toStringAsFixed(1)
                .replaceAll('.0', '') ??
            '';
        _setUIData[templateId] = {'setType': template.setType};
        _weightControllers[templateId] =
            TextEditingController(text: initialWeight);
        _repsControllers[templateId] = TextEditingController(text: initialReps);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _logSet(int setTemplateId, RoutineExercise re) async {
    final weight = double.tryParse(
            _weightControllers[setTemplateId]!.text.replaceAll(',', '.')) ??
        0.0;
    final reps = int.tryParse(_repsControllers[setTemplateId]!.text) ?? 0;

    await WorkoutSessionManager().logSet(setTemplateId, re, weight, reps);

    setState(() {}); // UI refresh
  }

  void _unlogSet(int setTemplateId) async {
    await WorkoutSessionManager().unlogSet(setTemplateId);
    setState(() {});
  }

  Future<void> _finishWorkout() async {
    // Wichtig: über den Session-Manager beenden, damit notifyListeners() feuert
    await WorkoutSessionManager().finishWorkout();

    if (mounted) {
      Navigator.of(context).pop(); // zurück zum Home-Screen
    }
  }

  void _addSet(RoutineExercise routineExercise) {
    setState(() {
      final newTemplate = SetTemplate(
          id: DateTime.now().millisecondsSinceEpoch, setType: 'normal');
      routineExercise.setTemplates.add(newTemplate);
      final templateId = newTemplate.id!;
      _setUIData[templateId] = {'setType': 'normal'};
      _weightControllers[templateId] = TextEditingController();
      _repsControllers[templateId] = TextEditingController();
    });
  }

  void _removeSet(RoutineExercise routineExercise, int setTemplateId) {
    setState(() {
      routineExercise.setTemplates.removeWhere((st) => st.id == setTemplateId);
      _setUIData.remove(setTemplateId);

      // Statt lokal jetzt über den Manager
      WorkoutSessionManager().completedSets.remove(setTemplateId);

      _weightControllers.remove(setTemplateId)?.dispose();
      _repsControllers.remove(setTemplateId)?.dispose();
    });
  }

  void _addExercise() async {
    final selectedExercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
          builder: (context) =>
              const ExerciseCatalogScreen(isSelectionMode: true)),
    );

    if (selectedExercise != null) {
      setState(() {
        final newTemplate = SetTemplate(
          id: DateTime.now().millisecondsSinceEpoch + 1,
          setType: 'normal',
        );

        final newRoutineExercise = RoutineExercise(
          id: DateTime.now().millisecondsSinceEpoch,
          exercise: selectedExercise,
          setTemplates: [newTemplate],
        );

        _liveExercises.add(newRoutineExercise);

        // ⬇️ Statt lokal → über den SessionManager
        WorkoutSessionManager().pauseTimes[newRoutineExercise.id!] = null;

        final templateId = newTemplate.id!;
        _setUIData[templateId] = {'setType': 'normal'};
        _weightControllers[templateId] = TextEditingController();
        _repsControllers[templateId] = TextEditingController();
      });
    }
  }

  void _changeSetType(int setTemplateId, String newType) {
    setState(() {
      _setUIData[setTemplateId]!['setType'] = newType;
    });
    Navigator.pop(context);
  }

  void _showSetTypePicker(int setTemplateId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
                title: const Text('Normal'),
                onTap: () => _changeSetType(setTemplateId, 'normal')),
            ListTile(
                title: const Text('Warmup'),
                onTap: () => _changeSetType(setTemplateId, 'warmup')),
            ListTile(
                title: const Text('Failure'),
                onTap: () => _changeSetType(setTemplateId, 'failure')),
            ListTile(
                title: const Text('Dropset'),
                onTap: () => _changeSetType(setTemplateId, 'dropset')),
          ],
        );
      },
    );
  }

  void _editPauseTime(RoutineExercise routineExercise) async {
    final l10n = AppLocalizations.of(context)!;
    final currentPause = WorkoutSessionManager()
        .exercises
        .firstWhere((ex) => ex.id == routineExercise.id)
        .pauseSeconds;

    final controller =
        TextEditingController(text: currentPause?.toString() ?? '');
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
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(int.tryParse(controller.text)),
              child: Text(l10n.save)),
        ],
      ),
    );
    if (result != null) {
      WorkoutSessionManager().updatePauseTime(routineExercise, result);
      setState(() {});
    }
  }

  void _removeExercise(RoutineExercise exerciseToRemove) {
    setState(() {
      for (var template in exerciseToRemove.setTemplates) {
        _setUIData.remove(template.id!);
        WorkoutSessionManager()
            .completedSets
            .remove(template.id!); // ⬅️ geändert
        _weightControllers.remove(template.id!)?.dispose();
        _repsControllers.remove(template.id!)?.dispose();
      }
      WorkoutSessionManager().pauseTimes.remove(exerciseToRemove.id!);
      _liveExercises.remove(exerciseToRemove);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final RoutineExercise item = _liveExercises.removeAt(oldIndex);
      _liveExercises.insert(newIndex, item);
    });
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final manager = WorkoutSessionManager();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          widget.workoutLog.routineName ?? l10n.freeWorkoutTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: Text(
              l10n.finishWorkoutButton,
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
          : Column(
              children: [
                AnimatedBuilder(
                  animation: manager,
                  builder: (context, _) {
                    return WorkoutSummaryBar(
                      duration: manager.elapsedDuration,
                      volume: manager.totalVolume,
                      sets: manager.totalSets,
                    );
                  },
                ),
                Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.1)),
                Expanded(
                  child: ReorderableListView(
                    proxyDecorator:
                        (Widget child, int index, Animation<double> animation) {
                      final exercise = _liveExercises[index];
                      return Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(12.0),
                        child: ListTile(
                          tileColor: Theme.of(context).cardColor,
                          title: Text(
                            exercise.exercise.getLocalizedName(context),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          trailing: const Icon(Icons.drag_handle),
                        ),
                      );
                    },
                    onReorderStart: (index) {
                      setState(() {
                        // SCHRITT 2: Diese Logik klappt alle Elemente in der LISTE ein.
                        for (final key in _exerciseExpanded.keys) {
                          _exerciseExpanded[key] = false;
                        }
                      });
                    },
                    onReorderEnd: (index) {
                      setState(() {
                        // Klappe alles wieder auf, wenn der Drag beendet ist.
                        for (final key in _exerciseExpanded.keys) {
                          _exerciseExpanded[key] = true;
                        }
                      });
                    },
                    onReorder: _onReorder,
                    padding: const EdgeInsets.all(8.0),
                    children: [
                      for (int index = 0;
                          index < _liveExercises.length;
                          index++)
                        SummaryCard(
                          // KORREKTUR 2: Übungsblock in SummaryCard
                          key: ValueKey(_liveExercises[index].id),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                // Übungstitel mit Drag-Handle und Aktionen
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                title: InkWell(
                                  // KORREKTUR: InkWell, um den Titel klickbar zu machen
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ExerciseDetailScreen(
                                                  exercise:
                                                      _liveExercises[index]
                                                          .exercise))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      _liveExercises[index]
                                          .exercise
                                          .getLocalizedName(context),
                                      style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold),
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
                                    // Pausezeit anzeigen
                                    if (manager.pauseTimes[
                                                _liveExercises[index].id!] !=
                                            null &&
                                        manager.pauseTimes[
                                                _liveExercises[index].id!]! >
                                            0)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4.0),
                                        child: Text(
                                          "${manager.pauseTimes[_liveExercises[index].id!]}s",
                                          style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    // Bearbeiten-Button für Pause
                                    IconButton(
                                      icon: const Icon(Icons.timer_outlined),
                                      tooltip: l10n.editPauseTime,
                                      onPressed: () =>
                                          _editPauseTime(_liveExercises[index]),
                                    ),
                                    // Löschen-Button für Übung
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                      tooltip: l10n.removeExercise,
                                      onPressed: () => _removeExercise(
                                          _liveExercises[index]),
                                    ),
                                  ],
                                ),
                              ),
                              // Trennlinie nach dem Titel
                              Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.1),
                                  indent: 16,
                                  endIndent: 16),
                              // Sets und "Satz hinzufügen"-Button
                              Padding(
                                padding: const EdgeInsets.all(
                                    16.0), // Padding für den Inhalt der Übung
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _buildHeader(l10n.setLabel),
                                        _buildHeader(l10n.lastTimeLabel),
                                        _buildHeader(l10n.kgLabel),
                                        _buildHeader(l10n.repsLabel),
                                        const SizedBox(width: 48),
                                      ],
                                    ),
                                    Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.1)),
                                    ..._liveExercises[index]
                                        .setTemplates
                                        .asMap()
                                        .entries
                                        .map((setEntry) {
                                      final setTemplate = setEntry.value;
                                      int workingSetIndex = 0; // Neu berechnen
                                      for (final st in _liveExercises[index]
                                          .setTemplates) {
                                        if (st.id == setTemplate.id) break;
                                        if (st.setType != 'warmup')
                                          workingSetIndex++;
                                      }
                                      if (setTemplate.setType != 'warmup')
                                        workingSetIndex++;

                                      return _buildSetRow(
                                        workingSetIndex,
                                        _liveExercises[index],
                                        setTemplate,
                                        manager.completedSets
                                            .contains(setTemplate.id!),
                                        colorScheme,
                                        _lastPerformances[_liveExercises[index]
                                            .exercise
                                            .nameEn],
                                      );
                                    }).toList(),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _addSet(_liveExercises[index]),
                                      icon: const Icon(Icons.add),
                                      label: Text(l10n.addSetButton),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: GlassFab(
          onPressed: _addExercise,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // KORREKTUR: BottomNavigationBar für Rest-Timer beibehalten und stylen
      bottomNavigationBar: AnimatedBuilder(
        animation: manager,
        builder: (context, _) {
          final bar =
              _buildRestBottomBar(l10n, colorScheme); // colorScheme übergeben
          return bar ?? const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSetRow(
    int setIndex,
    RoutineExercise re,
    SetTemplate template,
    bool isCompleted,
    ColorScheme colorScheme,
    SetLog? lastPerf,
  ) {
    final setType = _setUIData[template.id!]!['setType'];

    return Dismissible(
      key: ValueKey(template.id),
      direction:
          isCompleted ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => _removeSet(re, template.id!),
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(
          color:
              isCompleted ? Colors.green.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Expanded(
              child: SetTypeChip(
                setType: setType,
                setIndex: (setType == 'warmup') ? null : setIndex, // 🔥 hier!
                isCompleted: isCompleted,
                onTap: () => _showSetTypePicker(template.id!),
              ),
            ),
            Expanded(
              child: Text(
                lastPerf != null
                    ? "${lastPerf.weightKg}kg x ${lastPerf.reps}"
                    : "-",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: _weightControllers[template.id!],
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    border: InputBorder.none, isDense: true),
                enabled: !isCompleted,
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: _repsControllers[template.id!],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    border: InputBorder.none, isDense: true),
                enabled: !isCompleted,
              ),
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                icon: Icon(
                  isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  if (isCompleted) {
                    _unlogSet(template.id!);
                  } else {
                    _logSet(template.id!, re);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildRestBottomBar(AppLocalizations l10n, ColorScheme colorScheme) {
    final manager = WorkoutSessionManager();
    final isRunning = manager.remainingRestSeconds > 0;
    final isDoneBanner = !isRunning && manager.showRestDone;
    if (!isRunning && !isDoneBanner) return null;

    final theme = Theme.of(context);

    if (isRunning) {
      return BottomAppBar(
        color: colorScheme.surface,
        elevation: 0,
        // KORREKTUR: shape ist null
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${l10n.restTimerLabel}: ${manager.remainingRestSeconds}s",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  manager.cancelRest();
                },
                child: Text(l10n.skipButton),
              ),
            ],
          ),
        ),
      );
    }
    // Pause vorbei
    return BottomAppBar(
      color: Colors.green.shade600,
      elevation: 0,
      // KORREKTUR: shape ist null
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Pause vorbei!",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                manager.cancelRest();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      ),
    );
  }
}
