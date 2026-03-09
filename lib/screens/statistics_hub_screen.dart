// lib/screens/statistics_hub_screen.dart
import 'package:flutter/material.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import 'consistency_analytics_screen.dart';
import 'measurements_screen.dart';
import 'pr_dashboard_screen.dart';
import 'volume_analytics_screen.dart';
import '../util/design_constants.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/summary_card.dart';

/// A hub screen that gives users a quick overview of their fitness progress.
///
/// Contains inline summary modules for PR dashboard, volume analytics, and
/// consistency, plus gateways to dedicated in-depth analysis screens.
class StatisticsHubScreen extends StatefulWidget {
  const StatisticsHubScreen({super.key});

  @override
  State<StatisticsHubScreen> createState() => _StatisticsHubScreenState();
}

class _StatisticsHubScreenState extends State<StatisticsHubScreen> {
  late final l10n = AppLocalizations.of(context)!;
  bool _isLoading = true;

  // Consistency summary data
  int _currentStreak = 0;
  double _avgPerWeek = 0;
  int _workoutsThisWeek = 0;

  // PR summary (top 3 recent PRs)
  List<Map<String, dynamic>> _recentPRs = [];

  // Volume summary (last 4 weeks)
  List<Map<String, dynamic>> _weeklyVolume = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final results = await Future.wait([
      WorkoutDatabaseHelper.instance.getCurrentWorkoutStreak(),
      WorkoutDatabaseHelper.instance.getAverageWorkoutsPerWeek(weeks: 8),
      WorkoutDatabaseHelper.instance.getWorkoutsThisWeek(),
      WorkoutDatabaseHelper.instance.getRecentPRs(
          DateTime.now().subtract(const Duration(days: 30))),
      WorkoutDatabaseHelper.instance.getWeeklyVolume(weeks: 4),
    ]);

    if (mounted) {
      setState(() {
        _currentStreak = results[0] as int;
        _avgPerWeek = results[1] as double;
        _workoutsThisWeek = results[2] as int;
        _recentPRs = (results[3] as List<Map<String, dynamic>>).take(3).toList();
        _weeklyVolume = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = MediaQuery.of(context).padding.top;
    const EdgeInsets basePadding = DesignConstants.cardPadding;
    final EdgeInsets finalPadding = basePadding.copyWith(
      top: basePadding.top + appBarHeight,
    );

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadAllData,
            child: ListView(
              padding: finalPadding,
              children: [
                // ── PR DASHBOARD ─────────────────────────────────────────
                _buildSectionTitle(context, l10n.prDashboardTitle),
                _buildPRSummaryCard(context),
                const SizedBox(height: DesignConstants.spacingXL),

                // ── VOLUME ANALYTICS ─────────────────────────────────────
                _buildSectionTitle(context, l10n.volumeAnalyticsTitle),
                _buildVolumeSummaryCard(context),
                const SizedBox(height: DesignConstants.spacingXL),

                // ── CONSISTENCY ──────────────────────────────────────────
                _buildSectionTitle(context, l10n.consistencyTitle),
                _buildConsistencySummaryCard(context),
                const SizedBox(height: DesignConstants.spacingXL),

                // ── IN-DEPTH ANALYSIS ────────────────────────────────────
                _buildSectionTitle(context, l10n.in_depth_analysis),
                _buildAnalysisGateway(
                  context: context,
                  icon: Icons.emoji_events_rounded,
                  title: l10n.prDashboardTitle,
                  subtitle: l10n.prDashboardSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PrDashboardScreen(),
                    ),
                  ).then((_) => _loadAllData()),
                ),
                _buildAnalysisGateway(
                  context: context,
                  icon: Icons.bar_chart_rounded,
                  title: l10n.volumeAnalyticsTitle,
                  subtitle: l10n.volumeAnalyticsSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const VolumeAnalyticsScreen(),
                    ),
                  ).then((_) => _loadAllData()),
                ),
                _buildAnalysisGateway(
                  context: context,
                  icon: Icons.calendar_today_rounded,
                  title: l10n.consistencyTitle,
                  subtitle: l10n.consistencySubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const ConsistencyAnalyticsScreen(),
                    ),
                  ).then((_) => _loadAllData()),
                ),
                _buildAnalysisGateway(
                  context: context,
                  icon: Icons.monitor_weight_outlined,
                  title: l10n.body_measurements,
                  subtitle: l10n.measurements_description,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MeasurementsScreen(),
                    ),
                  ),
                ),
                const BottomContentSpacer(),
              ],
            ),
          );
  }

  // ── PR Summary Card ────────────────────────────────────────────────────────

  Widget _buildPRSummaryCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_recentPRs.isEmpty) {
      return SummaryCard(
        child: Padding(
          padding: DesignConstants.cardPadding,
          child: Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: Colors.grey[400], size: 32),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: Text(
                  l10n.prDashboardNoData,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: DesignConstants.spacingS),
                Text(
                  l10n.prDashboardRecent,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingS),
            ..._recentPRs.map((pr) {
              final exercise = pr['exercise'] as String;
              final weight = (pr['weight'] as num).toDouble();
              final reps = pr['reps'] as int;
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: DesignConstants.spacingXS),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingS),
                    Expanded(
                      child: Text(
                        exercise,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$weight kg × $reps',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Volume Summary Card ────────────────────────────────────────────────────

  Widget _buildVolumeSummaryCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_weeklyVolume.isEmpty) {
      return SummaryCard(
        child: Padding(
          padding: DesignConstants.cardPadding,
          child: Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.grey[400], size: 32),
              const SizedBox(width: DesignConstants.spacingM),
              Expanded(
                child: Text(
                  l10n.volumeNoData,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxTonnage = _weeklyVolume.fold<double>(
        0,
        (p, w) =>
            ((w['tonnage'] as double?) ?? 0.0) > p
                ? (w['tonnage'] as double)
                : p);

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded,
                    color: colorScheme.primary, size: 20),
                const SizedBox(width: DesignConstants.spacingS),
                Text(
                  l10n.volumeByWeek,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  l10n.volumeToggleTonnage,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyVolume.map((w) {
                final tonnage = (w['tonnage'] as double?) ?? 0.0;
                final ratio = maxTonnage > 0 ? tonnage / maxTonnage : 0.0;
                const barHeight = 48.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(tonnage / 1000).toStringAsFixed(1)}k',
                          style: const TextStyle(
                              fontSize: 8, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: barHeight * ratio.clamp(0.05, 1.0),
                          decoration: BoxDecoration(
                            color: colorScheme.primary
                                .withValues(alpha: 0.75),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Consistency Summary Card ──────────────────────────────────────────────

  Widget _buildConsistencySummaryCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn(
              context: context,
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orange,
              value: '$_currentStreak',
              label: l10n.consistencyCurrentStreak,
            ),
            _buildDivider(),
            _buildStatColumn(
              context: context,
              icon: Icons.fitness_center_rounded,
              iconColor: Colors.green,
              value: '$_workoutsThisWeek',
              label: l10n.consistencyWorkoutsThisWeek,
            ),
            _buildDivider(),
            _buildStatColumn(
              context: context,
              icon: Icons.show_chart_rounded,
              iconColor: colorScheme.primary,
              value: _avgPerWeek.toStringAsFixed(1),
              label: l10n.consistencyAvgPerWeek,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: Colors.grey[300]);
  }

  Widget _buildStatColumn({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 10,
              ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

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
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

