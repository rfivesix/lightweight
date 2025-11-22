import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/glass_bottom_menu.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/models/routine.dart';
import 'package:lightweight/models/routine_exercise.dart';
import 'package:lightweight/models/set_log.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/services/workout_session_manager.dart';
import 'package:lightweight/widgets/wger_attribution_widget.dart';
import 'package:lightweight/widgets/workout_summary_bar.dart';
import 'exercise_catalog_screen.dart';
import 'exercise_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:lightweight/screens/workout_summary_screen.dart';
import 'package:lightweight/widgets/workout_card.dart';

class LiveWorkoutScreen extends StatefulWidget {
  final Routine? routine;
  final WorkoutLog workoutLog;

  const LiveWorkoutScreen({super.key, this.routine, required this.workoutLog});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<String, List<SetLog>> _lastPerformances = {};
  bool _isLoading = true;

  // Definieren wir den Listener hier, damit er im ganzen State bekannt ist
  late final VoidCallback _onManagerUpdateCallback;

  @override
  void initState() {
    super.initState();
    // Der Listener wird jetzt einer Variable zugewiesen
    _onManagerUpdateCallback = () {
      if (mounted) {
        final manager = Provider.of<WorkoutSessionManager>(
          context,
          listen: false,
        );
        _syncControllersWithManager(manager);
        // setState() wird hier benötigt, um UI-Änderungen zu triggern,
        // die nicht von Controllern abgedeckt sind (z.B. ein neu hinzugefügter Satz)
        setState(() {});
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
      // Der Listener wird registriert
      Provider.of<WorkoutSessionManager>(
        context,
        listen: false,
      ).addListener(_onManagerUpdateCallback);
    });
  }

  // NEUE, KORREKTE dispose-Methode
  @override
  void dispose() {
    // Wir greifen direkt auf die Singleton-Instanz zu, ohne den "context" zu nutzen.
    WorkoutSessionManager().removeListener(_onManagerUpdateCallback);
    _clearControllers();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);
    List<RoutineExercise> exercisesToInit = [];

    if (!manager.isActive) {
      exercisesToInit = widget.routine?.exercises ?? [];
      manager.startWorkout(widget.workoutLog, exercisesToInit);
    } else {
      exercisesToInit = manager.exercises;
    }

    // Lade die "Last Time"-Daten für alle Übungen, die bereits im Workout sind
    for (var re in exercisesToInit) {
      final lastSets = await WorkoutDatabaseHelper.instance
          .getLastSetsForExercise(re.exercise.nameEn);
      if (mounted) {
        _lastPerformances[re.exercise.nameEn] = lastSets;
      }
    }

    _syncControllersWithManager(manager);
    if (mounted) {
      //manager.addListener(_onManagerUpdate);
      setState(() => _isLoading = false);
    }
  }

  void _syncControllersWithManager(WorkoutSessionManager manager) {
    manager.setLogs.forEach((templateId, setLog) {
      if (!_weightControllers.containsKey(templateId)) {
        _weightControllers[templateId] = TextEditingController(
          text: setLog.weightKg?.toStringAsFixed(1).replaceAll('.0', '') ?? '',
        );
        _repsControllers[templateId] = TextEditingController(
          text: setLog.reps?.toString() ?? '',
        );

        _weightControllers[templateId]!.addListener(() {
          final currentManagerValue = manager.setLogs[templateId]?.weightKg;
          final controllerText = _weightControllers[templateId]!.text;
          final controllerValue = double.tryParse(
            controllerText.replaceAll(',', '.'),
          );

          // Nur updaten, wenn sich der WERT tatsächlich geändert hat, oder das Feld leer ist.
          if (controllerValue != currentManagerValue) {
            // Wenn das Feld leer ist, senden wir 0.0, um den Wert im Manager zurückzusetzen.
            manager.updateSet(templateId, weight: controllerValue ?? 0.0);
          }
        });

        _repsControllers[templateId]!.addListener(() {
          final currentManagerValue = manager.setLogs[templateId]?.reps;
          final controllerText = _repsControllers[templateId]!.text;
          final controllerValue = int.tryParse(controllerText);

          if (controllerValue != currentManagerValue) {
            manager.updateSet(templateId, reps: controllerValue ?? 0);
          }
        });
      } else {
        // Hier ist die entscheidende Änderung:
        // Setze den Controller-Text nur, wenn das Feld NICHT den Fokus hat.
        // Das verhindert, dass der Wert beim Tippen zurückspringt.
        final weightText = setLog.weightKg == 0
            ? ''
            : setLog.weightKg?.toStringAsFixed(1).replaceAll('.0', '') ?? '';
        final repsText = setLog.reps == 0 ? '' : setLog.reps?.toString() ?? '';

        if (_weightControllers[templateId]!.text != weightText) {
          _weightControllers[templateId]!.text = weightText;
        }
        if (_repsControllers[templateId]!.text != repsText) {
          _repsControllers[templateId]!.text = repsText;
        }
      }
    });

    final toRemove = _weightControllers.keys
        .where((id) => !manager.setLogs.containsKey(id))
        .toList();
    for (final id in toRemove) {
      _weightControllers.remove(id)?.dispose();
      _repsControllers.remove(id)?.dispose();
    }
  }

  void _clearControllers() {
    for (var c in _weightControllers.values) {
      c.dispose();
    }
    for (var c in _repsControllers.values) {
      c.dispose();
    }
    _weightControllers.clear();
    _repsControllers.clear();
  }

  Future<void> _finishWorkout() async {
    final l10n = AppLocalizations.of(context)!;
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);

    final bool? confirmed = await showGlassBottomMenu<bool>(
      context: context,
      title: l10n.finishWorkoutButton, // "Beenden"
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                l10n.dialogFinishWorkoutBody,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(false);
                    },
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(true);
                    },
                    child: Text(l10n.finishWorkoutButton),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final logId = manager.workoutLog?.id;
      await manager.finishWorkout();
      if (mounted && logId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WorkoutSummaryScreen(logId: logId),
          ),
        );
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    Provider.of<WorkoutSessionManager>(
      context,
      listen: false,
    ).reorderExercise(oldIndex, newIndex);
  }

