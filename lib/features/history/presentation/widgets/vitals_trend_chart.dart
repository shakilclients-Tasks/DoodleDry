import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/features/history/data/models/vital_history_entry.dart';

class VitalsTrendChart extends StatelessWidget {
  final String title;
  final String unit;
  final Color lineColor;
  final List<VitalHistoryEntry> records;
  final double? Function(VitalHistoryEntry) valueSelector;
  final double minY;
  final double maxY;

  const VitalsTrendChart({
    super.key,
    required this.title,
    required this.unit,
    required this.lineColor,
    required this.records,
    required this.valueSelector,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final values = records.map(valueSelector).whereType<double>().toList();
    if (values.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Text("No records available for this timeframe."),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "Unit: $unit",
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 4,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: (maxY - minY) / 4,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: values.length > 1 ? (values.length - 1).toDouble() : 1,
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: lineColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
