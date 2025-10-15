// lib/widgets/todays_workout_summary_card.dart

import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/util/time_util.dart';
import 'package:lightweight/widgets/summary_card.dart';

class TodaysWorkoutSummaryCard extends StatelessWidget {
  final Duration duration;
  final double volume;
  final int sets;
  final int workoutCount;
  final VoidCallback onTap;

  const TodaysWorkoutSummaryCard({
    super.key,
    required this.duration,
    required this.volume,
    required this.sets,
    required this.workoutCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Erstellt den Subtitle-Text mit allen Statistiken
    final subtitleText =
        '${formatDuration(duration)}  •  ${volume.toStringAsFixed(0)} kg  •  ${l10n.setCount(sets)}';

    return SummaryCard(
      // Padding wird von der ListTile übernommen
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        leading: Icon(
          Icons.fitness_center,
          color: theme.colorScheme.primary,
          size: 32,
        ),
        title: Text(
          workoutCount > 1
              ? l10n.workoutsLabel // "Workouts"
              : l10n.workout, // "Workout"
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitleText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
