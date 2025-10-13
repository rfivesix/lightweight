import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lightweight/generated/app_localizations.dart';

/// One action row in the glass menu.
class GlassMenuAction {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  GlassMenuAction({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
}

/// Show the glass bottom menu with a static blurred scrim (like GlassFab).
/// Drag-to-dismiss is handled by showModalBottomSheet.
Future<T?> showGlassBottomMenu<T>({
  required BuildContext context,
  String? title,
  List<GlassMenuAction>? actions, // ⬅️ jetzt optional
  Widget Function(BuildContext, VoidCallback)? contentBuilder, // ⬅️ NEU
}) {
  assert(
    (actions != null && contentBuilder == null) ||
        (actions == null && contentBuilder != null),
    'Either actions OR contentBuilder must be provided',
  );
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false, // lassen wir so
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    // 👇 animiert automatisch mit dem Sheet (kein „an/aus“)
    barrierColor: isDark
        ? Colors.black.withOpacity(0.50)
        : Colors.black.withOpacity(0.30),
    builder: (ctx) {
      final kb = MediaQuery.of(ctx).viewInsets.bottom; // Tastaturhöhe
      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: kb),
        child: _GlassBottomMenuSheet(
          title: title,
          actions: actions ?? const <GlassMenuAction>[], // ⬅️ nie null
          contentBuilder: contentBuilder, // ⬅️ sicher weitergeben
        ),
      );
    },
  );
}

class _GlassBottomMenuSheet extends StatelessWidget {
  const _GlassBottomMenuSheet({
    this.title,
    this.contentBuilder,
    this.actions = const <GlassMenuAction>[], // ⬅️ Default: leere Liste
  });

  final String? title;
  final Widget Function(BuildContext, VoidCallback)? contentBuilder;
  final List<GlassMenuAction> actions; // ⬅️ non-null

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = media.viewPadding.bottom;
    final keyboard = media.viewInsets.bottom; // ⬅️ NEU: Tastaturhöhe

    return SafeArea(
      top: false,
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _GlassSurface(
          // straight top line color (like GlassFab), tuned for dark mode
          topBorderColor: isDark
              ? Colors.white.withOpacity(0.22)
              : Colors.black.withOpacity(0.10),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Drag handle
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (contentBuilder != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: contentBuilder!(
                      context,
                      () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ] else if (actions.isNotEmpty) ...[
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                        shrinkWrap: true,
                        itemCount: actions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final a = actions[i];
                          return _GlassTile(
                            icon: a.icon,
                            title: a.label,
                            subtitle: a.subtitle,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(context).maybePop();
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => a.onTap(),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
                /*if (contentBuilder != null) ...[
  const SizedBox(height: 12),
  Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ),1
        const SizedBox(width: 12),
        Expanded(
          child: _InlinePrimaryButton(), // ⬅️ Handler wird im Aufrufer gesetzt (siehe unten)
        ),
      ],
    ),
  ),
]
*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted glass surface: full width, rounded only on top.
/// IMPORTANT: Straight top line (not following the curve) is painted OUTSIDE the clip.
class _GlassSurface extends StatelessWidget {
  const _GlassSurface({required this.child, required this.topBorderColor});

  final Widget child;
  final Color topBorderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Slightly different from summary-cards to stand out
    final c0 = theme.colorScheme.surface.withOpacity(isDark ? 0.86 : 0.94);
    final c1 = theme.colorScheme.surface.withOpacity(isDark ? 0.70 : 0.88);

    return Stack(
      clipBehavior: Clip.none, // allow the straight top line to draw freely
      children: [
        // Blurred glass body with rounded top corners
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c0, c1],
                ),
              ),
              child: child,
            ),
          ),
        ),
        // Straight top divider line (not following the curve)
        // Hard top edge that follows the rounded corners
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TopEdgePainter(
                color: topBorderColor,
                radius: 24, // ⬅️ dein Top-Radius
                strokeWidth: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual action row with subtle glass button look.
class _GlassTile extends StatelessWidget {
  const _GlassTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

    return Material(
      color: isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.white.withOpacity(0.12),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.14 : 0.18),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: textTheme.bodySmall?.color?.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Colors.white.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopEdgePainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  _TopEdgePainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // RRect mit nur oben gerundeten Ecken
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );

    // Nur den oberen Bereich zeichnen (inkl. Rundungen)
    final clipBand = Rect.fromLTWH(0, 0, size.width, radius + strokeWidth);
    canvas.save();
    canvas.clipRect(clipBand);

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    final path = Path()..addRRect(rrect);
    canvas.drawPath(path, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TopEdgePainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

class _InlinePrimaryButton extends StatelessWidget {
  const _InlinePrimaryButton(this.onPressed, this.label);
  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FilledButton(
      onPressed: onPressed,
      child: Text(label ?? l10n.add_button),
    );
  }
}
