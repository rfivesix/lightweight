// lib/screens/routines_screen.dart (Final & De-Materialisiert - Korrigiert)

import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/routine.dart';
import 'package:lightweight/screens/edit_routine_screen.dart';
import 'package:lightweight/screens/live_workout_screen.dart';
import 'package:lightweight/screens/workout_history_screen.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/util/time_util.dart';

class RoutinesScreen extends StatefulWidget {
  final int? initialRoutineId;
  const RoutinesScreen({super.key, this.initialRoutineId});
  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  bool _isLoading = true;
  List<Routine> _routines = [];

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);
    final data = await WorkoutDatabaseHelper.instance.getAllRoutines();
    if (mounted) {
      setState(() {
        _routines = data;
        _isLoading = false;
      });
      // Wenn eine initialRoutineId übergeben wurde, direkt dorthin navigieren
      if (widget.initialRoutineId != null) {
        final routineToEdit = _routines.firstWhere(
            (r) => r.id == widget.initialRoutineId,
            orElse: () => throw Exception("Routine not found"));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (context) =>
                      EditRoutineScreen(routine: routineToEdit)))
              .then((_) => _loadRoutines());
        });
      }
    }
  }

  void _startWorkout(Routine routine) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));
    final fullRoutine =
        await WorkoutDatabaseHelper.instance.getRoutineById(routine.id!);
    final newWorkoutLog = await WorkoutDatabaseHelper.instance
        .startWorkout(routineName: routine.name);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (fullRoutine != null) {
      Navigator.of(context)
          .push(MaterialPageRoute(
            builder: (context) => LiveWorkoutScreen(
                routine: fullRoutine, workoutLog: newWorkoutLog),
          ))
          .then((_) => _loadRoutines());
    }
  }

  void _startEmptyWorkout() async {
    final l10n = AppLocalizations.of(context)!;
    final newWorkoutLog = await WorkoutDatabaseHelper.instance
        .startWorkout(routineName: l10n.freeWorkoutTitle);
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => LiveWorkoutScreen(workoutLog: newWorkoutLog),
        ))
        .then((_) => _loadRoutines());
  }

  void _createNewRoutine() {
    Navigator.of(context)
        .push(
            MaterialPageRoute(builder: (context) => const EditRoutineScreen()))
        .then((_) => _loadRoutines());
  }

// NEUE METHODEN FÜR DAS MENÜ
  void _duplicateRoutine(int routineId) async {
    await WorkoutDatabaseHelper.instance.duplicateRoutine(routineId);
    _loadRoutines();
  }

  void _deleteRoutine(BuildContext context, Routine routine) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteRoutineConfirmContent(routine.name)),
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

    if (confirmed == true) {
      await WorkoutDatabaseHelper.instance.deleteRoutine(routine.id!);
      _loadRoutines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme; // Hier definiert

    return Scaffold(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  appBar: AppBar(
    automaticallyImplyLeading: true,
    elevation: 0,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    scrolledUnderElevation: 0,
    centerTitle: false,
    title: Text(
      l10n.workoutRoutinesTitle,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    ),
  ),
  body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _routines.isEmpty
          ? _buildEmptyState(context, l10n, textTheme)
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _routines.length + 1, // statt +2
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildStartEmptyWorkoutCard(context, l10n);
                }
                final routine = _routines[index - 1];
                    return Dismissible(
                      key: Key('routine_${routine.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.deleteConfirmTitle),
                                content: Text(l10n
                                    .deleteRoutineConfirmContent(routine.name)),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: Text(l10n.cancel)),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: Text(l10n.delete)),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (direction) {
                        _deleteRoutine(context, routine);
                      },
                      child: SummaryCard(
                        child: ListTile(
                          leading: ElevatedButton(
                            onPressed: () => _startWorkout(routine),
                            child: Text(l10n.startButton),
                          ),
                          title: Text(routine.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(l10n.editRoutineSubtitle),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                color: textTheme.bodyMedium?.color),
                            onSelected: (value) {
                              if (value == 'duplicate') {
                                _duplicateRoutine(routine.id!);
                              } else if (value == 'delete') {
                                _deleteRoutine(context, routine);
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                  value: 'duplicate',
                                  child: Text(l10n.duplicate)),
                              PopupMenuItem<String>(
                                  value: 'delete', child: Text(l10n.delete)),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (context) =>
                                        EditRoutineScreen(routine: routine)))
                                .then((_) => _loadRoutines());
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: GlassFab(
          onPressed: _createNewRoutine,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // KORREKTUR 5: _buildStartEmptyWorkoutCard als SummaryCard-Button
  Widget _buildStartEmptyWorkoutCard(
      BuildContext context, AppLocalizations l10n) {
    return SummaryCard(
      child: ListTile(
        leading: const Icon(Icons.play_circle_fill),
        title: Text(l10n.startEmptyWorkoutButton,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: _startEmptyWorkout,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    );
  }

  // KORREKTUR: _buildEmptyState akzeptiert jetzt TextTheme als Parameter
  Widget _buildEmptyState(
      BuildContext context, AppLocalizations l10n, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list_alt, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.emptyRoutinesTitle,
                style: textTheme
                    .headlineMedium), // Jetzt kann TextTheme verwendet werden
            const SizedBox(height: 8),
            Text(l10n.emptyRoutinesSubtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                    color:
                        Colors.grey)), // Jetzt kann TextTheme verwendet werden
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewRoutine,
              icon: const Icon(Icons.add),
              label: Text(l10n.createFirstRoutineButton),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _startEmptyWorkout,
              child: Text(l10n.startEmptyWorkoutButton),
            ),
          ],
        ),
      ),
    );
  }
}
