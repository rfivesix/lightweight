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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          exercise.getLocalizedName(context),
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CategoryBadge(text: exercise.categoryName),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bild / GIF
            if ((exercise.imagePath ?? '').isNotEmpty)
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  exercise.imagePath!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    alignment: Alignment.center,
                    color: Colors.black12,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),

            const SizedBox(height: DesignConstants.spacingXL),

            // Beschreibung
            _buildSectionTitle(context, l10n.descriptionLabel.toUpperCase()),
            SummaryCard(
              child: Padding(
                padding: DesignConstants.cardPadding,
                child: Text(
                  exercise.getLocalizedDescription(context).isNotEmpty
                      ? exercise.getLocalizedDescription(context)
                      : l10n.noDescriptionAvailable,
                  style: textTheme.bodyMedium,
                ),
              ),
            ),

            const SizedBox(height: DesignConstants.spacingXL),

            // Muskeln
            _buildSectionTitle(context, l10n.involvedMuscles.toUpperCase()),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MuscleGroupCard(
                    title: l10n.primaryLabel,
                    muscles: exercise.primaryMuscles,
                    fallback: l10n.noMusclesSpecified,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingM),
                Expanded(
                  child: _MuscleGroupCard(
                    title: l10n.secondaryLabel,
                    muscles: exercise.secondaryMuscles,
                    fallback: l10n.noMusclesSpecified,
                  ),
                ),
              ],
            ),

            const SizedBox(height: DesignConstants.spacingL),

            // Attribution
            Center(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  bottom: DesignConstants.spacingM,
                ),
                child: WgerAttributionWidget(
                  textStyle: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------
// Kategorie-Pill oben rechts
// -----------------------------
class _CategoryBadge extends StatelessWidget {
  final String text;
  const _CategoryBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.primary.withOpacity(0.15);
    final fg = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// -----------------------------
// Überschriften-Stil (bereit für deine ARB-Texte in CAPS)
// -----------------------------
Widget _buildSectionTitle(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Colors.grey[600],
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// -----------------------------
// Einzel-Kachel für Primär / Sekundär
// -----------------------------
class _MuscleGroupCard extends StatelessWidget {
  final String title;
  final List<String> muscles;
  final String fallback;

  const _MuscleGroupCard({
    required this.title,
    required this.muscles,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (muscles.isEmpty)
            Text(
              fallback,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscles
                  .map(
                    (m) => Chip(
                      label: Text(m),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}
