// lib/widgets/measurement_chart_widget.dart (Final & De-Materialisiert)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/models/chart_data_point.dart';
import 'package:intl/intl.dart'; // Für das Datumsformat im Chart

class MeasurementChartWidget extends StatefulWidget {
  final String chartType;
  final DateTimeRange dateRange;
  final Color lineColor;
  final String unit;

  const MeasurementChartWidget({
    super.key,
    required this.chartType,
    required this.dateRange,
    required this.lineColor,
    required this.unit,
  });

  @override
  State<MeasurementChartWidget> createState() => _MeasurementChartWidgetState();
}

class _MeasurementChartWidgetState extends State<MeasurementChartWidget> {
  List<ChartDataPoint> _dataPoints = [];
  bool _isLoadingChart = true;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  @override
  void didUpdateWidget(covariant MeasurementChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nur neu laden, wenn sich Typ oder Datumsbereich geändert hat
    if (oldWidget.chartType != widget.chartType ||
        oldWidget.dateRange != widget.dateRange) {
      _loadChartData();
    }
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoadingChart = true);
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
    if (_isLoadingChart) {
      return const SizedBox(
        height: 200, // Feste Höhe für den Chart-Bereich
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_dataPoints.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Keine Daten für diesen Zeitraum.")),
      );
    }

    // Chart-Daten normalisieren (Min/Max Werte für die Skalierung)
    final double minY =
        _dataPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b) *
            0.95; // 5% Puffer
    final double maxY =
        _dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.05;

    // X-Achsen-Labels anpassen (nur Monat/Tag anzeigen)
    final List<FlSpot> spots = _dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return SizedBox(
      height: 200, // Feste Höhe für den Chart
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY - minY) / 5, // 5 horizontale Linien
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.1),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _dataPoints.length) {
                    final date = _dataPoints[index].date;
                    // Zeige nur den ersten des Monats oder wenn es viele Datenpunkte gibt
                    if (index == 0 ||
                        date.day == 1 ||
                        _dataPoints.length > 10) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat.MMMd().format(date),
                            style: Theme.of(context).textTheme.bodySmall),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(value.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.bodySmall);
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.1),
                width: 1),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [widget.lineColor.withOpacity(0.5), widget.lineColor],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: _dataPoints.length <
                    10, // Nur Punkte anzeigen, wenn nicht zu viele Datenpunkte vorhanden sind
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: widget.lineColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    widget.lineColor.withOpacity(0.2),
                    widget.lineColor.withOpacity(0.0),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
          minY: minY,
          maxY: maxY,
        ),
      ),
    );
  }
}
