import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lightweight/services/theme_service.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';

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

Future<T?> showGlassBottomMenu<T>({
  required BuildContext context,
  String? title,
  List<GlassMenuAction>? actions,
  Widget Function(BuildContext, VoidCallback)? contentBuilder,
}) {
  assert(
    (actions != null && contentBuilder == null) ||
        (actions == null && contentBuilder != null),
    'Either actions OR contentBuilder must be provided',
  );

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final themeService = Provider.of<ThemeService>(context, listen: false);
  final bool isLiquid = themeService.visualStyle == 1;

  final Color barrierColor = isDark
      ? (!isLiquid
          ? Colors.grey.withOpacity(0.187) // old dark barrier for liquid glass
          : Colors.black.withOpacity(0.5)) // new dark barrier
      : Colors.black.withOpacity(0.3); // unchanged light barrier

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    builder: (ctx) {
      final kb = MediaQuery.of(ctx).viewInsets.bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: kb),
        child: _GlassBottomMenuSheet(
          title: title,
          actions: actions ?? const <GlassMenuAction>[],
          contentBuilder: contentBuilder,
        ),
      );
    },
  );
}

class _GlassBottomMenuSheet extends StatelessWidget {
  const _GlassBottomMenuSheet({
    this.title,
    this.contentBuilder,
    this.actions = const <GlassMenuAction>[],
  });

  final String? title;
  final Widget Function(BuildContext, VoidCallback)? contentBuilder;
  final List<GlassMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = media.viewPadding.bottom;
    final themeService = context.watch<ThemeService>();

    // neutral tint + effective glass color (works on dark/light + empty background)
    final Color neutralTint = (isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.22));
    final Color effectiveGlass = Color.alphaBlend(
      neutralTint,
      theme.colorScheme.surface.withOpacity(isDark ? 0.22 : 0.22),
    );

    const double r = 24; // corner radius of the floating card
    const EdgeInsets outerMargin =
        EdgeInsets.fromLTRB(16, 0, 16, 16); // paddings around the card

    // --- Common content (title + actions/contentBuilder) ---
    Widget contentColumn() {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // handle
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
          ],
        ),
      );
    }

    // --- Floating card surfaces ---
    Widget liquidCard() {
      return Stack(
        children: [
          // Soft drop shadow behind the card (kept outside the glass)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
            ),
          ),
          LiquidGlass.withOwnLayer(
            settings: LiquidGlassSettings(
              thickness: 25,
              blur: 8,
              glassColor: effectiveGlass,
              lightIntensity: 0.35,
              saturation: 1.10,
            ),
            shape: const LiquidRoundedSuperellipse(borderRadius: r),
            child: Stack(
              children: [
                // base tint inside the card – keeps slight tone on empty bg
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: neutralTint,
                      borderRadius: BorderRadius.circular(r),
                    ),
                  ),
                ),
                // subtle rim
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.20)
                              : Colors.black.withOpacity(0.08),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                contentColumn(),
              ],
            ),
          ),
        ],
      );
    }

    Widget plainCard() {
      return Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(
                    isDark ? 0.80 : 0.92,
                  ),
                ),
                child: contentColumn(),
              ),
            ),
          ),
        ],
      );
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: outerMargin,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: themeService.visualStyle == 1 ? liquidCard() : plainCard(),
          ),
        ),
      ),
    );
  }
}

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
    //theme.color
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;
    final themeService = context.watch<ThemeService>();
    final Color neutralTint =
        (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.1 : 0.1);
    final Color effectiveGlass = Color.alphaBlend(
        neutralTint, Colors.white.withOpacity(isDark ? 0.10 : 0.12));

    final tileContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.2),
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
    );

    switch (themeService.visualStyle) {
      case 1:
        return LiquidGlass.withOwnLayer(
          settings: LiquidGlassSettings(
            thickness: 25,
            blur: 5,
            glassColor: effectiveGlass,
            lightIntensity: 0.35,
            saturation: 1.10,
          ),
          shape: const LiquidRoundedSuperellipse(borderRadius: 18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: neutralTint),
                    ),
                  ),
                  // Inhalt
                  Positioned.fill(child: tileContent),
                ],
              ),
            ),
          ),
        );

      default:
        return Material(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: tileContent,
          ),
        );
    }
  }
}
