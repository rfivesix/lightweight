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

    // Punkt zur Anzeige (entweder getouched oder letzter)
    final int lastIdx = _dataPoints.length - 1;
    final int shownIdx = (_touchedIndex != null &&
            _touchedIndex! >= 0 &&
            _touchedIndex! < _dataPoints.length)
        ? _touchedIndex!
        : lastIdx;

    final ChartDataPoint displayPoint = _dataPoints[shownIdx];
    final String displayValue =
        '${displayPoint.value.toStringAsFixed(1)} ${widget.unit}';
    final String displayDate = DateFormat.yMMMd().format(displayPoint.date);

    final Color lineColor = Theme.of(context).colorScheme.primary;
    final DateTime baseDate = _dataPoints.first.date;

    return SizedBox(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LINKS bündig: Gewicht groß + Datum rechts daneben
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                displayValue,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                displayDate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          Expanded(
            child: LineChart(
              LineChartData(
                // Touch aktiv lassen, aber Tooltip-Fenster vollständig ausblenden
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    //tooltipBgColor: Colors.transparent,
                    getTooltipItems: (touchedSpots) =>
                        List<LineTooltipItem?>.filled(touchedSpots.length, null,
                            growable: false),
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

                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 7, // z. B. alle 7 Tage ein Label
                      getTitlesWidget: (value, meta) {
                        final date =
                            baseDate.add(Duration(days: value.toInt()));
                        return SideTitleWidget(
                          meta: meta,
                          space: 8.0,
                          child: Text(
                            DateFormat.MMMd().format(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _dataPoints.map((p) {
                      final days =
                          p.date.difference(baseDate).inDays.toDouble();
                      return FlSpot(days, p.value);
                    }).toList(),

                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    // Punkt nur am getouchten Index anzeigen
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) {
                        if (_touchedIndex == null) return false;
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
        ],
      ),
    );
  }
}