/*
  void _editPauseTime(RoutineExercise routineExercise) async {
    final l10n = AppLocalizations.of(context)!;
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);
    final currentPause = manager.pauseTimes[routineExercise.id!];

    final controller = TextEditingController(
      text: currentPause?.toString() ?? '',
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
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(controller.text)),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result != null) {
      manager.updatePauseTime(routineExercise.id!, result);
    }
  }
*/
  void _removeExercise(RoutineExercise exerciseToRemove) {
    Provider.of<WorkoutSessionManager>(
      context,
      listen: false,
    ).removeExercise(exerciseToRemove.id!);
  }

  void _addExercise() async {
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);
    final selectedExercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (context) =>
            const ExerciseCatalogScreen(isSelectionMode: true),
      ),
    );

    if (selectedExercise != null) {
      // Lade "Last Time"-Daten für die NEUE Übung
      final lastSets = await WorkoutDatabaseHelper.instance
          .getLastSetsForExercise(selectedExercise.nameEn);
      if (mounted) {
        setState(() {
          _lastPerformances[selectedExercise.nameEn] = lastSets;
        });
      }
      await manager.addExercise(selectedExercise);
    }
  }

  void _addSet(RoutineExercise re) {
    Provider.of<WorkoutSessionManager>(
      context,
      listen: false,
    ).addSetToExercise(re.id!);
  }

  void _removeSet(int templateId) {
    Provider.of<WorkoutSessionManager>(
      context,
      listen: false,
    ).removeSet(templateId);
  }

  void _changeSetType(int templateId, String newType) {
    Provider.of<WorkoutSessionManager>(
      context,
      listen: false,
    ).updateSet(templateId, setType: newType);
  }

  void _showSetTypePicker(int templateId) {
    final l10n = AppLocalizations.of(context)!;

    // Helfer zum Erstellen des Buchstaben-Widgets
    Widget buildSymbol(String char, Color color) {
      return Text(
        char,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final options = [
      {
        'type': 'normal',
        'label': l10n.set_type_normal,
        // Wir nutzen 'N' für Normal im Menü, oder einfach leer lassen wenn du willst
        'symbol': buildSymbol('N', Colors.grey)
      },
      {
        'type': 'warmup',
        'label': l10n.set_type_warmup,
        'symbol': buildSymbol('W', Colors.orange)
      },
      {
        'type': 'failure',
        'label': l10n.set_type_failure,
        'symbol': buildSymbol('F', Colors.red)
      },
      {
        'type': 'dropset',
        'label': l10n.set_type_dropset,
        'symbol': buildSymbol('D', Colors.blue)
      },
    ];

    showGlassBottomMenu(
      context: context,
      title: l10n.changeSetTypTitle,
      actions: options.map((opt) {
        return GlassMenuAction(
          // icon: null, // Brauchen wir nicht mehr
          customIcon:
              opt['symbol'] as Widget, // <-- Hier übergeben wir das Text-Widget
          label: opt['label'] as String,
          onTap: () => _changeSetType(templateId, opt['type'] as String),
        );
      }).toList(),
    );
  }

  void _editPauseTime(RoutineExercise routineExercise) async {
    final l10n = AppLocalizations.of(context)!;
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);
    final currentPause = manager.pauseTimes[routineExercise.id!];
    final controller =
        TextEditingController(text: currentPause?.toString() ?? '');

    final result = await showGlassBottomMenu<int?>(
      context: context,
      title: l10n.editPauseTimeTitle,
      contentBuilder: (ctx, close) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.pauseInSeconds,
                hintText: "z.B. 90",
                suffixText: "s",
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      close();
                      Navigator.of(ctx).pop(null);
                    },
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final val = int.tryParse(controller.text);
                      close();
                      Navigator.of(ctx).pop(val);
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result != null) {
      manager.updatePauseTime(routineExercise.id!, result);
    }
  }

  // NEUE HELFER-METHODE für den leeren Zustand
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: DesignConstants.spacingL),
            Text(
              l10n.emptyStateAddFirstExercise,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Text(
              "Füge eine Übung hinzu, um mit dem Protokollieren zu beginnen.", // TODO: l10n
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: Text(l10n.fabAddExercise),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final manager = Provider.of<WorkoutSessionManager>(context);
    void editPauseTime(RoutineExercise routineExercise) async {
      final l10n = AppLocalizations.of(context)!;
      final manager =
          Provider.of<WorkoutSessionManager>(context, listen: false);
      final currentPause = manager.pauseTimes[routineExercise.id!];
      final controller =
          TextEditingController(text: currentPause?.toString() ?? '');

      final result = await showGlassBottomMenu<int?>(
        context: context,
        title: l10n.editPauseTimeTitle,
        contentBuilder: (ctx, close) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.pauseInSeconds,
                  hintText: "z.B. 90",
                  suffixText: "s",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        close();
                        Navigator.of(ctx).pop(null);
                      },
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final val = int.tryParse(controller.text);
                        close();
                        Navigator.of(ctx).pop(val);
                      },
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );

      if (result != null) {
        manager.updatePauseTime(routineExercise.id!, result);
      }
    }

    final mgr = manager;

    // geplante/angelegte Sets = Anzahl aller SetLogs (egal ob erledigt)
    final int planned = mgr.setLogs.length;

    // erledigte Sets = isCompleted == true
    final int completed =
        mgr.setLogs.values.where((s) => s.isCompleted == true).length;

    final double progress = planned == 0 ? 0.0 : completed / planned;

    // NEU: Synchronisiere die Controller bei jedem Build
    // Das ersetzt den alten Listener und ist sicher.
    if (!_isLoading) {
      _syncControllersWithManager(manager);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          manager.workoutLog?.routineName ?? l10n.freeWorkoutTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
                WorkoutSummaryBar(
                  duration: mgr.elapsedDuration,
                  volume: mgr.totalVolume,
                  sets:
                      planned, // oder mgr.totalSets, falls das *geplante* Sets sind
                  progress: progress, // LIVE: echter Fortschritt
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.1),
                ),
                Expanded(
                  child: manager.exercises.isEmpty
                      ? _buildEmptyState(l10n)
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.only(
                              bottom: DesignConstants.bottomContentSpacer),
                          onReorder: _onReorder,
                          itemCount: manager.exercises.length,
                          itemBuilder: (context, index) {
                            final routineExercise = manager.exercises[index];
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
                                    leading: ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_handle),
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
                                              .getLocalizedName(context),
                                          style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // NEUER, KORRIGIERTER trailing-Block
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Zeigt die eingestellte Pausenzeit an
                                        if (manager.pauseTimes[
                                                    routineExercise.id!] !=
                                                null &&
                                            manager.pauseTimes[
                                                    routineExercise.id!]! >
                                                0)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4.0,
                                            ),
                                            child: Text(
                                              "${manager.pauseTimes[routineExercise.id!]}s",
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.timer_outlined,
                                          ),
                                          tooltip: l10n.editPauseTime,
                                          onPressed: () =>
                                              editPauseTime(routineExercise),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          tooltip: l10n.removeExercise,
                                          onPressed: () =>
                                              _removeExercise(routineExercise),
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
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
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
                                                ),
                                              ),
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
                                                ),
                                              ),
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
                                                ),
                                              ),
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
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 48),
                                          ],
                                        ),
                                        ...routineExercise.setTemplates
                                            .asMap()
                                            .entries
                                            .map((setEntry) {
                                          final templateId = setEntry.value.id!;
                                          final setLog =
                                              manager.setLogs[templateId];
                                          if (setLog == null) {
                                            return const SizedBox.shrink();
                                          }
                                          int workingSetIndex = 0;
                                          for (int i = 0;
                                              i <= setEntry.key;
                                              i++) {
                                            final currentTemplateId =
                                                routineExercise
                                                    .setTemplates[i].id!;
                                            if (manager
                                                    .setLogs[currentTemplateId]
                                                    ?.setType !=
                                                'warmup') {
                                              workingSetIndex++;
                                            }
                                          }
                                          return _buildSetRow(
                                            workingSetIndex,
                                            setEntry.key,
                                            templateId,
                                            setLog,
                                            _lastPerformances[routineExercise
                                                    .exercise.nameEn] ??
                                                [], // Hier die Liste übergeben
                                          );
                                        }),
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
              ],
            ),
      // KORRIGIERT: label hinzugefügt
      floatingActionButton: GlassFab(
        label: l10n.fabAddExercise,
        onPressed: _addExercise,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // NEUER, KORREKTER bottomNavigationBar
      bottomNavigationBar: Column(
        mainAxisSize:
            MainAxisSize.min, // Wichtig: Nimmt nur so viel Höhe wie nötig
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 1. Dein bestehender AnimatedBuilder für die Rest-Timer-Bar
          AnimatedBuilder(
            animation: manager,
            builder: (context, _) {
              final bar = _buildRestBottomBar(l10n, colorScheme, manager);
              return bar ?? const SizedBox.shrink();
            },
          ),
          // 2. Das Wger-Widget direkt darunter (nur wenn kein Timer läuft)
          if (manager.remainingRestSeconds <= 0 && !manager.showRestDone)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: WgerAttributionWidget(
                textStyle: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Ersetze diese Methode im _LiveWorkoutScreenState

  Widget _buildSetRow(
    int setIndex,
    int rowIndex,
    int templateId,
    SetLog setLog,
    List<SetLog> lastPerfSets, // Nimmt jetzt eine Liste entgegen
  ) {
    final manager = Provider.of<WorkoutSessionManager>(context, listen: false);
    final isCompleted = setLog.isCompleted ?? false;
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool isColoredRow = rowIndex > 0 && rowIndex.isOdd;
    final Color rowColor = isColoredRow
        ? (isLightMode
            ? Colors.grey.withOpacity(0.1)
            : Colors.white.withOpacity(0.1))
        : Colors.transparent;

    // Finde den korrespondierenden Satz vom letzten Mal
    SetLog? lastPerf;
    if (rowIndex < lastPerfSets.length) {
      lastPerf = lastPerfSets[rowIndex];
    }

    final rowContent = Row(
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: GestureDetector(
              onTap: () => isCompleted ? null : _showSetTypePicker(templateId),
              child: Text(
                _getSetDisplayText(setLog.setType, setIndex),
                style: TextStyle(
                  color: _getSetTypeColor(setLog.setType),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            lastPerf != null
                ? "${lastPerf.weightKg?.toStringAsFixed(1).replaceAll('.0', '')}kg × ${lastPerf.reps}"
                : "-",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _weightControllers[templateId],
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              fillColor: Colors.transparent,
            ),
            enabled: !isCompleted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _repsControllers[templateId],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              fillColor: Colors.transparent,
            ),
            enabled: !isCompleted,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: SizedBox(
            width: 48,
            child: IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                manager.updateSet(templateId, isCompleted: !isCompleted);
              },
            ),
          ),
        ),
      ],
    );

    return Dismissible(
      key: ValueKey('set_$templateId'),
      direction:
          isCompleted ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => _removeSet(templateId),
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: isCompleted ? Colors.green.withOpacity(0.2) : rowColor,
            ),
          ),
          rowContent,
        ],
      ),
    );
  }

  Widget? _buildRestBottomBar(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    WorkoutSessionManager manager,
  ) {
    final isRunning = manager.remainingRestSeconds > 0;
    final isDoneBanner = !isRunning && manager.showRestDone;
    if (!isRunning && !isDoneBanner) return null;
    final theme = Theme.of(context);
    if (isRunning) {
      return BottomAppBar(
        color: colorScheme.surface,
        elevation: 0,
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
    return BottomAppBar(
      color: Colors.green.shade600,
      elevation: 0,
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
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                manager.cancelRest();
              },
              child: Text(
                l10n.snackbar_button_ok,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Color _getSetTypeColor(String setType) {
    switch (setType) {
      case 'warmup':
        return Colors.orange;
      case 'dropset':
        return Colors.blue;
      case 'failure':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
