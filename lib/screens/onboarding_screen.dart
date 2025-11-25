// lib/screens/onboarding_screen.dart
// VOLLSTÄNDIGE DATEI (LOKALISIERT)

import 'package:flutter/material.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/main_screen.dart';
import 'package:lightweight/screens/goals_screen.dart';
import 'package:lightweight/theme/color_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _page = PageController();
  int _index = 0;

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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Wir erstellen die Liste der Folien
    final pages = <Widget>[
      // 1) Welcome/Goals
      _WelcomeSlide(
        title: l10n.appTitle,
        subtitle: l10n.onbSubtitleWelcome,
        body: l10n.onbBodyWelcome,
        primaryCta: _Cta(
          icon: Icons.edit_outlined,
          label: l10n.onbSetGoalsCta,
          onTap: () async {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GoalsScreen()));
          },
        ),
      ),

      // 2) Nutrition: Visueller Fokus auf Today-Summary
      _VisualSlide(
        title: l10n.nutrition,
        body: l10n.onbBodyNutritionVisual,
        visual: _NutritionDiaryVisual(l10n: l10n),
      ),

      // 3) Measurements: Visueller Fokus auf Chart
      _VisualSlide(
        title: l10n.drawerMeasurements,
        body: l10n.onbBodyMeasurementsVisual,
        visual: _MeasurementChartVisual(l10n: l10n),
      ),

      // 4) Training: Visueller Fokus auf Workout History
      _VisualSlide(
        title: l10n.workout,
        body: l10n.onbBodyWorkoutVisual,
        visual: _WorkoutHistoryVisual(l10n: l10n),
      ),

      // 5) App-Bauplan: Bottom Bar und FAB
      _AppLayoutSlide(
        title: l10n.onbTitleAppLayout,
        body: l10n.onbBodyAppLayout,
      ),

      // 6) Privacy bleibt
      _TextSlide(
        icon: Icons.lock_outline,
        title: l10n.onbPrivacyTitle,
        body: l10n.onbPrivacyBody,
      ),

      // 7) Finish bleibt
      _FinalSlide(
        title: l10n.onbFinishTitle,
        body: l10n.onbFinishBody,
        onFinish: _finish,
      ),
    ];

    final lastIndex = pages.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildAppBarHeader(context, l10n),

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

  Widget _buildAppBarHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // App-Name
          Text(l10n.appTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  )),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// NEUE/ANGEPASSTE SLIDE-KOMPONENTEN FÜR DAS VISUELLE DESIGN
// ----------------------------------------------------

class _WelcomeSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final String body;
  final _Cta? primaryCta;
  const _WelcomeSlide({
    required this.title,
    required this.subtitle,
    required this.body,
    this.primaryCta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waving_hand, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: DesignConstants.spacingL),
          Text(
            title,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
          if (primaryCta != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: primaryCta!.onTap,
                icon: Icon(primaryCta!.icon),
                label: Text(primaryCta!.label),
              ),
            ),
        ],
      ),
    );
  }
}

// Allgemeine Text-Slide (für Privacy)
class _TextSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _TextSlide({
    required this.icon,
    required this.title,
    required this.body,
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
          const SizedBox(height: DesignConstants.spacingXL),
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
        ],
      ),
    );
  }
}

