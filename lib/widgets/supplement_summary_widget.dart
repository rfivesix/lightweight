import 'package:flutter/material.dart';
import 'package:lightweight/screens/supplement_hub_screen.dart';
import 'package:lightweight/widgets/glass_progress_bar.dart';
import 'package:lightweight/theme/color_constants.dart';
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
    final goalOnlySupplements = trackedSupplements
        .where((ts) =>
            ts.supplement.dailyGoal != null && ts.supplement.dailyLimit == null)
        .toList();

    final progressSupplements = trackedSupplements
        .where((ts) => ts.supplement.dailyLimit != null)
        .toList();

    if (goalOnlySupplements.isEmpty && progressSupplements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ...goalOnlySupplements.map((ts) => GestureDetector(
              onTap: onTap,
              child: _CheckmarkCard(trackedSupplement: ts),
            )),
        ...progressSupplements.map((ts) {
          final supplement = ts.supplement;
          return GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: GlassProgressBar(
                label: supplement.name,
                unit: supplement.unit,
                value: ts.totalDosedToday,
                target: supplement.dailyLimit!,
                color: Colors.amber.shade600,
                height: 50,
                borderRadius: 16,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CheckmarkCard extends StatelessWidget {
  final TrackedSupplement trackedSupplement;
  const _CheckmarkCard({required this.trackedSupplement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final supplement = trackedSupplement.supplement;
    final doseTaken = trackedSupplement.totalDosedToday;
    final isDone = doseTaken > 0;

    final String displayText;
    if (isDone) {
      displayText =
          '${doseTaken.toStringAsFixed(1).replaceAll('.0', '')} ${supplement.unit}';
    } else {
      displayText =
          '${supplement.dailyGoal?.toStringAsFixed(1).replaceAll('.0', '') ?? ''} ${supplement.unit}';
    }

    final backgroundColor = brightness == Brightness.dark
        ? summary_card_dark_mode
        : summary_card_white_mode;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green.shade400 : Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              supplement.name,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            displayText,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
