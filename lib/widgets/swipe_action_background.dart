import 'package:flutter/material.dart';

class SwipeActionBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Alignment alignment;

  const SwipeActionBackground({
    super.key,
    required this.color,
    required this.icon,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          vertical: 6.0), // Selber Margin wie SummaryCard
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(20), // Selber Radius wie SummaryCard
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
