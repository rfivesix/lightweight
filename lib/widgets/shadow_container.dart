// lib/widgets/shadow_container.dart

import 'package:flutter/material.dart';

class ShadowContainer extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? margin; // Optionaler externer Margin

  const ShadowContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16.0)),
    this.boxShadow,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow ?? [ // Standard-Schatten, wenn keiner angegeben ist
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect( // ClipRRect, um den Inhalt innerhalb der Ecken zu halten
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}