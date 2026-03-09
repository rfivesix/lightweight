import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../data/workout_database_helper.dart';
import '../util/design_constants.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/summary_card.dart';
import 'measurements_screen.dart';
// Drill-down screens
import 'analytics/consistency_tracker_screen.dart';
import 'analytics/muscle_group_analytics_screen.dart';
import 'analytics/pr_dashboard_screen.dart';
import 'exercise_catalog_screen.dart';
import 'analytics/recovery_tracker_screen.dart';

class StatisticsHubScreen extends StatefulWidget {
  const StatisticsHubScreen({super.key});

  @override
  State<StatisticsHubScreen> createState() => _StatisticsHubScreenState();
}

class _StatisticsHubScreenState extends State<StatisticsHubScreen> {
  late final l10n = AppLocalizations.of(context)!;

  // Time range filter state
  int _selectedTimeRangeIndex = 1; // Default to 30 Days

  List<Map<String, dynamic>> _recentPRs = [];

  @override
  void initState() {
    super.initState();
    _loadPRData();
  }

  Future<void> _loadPRData() async {
    final prs =
        await WorkoutDatabaseHelper.instance.getRecentGlobalPRs(limit: 3);
    if (mounted) setState(() => _recentPRs = prs);
  }

  List<String> get _timeRanges => [
        l10n.filter7Days,
        l10n.filter30Days,
        l10n.filter3Months,
        l10n.filter6Months,
        l10n.filterAll,
      ];

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = MediaQuery.of(context).padding.top;
    final EdgeInsets finalPadding = DesignConstants.cardPadding.copyWith(
      top: DesignConstants.cardPadding.top +
          appBarHeight +
          16, // Extra padding for top
    );

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Inherit background from main_screen
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: finalPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTimeRangeFilter(),
                const SizedBox(height: DesignConstants.spacingL),

                // Section A: Consistency & Training Frequency
                _buildSectionTitle(
                    context, l10n.sectionConsistency.toUpperCase()),
                _buildConsistencySection(),
                const SizedBox(height: DesignConstants.spacingL),

                // Section B: Muscle Groups & Volume
                _buildSectionTitle(
                    context, l10n.sectionMuscleVolume.toUpperCase()),
                _buildMuscleVolumeSection(),
                const SizedBox(height: DesignConstants.spacingL),

                // Section C: Performance & PRs
                _buildSectionTitle(
                    context, l10n.sectionPerformance.toUpperCase()),
                _buildPerformanceSection(),
                const SizedBox(height: DesignConstants.spacingL),

                // Section D: Recovery Heuristics
                _buildSectionTitle(context, l10n.sectionRecovery.toUpperCase()),
                _buildRecoverySection(),
                const SizedBox(height: DesignConstants.spacingL),

                // Section E: Body Metrics & Nutrition
                _buildSectionTitle(
                    context, l10n.sectionBodyNutrition.toUpperCase()),
                _buildBodyMetricsSection(),

                const BottomContentSpacer(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_timeRanges.length, (index) {
          final range = _timeRanges[index];
          final isSelected = _selectedTimeRangeIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(range),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTimeRangeIndex = index);
                }
              },
            ),
          );
        }),
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

  // --- Section Builders ---

  Widget _buildConsistencySection() {
    return Column(
      children: [
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ConsistencyTrackerScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini-Chart Placeholder
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('Calendar Heatmap Visual')),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol('Workouts (Week)', '3', '4 hours'),
                    _buildMetricCol('Current Streak', '4', 'weeks active'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleVolumeSection() {
    return SummaryCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MuscleGroupAnalyticsScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  l10n.placeholderMuscleHeatmap,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol(l10n.metricsTopTrained, 'Chest', '12 sets'),
                _buildMetricCol(
                    l10n.metricsMostNeglected, 'Hamstrings', '0 sets'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      children: [
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PRDashboardScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.metricsRecentPrs,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_recentPRs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      l10n.exerciseAnalyticsNoData,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  )
                else
                  ...List.generate(_recentPRs.length * 2 - 1, (i) {
                    if (i.isOdd) return const Divider(height: 12);
                    final pr = _recentPRs[i ~/ 2];
                    final name = pr['exerciseName'] as String;
                    final weight = pr['weight'] as double;
                    final reps = pr['reps'] as int;
                    final weightStr = weight == weight.truncateToDouble()
                        ? weight.toInt().toString()
                        : weight.toStringAsFixed(1);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$weightStr kg × $reps',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol(l10n.metricsVolumeLifted, '12.4k', 'kg'),
                    _buildMetricCol(l10n.metricsMostImproved, 'Squat', '+5%'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseCatalogScreen()),
            );
          },
          child: ListTile(
            leading: Icon(Icons.search,
                color: Theme.of(context).colorScheme.primary),
            title: Text(l10n.exerciseAnalyticsTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(l10n.exerciseAnalyticsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoverySection() {
    return SummaryCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecoveryTrackerScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.metricsMuscleReadiness,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('3 Recovering, 8 Fresh'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyMetricsSection() {
    return Column(
      children: [
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const MeasurementsScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      l10n.placeholderWeightTrend,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol(
                        l10n.metricsCurrentWeight, '82.5', 'kg (-0.5)'),
                    _buildMetricCol(l10n.metricsAvgCalories, '2,450', 'kcal/d'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SummaryCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const MeasurementsScreen()),
            );
          },
          child: ListTile(
            leading: Icon(Icons.straighten,
                color: Theme.of(context).colorScheme.primary),
            title: Text(l10n.body_measurements,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(l10n.measurements_description),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesignConstants.borderRadiusM),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCol(String label, String value, String subLabel) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(subLabel,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey)),
      ],
    );
  }
}
