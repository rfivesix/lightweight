// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lightweight/generated/app_localizations.dart';

// TODO: Ersetze diese Imports durch deine echten Screens/Routes
import 'package:lightweight/screens/main_screen.dart';
import 'package:lightweight/screens/goals_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _page = PageController();
  int _index = 0;
  bool _goalVisited = false;
  final bool _foodVisited = false;
  final bool _trainVisited = false;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    // Zurück ins Haupt-UI
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (r) => false,
    );
  }

  void _next(int lastIndex) {
    if (_index < lastIndex) {
      _page.animateToPage(
        _index + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final pages = <Widget>[
      _Slide(
        icon: Icons.flag,
        title: l10n.onbWelcomeTitle,
        body: l10n.onbWelcomeBody,
        primaryCta: _Cta(
          icon: Icons.edit_outlined,
          label: l10n.onbSetGoalsCta,
          onTap: () async {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GoalsScreen()));
            if (!mounted) return;
            setState(() => _goalVisited = true);
          },
        ),
        footer: _goalVisited
            ? _Badge(text: l10n.onbBadgeDone)
            : _Hint(text: l10n.onbTipSetGoals),
      ),
      // 2) Nutrition (nur Beschreibung, kein Link)
      _Slide(
        icon: Icons.restaurant_menu,
        title: l10n
            .onbTrackTitle, // oder eigener Titel, z. B. l10n.onbNutritionTitle
        body: l10n
            .onbTrackHowBody, // bereits eingefügt: Schrittfolge fürs Essen-Loggen
        primaryCta: null,
        footer: _Hint(text: l10n.onbTipAddEntry),
      ),

      // 3) Measurements (neue Folie)
      _Slide(
        icon: Icons.monitor_weight_outlined,
        title: l10n.onbMeasureTitle,
        body: l10n.onbMeasureBody, // Schrittfolge zum Hinzufügen von Messungen
        primaryCta: null,
        footer: _Hint(text: l10n.onbTipMeasureToday),
      ),

      // 4) Training: Routine erstellen + Workout starten (neue Folie)
      _Slide(
        icon: Icons.fitness_center,
        title: l10n.onbTrainTitle,
        body: l10n.onbTrainBody, // Kombinierte Anleitung Routine/Workout
        primaryCta: null,
        footer: _Hint(text: l10n.onbTipStartWorkout),
      ),

      // 5) Offline & Privacy bleibt
      _Slide(
        icon: Icons.lock_outline,
        title: l10n.onbPrivacyTitle,
        body: l10n.onbPrivacyBody,
        primaryCta: null,
        footer: _Hint(text: l10n.onbTipLocalControl),
      ),

      // 6) Finish bleibt
      _FinalSlide(
        title: l10n.onbFinishTitle,
        body: l10n.onbFinishBody,
        onFinish: _finish,
      ),
    ];

    final lastIndex = pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text(l10n.onbHeaderTitle, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  TextButton(onPressed: _skip, child: Text(l10n.onbHeaderSkip)),
                ],
              ),
            ),
            // Compact guide banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.swipe, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.onbGuideTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.onbGuideBody,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => pages[i],
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(6),
                  height: 8,
                  width: _index == i ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _index == i
                        ? theme.colorScheme.primary
                        : theme.disabledColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            // Bottom bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _index == 0
                          ? null
                          : () => _page.animateToPage(
                                _index - 1,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                      icon: const Icon(Icons.chevron_left),
                      label: Text(l10n.onbBack),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _next(lastIndex),
                      icon: Icon(
                        _index < lastIndex ? Icons.chevron_right : Icons.check,
                      ),
                      label: Text(
                        _index < lastIndex ? l10n.onbNext : l10n.onbFinishCta,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final _Cta? primaryCta;
  final Widget? footer;
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    this.primaryCta,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: DesignConstants.spacingL),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          if (primaryCta != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: primaryCta!.onTap,
                icon: Icon(primaryCta!.icon),
                label: Text(primaryCta!.label),
              ),
            ),
          if (footer != null) ...[
            const SizedBox(height: DesignConstants.spacingM),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _FinalSlide extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onFinish;
  const _FinalSlide({
    required this.title,
    required this.body,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: DesignConstants.spacingL),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.check),
              label: Text(AppLocalizations.of(context)!.onbFinishCta),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cta {
  final IconData icon;
  final String label;
  final Future<void> Function()? onTap;
  const _Cta({required this.icon, required this.label, this.onTap});
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.primary.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: c.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: c.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
    );
  }
}
