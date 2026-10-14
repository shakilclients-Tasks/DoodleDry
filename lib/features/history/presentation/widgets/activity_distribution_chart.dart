import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ActivityDistributionChart extends StatelessWidget {
  final Map<String, double> distribution;

  const ActivityDistributionChart({
    super.key,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (distribution.isEmpty) return const SizedBox(height: 80, child: Center(child: Text('No activity records yet.')));
    final still = distribution['still'] ?? 0.0;
    final moving = distribution['moving'] ?? 0.0;
    final active = distribution['active'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ACTIVITY & REST SUMMARY",
          style: AppTextStyles.label.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              height: 110,
              width: 110,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 28,
                  sections: [
                    PieChartSectionData(
                      color: const Color(0xFF6366F1), // Indigo
                      value: still,
                      title: '${still.toInt()}%',
                      radius: 24,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: const Color(0xFF0D9488), // Teal
                      value: moving,
                      title: '${moving.toInt()}%',
                      radius: 24,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: const Color(0xFFF59E0B), // Amber
                      value: active,
                      title: '${active.toInt()}%',
                      radius: 24,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  _buildLegend("Still", "${still.toStringAsFixed(0)}%", const Color(0xFF6366F1), isDark),
                  const SizedBox(height: 6),
                  _buildLegend("Moving", "${moving.toStringAsFixed(0)}%", const Color(0xFF0D9488), isDark),
                  const SizedBox(height: 6),
                  _buildLegend("Active", "${active.toStringAsFixed(0)}%", const Color(0xFFF59E0B), isDark),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(String title, String val, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ),
        Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
