import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/models/baby_sensor_data.dart';
import '../../../../shared/models/sensor_status.dart';
import '../../../baby_profile/presentation/providers/baby_profile_provider.dart';
import '../../../device_connection/presentation/providers/device_connection_provider.dart';
import '../../../device_connection/presentation/screens/device_connection_screen.dart';
import '../../../diagnostics/presentation/screens/diagnostics_screen.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../simulation/presentation/widgets/simulation_control_sheet.dart';
import '../widgets/device_status_card.dart';
import '../widgets/fall_alert_banner.dart';
import '../widgets/quick_vital_card.dart';
import '../widgets/simulation_banner.dart';

class DashboardScreen extends ConsumerWidget {
  final ValueChanged<int> onNavigateToTab;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTab,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _vitalStatus(BabySensorData data, SensorState state, {bool fingerSensor = false}) {
    if (!data.isDeviceConnected) return 'Device Disconnected';
    if (data.dataQuality == SensorDataQuality.stale) return 'Updating...';
    if (state == SensorState.active) return 'Live Reading';
    if (state == SensorState.poorSignal) return 'Adjust Finger';
    if (state == SensorState.measuring) return 'Measuring...';
    if (state == SensorState.error) return 'Sensor Unavailable';
    if (fingerSensor && data.fingerDetected == false) return 'Waiting for Finger';
    return 'Sensor Unavailable';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorDataAsync = ref.watch(activeSensorDataProvider);
    final connectionState = ref.watch(deviceConnectionNotifierProvider);
    final babyProfile = ref.watch(currentBabyProfileProvider).value;
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sensorData = sensorDataAsync.value ?? BabySensorData.disconnected();

    final parentName = babyProfile?.caregiverName.split(' ').first ?? 'Parent';
    final babyName = babyProfile?.name ?? 'Baby';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (settings.isSimulationMode) {
              ref.read(simulationEngineProvider).resetToNormal();
            } else {
              await ref.read(deviceConnectionNotifierProvider.notifier).startScan();
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, $parentName',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: sensorData.isDeviceConnected
                                    ? AppColors.success
                                    : AppColors.textMutedLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sensorData.isDeviceConnected
                                  ? '$babyName is being monitored'
                                  : '$babyName — Waiting for device data',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: const Icon(Icons.bluetooth_searching_rounded, size: 20),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DeviceConnectionScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Simulation Banner (if active)
                if (settings.isSimulationMode)
                  SimulationBanner(
                    onTapControls: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SimulationControlSheet(),
                      );
                    },
                  ),

                // 3. Fall Detected Critical Alert Banner
                if (sensorData.isDeviceConnected && sensorData.motionState == SensorState.active && sensorData.fallDetected == true)
                  FallAlertBanner(
                    onDismiss: () {
                      if (settings.isSimulationMode) {
                        ref.read(simulationEngineProvider).clearFallEvent();
                      }
                    },
                    onViewDetails: () => onNavigateToTab(3), // Navigate to Alerts tab
                  ),

