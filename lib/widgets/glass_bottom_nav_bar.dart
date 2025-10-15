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
  // Add inside class GlassBottomNavBar
  Widget _buildNavItem(
    BuildContext context,
    BottomNavigationBarItem item,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    final color = isSelected ? cs.primary : cs.onSurface.withOpacity(0.60);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconTheme(
                      data: IconThemeData(color: color, size: 24),
                      child: item.icon,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label ?? '',
                      maxLines: 1,
                      //overflow: TextOverflow.,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w400 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? summary_card_dark_mode : summary_card_white_mode;
    final backgroundColor =
        isDark ? summary_card_dark_mode : summary_card_white_mode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg.withOpacity(0.80),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.30)
                  : Colors.black.withOpacity(0.10),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Only the 4 nav items now
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareFab extends StatelessWidget {
  final VoidCallback onTap;
  const _SquareFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      // tiny inset so it doesn’t kiss the bar’s edge
      padding: const EdgeInsets.only(right: 4),
      child: SizedBox(
        width: 68, // a bit chunkier
        height: 68,
        child: Material(
          color: cs.primary, // accent
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // closer to the bar’s 24
            side: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.20)
                  : Colors.black.withOpacity(0.10),
              width: 1, // same outline weight as the glass card
            ),
          ),
          elevation: 0, // we’ll use a soft drop shadow via DecoratedBox
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                // soft drop shadow so it feels detached
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    offset: Offset(0, 8),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.add, size: 30, color: cs.onPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final BottomNavigationBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color color =
        isSelected ? cs.primary : cs.onSurface.withOpacity(0.60);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // content
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconTheme(
                      data: IconThemeData(color: color, size: 24),
                      child: item.icon,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // tiny top indicator (2px)
              if (isSelected)
                Positioned(
                  top: 0,
                  child: Container(
                    width: 24,
                    height: 2,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
