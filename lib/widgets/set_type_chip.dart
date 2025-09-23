// lib/widgets/set_type_chip.dart

import 'package:flutter/material.dart';

class SetTypeChip extends StatelessWidget {
  final String setType;
  final int? setIndex;
  final bool isCompleted;
  final VoidCallback? onTap;

  const SetTypeChip({
    super.key,
    required this.setType,
    this.setIndex, // setIndex ist jetzt optional
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> typeInfo = {
      'normal': {'char': setIndex.toString(), 'color': Colors.grey},
      'warmup': {'char': 'W', 'color': Colors.orange},
      'failure': {'char': 'F', 'color': Colors.red},
      'dropset': {'char': 'D', 'color': Colors.blue},
    };
    final type = typeInfo[setType] ?? typeInfo['normal']!;
    final Color textColor = type['color'];

    return GestureDetector(
      onTap: isCompleted ? null : onTap,
      child: SizedBox(
        width: 40, // Feste Breite für die Spalte
        height: 40, // Feste Höhe
        child: Center(
          child: Text(
            type['char'],
            style: TextStyle(
              color: textColor,
              fontSize: 20, // Größere Schriftart
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
