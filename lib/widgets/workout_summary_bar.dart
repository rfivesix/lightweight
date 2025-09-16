// lib/widgets/workout_summary_bar.dart

import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/util/time_util.dart'; // Wir erstellen diese Hilfsdatei gleich

class WorkoutSummaryBar extends StatelessWidget {
  const WorkoutSummaryBar({
    super.key,
    this.duration,
    required this.volume,
    required this.sets,
  });

  // 'duration' ist optional, da es live aktualisiert wird
  // und nicht immer als fester Wert übergeben wird.
  final Duration? duration;
  final double volume;
  final int sets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(
        context)!; // Annahme: AppLocalizations ist verfügbar

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // --- Dauer ---
            _buildStatColumn(
              context: context,
              label: l10n.durationLabel,
              // Nutzt unsere neue Hilfsfunktion zur Formatierung
              value: formatDuration(duration ?? Duration.zero),
              highlight: true, // Hebt die Dauer hervor
            ),
            // --- Volumen ---
            _buildStatColumn(
              context: context,
              label: l10n.volumeLabel,
              value: "${volume.toStringAsFixed(0)} kg",
            ),

            // --- Sätze ---
            _buildStatColumn(
              context: context,
              label: l10n.setsLabel,
              value: sets.toString(),
            ),
          ],
        ),
      ),
    );
  }

  /// Ein kleines Helfer-Widget für eine einzelne Statistik-Spalte.
  Widget _buildStatColumn({
    required BuildContext context,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
      color: highlight
          ? theme.colorScheme.primary
          : theme.textTheme.titleMedium?.color,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey[600],
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}
