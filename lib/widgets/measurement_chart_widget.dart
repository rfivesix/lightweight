import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/models/chart_data_point.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/util/design_constants.dart';

class MeasurementChartWidget extends StatefulWidget {
  final String chartType;
  final DateTimeRange dateRange;
  final String unit;

  const MeasurementChartWidget({
    super.key,
    required this.chartType,
    required this.dateRange,
    required this.unit,
  });

  @override
  State<MeasurementChartWidget> createState() => _MeasurementChartWidgetState();
}

class _MeasurementChartWidgetState extends State<MeasurementChartWidget> {
  List<ChartDataPoint> _dataPoints = [];
  bool _isLoadingChart = true;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  @override
  void didUpdateWidget(covariant MeasurementChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chartType != widget.chartType ||
        oldWidget.dateRange != widget.dateRange) {
      _loadChartData();
    }
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoadingChart = true;
      _touchedIndex = null;
    });
    final data = await DatabaseHelper.instance
        .getChartDataForTypeAndRange(widget.chartType, widget.dateRange);
    if (mounted) {
      setState(() {
        _dataPoints = data;
        _isLoadingChart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingChart) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_dataPoints.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(child: Text(l10n.chart_no_data_for_period)),
      );
    }

    final ChartDataPoint displayPoint =
        _touchedIndex != null ? _dataPoints[_touchedIndex!] : _dataPoints.last;

    final Color lineColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${displayPoint.value.toStringAsFixed(1)} ${widget.unit}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      // Tooltips bleiben aktiv für exakte Werte bei Berührung
                      return touchedBarSpots.map((barSpot) {
                        final index = barSpot.spotIndex;
                        final dataPoint = _dataPoints[index];
                        return LineTooltipItem(
                          '${dataPoint.value.toStringAsFixed(1)} ${widget.unit}',
                          TextStyle(
                            color: lineColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? response) {
                    if (event is FlPanEndEvent || event is FlTapUpEvent) {
                      setState(() => _touchedIndex = null);
                    } else if (response?.lineBarSpots != null &&
                        response!.lineBarSpots!.isNotEmpty) {
                      setState(() => _touchedIndex =
                          response.lineBarSpots!.first.spotIndex);
                    }
                  },
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _dataPoints.first.value,
                      color: Colors.grey.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: [3, 4],
                    ),
                  ],
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),

                // KORREKTUR: Achsen sind jetzt immer sichtbar
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, // IMMER ANZEIGEN
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right, // RECHTSBÜNDIG
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, // IMMER ANZEIGEN
                      reservedSize: 30,
                      interval: (_dataPoints.length / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _dataPoints.length) {
                          return SideTitleWidget(
                            meta: meta,
                            space: 8.0,
                            child: Text(
                              DateFormat.MMMd().format(_dataPoints[index].date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _dataPoints
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                        .toList(),
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) {
                        return spot.x.toInt() == _touchedIndex;
                      },
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 6,
                        color: lineColor,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          lineColor.withOpacity(0.3),
                          lineColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // KORREKTUR: Die separate Datumsanzeige am unteren Rand wurde entfernt.
        ],
      ),
    );
  }
}
