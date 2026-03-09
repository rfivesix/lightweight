// lib/screens/volume_analytics_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/bottom_content_spacer.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';

/// A screen for analyzing training volume over time.
///
/// Shows tonnage and work-set counts through bar charts, with views by
/// week, month, exercise, and muscle group.
class VolumeAnalyticsScreen extends StatefulWidget {
  const VolumeAnalyticsScreen({super.key});

  @override
  State<VolumeAnalyticsScreen> createState() => _VolumeAnalyticsScreenState();
}

class _VolumeAnalyticsScreenState extends State<VolumeAnalyticsScreen> {
  bool _isLoading = true;

  // View mode: 'week', 'month', 'exercise', 'muscleGroup'
  String _viewMode = 'week';

  // Metric: 'tonnage' or 'workSets'
  String _metric = 'tonnage';

  // Date range: '12w', '6m', '1y', 'all'
  String _dateRange = '12w';

  List<VolumeDataPoint> _periodData = [];
  List<ExerciseVolumeEntry> _exerciseData = [];

  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final DateTime start;
    switch (_dateRange) {
      case '12w':
        start = now.subtract(const Duration(days: 84));
      case '6m':
        start = now.subtract(const Duration(days: 182));
      case '1y':
        start = now.subtract(const Duration(days: 365));
      default:
        start = DateTime(2020, 1, 1);
    }

