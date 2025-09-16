import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SummaryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12.0),
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final background = brightness == Brightness.dark
        ? const Color.fromARGB(255, 22, 22, 22) // tiefes Grau für Dark Mode
        : const Color.fromARGB(
            255, 253, 253, 253); // sehr helles Grau für Light Mode

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
