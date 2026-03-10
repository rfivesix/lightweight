import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsChartDefaults {
  static const FlGridData compactGrid =
      FlGridData(show: true, drawVerticalLine: false);

  static const FlTitlesData hiddenTitles = FlTitlesData(
    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );

  static LineChartBarData straightLine({
    required List<FlSpot> spots,
    required Color color,
    double barWidth = 2.5,
    bool showDots = false,
    BarAreaData? belowBarData,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      barWidth: barWidth,
      color: color,
      dotData: FlDotData(show: showDots),
      belowBarData: belowBarData ?? BarAreaData(show: false),
    );
  }
}
