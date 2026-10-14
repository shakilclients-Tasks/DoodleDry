import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:doodledry/features/history/data/models/vital_history_entry.dart';

class LiveVitalSparkline extends StatelessWidget {
  final List<VitalHistoryEntry> points;
  final double? Function(VitalHistoryEntry) valueSelector;
  final Color lineColor;
  final Color fillColor;
  final double minY;
  final double maxY;

  const LiveVitalSparkline({
    super.key,
    required this.points,
    required this.valueSelector,
    required this.lineColor,
    required this.fillColor,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final values = points.map(valueSelector).whereType<double>().toList();
    if (values.isEmpty) {
      return const Center(
        child: Text("Awaiting live stream data...", style: TextStyle(fontSize: 11, color: Colors.grey)),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: values.length > 1 ? (values.length - 1).toDouble() : 1,
        minY: minY,
        maxY: maxY,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: fillColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
