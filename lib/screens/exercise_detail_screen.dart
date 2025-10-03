// lib/screens/exercise_detail_screen.dart (Final & De-Materialisiert - Korrigiert)

import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/exercise.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/widgets/wger_attribution_widget.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true, // <-- zeigt den Zurück-Pfeil
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          exercise.getLocalizedName(context),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.categoryName,
              style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            SummaryCard(
              child: Padding(
                padding: DesignConstants.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.descriptionLabel, style: textTheme.titleLarge),
                    const SizedBox(height: DesignConstants.spacingS),
                    Text(
                      exercise.getLocalizedDescription(context).isNotEmpty
                          ? exercise.getLocalizedDescription(context)
                          : l10n.noDescriptionAvailable,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingM),
            SummaryCard(
              child: Padding(
                padding: DesignConstants.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.involvedMuscles, style: textTheme.titleLarge),
                    const SizedBox(height: DesignConstants.spacingS),
                    if (exercise.primaryMuscles.isNotEmpty)
                      _buildMuscleRow(l10n.primaryLabel,
                          exercise.primaryMuscles.join(', '), textTheme),
                    if (exercise.secondaryMuscles.isNotEmpty)
                      _buildMuscleRow(l10n.secondaryLabel,
                          exercise.secondaryMuscles.join(', '), textTheme),
                    if (exercise.primaryMuscles.isEmpty &&
                        exercise.secondaryMuscles.isEmpty)
                      Text(l10n.noMusclesSpecified,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
              child: WgerAttributionWidget(
                textStyle:
                    textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleRow(String label, String muscles, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(muscles, style: textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
