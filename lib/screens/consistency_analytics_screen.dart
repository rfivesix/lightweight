// lib/screens/consistency_analytics_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

/// A screen for analyzing training consistency.
///
/// Shows streaks, weekly workout frequency, a bar chart of workouts per week,
/// and a meaningful calendar highlighting training days.
class ConsistencyAnalyticsScreen extends StatefulWidget {
  const ConsistencyAnalyticsScreen({super.key});

  @override
  State<ConsistencyAnalyticsScreen> createState() =>
      _ConsistencyAnalyticsScreenState();
}

class _ConsistencyAnalyticsScreenState
    extends State<ConsistencyAnalyticsScreen> {
  bool _isLoading = true;
  ConsistencyStats? _stats;
  DateTime _calendarFocusedDay = DateTime.now();
  DateTime? _calendarSelectedDay;

  @override
  void initState() {
    super.initState();
    _calendarSelectedDay = _calendarFocusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final stats =
        await WorkoutDatabaseHelper.instance.getConsistencyStats();

    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(title: l10n.consistency_analytics),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(l10n, topPadding),
            ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, double topPadding) {
    final stats = _stats;

    if (stats == null || stats.totalWorkouts == 0) {
      return ListView(
        padding: DesignConstants.cardPadding.copyWith(top: topPadding + DesignConstants.spacingM),
        children: [
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
              child: Center(
                child: Text(
                  l10n.noConsistencyData,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ),
            ),
          ),
          const BottomContentSpacer(),
        ],
      );
    }

    final workoutDaySet = stats.workoutDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    return ListView(
      padding: DesignConstants.cardPadding.copyWith(top: topPadding + DesignConstants.spacingM),
      children: [
        _buildStatsOverview(l10n, stats),
        const SizedBox(height: DesignConstants.spacingM),
        _buildSectionTitle(l10n.weeklyWorkoutCount),
        _buildWeeklyBarChart(l10n, stats),
        const SizedBox(height: DesignConstants.spacingM),
        _buildSectionTitle(l10n.my_consistency),
        _buildCalendar(l10n, workoutDaySet),
        const SizedBox(height: DesignConstants.spacingM),
        _buildConsistencyScoreCard(l10n, stats),
        const BottomContentSpacer(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingS, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildStatsOverview(AppLocalizations l10n, ConsistencyStats stats) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatTile(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orange,
              value: stats.currentStreakWeeks.toString(),
              unit: _weeksLabel(stats.currentStreakWeeks),
              label: l10n.currentStreak,
            ),
            _StatTile(
              icon: Icons.emoji_events_rounded,
              iconColor: Colors.amber,
              value: stats.longestStreakWeeks.toString(),
              unit: _weeksLabel(stats.longestStreakWeeks),
              label: l10n.longestStreak,
            ),
            _StatTile(
              icon: Icons.trending_up_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              value: stats.avgWorkoutsPerWeek.toStringAsFixed(1),
              unit: 'x',
              label: l10n.weeklyAverage,
            ),
          ],
        ),
      ),
    );
  }

  String _weeksLabel(int count) => count == 1 ? 'wk' : 'wks';

  Widget _buildWeeklyBarChart(
      AppLocalizations l10n, ConsistencyStats stats) {
    final entries = stats.weeklyWorkoutCounts;
    if (entries.isEmpty) return const SizedBox.shrink();

    final maxCount =
        entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final displayMax = (maxCount < 1 ? 1 : maxCount).toDouble() + 0.5;

    return SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.last16Weeks,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: displayMax,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        if (v != v.toInt().toDouble()) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          v.toInt().toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every 4th label
                        if (idx % 4 != 0) {
                          return const SizedBox.shrink();
                        }
                        final label =
                            DateFormat('MMM d').format(entries[idx].weekStart);
                        return SideTitleWidget(
                          meta: _,
                          space: 4,
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(entries.length, (i) {
                  final count = entries[i].count;
                  final color = count == 0
                      ? Colors.grey.shade300
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.4 + (count / (maxCount + 1)) * 0.6);

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: color,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
      AppLocalizations l10n, Set<DateTime> workoutDaySet) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          locale: Localizations.localeOf(context).toString(),
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 1)),
          focusedDay: _calendarFocusedDay,
          selectedDayPredicate: (day) =>
              isSameDay(_calendarSelectedDay, day),
          calendarFormat: CalendarFormat.month,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: Theme.of(context).textTheme.titleMedium!,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _calendarSelectedDay = selectedDay;
              _calendarFocusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() => _calendarFocusedDay = focusedDay);
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final normalized =
                  DateTime(day.year, day.month, day.day);
              final isWorkoutDay = workoutDaySet.contains(normalized);
              if (!isWorkoutDay) return null;

              return Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.85),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final normalized =
                  DateTime(day.year, day.month, day.day);
              final isWorkoutDay = workoutDaySet.contains(normalized);
              final primaryColor =
                  Theme.of(context).colorScheme.primary;

              return Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isWorkoutDay
                        ? primaryColor
                        : Colors.transparent,
                    border: isWorkoutDay
                        ? null
                        : Border.all(color: primaryColor, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isWorkoutDay
                            ? Theme.of(context).colorScheme.onPrimary
                            : primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConsistencyScoreCard(
      AppLocalizations l10n, ConsistencyStats stats) {
    // Consistency score = % of weeks (in the tracked range) with >= 1 workout
    final entries = stats.weeklyWorkoutCounts;
    final activeWeeks = entries.where((e) => e.count > 0).length;
    final score = entries.isEmpty
        ? 0
        : ((activeWeeks / entries.length) * 100).round();

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.consistencyScore,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '$score%',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _scoreColor(score),
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingS),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 10,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                valueColor:
                    AlwaysStoppedAnimation<Color>(_scoreColor(score)),
              ),
            ),
            const SizedBox(height: DesignConstants.spacingXS),
            Text(
              l10n.consistencyScoreDesc,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red.shade400;
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
