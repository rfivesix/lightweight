// lib/widgets/workout_card.dart
import 'package:flutter/material.dart';

class WorkoutCard extends StatelessWidget {
  /// Child content padding (now zero to span full width).
  final EdgeInsetsGeometry padding;

  /// Outer margin (now zero to span full width).
  final EdgeInsetsGeometry margin;

  final dynamic child;

  const WorkoutCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    // transparent background for the card itself
    const background = Colors.transparent;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        // remove default shadow if you want full transparency
        boxShadow: [
          // optional: keep or remove shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: _AlternatingBackground(
        child: child,
      ),
    );
  }
}

/// Wraps the child and applies alternating grey backgrounds to its direct row children.
class _AlternatingBackground extends StatelessWidget {
  final Widget child;
  const _AlternatingBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.from(
        (child as Column).children.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          final color = idx.isOdd
              ? Colors.grey.shade900.withOpacity(0.1)
              : Colors.grey.shade900.withOpacity(0.05);
          return Container(
            color: color,
            child: row,
          );
        }),
      ),
    );
  }
}
