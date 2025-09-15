// lib/screens/routines_screen.dart

import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/routine.dart';
import 'edit_routine_screen.dart';
import 'live_workout_screen.dart';
import 'workout_history_screen.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});
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
    if (mounted) setState(() { _routines = data; _isLoading = false; });
  }


  void _startWorkout(Routine routine) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    final fullRoutine = await WorkoutDatabaseHelper.instance.getRoutineById(routine.id!);
    final newWorkoutLog = await WorkoutDatabaseHelper.instance.startWorkout(routineName: routine.name);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (fullRoutine != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LiveWorkoutScreen(routine: fullRoutine, workoutLog: newWorkoutLog),
      )).then((_) => _loadRoutines());
    }
  }
  
  void _startEmptyWorkout() async {
    final l10n = AppLocalizations.of(context)!;
    final newWorkoutLog = await WorkoutDatabaseHelper.instance.startWorkout(routineName: l10n.freeWorkoutTitle);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => LiveWorkoutScreen(workoutLog: newWorkoutLog),
    )).then((_) => _loadRoutines());
  }

  void _createNewRoutine() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditRoutineScreen())).then((_) => _loadRoutines());
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.delete)),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workoutRoutinesTitle),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.workoutHistoryButton,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WorkoutHistoryScreen())),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routines.isEmpty
              ? _buildEmptyState(context, l10n)
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _routines.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildStartEmptyWorkoutCard(context, l10n);
                    }
                    final routine = _routines[index - 1];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.list_alt_rounded),
                        title: Text(routine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(l10n.editRoutineSubtitle),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () => _startWorkout(routine),
                              child: Text(l10n.startButton),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'duplicate') {
                                  _duplicateRoutine(routine.id!);
                                } else if (value == 'delete') {
                                  _deleteRoutine(context, routine);
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'duplicate',
                                  child: Text(l10n.duplicate),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text(l10n.delete),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditRoutineScreen(routine: routine))).then((_) => _loadRoutines());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewRoutine,
        label: Text(l10n.addRoutineButton),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStartEmptyWorkoutCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: const Icon(Icons.play_circle_fill),
        title: Text(l10n.startEmptyWorkoutButton, style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: _startEmptyWorkout,
      ),
    );
  }

  // BUGFIX 4: Empty State wurde um den "Freies Training"-Button erweitert
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list_alt, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.emptyRoutinesTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.emptyRoutinesSubtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
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