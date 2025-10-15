// lib/screens/workout_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:lightweight/data/workout_database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/workout_log.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/widgets/workout_summary_bar.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final int logId;

  const WorkoutSummaryScreen({super.key, required this.logId});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  bool _isLoading = true;
  WorkoutLog? _log;
  Map<String, double> _volumePerExercise = {};

  @override
  void initState() {
    super.initState();
    _loadWorkoutDetails();
  }

  Future<void> _loadWorkoutDetails() async {
    final data = await WorkoutDatabaseHelper.instance.getWorkoutLogById(
      widget.logId,
    );

    if (data != null) {
      final Map<String, double> volumeMap = {};
      for (var set in data.sets) {
        final volume = (set.weightKg ?? 0) * (set.reps ?? 0);
        volumeMap.update(
          set.exerciseName,
          (value) => value + volume,
          ifAbsent: () => volume,
        );
      }

      if (mounted) {
        setState(() {
          _log = data;
          _volumePerExercise = volumeMap;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Verhindert den Zurück-Pfeil
        title: Text(
          l10n.workoutSummaryTitle,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _log == null
              ? Center(child: Text(l10n.workoutNotFound))
              : Padding(
                  padding: DesignConstants.cardPadding,
                  child: Column(
                    children: [
                      // Gesamt-Statistiken
                      WorkoutSummaryBar(
                        duration: _log!.endTime?.difference(_log!.startTime),
                        volume:
                            _volumePerExercise.values.fold(0, (a, b) => a + b),
                        sets: _log!.sets.length,
                        progress: null,
                      ),
                      const SizedBox(height: DesignConstants.spacingXL),

                      // Liste der Übungen
                      Expanded(
                        child: ListView(
                          children: [
                            Text(
                              l10n.workoutSummaryExerciseOverview,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: DesignConstants.spacingS),
                            ..._volumePerExercise.entries.map((entry) {
                              return SummaryCard(
                                child: ListTile(
                                  title: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Text(
                                    "${entry.value.toStringAsFixed(0)} kg",
                                    style: textTheme.bodyLarge,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingXL),

                      // Fertig-Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            // Schließt den Summary-Screen und kehrt zum vorherigen Screen zurück
                            // (vermutlich der Routines- oder Home-Screen)
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            l10n.doneButtonLabel,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
