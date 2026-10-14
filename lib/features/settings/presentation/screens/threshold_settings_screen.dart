import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/features/settings/data/models/monitoring_thresholds.dart';
import 'package:doodledry/features/settings/presentation/providers/settings_provider.dart';
import 'package:doodledry/shared/widgets/custom_button.dart';
import 'package:doodledry/shared/widgets/custom_card.dart';

class ThresholdSettingsScreen extends ConsumerStatefulWidget {
  const ThresholdSettingsScreen({super.key});

  @override
  ConsumerState<ThresholdSettingsScreen> createState() => _ThresholdSettingsScreenState();
}

class _ThresholdSettingsScreenState extends ConsumerState<ThresholdSettingsScreen> {
  late double _minHr;
  late double _maxHr;
  late double _minSpo2;
  late double _minTemp;
  late double _maxTemp;
  late int _lowBattery;
  late bool _fallAlert;
  late bool _disconnectAlert;

  @override
  void initState() {
    super.initState();
    final t = ref.read(settingsProvider).thresholds;
    _minHr = t.minHeartRate;
    _maxHr = t.maxHeartRate;
    _minSpo2 = t.minSpo2;
    _minTemp = t.minTemperatureCelsius;
    _maxTemp = t.maxTemperatureCelsius;
    _lowBattery = t.lowBatteryThreshold;
    _fallAlert = t.fallAlertEnabled;
    _disconnectAlert = t.disconnectionAlertEnabled;
  }

  void _save() {
    final updated = MonitoringThresholds(
      minHeartRate: _minHr,
      maxHeartRate: _maxHr,
      minSpo2: _minSpo2,
      minTemperatureCelsius: _minTemp,
      maxTemperatureCelsius: _maxTemp,
      lowBatteryThreshold: _lowBattery,
      fallAlertEnabled: _fallAlert,
      disconnectionAlertEnabled: _disconnectAlert,
    );
    ref.read(settingsProvider.notifier).updateThresholds(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Alert thresholds saved successfully."),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pop();
  }

  void _resetToDefaults() {
    final def = MonitoringThresholds.defaults();
    setState(() {
      _minHr = def.minHeartRate;
      _maxHr = def.maxHeartRate;
      _minSpo2 = def.minSpo2;
      _minTemp = def.minTemperatureCelsius;
      _maxTemp = def.maxTemperatureCelsius;
      _lowBattery = def.lowBatteryThreshold;
      _fallAlert = def.fallAlertEnabled;
      _disconnectAlert = def.disconnectionAlertEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alert Thresholds',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child: const Text("Reset Defaults"),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Thresholds are customizable caregiver alert bounds for prototype monitoring, not universal clinical standards.",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF1E3A8A),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. Heart Rate Range
              CustomCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Heart Rate Range (BPM)", style: AppTextStyles.titleSmall),
                        Text(
                          "${_minHr.toInt()} - ${_maxHr.toInt()} BPM",
                          style: AppTextStyles.titleSmall.copyWith(color: AppColors.heartRate, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text("Low Heart Rate Threshold: ${_minHr.toInt()} BPM", style: AppTextStyles.bodySmall),
                    Slider(
                      value: _minHr,
                      min: 60,
                      max: 110,
                      divisions: 50,
                      activeColor: AppColors.heartRate,
                      onChanged: (v) => setState(() => _minHr = v),
                    ),
                    Text("High Heart Rate Threshold: ${_maxHr.toInt()} BPM", style: AppTextStyles.bodySmall),
                    Slider(
                      value: _maxHr,
                      min: 140,
                      max: 210,
                      divisions: 70,
                      activeColor: AppColors.heartRate,
                      onChanged: (v) => setState(() => _maxHr = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Minimum SpO2
              CustomCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Minimum Oxygen (SpO₂)", style: AppTextStyles.titleSmall),
                        Text(
                          "${_minSpo2.toInt()}%",
                          style: AppTextStyles.titleSmall.copyWith(color: AppColors.spo2, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: _minSpo2,
                      min: 85,
                      max: 98,
                      divisions: 13,
                      activeColor: AppColors.spo2,
                      onChanged: (v) => setState(() => _minSpo2 = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Temperature Range
              CustomCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Temperature Range (°C)", style: AppTextStyles.titleSmall),
                        Text(
                          "${_minTemp.toStringAsFixed(1)}°C - ${_maxTemp.toStringAsFixed(1)}°C",
                          style: AppTextStyles.titleSmall.copyWith(color: AppColors.temperature, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text("Low Temperature Alert: ${_minTemp.toStringAsFixed(1)}°C", style: AppTextStyles.bodySmall),
                    Slider(
                      value: _minTemp,
                      min: 35.0,
                      max: 36.6,
                      divisions: 16,
                      activeColor: AppColors.temperature,
                      onChanged: (v) => setState(() => _minTemp = v),
                    ),
                    Text("Fever Alert Threshold: ${_maxTemp.toStringAsFixed(1)}°C", style: AppTextStyles.bodySmall),
                    Slider(
                      value: _maxTemp,
                      min: 37.2,
                      max: 39.5,
                      divisions: 23,
                      activeColor: AppColors.temperature,
                      onChanged: (v) => setState(() => _maxTemp = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Fall & Disconnection Toggles
              CustomCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 18,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      title: Text("Fall & Impact Alerts", style: AppTextStyles.titleSmall),
                      subtitle: const Text("Immediate critical notification upon sharp acceleration changes", style: TextStyle(fontSize: 11)),
                      value: _fallAlert,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _fallAlert = v),
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      title: Text("Wearable Disconnection Alert", style: AppTextStyles.titleSmall),
                      subtitle: const Text("Alert when Bluetooth link or data packets stop", style: TextStyle(fontSize: 11)),
                      value: _disconnectAlert,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _disconnectAlert = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              CustomButton(
                text: "Save Thresholds",
                variant: CustomButtonVariant.primary,
                onPressed: _save,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
