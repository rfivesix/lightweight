// lib/widgets/workout_card.dart
import 'package:flutter/material.dart';

class WorkoutCard extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Widget child;

  const WorkoutCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key, // Key an den Container weitergeben
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.transparent, // Komplett transparent
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        // Stellt sicher, dass die Ecken der Kinder abgerundet sind
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}
