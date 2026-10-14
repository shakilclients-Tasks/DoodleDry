import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/features/history/data/repositories/history_repository.dart';
import 'package:doodledry/features/history/presentation/providers/history_provider.dart';
import 'package:doodledry/features/history/presentation/widgets/activity_distribution_chart.dart';
import 'package:doodledry/features/history/presentation/widgets/vitals_trend_chart.dart';
import 'package:doodledry/features/settings/presentation/providers/settings_provider.dart';
import 'package:doodledry/shared/widgets/custom_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyRepo = ref.watch(historyRepositoryProvider);
    ref.watch(liveBufferProvider);
    final selectedTimeframe = ref.watch(selectedTimeframeProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final records = historyRepo.getHistory(selectedTimeframe);
    final averages = historyRepo.getAverages(selectedTimeframe);
    final distribution = historyRepo.getActivityDistribution(selectedTimeframe);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Monitoring History',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe Segmented Switcher
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildTimeframeTab(ref, HistoryTimeframe.day, selectedTimeframe),
                    _buildTimeframeTab(ref, HistoryTimeframe.week, selectedTimeframe),
                    _buildTimeframeTab(ref, HistoryTimeframe.month, selectedTimeframe),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Summary Averages Card
              CustomCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAverageStat(
                      "Avg HR",
                      "${averages['avgHr']?.toStringAsFixed(0) ?? '--'} BPM",
                      AppColors.heartRate,
                      isDark,
                    ),
                    Container(height: 36, width: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    _buildAverageStat(
                      "Avg SpO₂",
                      "${averages['avgSpo2']?.toStringAsFixed(0) ?? '--'}%",
                      AppColors.spo2,
                      isDark,
                    ),
                    Container(height: 36, width: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    _buildAverageStat(
                      "Avg Temp",
                      settings.isFahrenheit
                          ? (averages['avgTemp'] == null ? '-- °F' : "${(averages['avgTemp']! * 9 / 5 + 32).toStringAsFixed(1)} °F")
                          : "${averages['avgTemp']?.toStringAsFixed(1) ?? '--'} °C",
                      AppColors.temperature,
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Activity Distribution Summary
              CustomCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                child: ActivityDistributionChart(distribution: distribution),
              ),
              const SizedBox(height: 20),

              // Heart Rate Trend Chart
              CustomCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                child: VitalsTrendChart(
                  title: "Heart Rate Trend",
                  unit: "BPM",
                  lineColor: AppColors.heartRate,
                  records: records,
                  valueSelector: (e) => e.heartRate,
                  minY: 80,
                  maxY: 180,
                ),
              ),
              const SizedBox(height: 16),

              // SpO2 Trend Chart
              CustomCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                child: VitalsTrendChart(
                  title: "Oxygen Saturation (SpO₂)",
                  unit: "%",
                  lineColor: AppColors.spo2,
                  records: records,
                  valueSelector: (e) => e.spo2,
                  minY: 85,
                  maxY: 100,
                ),
              ),
              const SizedBox(height: 16),

              // Temperature Trend Chart
              CustomCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                child: VitalsTrendChart(
                  title: "Body Temperature Trend",
                  unit: settings.isFahrenheit ? "°F" : "°C",
                  lineColor: AppColors.temperature,
                  records: records,
                  valueSelector: (e) => e.temperature == null ? null : settings.isFahrenheit
                      ? (e.temperature! * 9 / 5 + 32)
                      : e.temperature,
                  minY: settings.isFahrenheit ? 94.0 : 35.0,
                  maxY: settings.isFahrenheit ? 104.0 : 40.0,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeTab(WidgetRef ref, HistoryTimeframe tf, HistoryTimeframe selected) {
    final isSelected = tf == selected;
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(selectedTimeframeProvider.notifier).state = tf,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            tf.displayName,
            style: AppTextStyles.label.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondaryLight,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAverageStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
