import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lightweight/screens/supplement_hub_screen.dart'; // Benötigt für TrackedSupplement
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/util/design_constants.dart';

class SupplementSummaryWidget extends StatelessWidget {
  final List<TrackedSupplement> trackedSupplements;
  final VoidCallback onTap;

  const SupplementSummaryWidget({
    super.key,
    required this.trackedSupplements,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Filtere nur die Supplements, die ein Ziel oder ein Limit haben.
    final relevantSupplements = trackedSupplements
        .where((ts) =>
            ts.supplement.dailyGoal != null || ts.supplement.dailyLimit != null)
        .toList();

    // Wenn es keine relevanten Supplements gibt, zeige das Widget gar nicht an.
    if (relevantSupplements.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: SummaryCard(
        // Das Padding ist für die äußere Karte.
        padding: const EdgeInsets.all(12.0),
        child: Column(
          // Erzeuge für jedes relevante Supplement eine Info-Box.
          children: List.generate(relevantSupplements.length, (index) {
            final ts = relevantSupplements[index];
            return Padding(
              // Füge einen Abstand zwischen den Boxen hinzu, aber nicht nach der letzten.
              padding: EdgeInsets.only(
                bottom: index == relevantSupplements.length - 1
                    ? 0
                    : DesignConstants.spacingS,
              ),
              child: _SupplementInfoBox(trackedSupplement: ts),
            );
          }),
        ),
      ),
    );
  }
}

/// Diese interne Klasse ist eine exakte Kopie der _InfoBox aus dem
/// NutritionSummaryWidget, angepasst für Supplement-Daten.
class _SupplementInfoBox extends StatelessWidget {
  final TrackedSupplement trackedSupplement;

  const _SupplementInfoBox({required this.trackedSupplement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final colorScheme = theme.colorScheme;
    final supplement = trackedSupplement.supplement;

    // Logik zur Bestimmung des Fortschritts und der Farbe
    final isLimit = supplement.dailyLimit != null;
    final target = (isLimit ? supplement.dailyLimit : supplement.dailyGoal)!;
    final overTarget = isLimit && trackedSupplement.totalDosedToday > target;

    final hasTarget = target > 0;
    final rawProgress =
        hasTarget ? (trackedSupplement.totalDosedToday / target) : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);
    final progressColor =
        overTarget ? Colors.red.shade400 : Colors.green.shade400;

    // Farben für den "Frostglas"-Effekt
    final backgroundColor = brightness == Brightness.dark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.65);

    final borderColor = brightness == Brightness.dark
        ? Colors.white.withOpacity(0.20)
        : Colors.black.withOpacity(0.12);

    return Container(
      height: 60, // Feste Höhe für eine konsistente Optik
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Animierter Fortschrittsbalken im Hintergrund
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(color: progressColor),
                ),
              ),
              // Text-Inhalt im Vordergrund
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        supplement.name,
                        maxLines: 1,
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trackedSupplement.totalDosedToday.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} ${supplement.unit}',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