    if (_viewMode == 'week') {
      final data = await WorkoutDatabaseHelper.instance.getWeeklyVolume(
        start,
        now,
      );
      if (mounted) setState(() => _periodData = data);
    } else if (_viewMode == 'month') {
      final data = await WorkoutDatabaseHelper.instance.getMonthlyVolume(
        start,
        now,
      );
      if (mounted) setState(() => _periodData = data);
    } else if (_viewMode == 'exercise') {
      final data = await WorkoutDatabaseHelper.instance.getVolumeByExercise(
        start,
        now,
      );
      if (mounted) setState(() => _exerciseData = data);
    } else {
      final data =
          await WorkoutDatabaseHelper.instance.getVolumeByMuscleGroup(
        start,
        now,
      );
      if (mounted) setState(() => _exerciseData = data);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBar(title: l10n.volume_analytics),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: DesignConstants.cardPadding.copyWith(top: topPadding + DesignConstants.spacingM),
                children: [
                  _buildViewModeSelector(l10n),
                  const SizedBox(height: DesignConstants.spacingS),
                  _buildMetricSelector(l10n),
                  const SizedBox(height: DesignConstants.spacingS),
                  if (_viewMode == 'week' || _viewMode == 'month')
                    _buildDateRangeSelector(l10n),
                  const SizedBox(height: DesignConstants.spacingM),
                  _buildChart(l10n),
                  const SizedBox(height: DesignConstants.spacingL),
                  if (_viewMode == 'week' || _viewMode == 'month')
                    _buildSummaryRow(l10n),
                  const BottomContentSpacer(),
                ],
              ),
            ),
    );
  }

  Widget _buildViewModeSelector(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'week', label: Text(l10n.byWeek)),
          ButtonSegment(value: 'month', label: Text(l10n.byMonth)),
          ButtonSegment(value: 'exercise', label: Text(l10n.byExercise)),
          ButtonSegment(
              value: 'muscleGroup', label: Text(l10n.byMuscleGroup)),
        ],
        selected: {_viewMode},
        onSelectionChanged: (s) {
          setState(() {
            _viewMode = s.first;
            _touchedIndex = null;
          });
          _loadData();
        },
      ),
    );
  }

  Widget _buildMetricSelector(AppLocalizations l10n) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'tonnage', label: Text(l10n.tonnage)),
        ButtonSegment(value: 'workSets', label: Text(l10n.workSets)),
      ],
      selected: {_metric},
      onSelectionChanged: (s) {
        setState(() {
          _metric = s.first;
          _touchedIndex = null;
        });
      },
    );
  }

  Widget _buildDateRangeSelector(AppLocalizations l10n) {
    return SegmentedButton<String>(
      segments: [
        const ButtonSegment(value: '12w', label: Text('12W')),
        const ButtonSegment(value: '6m', label: Text('6M')),
        const ButtonSegment(value: '1y', label: Text('1Y')),
        ButtonSegment(value: 'all', label: Text(l10n.allTime)),
      ],
      selected: {_dateRange},
      onSelectionChanged: (s) {
        setState(() {
          _dateRange = s.first;
          _touchedIndex = null;
        });
        _loadData();
      },
    );
  }

  Widget _buildChart(AppLocalizations l10n) {
    final isPeriodView = _viewMode == 'week' || _viewMode == 'month';

    if (isPeriodView) {
      if (_periodData.isEmpty) {
        return _buildEmptyState(l10n);
      }
      return _buildBarChart(l10n);
    } else {
      if (_exerciseData.isEmpty) {
        return _buildEmptyState(l10n);
      }
      return _buildHorizontalBars(l10n);
    }
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return SummaryCard(
      child: SizedBox(
        height: 200,
        child: Center(
          child: Text(
            l10n.noVolumeData,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(AppLocalizations l10n) {
    final values = _periodData.map((p) {
      return _metric == 'tonnage' ? p.tonnage : p.workSets.toDouble();
    }).toList();

    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final displayMax = maxValue == 0 ? 1.0 : maxValue * 1.2;

    return SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_touchedIndex != null &&
              _touchedIndex! >= 0 &&
              _touchedIndex! < _periodData.length)
            _buildTooltipRow(l10n, _touchedIndex!)
          else
            _buildChartHeader(l10n),
          const SizedBox(height: DesignConstants.spacingM),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: displayMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (_, __, ___, ____) => null,
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent ||
                        event is FlPanEndEvent) {
                      setState(() => _touchedIndex = null);
                      return;
                    }
                    final idx =
                        response?.spot?.touchedBarGroupIndex;
                    if (idx != null && idx != _touchedIndex) {
                      setState(() => _touchedIndex = idx);
                    }
                  },
                ),
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
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(
                        _metric == 'tonnage'
                            ? '${(v / 1000).toStringAsFixed(v >= 1000 ? 0 : 1)}k'
                            : v.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _periodData.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every 2nd label if there are many bars
                        final showAll = _periodData.length <= 8;
                        if (!showAll && idx % 2 != 0) {
                          return const SizedBox.shrink();
                        }
                        final date = _periodData[idx].date;
                        final label = _viewMode == 'week'
                            ? DateFormat('MMM d').format(date)
                            : DateFormat('MMM yy').format(date);
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
                barGroups: List.generate(
                  _periodData.length,
                  (i) {
                    final v = _metric == 'tonnage'
                        ? _periodData[i].tonnage
                        : _periodData[i].workSets.toDouble();
                    final isTouched = _touchedIndex == i;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: v,
                          color: isTouched
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                          width: _periodData.length > 20 ? 6 : 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartHeader(AppLocalizations l10n) {
    return Text(
      _metric == 'tonnage' ? l10n.tonnage : l10n.workSets,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildTooltipRow(AppLocalizations l10n, int idx) {
    final point = _periodData[idx];
    final value = _metric == 'tonnage' ? point.tonnage : point.workSets.toDouble();
    final label = _viewMode == 'week'
        ? DateFormat('MMM d, yyyy').format(point.date)
        : DateFormat('MMMM yyyy').format(point.date);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _metric == 'tonnage'
              ? '${value.toStringAsFixed(0)} kg'
              : value.toInt().toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(width: DesignConstants.spacingS),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalBars(AppLocalizations l10n) {
    final topEntries = _exerciseData.take(15).toList();
    final maxValue = topEntries.isEmpty
        ? 1.0
        : (_metric == 'tonnage'
            ? topEntries.first.tonnage
            : topEntries.first.workSets.toDouble());

    return SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _metric == 'tonnage' ? l10n.tonnage : l10n.workSets,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          ...topEntries.map((entry) {
            final v = _metric == 'tonnage'
                ? entry.tonnage
                : entry.workSets.toDouble();
            final ratio = maxValue > 0 ? v / maxValue : 0.0;
            return _buildHorizontalBar(context, entry.name, v, ratio, l10n);
          }),
        ],
      ),
    );
  }

  Widget _buildHorizontalBar(BuildContext context, String label, double value,
      double ratio, AppLocalizations l10n) {
    final color = Theme.of(context).colorScheme.primary;
    final valueStr = _metric == 'tonnage'
        ? '${value.toStringAsFixed(0)} kg'
        : value.toInt().toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                valueStr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(AppLocalizations l10n) {
    if (_periodData.isEmpty) return const SizedBox.shrink();

    final totalTonnage =
        _periodData.fold<double>(0, (sum, p) => sum + p.tonnage);
    final totalSets =
        _periodData.fold<int>(0, (sum, p) => sum + p.workSets);
    final avgTonnage = _periodData.isEmpty
        ? 0.0
        : totalTonnage / _periodData.length;
    final avgSets = _periodData.isEmpty ? 0 : totalSets ~/ _periodData.length;

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(
              label: l10n.totalTonnageLabel,
              value: totalTonnage >= 1000
                  ? '${(totalTonnage / 1000).toStringAsFixed(1)}k kg'
                  : '${totalTonnage.toStringAsFixed(0)} kg',
            ),
            _StatColumn(
              label: l10n.avgPerWeekLabel,
              value: _metric == 'tonnage'
                  ? '${avgTonnage.toStringAsFixed(0)} kg'
                  : avgSets.toString(),
            ),
            _StatColumn(
              label: l10n.workSets,
              value: totalSets.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
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
