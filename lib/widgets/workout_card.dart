// lib/widgets/workout_card.dart
import 'package:flutter/material.dart';

/// A transparent container for workout items with rounded corners.
///
/// Used to group workout elements while maintaining layout consistency.
class WorkoutCard extends StatelessWidget {
  /// Internal padding for the [child].
  final EdgeInsetsGeometry padding;

  /// External margin for the card.
  final EdgeInsetsGeometry margin;

  /// The content within the card.
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
