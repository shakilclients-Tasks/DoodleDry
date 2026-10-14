import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/features/device_connection/presentation/providers/device_connection_provider.dart';
import 'package:doodledry/features/simulation/data/simulation_engine.dart';
import 'package:doodledry/shared/widgets/custom_button.dart';

class SimulationControlSheet extends ConsumerWidget {
  const SimulationControlSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simEngine = ref.watch(simulationEngineProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.simulationBadgeBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.simulationBadge, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hardware Simulator Controls", style: AppTextStyles.titleMedium),
                          Text("Simulate hardware faults & edge cases", style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedLight)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Connection & Fall Trigger
              Text("EMERGENCY & CONNECTION", style: AppTextStyles.label.copyWith(color: AppColors.primary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "Trigger Fall Event",
                      icon: Icons.warning_rounded,
                      variant: CustomButtonVariant.danger,
                      height: 46,
                      onPressed: () {
                        simEngine.triggerFallEvent();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("🚨 Sudden Fall event injected! Check alerts & dashboard."),
                            backgroundColor: AppColors.danger,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: simEngine.isConnected ? "Simulate Drop" : "Reconnect",
                      icon: simEngine.isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_connected,
                      variant: CustomButtonVariant.secondary,
                      height: 46,
                      onPressed: () {
                        simEngine.toggleConnection();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Vitals Overrides
              Text("SIMULATE ABNORMAL VITALS", style: AppTextStyles.label.copyWith(color: AppColors.primary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.favorite_rounded, color: AppColors.danger, size: 16),
                    label: const Text("High HR (185 BPM)"),
                    onPressed: () => simEngine.setForcedVitals(hr: 185.0),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.favorite_border_rounded, color: AppColors.warning, size: 16),
                    label: const Text("Low HR (72 BPM)"),
                    onPressed: () => simEngine.setForcedVitals(hr: 72.0),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.air_rounded, color: AppColors.danger, size: 16),
                    label: const Text("Low SpO₂ (88%)"),
                    onPressed: () => simEngine.setForcedVitals(spo2: 88.0),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.thermostat_rounded, color: AppColors.danger, size: 16),
                    label: const Text("Fever (39.2 °C)"),
                    onPressed: () => simEngine.setForcedVitals(temp: 39.2),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Activity State
              Text("ACTIVITY STATE", style: AppTextStyles.label.copyWith(color: AppColors.primary)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActivityBtn(simEngine, "sleeping", Icons.bedtime_rounded),
                    const SizedBox(width: 8),
                    _buildActivityBtn(simEngine, "awake", Icons.wb_sunny_rounded),
                    const SizedBox(width: 8),
                    _buildActivityBtn(simEngine, "active", Icons.directions_run_rounded),
                    const SizedBox(width: 8),
                    _buildActivityBtn(simEngine, "restless", Icons.waves_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Battery Level
              Text("BATTERY STATE", style: AppTextStyles.label.copyWith(color: AppColors.primary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.battery_full_rounded, color: AppColors.batteryGood),
                      label: const Text("85% Normal"),
                      onPressed: () => simEngine.setBattery(85),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.battery_alert_rounded, color: AppColors.warning),
                      label: const Text("18% Low"),
                      onPressed: () => simEngine.setBattery(18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.battery_0_bar_rounded, color: AppColors.danger),
                      label: const Text("7% Critical"),
                      onPressed: () => simEngine.setBattery(7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reset All Button
              CustomButton(
                text: "Reset All to Normal Baseline",
                icon: Icons.refresh_rounded,
                variant: CustomButtonVariant.primary,
                onPressed: () {
                  simEngine.resetToNormal();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Simulator reset to healthy normal baseline."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityBtn(SimulationEngine engine, String activity, IconData icon) {
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(activity.toUpperCase()),
      selected: false,
      onSelected: (_) => engine.setActivity(activity),
    );
  }
}
