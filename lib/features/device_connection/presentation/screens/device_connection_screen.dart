import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/features/device_connection/data/models/device_connection_state.dart';
import 'package:doodledry/features/device_connection/data/models/discovered_device.dart';
import 'package:doodledry/features/device_connection/presentation/providers/device_connection_provider.dart';
import 'package:doodledry/features/settings/presentation/providers/settings_provider.dart';
import 'package:doodledry/shared/widgets/custom_button.dart';
import 'package:doodledry/shared/widgets/custom_card.dart';

class DeviceConnectionScreen extends ConsumerStatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  ConsumerState<DeviceConnectionScreen> createState() =>
      _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState
    extends ConsumerState<DeviceConnectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isSim = ref.read(settingsProvider).isSimulationMode;
      if (!isSim) {
        ref.read(deviceConnectionNotifierProvider.notifier).startScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(deviceConnectionNotifierProvider);
    final discoveredDevices = ref.watch(discoveredDevicesProvider).value ?? [];
    final settings = ref.watch(settingsProvider);
    final bleError = ref.watch(bleDeviceRepositoryProvider).lastBleError;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wearable Connection',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!settings.isSimulationMode)
            IconButton(
              icon: Icon(
                connectionState == DeviceConnectionState.scanning
                    ? Icons.stop_rounded
                    : Icons.refresh_rounded,
              ),
              onPressed: () {
                if (connectionState == DeviceConnectionState.scanning) {
                  ref
                      .read(deviceConnectionNotifierProvider.notifier)
                      .stopScan();
                } else {
                  ref
                      .read(deviceConnectionNotifierProvider.notifier)
                      .startScan();
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Connection State Card
              CustomCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: connectionState.isConnectedOrReceiving
                                ? AppColors.successBg
                                : AppColors.infoBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            connectionState.isConnectedOrReceiving
                                ? Icons.bluetooth_connected_rounded
                                : Icons.bluetooth_searching_rounded,
                            color: connectionState.isConnectedOrReceiving
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CURRENT STATUS",
                                style: AppTextStyles.label.copyWith(
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                connectionState.displayName,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!settings.isSimulationMode &&
                        (connectionState ==
                                DeviceConnectionState.connectionFailed ||
                            connectionState ==
                                DeviceConnectionState.reconnecting ||
                            connectionState ==
                                DeviceConnectionState.permissionDenied ||
                            connectionState ==
                                DeviceConnectionState.bluetoothDisabled)) ...[
                      Text(
                        connectionState ==
                                DeviceConnectionState.bluetoothDisabled
                            ? 'Turn on Bluetooth and try scanning again.'
                            : connectionState ==
                                    DeviceConnectionState.permissionDenied
                                ? 'Allow Nearby devices / Bluetooth permission in your phone settings, then try again.'
                                : connectionState ==
                                        DeviceConnectionState.reconnecting
                                    ? 'Connection lost. Retrying... ${bleError ?? ''}'
                                    : bleError ??
                                        'Could not connect. Check that the ESP32 is powered on and nearby.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.danger),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (connectionState.isConnectedOrReceiving)
                      CustomButton(
                        text: "Disconnect Device",
                        variant: CustomButtonVariant.outline,
                        height: 44,
                        onPressed: () {
                          ref
                              .read(deviceConnectionNotifierProvider.notifier)
                              .disconnect();
                        },
                      )
                    else if (!settings.isSimulationMode)
                      CustomButton(
                        text: connectionState == DeviceConnectionState.scanning
                            ? "Scanning..."
                            : "Scan for DOODLEDRY Wearable",
                        isLoading:
                            connectionState == DeviceConnectionState.scanning,
                        variant: CustomButtonVariant.primary,
                        height: 44,
                        onPressed: () {
                          ref
                              .read(deviceConnectionNotifierProvider.notifier)
                              .startScan();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Simulation Notice
              if (settings.isSimulationMode) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.simulationBadgeBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.simulationBadge.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.simulationBadge, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Simulation Mode is Enabled",
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.simulationBadge,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "The app is currently streaming simulated virtual hardware data. To connect to physical hardware, disable Simulation Mode in Settings.",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: "Switch to Real Hardware BLE",
                        variant: CustomButtonVariant.primary,
                        height: 40,
                        onPressed: () {
                          ref
                              .read(settingsProvider.notifier)
                              .toggleSimulationMode(false);
                          ref
                              .read(deviceConnectionNotifierProvider.notifier)
                              .startScan();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Discovered Hardware Devices Section
              Text(
                "NEARBY WEARABLES",
                style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              if (discoveredDevices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sensors_off_rounded,
                        size: 40,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No Wearable Found Yet",
                        style: AppTextStyles.titleSmall
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Make sure your DOODLEDRY module is charged and powered on near your phone.",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: discoveredDevices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final device = discoveredDevices[index];
                    return _buildDeviceTile(device, isDark, connectionState);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceTile(DiscoveredBleDevice device, bool isDark,
      DeviceConnectionState connectionState) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.watch_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  "ID: ${device.id} • RSSI: ${device.rssi} dBm",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          CustomButton(
            text: connectionState == DeviceConnectionState.connecting
                ? "Connecting..."
                : "Connect",
            variant: CustomButtonVariant.primary,
            height: 36,
            onPressed: (connectionState.isConnectingOrScanning &&
                        connectionState != DeviceConnectionState.scanning) ||
                    connectionState.isConnectedOrReceiving
                ? null
                : () => ref
                    .read(deviceConnectionNotifierProvider.notifier)
                    .connect(device.id),
          ),
        ],
      ),
    );
  }
}