                // 4. Large Device Status Card
                DeviceStatusCard(
                  sensorData: sensorData,
                  connectionState: connectionState,
                  onDiagnosticsTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                    );
                  },
                  onDeviceTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeviceConnectionScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 5. Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'REAL-TIME VITALS',
                      style: AppTextStyles.label.copyWith(
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    InkWell(
                      onTap: () => onNavigateToTab(1), // Go to Monitoring Tab
                      child: Text(
                        'View Live Trends →',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 6. 2x2 Grid of Vital Cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: MediaQuery.sizeOf(context).width < 380 ? 0.82 : 1.0,
                  children: [
                    // Heart Rate
                    QuickVitalCard(
                      label: 'Heart Rate',
                      value: (sensorData.isDeviceConnected && sensorData.heartRateState == SensorState.active && sensorData.heartRate != null)
                          ? sensorData.heartRate!.toStringAsFixed(0)
                          : '--',
                      unit: 'BPM',
                      statusText: _vitalStatus(sensorData, sensorData.heartRateState, fingerSensor: true),
                      icon: Icons.favorite_rounded,
                      accentColor: AppColors.heartRate,
                      bgColor: AppColors.heartRateBg,
                      sensorState: sensorData.heartRateState,
                      onTap: () => onNavigateToTab(1),
                    ),

                    // SpO2
                    QuickVitalCard(
                      label: 'SpO₂ Oxygen',
                      value: (sensorData.isDeviceConnected && sensorData.spo2State == SensorState.active && sensorData.spo2 != null)
                          ? sensorData.spo2!.toStringAsFixed(0)
                          : '--',
                      unit: '%',
                      statusText: _vitalStatus(sensorData, sensorData.spo2State, fingerSensor: true),
                      icon: Icons.air_rounded,
                      accentColor: AppColors.spo2,
                      bgColor: AppColors.spo2Bg,
                      sensorState: sensorData.spo2State,
                      onTap: () => onNavigateToTab(1),
                    ),

                    // Temperature
                    QuickVitalCard(
                      label: 'Body Temp',
                      value: sensorData.isDeviceConnected && sensorData.temperatureState == SensorState.active && sensorData.temperature != null
                          ? (settings.isFahrenheit
                              ? sensorData.temperatureInFahrenheit!.toStringAsFixed(1)
                              : sensorData.temperature!.toStringAsFixed(1))
                          : '--',
                      unit: settings.isFahrenheit ? '°F' : '°C',
                      statusText: _vitalStatus(sensorData, sensorData.temperatureState),
                      icon: Icons.thermostat_rounded,
                      accentColor: AppColors.temperature,
                      bgColor: AppColors.temperatureBg,
                      sensorState: sensorData.temperatureState,
                      onTap: () => onNavigateToTab(1),
                    ),

                    // Activity
                    Builder(
                      builder: (context) {
                        String activityStatusText;
                        IconData activityIcon;
                        Color activityAccent;
                        Color activityBg;

                        if (!sensorData.isDeviceConnected) {
                          activityStatusText = 'Device Disconnected';
                          activityIcon = Icons.sensors_off_rounded;
                          activityAccent = AppColors.textMutedLight;
                          activityBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
                        } else if (sensorData.motionState != SensorState.active) {
                          activityStatusText = 'Sensor Unavailable';
                          activityIcon = Icons.sensors_off_rounded;
                          activityAccent = AppColors.textMutedLight;
                          activityBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
                        } else if (sensorData.fallDetected == true) {
                          activityStatusText = 'FALL DETECTED!';
                          activityIcon = Icons.crisis_alert_rounded;
                          activityAccent = AppColors.danger;
                          activityBg = AppColors.dangerBg;
                        } else {
                          switch (sensorData.activityStatus?.toLowerCase()) {
                            case 'still':
                              activityStatusText = 'No Significant Movement';
                              activityIcon = Icons.bedtime_rounded;
                              activityAccent = AppColors.motion;
                              activityBg = AppColors.motionBg;
                              break;
                            case 'moving':
                              activityStatusText = 'Moving';
                              activityIcon = Icons.directions_walk_rounded;
                              activityAccent = AppColors.motion;
                              activityBg = AppColors.motionBg;
                              break;
                            case 'sleeping':
                              activityStatusText = 'Resting / Still';
                              activityIcon = Icons.bedtime_rounded;
                              activityAccent = AppColors.motion;
                              activityBg = AppColors.motionBg;
                              break;
                            case 'awake':
                              activityStatusText = 'Gentle Movement';
                              activityIcon = Icons.visibility_rounded;
                              activityAccent = AppColors.primary;
                              activityBg = isDark ? const Color(0xFF1E3A4C) : const Color(0xFFE0F2FE);
                              break;
                            case 'active':
                              activityStatusText = 'Moving / Active';
                              activityIcon = Icons.directions_run_rounded;
                              activityAccent = AppColors.success;
                              activityBg = AppColors.successBg;
                              break;
                            case 'restless':
                              activityStatusText = 'High Motion / Restless';
                              activityIcon = Icons.waves_rounded;
                              activityAccent = AppColors.warning;
                              activityBg = AppColors.warningBg;
                              break;
                            default:
                              activityStatusText = 'Movement Active';
                              activityIcon = Icons.directions_walk_rounded;
                              activityAccent = AppColors.motion;
                              activityBg = AppColors.motionBg;
                          }
                        }

                        return QuickVitalCard(
                          label: 'Activity',
                          value: sensorData.isDeviceConnected && sensorData.motionState == SensorState.active
                              ? (sensorData.fallDetected == true
                                  ? 'FALL ALERT'
                                  : sensorData.formattedActivity)
                              : '--',
                          unit: null,
                          statusText: activityStatusText,
                          icon: activityIcon,
                          accentColor: activityAccent,
                          bgColor: activityBg,
                          sensorState: sensorData.fallDetected == true
                              ? SensorState.error
                              : sensorData.motionState,
                          onTap: () => onNavigateToTab(1),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 7. Medical Disclaimer Notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "DOODLEDRY is a caregiver assistance and monitoring tool, not an automated diagnostic device. Consult medical professionals for clinical evaluation.",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
