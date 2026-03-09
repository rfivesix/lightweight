// lib/screens/consistency_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/database_helper.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/bottom_content_spacer.dart';

/// A screen displaying workout consistency metrics, streaks, and
/// an enhanced calendar with actionable insights.
///
/// Replaces the passive standalone calendar with meaningful analytics:
/// streak tracking, weekly workout frequency, and a heatmap-style calendar.
class ConsistencyAnalyticsScreen extends StatefulWidget {
  const ConsistencyAnalyticsScreen({super.key});

  @override
  State<ConsistencyAnalyticsScreen> createState() =>
      _ConsistencyAnalyticsScreenState();
}

class _ConsistencyAnalyticsScreenState
    extends State<ConsistencyAnalyticsScreen> {
  bool _isLoading = true;

  int _currentStreak = 0;
  int _longestStreak = 0;
  double _avgPerWeek = 0;
  int _workoutsThisWeek = 0;
  int _workoutsThisMonth = 0;
  Map<String, int> _workoutFrequency = {};

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<int> _calWorkoutDays = {};
  Set<int> _calNutritionDays = {};
  Set<int> _calSupplementDays = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      WorkoutDatabaseHelper.instance.getCurrentWorkoutStreak(),
      WorkoutDatabaseHelper.instance.getLongestWorkoutStreak(),
      WorkoutDatabaseHelper.instance.getAverageWorkoutsPerWeek(),
      WorkoutDatabaseHelper.instance.getWorkoutsThisWeek(),
      WorkoutDatabaseHelper.instance.getWorkoutsThisMonth(),
      WorkoutDatabaseHelper.instance.getWorkoutFrequencyByDay(),
      WorkoutDatabaseHelper.instance.getWorkoutDaysInMonth(_focusedDay),
      DatabaseHelper.instance.getNutritionLogDaysInMonth(_focusedDay),
      DatabaseHelper.instance.getSupplementLogDaysInMonth(_focusedDay),
    ]);
    if (mounted) {
      setState(() {
        _currentStreak = results[0] as int;
        _longestStreak = results[1] as int;
        _avgPerWeek = results[2] as double;
        _workoutsThisWeek = results[3] as int;
        _workoutsThisMonth = results[4] as int;
        _workoutFrequency = results[5] as Map<String, int>;
        _calWorkoutDays = results[6] as Set<int>;
        _calNutritionDays = results[7] as Set<int>;
        _calSupplementDays = results[8] as Set<int>;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCalendarMonth(DateTime month) async {
    final workoutDays =
        await WorkoutDatabaseHelper.instance.getWorkoutDaysInMonth(month);
    final nutritionDays =
        await DatabaseHelper.instance.getNutritionLogDaysInMonth(month);
    final supplementDays =
        await DatabaseHelper.instance.getSupplementLogDaysInMonth(month);
    if (mounted) {
      setState(() {
        _calWorkoutDays = workoutDays;
        _calNutritionDays = nutritionDays;
        _calSupplementDays = supplementDays;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.consistencyTitle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  DesignConstants.cardPaddingInternal,
                  topPadding + DesignConstants.spacingM,
                  DesignConstants.cardPaddingInternal,
                  0,
                ),
                children: [
                  _buildSectionTitle(context, l10n.consistencyStreaks),
                  _buildStreakCards(l10n, colorScheme),
                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(context, l10n.consistencyOverview),
                  _buildOverviewCards(l10n, colorScheme),
                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(context, l10n.consistencyWeeklyActivity),
                  _buildWeeklyHeatmap(colorScheme),
                  const SizedBox(height: DesignConstants.spacingXL),
                  _buildSectionTitle(context, l10n.my_consistency),
                  _buildEnhancedCalendar(l10n, colorScheme),
                  const BottomContentSpacer(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildStreakCards(AppLocalizations l10n, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.orange,
            value: '$_currentStreak',
            unit: l10n.consistencyDays,
            label: l10n.consistencyCurrentStreak,
          ),
        ),
        const SizedBox(width: DesignConstants.spacingS),
        Expanded(
          child: _StatCard(
            icon: Icons.military_tech_rounded,
            iconColor: Colors.amber,
            value: '$_longestStreak',
            unit: l10n.consistencyDays,
            label: l10n.consistencyLongestStreak,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards(AppLocalizations l10n, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_view_week_rounded,
            iconColor: colorScheme.primary,
            value: _avgPerWeek.toStringAsFixed(1),
            unit: '',
            label: l10n.consistencyAvgPerWeek,
          ),
        ),
        const SizedBox(width: DesignConstants.spacingS),
        Expanded(
          child: _StatCard(
            icon: Icons.fitness_center_rounded,
            iconColor: Colors.green,
            value: '$_workoutsThisWeek',
            unit: '',
            label: l10n.consistencyWorkoutsThisWeek,
          ),
        ),
        const SizedBox(width: DesignConstants.spacingS),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_month_rounded,
            iconColor: Colors.purple,
            value: '$_workoutsThisMonth',
            unit: '',
            label: l10n.consistencyWorkoutsThisMonth,
          ),
        ),
      ],
    );
  }

  /// Builds a 12-week heatmap grid showing workout activity.
  Widget _buildWeeklyHeatmap(ColorScheme colorScheme) {
    final now = DateTime.now();
    // Show 12 weeks; start on Monday 11 weeks back so the current week is included.
    const int heatmapWeeksBack = 11;
    final startMonday =
        now.subtract(Duration(days: now.weekday - 1 + heatmapWeeksBack * 7));

    final List<Widget> weekColumns = [];
    // Day-of-week labels
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    for (int week = 0; week < 12; week++) {
      final List<Widget> dayCells = [];
      for (int day = 0; day < 7; day++) {
        final date = startMonday.add(Duration(days: week * 7 + day));
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final count = _workoutFrequency[key] ?? 0;
        final isFuture = date.isAfter(now);

        Color cellColor;
        if (isFuture) {
          cellColor = Colors.transparent;
        } else if (count == 0) {
          cellColor = colorScheme.surfaceContainerHighest;
        } else {
          cellColor = colorScheme.primary.withValues(alpha: 0.85);
        }

        dayCells.add(
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }
      weekColumns.add(Column(
        mainAxisSize: MainAxisSize.min,
        children: dayCells,
      ));
    }

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day labels
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: dayLabels
                      .map((d) => SizedBox(
                            height: 15,
                            child: Text(d,
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.grey)),
                          ))
                      .toList(),
                ),
                const SizedBox(width: 4),
                Wrap(
                  direction: Axis.horizontal,
                  spacing: 0,
                  children: weekColumns,
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Rest', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 12),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Workout', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedCalendar(AppLocalizations l10n, ColorScheme colorScheme) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TableCalendar(
              locale: Localizations.localeOf(context).toString(),
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: Theme.of(context).textTheme.titleMedium!,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _loadCalendarMonth(focusedDay);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final isNutritionDay =
                      _calNutritionDays.contains(day.day);
                  final isSupplementDay =
                      _calSupplementDays.contains(day.day);

                  if (!isNutritionDay && !isSupplementDay) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isNutritionDay)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                            ),
                          ),
                        if (isNutritionDay && isSupplementDay)
                          const SizedBox(width: 2),
                        if (isSupplementDay)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                            ),
                          ),
                      ],
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  final isWorkoutDay = _calWorkoutDays.contains(day.day);
                  if (isWorkoutDay) {
                    return Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(
                      color: colorScheme.primary, label: 'Workout'),
                  const SizedBox(width: 12),
                  const _LegendDot(
                      color: Colors.blueAccent, label: 'Nutrition'),
                  const SizedBox(width: 12),
                  const _LegendDot(
                      color: Colors.amber, label: 'Supplements'),
                ],
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: DesignConstants.spacingS),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
