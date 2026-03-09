// lib/screens/statistics_hub_screen.dart
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import 'consistency_analytics_screen.dart';
import 'measurements_screen.dart';
import 'pr_dashboard_screen.dart';
import 'volume_analytics_screen.dart';
import '../util/design_constants.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/summary_card.dart';
import 'package:table_calendar/table_calendar.dart';

/// A screen providing an overview of the user's statistics and analytics.
///
/// Contains a consistency calendar, quick-access overview cards,
/// and gateways to deeper analytics modules (PR Dashboard, Volume, Consistency).
class StatisticsHubScreen extends StatefulWidget {
  const StatisticsHubScreen({super.key});

  @override
  State<StatisticsHubScreen> createState() => _StatisticsHubScreenState();
}

class _StatisticsHubScreenState extends State<StatisticsHubScreen> {
  late final l10n = AppLocalizations.of(context)!;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  Set<int> _workoutDays = {};
  Set<int> _nutritionLogDays = {};
  Set<int> _supplementDays = {};

  // Quick-stat summaries for overview cards
  int _prCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await Future.wait([
      _loadMonthData(_focusedDay),
      _loadQuickStats(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMonthData(DateTime month) async {
    final workoutDays =
        await WorkoutDatabaseHelper.instance.getWorkoutDaysInMonth(month);
    final nutritionDays =
        await DatabaseHelper.instance.getNutritionLogDaysInMonth(month);
    final supplementDays =
        await DatabaseHelper.instance.getSupplementLogDaysInMonth(month);

    if (mounted) {
      setState(() {
        _workoutDays = workoutDays;
        _nutritionLogDays = nutritionDays;
        _supplementDays = supplementDays;
      });
    }
  }

  Future<void> _loadQuickStats() async {
    final prs = await WorkoutDatabaseHelper.instance.getPersonalRecords();
    if (mounted) {
      setState(() {
        _prCount = prs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight =
        MediaQuery.of(context).padding.top; // + kToolbarHeight;

    // 2. Get your base padding from your design constants
    const EdgeInsets basePadding =
        DesignConstants.cardPadding; // This is EdgeInsets.all(16.0)

    // 3. Create the final combined padding
    final EdgeInsets finalPadding = basePadding.copyWith(
      // Take the original top value (16.0) and add the app bar height
      top: basePadding.top + appBarHeight,
    );
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadAllData,
            child: ListView(
              padding: finalPadding,
              children: [
                _buildSectionTitle(context, l10n.my_consistency),
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TableCalendar(
                      locale: Localizations.localeOf(context).toString(),
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      calendarFormat: CalendarFormat.month,
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: Theme.of(
                          context,
                        ).textTheme.titleMedium!,
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
                        _loadMonthData(focusedDay);
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          final isNutritionDay = _nutritionLogDays.contains(
                            day.day,
                          );
                          final isSupplementDay = _supplementDays.contains(
                            day.day,
                          );

                          return Positioned(
                            bottom: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isNutritionDay)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                if (isNutritionDay && isSupplementDay)
                                  const SizedBox(width: 2),
                                if (isSupplementDay)
                                  Container(
                                    width: 6,
                                    height: 6,
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
                          final isWorkoutDay = _workoutDays.contains(day.day);
                          if (isWorkoutDay) {
                            return Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
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
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXL),
                _buildSectionTitle(context, l10n.in_depth_analysis),
                _buildAnalysisGateway(
                  context: context,
                  icon: Icons.emoji_events_rounded,
                  title: l10n.pr_dashboard,
                  subtitle: l10n.pr_dashboard_description,
                  badge: _prCount > 0 ? '$_prCount' : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PRDashboardScreen(),
                      ),
                    );
                  },
                ),
                _buildAnalysisGateway(
                  context: context,
                  icon: Icons.bar_chart_rounded,
                  title: l10n.volume_analytics,
                  subtitle: l10n.volume_analytics_description,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const VolumeAnalyticsScreen(),
                      ),
                    );
                  },
                ),
                _buildAnalysisGateway(
                  context: context,
                  icon: Icons.local_fire_department_rounded,
                  title: l10n.consistency_analytics,
                  subtitle: l10n.consistency_analytics_description,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const ConsistencyAnalyticsScreen(),
                      ),
                    );
                  },
                ),
                _buildAnalysisGateway(
                  context: context,
                  icon: Icons.monitor_weight_outlined,
                  title: l10n.body_measurements,
                  subtitle: l10n.measurements_description,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MeasurementsScreen(),
                      ),
                    );
                  },
                ),
                const BottomContentSpacer(),
              ],
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

  Widget _buildAnalysisGateway({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return SummaryCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
        leading: Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: badge != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

