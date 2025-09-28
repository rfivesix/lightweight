import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lightweight/theme/color_constants.dart';

class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final List<BottomNavigationBarItem> items;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDark ? summary_card_dark_mode : summary_card_white_mode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 70, // Höhe angepasst für besseres Tapping
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Die Navigations-Items nehmen den verfügbaren Platz ein
              ...List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;
                return _buildNavItem(
                  context,
                  item,
                  isSelected,
                  () => onTap(index),
                );
              }),
              // Ein Trenner, um den FAB visuell abzugrenzen
              const SizedBox(width: 8),
              // Der FAB als Teil der Row
              _buildFab(theme.colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab(ColorScheme colorScheme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onFabTap,
          customBorder: const CircleBorder(),
          child: Icon(Icons.add, color: colorScheme.onPrimary, size: 32),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    BottomNavigationBarItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(color: color, size: 24),
                child: item.icon,
              ),
              const SizedBox(height: 2),
              Text(
                item.label ?? '',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}