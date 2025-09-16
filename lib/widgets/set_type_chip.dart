// lib/widgets/set_type_chip.dart

import 'package:flutter/material.dart';

class SetTypeChip extends StatelessWidget {
  final String setType;
  final int? setIndex; // Der tatsächliche Arbeits-Satz-Index (ohne Warmups)
  final bool isCompleted;
  final VoidCallback? onTap;

  const SetTypeChip({
    super.key,
    required this.setType,
    required this.setIndex,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> typeInfo = {
      'normal': {
        'char': setIndex.toString(),
        'color': Theme.of(context).colorScheme.primary
      },
      'warmup': {'char': 'W', 'color': Colors.orange.shade700},
      'failure': {'char': 'F', 'color': Colors.red.shade700},
      'dropset': {'char': 'D', 'color': Colors.blue.shade700},
    };
    final type = typeInfo[setType] ?? typeInfo['normal']!;

    return InkWell(
      onTap: isCompleted ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: isCompleted ? Colors.grey[300] : type['color'],
        child: Text(
          type['char'],
          style: TextStyle(
            color: isCompleted ? Colors.grey[700] : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
