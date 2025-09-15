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
      //margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        // DOC: SCHATTEN VERSTÄRKT
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15), // Etwas dunkler
            blurRadius: 25,                        // Weicher und größer
            spreadRadius: 0,                         // Etwas breiter
            offset: const Offset(0, 15),           // Deutlich nach unten verschoben
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: colorScheme.surfaceContainerHighest.withOpacity(0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}