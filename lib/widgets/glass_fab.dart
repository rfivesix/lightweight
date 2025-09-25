import 'dart:ui';
import 'package:flutter/material.dart';

class GlassFab extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label; // KORREKTUR: Label ist jetzt optional (kann null sein)

  const GlassFab({
    super.key,
    required this.onPressed,
    this.label, // KORREKTUR: Nicht mehr 'required'
    this.icon = Icons.add,
  });

  @override
  State<GlassFab> createState() => _GlassFabState();
}

class _GlassFabState extends State<GlassFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - _controller.value;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              // KORREKTUR: Höhe und Breite sind jetzt dynamisch
              height: 76,
              width: widget.label != null
                  ? null
                  : 76, // Quadratisch, wenn kein Label
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              // KORREKTUR: Inhalt hängt davon ab, ob ein Label existiert
              child: Padding(
                padding: widget.label != null
                    ? const EdgeInsets.symmetric(horizontal: 24.0)
                    : EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 30,
                      color: Colors.white,
                    ),
                    if (widget.label != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        widget.label!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
