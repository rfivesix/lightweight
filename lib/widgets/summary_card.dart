// lib/widgets/summary_card.dart (Endgültige Korrektur)

import 'dart:ui';
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final Widget child;

  const SummaryCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      decoration: BoxDecoration(
        // KORREKTUR: Rundung direkt in der BoxDecoration ändern
        borderRadius:
            BorderRadius.circular(16.0), // Rundung von 24 auf 16 reduziert
        // KORREKTUR: Schatten direkt in der BoxDecoration ändern
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.08), // Leichterer, dezenterer Schatten
            blurRadius: 15, // Weicher und kleiner
            spreadRadius: 0,
            offset: const Offset(0, 8), // Weniger stark nach unten verschoben
          ),
        ],
      ),
      child: ClipRRect(
        // KORREKTUR: Rundung direkt in ClipRRect ändern
        borderRadius:
            BorderRadius.circular(16.0), // Passende Rundung für ClipRRect
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.9),
              // KORREKTUR: Rundung und Rand in der inneren BoxDecoration anpassen
              borderRadius: BorderRadius.circular(16.0), // Passende Rundung
              border: Border.all(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
