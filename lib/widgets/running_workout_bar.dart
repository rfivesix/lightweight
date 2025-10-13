// lib/widgets/running_workout_bar.dart

import 'package:flutter/material.dart';

class RunningWorkoutBar extends StatelessWidget {
  final String timeText; // z.B. "13:12"
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const RunningWorkoutBar({
    super.key,
    required this.timeText,
    required this.onResume,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Zeit (links)
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20),
              const SizedBox(width: 6),
              Text(
                timeText,
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        // Fortsetzen (Accent)
        FilledButton(
          onPressed: onResume,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Fortsetzen'),
        ),
        const SizedBox(width: 8),
        // Verwerfen (Rot)
        FilledButton(
          onPressed: onDiscard,
          style: FilledButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: cs.onError,
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Verwerfen'),
        ),
      ],
    );
  }
}