// Slide mit Fokus auf eine Visualisierung (für Nutrition/Stats/Training)
class _VisualSlide extends StatelessWidget {
  final String title;
  final String body;
  final Widget visual;
  const _VisualSlide({
    required this.title,
    required this.body,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Visuelle Komponente (Container ohne Border)
            Container(
              height: 240, // Höhe beibehalten
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(DesignConstants.borderRadiusL),
                // Hintergrundfarbe des SummaryCard/Dialogs
                color: theme.brightness == Brightness.dark
                    ? summary_card_dark_mode
                    : summary_card_white_mode,
              ),
              child: visual,
            ),
            const SizedBox(height: DesignConstants.spacingXL),

            // Textlicher Inhalt
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
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

// Finale Folie (unverändert)
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

// ----------------------------------------------------
// HILFS-KLASSEN FÜR DIE VISUALISIERUNGEN (SIMULIERT)
// ----------------------------------------------------

class _NutritionDiaryVisual extends StatelessWidget {
  final AppLocalizations l10n;
  const _NutritionDiaryVisual({required this.l10n});

  @override
  Widget build(BuildContext context) {
    // KORRIGIERT: Abstand unten reduziert, um Platz zu sparen
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titel
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.today_overview_text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          // 2x2 Makros
          Row(
            children: [
              Expanded(
                child: _SimulatedMacroCard(
                  label: l10n.calories,
                  unit: 'kcal',
                  value: 1853,
                  target: 2500,
                  color: Colors.orange.shade400,
                  height: 50,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SimulatedMacroCard(
                  label: l10n.protein,
                  unit: 'g',
                  value: 116,
                  target: 180,
                  color: Colors.red.shade400,
                  height: 50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SimulatedMacroCard(
                  label: l10n.water,
                  unit: 'ml',
                  value: 1400,
                  target: 3000,
                  color: Colors.blue.shade400,
                  height: 50,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SimulatedMacroCard(
                  label: l10n.carbs,
                  unit: 'g',
                  value: 203,
                  target: 250,
                  color: Colors.green.shade400,
                  height: 50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 2x1 Makros + Supps
          Row(
            children: [
              Expanded(
                child: _SimulatedSuppTile(
                  label: l10n.supplement_creatine_monohydrate,
                  value: '5 g',
                  isDone: true,
                  height: 50,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SimulatedMacroCard(
                  label: l10n.supplement_caffeine,
                  unit: 'mg',
                  value: 100,
                  target: 400,
                  color: Colors.orange.shade600,
                  height: 50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// NEU: Simuliert eine Makro-Card (Kopie der Logik aus NutritionSummaryWidget)
class _SimulatedMacroCard extends StatelessWidget {
  final String label;
  final String unit;
  final double value;
  final double target;
  final Color color;
  final double height;
  final bool isPrimary;
  const _SimulatedMacroCard({
    required this.label,
    required this.unit,
    required this.value,
    required this.target,
    required this.color,
    this.height = 70.0,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasTarget = target > 0;
    final progress = hasTarget ? (value / target).clamp(0.0, 1.0) : 0.0;
    const borderRadius = 12.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Progress Bar
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(color: color),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: isPrimary ? cs.onPrimary : cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasTarget
                        ? '${value.toStringAsFixed(1).replaceAll('.0', '')} / ${target.toStringAsFixed(0)} $unit'
                        : '${value.toStringAsFixed(1).replaceAll('.0', '')} $unit',
                    style: TextStyle(
                      color: isPrimary
                          ? cs.onPrimary
                          : cs.onSurface.withOpacity(0.8),
                      fontSize: 14,
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

class _SimulatedSuppTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDone;
  final double height;
  const _SimulatedSuppTile({
    required this.label,
    required this.value,
    this.isDone = false,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.cardColor;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green.shade400 : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// NEU: Simulierte Chart-Ansicht
class _MeasurementChartVisual extends StatelessWidget {
  final AppLocalizations l10n;
  const _MeasurementChartVisual({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.weightHistoryTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Row(
                children: [
                  _ChartFilterButton(label: '30D', isSelected: false),
                  _ChartFilterButton(label: '90D', isSelected: true),
                  _ChartFilterButton(label: 'All', isSelected: false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                // Y-Achse
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('80', style: theme.textTheme.bodySmall),
                      Text('75', style: theme.textTheme.bodySmall),
                      Text('70', style: theme.textTheme.bodySmall),
                      Text('65', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                // Chart & Daten
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '65.0 kg',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        'Oct 18, 2025',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CustomPaint(
                          painter: _LineChartPainter(
                            lineColor: cs.primary,
                          ),
                          child: Container(),
                        ),
                      ),
                      // X-Achse (Datum)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Aug 7', style: theme.textTheme.bodySmall),
                          Text('Aug 31', style: theme.textTheme.bodySmall),
                          Text('Sep 24', style: theme.textTheme.bodySmall),
                          Text('Oct 18', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartFilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _ChartFilterButton({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// NEU: Simuliert den Workout-Verlauf
class _WorkoutHistoryVisual extends StatelessWidget {
  final AppLocalizations l10n;
  const _WorkoutHistoryVisual({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Titel
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.workoutHistoryTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),

          // Log 1
          const _WorkoutLogItem(
            title: 'Backday',
            date: '18. Oktober 2025 16:09',
            volume: '9138 kg',
            sets: '10 Sätze',
            duration: '1:06:34',
          ),
          const SizedBox(height: 8),

          // Log 2
          const _WorkoutLogItem(
            title: 'Legday',
            date: '14. Oktober 2025 12:27',
            volume: '8057 kg',
            sets: '10 Sätze',
            duration: '1:43:34',
          ),
        ],
      ),
    );
  }
}

class _WorkoutLogItem extends StatelessWidget {
  final String title;
  final String date;
  final String volume;
  final String sets;
  final String duration;
  const _WorkoutLogItem({
    required this.title,
    required this.date,
    required this.volume,
    required this.sets,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calendar_month,
              size: 40, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  date,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.monitor_weight_outlined,
                        size: 14, color: Colors.grey.shade600),
                    Text(volume,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Icon(Icons.replay_circle_filled_outlined,
                        size: 14, color: Colors.grey.shade600),
                    Text(sets,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            duration,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

// Neue Folie für den App-Bauplan (Bottom Bar + FAB)
class _AppLayoutSlide extends StatelessWidget {
  final String title;
  final String body;
  const _AppLayoutSlide({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.widgets_outlined,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: DesignConstants.spacingXL),
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
          const SizedBox(height: DesignConstants.spacingXXL),
          // Simulierte Bottom Bar und FAB
          Container(
            height: 76,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? summary_card_dark_mode.withOpacity(0.8)
                  : summary_card_white_mode.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Spacer(),
                _NavIcon(
                    icon: Icons.book_outlined,
                    label: "Tagebuch",
                    isSelected: true),
                Spacer(flex: 2),
                _NavIcon(icon: Icons.fitness_center_outlined, label: "Workout"),
                Spacer(flex: 2),
                _NavIcon(icon: Icons.bar_chart_outlined, label: "Stats"),
                Spacer(flex: 2),
                _NavIcon(
                    icon: Icons.restaurant_menu_rounded, label: "Ernährung"),
                Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Simulierte FAB (separat gerendert, da er getrennt ist)
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: isDark
                  ? summary_card_dark_mode.withOpacity(0.8)
                  : summary_card_white_mode.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.add,
                color: isDark ? Colors.white : Colors.black, size: 34),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  const _NavIcon(
      {required this.icon, required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}

// ----------------------------------------------------
// HILFS-KLASSEN (unverändert)
// ----------------------------------------------------

class _LineChartPainter extends CustomPainter {
  final Color lineColor;
  _LineChartPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Simulierter Graph (von rechts nach links, wie im Screenshot)
    final path = Path()
      ..moveTo(size.width * 0.9, size.height * 0.9)
      ..lineTo(size.width * 0.7, size.height * 0.6)
      ..lineTo(size.width * 0.5, size.height * 0.8)
      ..lineTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(size.width * 0.1, size.height * 0.1);

    canvas.drawPath(path, paint);

    // Area (subtle fade)
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final areaPath = Path()
      ..addPath(path, Offset.zero)
      ..lineTo(size.width * 0.1, size.height * 0.95) // Basislinie links
      ..lineTo(size.width * 0.9, size.height * 0.95) // Basislinie rechts
      ..close();

    canvas.drawPath(areaPath, areaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
