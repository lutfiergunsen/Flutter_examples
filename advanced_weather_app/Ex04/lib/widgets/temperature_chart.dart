import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartSeries {
  final String label;
  final Color color;
  final List<double> values;

  const ChartSeries(
      {required this.label, required this.color, required this.values});
}

/// Line chart whose Y axis adapts to the data, so sub-zero and hot days
/// are never clipped.
class TemperatureChart extends StatelessWidget {
  final List<ChartSeries> series;
  final String Function(int index) bottomLabel;

  /// Show only every n-th bottom label to avoid overlap.
  final int labelEvery;

  const TemperatureChart({
    super.key,
    required this.series,
    required this.bottomLabel,
    this.labelEvery = 1,
  });

  @override
  Widget build(BuildContext context) {
    final all = series.expand((s) => s.values);
    if (all.isEmpty) return const SizedBox.shrink();

    final minY = (all.reduce(math.min) - 2).floorToDouble();
    final maxY = (all.reduce(math.max) + 2).ceilToDouble();
    final yInterval = math.max(1, ((maxY - minY) / 5).ceil()).toDouble();
    final length = series.first.values.length;

    return Column(
      children: [
        if (series.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final s in series) ...[
                  Container(width: 12, height: 12, color: s.color),
                  const SizedBox(width: 4),
                  Text(s.label, style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 16),
                ],
              ],
            ),
          ),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white24, strokeWidth: 1),
                getDrawingVerticalLine: (_) =>
                    const FlLine(color: Colors.white12, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.white30),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.round()}°C',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (value != index.toDouble() ||
                          index < 0 ||
                          index >= length ||
                          index % labelEvery != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          bottomLabel(index),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.black87,
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)}°C',
                        TextStyle(color: series[spot.barIndex].color),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                for (final s in series)
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < s.values.length; i++)
                        FlSpot(i.toDouble(), s.values[i]),
                    ],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: s.color,
                    barWidth: 3,
                    dotData: FlDotData(show: s.values.length <= 7),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
