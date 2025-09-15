// lib/widgets/measurement_chart_widget.dart

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/models/chart_data_point.dart';

class MeasurementChartWidget extends StatelessWidget {
  final String? title;
  final List<ChartDataPoint> dataPoints;
  final Color lineColor;
  final String unit;

  const MeasurementChartWidget({
    super.key,
    this.title,
    required this.dataPoints,
    required this.lineColor,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        // KORREKTUR 1: Padding angepasst für eine bessere visuelle Balance.
        padding: const EdgeInsets.fromLTRB(0, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null && title!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: dataPoints.length < 2
                  ? const Center(child: Text("Nicht genügend Daten für eine Grafik vorhanden.")) // TODO: Lokalisieren
                  : LineChart(
                      _buildChartData(context),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    
    return LineChartData(
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot spot) => colorScheme.surfaceContainerHighest,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} $unit\n',
                TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: DateFormat.yMMMMd(locale).format(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt())),
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.normal),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                meta: meta, 
                space: 10,
                angle: -math.pi / 4, 
                child: Text(DateFormat.MMMd(locale).format(date), style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              // KORREKTUR 2: Bedingung entfernt, um wieder sinnvolle Y-Achsen-Labels anzuzeigen.
              return SideTitleWidget(
                meta: meta,
                space: 8,
                child: Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      // KORREKTUR 3: Rahmen des Graphen für einen cleaneren Look entfernt.
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: dataPoints.map((point) => FlSpot(point.date.millisecondsSinceEpoch.toDouble(), point.value)).toList(),
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 4,
                  color: lineColor,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}