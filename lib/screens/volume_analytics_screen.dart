// lib/screens/volume_analytics_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../util/design_constants.dart';
import '../widgets/global_app_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/bottom_content_spacer.dart';

/// A screen that visualises training volume over time using bar charts.
///
/// Supports four views: by week, by month, by exercise, and by muscle group.
/// Users can toggle between tonnage (kg) and work-set count.
class VolumeAnalyticsScreen extends StatefulWidget {
  const VolumeAnalyticsScreen({super.key});

  @override
  State<VolumeAnalyticsScreen> createState() => _VolumeAnalyticsScreenState();
}

enum _VolumeView { week, month, exercise, muscle }

enum _VolumeMetric { tonnage, sets }

class _VolumeAnalyticsScreenState extends State<VolumeAnalyticsScreen> {
  bool _isLoading = true;
  _VolumeView _view = _VolumeView.week;
  _VolumeMetric _metric = _VolumeMetric.tonnage;
  int? _touchedIndex;

  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _exerciseData = [];
  List<Map<String, dynamic>> _muscleData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      WorkoutDatabaseHelper.instance.getWeeklyVolume(),
      WorkoutDatabaseHelper.instance.getMonthlyVolume(),
      WorkoutDatabaseHelper.instance.getVolumeByExercise(),
      WorkoutDatabaseHelper.instance.getVolumeByMuscleGroup(),
    ]);
    if (mounted) {
      setState(() {
        _weeklyData = results[0];
        _monthlyData = results[1];
        _exerciseData = results[2];
        _muscleData = results[3];
        _isLoading = false;
        _touchedIndex = null;
      });
    }
  }

  List<Map<String, dynamic>> get _currentData {
    switch (_view) {
      case _VolumeView.week:
        return _weeklyData;
      case _VolumeView.month:
        return _monthlyData;
      case _VolumeView.exercise:
        return _exerciseData;
      case _VolumeView.muscle:
        return _muscleData;
    }
  }

  double _getValue(Map<String, dynamic> d) {
    if (_metric == _VolumeMetric.sets) {
      return (d['set_count'] as int? ?? 0).toDouble();
    }
    return (d['tonnage'] as double? ?? 0.0);
  }

  String _getLabel(Map<String, dynamic> d, int index) {
    switch (_view) {
      case _VolumeView.week:
        final key = d['week_start'] as String? ?? '';
        if (key.isEmpty) return '';
        try {
          final dt = DateTime.parse(key);
          return DateFormat('d/M').format(dt);
        } catch (_) {
          return key;
        }
      case _VolumeView.month:
        final key = d['month'] as String? ?? '';
        if (key.isEmpty) return '';
        try {
          final parts = key.split('-');
          if (parts.length == 2) {
            final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
            return DateFormat('MMM').format(dt);
          }
        } catch (_) {}
        return key;
      case _VolumeView.exercise:
        final name = d['exercise'] as String? ?? '';
        // Shorten long exercise names
        if (name.length > 14) return '${name.substring(0, 12)}…';
        return name;
      case _VolumeView.muscle:
        final name = d['muscle'] as String? ?? '';
        if (name.length > 12) return '${name.substring(0, 10)}…';
        return name;
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
      appBar: GlobalAppBar(title: l10n.volumeAnalyticsTitle),
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
                  // View selector
                  _buildViewSelector(l10n, colorScheme),
                  const SizedBox(height: DesignConstants.spacingM),
                  // Metric toggle
                  _buildMetricToggle(l10n, colorScheme),
                  const SizedBox(height: DesignConstants.spacingM),
                  // Chart
                  _currentData.isEmpty
                      ? _buildEmptyState(l10n)
                      : _buildChart(l10n, colorScheme),
                  const SizedBox(height: DesignConstants.spacingXL),
                  // Data table
                  if (_currentData.isNotEmpty)
                    _buildDataTable(l10n, colorScheme),
                  const BottomContentSpacer(),
                ],
              ),
            ),
    );
  }

  Widget _buildViewSelector(AppLocalizations l10n, ColorScheme colorScheme) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingM,
            vertical: DesignConstants.spacingS),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _VolumeView.values.map((v) {
            final labels = {
              _VolumeView.week: l10n.volumeByWeek,
              _VolumeView.month: l10n.volumeByMonth,
              _VolumeView.exercise: l10n.volumeByExercise,
              _VolumeView.muscle: l10n.volumeByMuscle,
            };
            final selected = _view == v;
            return GestureDetector(
              onTap: () => setState(() {
                _view = v;
                _touchedIndex = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                      DesignConstants.borderRadiusS),
                ),
                child: Text(
                  labels[v]!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMetricToggle(AppLocalizations l10n, ColorScheme colorScheme) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingM,
            vertical: DesignConstants.spacingS),
        child: Row(
          children: [
            Text(
              _metric == _VolumeMetric.tonnage
                  ? l10n.volumeTonnage
                  : l10n.volumeSets,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            SegmentedButton<_VolumeMetric>(
              segments: [
                ButtonSegment(
                  value: _VolumeMetric.tonnage,
                  label: Text(l10n.volumeToggleTonnage),
                ),
                ButtonSegment(
                  value: _VolumeMetric.sets,
                  label: Text(l10n.volumeToggleSets),
                ),
              ],
              selected: {_metric},
              onSelectionChanged: (s) => setState(() {
                _metric = s.first;
                _touchedIndex = null;
              }),
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(AppLocalizations l10n, ColorScheme colorScheme) {
    final data = _currentData;
    final maxVal =
        data.fold<double>(0, (prev, d) => _getValue(d) > prev ? _getValue(d) : prev);

    // Show at most 12 bars; if more data, show last 12
    final displayData = data.length > 12 ? data.sublist(data.length - 12) : data;

    final barGroups = displayData.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      final val = _getValue(d);
      final isTouched = _touchedIndex == i;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: val,
            color: isTouched
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.7),
            width: displayData.length > 8 ? 14 : 20,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_touchedIndex != null &&
                _touchedIndex! < displayData.length) ...[
              Text(
                _getLabel(displayData[_touchedIndex!], _touchedIndex!),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                _metric == _VolumeMetric.tonnage
                    ? '${_getValue(displayData[_touchedIndex!]).toStringAsFixed(0)} kg'
                    : '${_getValue(displayData[_touchedIndex!]).toStringAsFixed(0)} ${l10n.volumeSets}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),
              const SizedBox(height: DesignConstants.spacingS),
            ],
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxVal * 1.2,
                  barGroups: barGroups,
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
                      if (response?.spot != null) {
                        setState(
                            () => _touchedIndex = response!.spot!.touchedBarGroupIndex);
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= displayData.length) {
                            return const SizedBox.shrink();
                          }
                          // Show every 2nd label if many bars
                          if (displayData.length > 6 && i % 2 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _getLabel(displayData[i], i),
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          if (value == meta.max) return const SizedBox.shrink();
                          return Text(
                            _metric == _VolumeMetric.tonnage
                                ? '${(value / 1000).toStringAsFixed(value >= 1000000 ? 0 : 1)}k'
                                : value.toInt().toString(),
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(AppLocalizations l10n, ColorScheme colorScheme) {
    final data = _currentData;
    // Show last 10 items reversed
    final display = data.length > 10 ? data.sublist(data.length - 10) : data;
    final reversed = display.reversed.toList();

    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _metric == _VolumeMetric.tonnage
                  ? l10n.volumeTonnage
                  : l10n.volumeSets,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            ...reversed.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final val = _getValue(d);
              final maxVal = display
                  .fold<double>(0, (p, e) => _getValue(e) > p ? _getValue(e) : p);
              final ratio = maxVal > 0 ? val / maxVal : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: DesignConstants.spacingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getLabel(d, i),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _metric == _VolumeMetric.tonnage
                              ? '${val.toStringAsFixed(0)} kg'
                              : '${val.toStringAsFixed(0)} sets',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    LinearProgressIndicator(
                      value: ratio.toDouble(),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart_rounded, size: 56, color: Colors.grey[400]),
              const SizedBox(height: DesignConstants.spacingL),
              Text(
                l10n.volumeNoData,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
