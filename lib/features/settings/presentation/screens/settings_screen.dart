import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/features/authentication/presentation/providers/auth_provider.dart';
import 'package:doodledry/features/authentication/presentation/screens/login_screen.dart';
import 'package:doodledry/features/baby_profile/presentation/providers/baby_profile_provider.dart';
import 'package:doodledry/features/baby_profile/presentation/screens/baby_profile_screen.dart';
import 'package:doodledry/features/device_connection/presentation/screens/device_connection_screen.dart';
import 'package:doodledry/features/diagnostics/presentation/screens/diagnostics_screen.dart';
import 'package:doodledry/features/settings/presentation/providers/settings_provider.dart';
import 'package:doodledry/features/settings/presentation/screens/threshold_settings_screen.dart';
import 'package:doodledry/shared/widgets/custom_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider).value;
    final babyProfile = ref.watch(currentBabyProfileProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Caregiver Profile Summary Card
              CustomCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ??
                                babyProfile?.caregiverName ??
                                'Sarah Jenkins',
                            style: AppTextStyles.titleMedium
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'parent@doodledry.com',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Baby: ${babyProfile?.name ?? 'Leo'} (${babyProfile?.ageDisplay ?? '4 months old'})",
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const BabyProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // PREFERENCES
              Text(
                "PREFERENCES & UNITS",
                style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              CustomCard(
                padding: EdgeInsets.zero,
                borderRadius: 18,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.thermostat_rounded,
                          color: AppColors.temperature),
                      title: Text("Temperature Unit",
                          style: AppTextStyles.titleSmall),
                      trailing: Text(
                        settings.isFahrenheit
                            ? "Fahrenheit (°F)"
                            : "Celsius (°C)",
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        ref
                            .read(settingsProvider.notifier)
                            .toggleTemperatureUnit();
                      },
                    ),
                    const Divider(),
                    if (kDebugMode)
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.dark_mode_outlined,
                            color: AppColors.secondary),
                        title:
                            Text("Dark Mode", style: AppTextStyles.titleSmall),
                        value: settings.isDarkMode,
                        activeColor: AppColors.primary,
                        onChanged: (v) =>
                            ref.read(settingsProvider.notifier).toggleTheme(v),
                      ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.notifications_active_outlined,
                          color: AppColors.warning),
                      title: Text("Notifications & Alerts",
                          style: AppTextStyles.titleSmall),
                      value: settings.notificationsEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .toggleNotifications(v),
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.cloud_sync_outlined,
                          color: AppColors.primary),
                      title: Text("Cloud Database Sync",
                          style: AppTextStyles.titleSmall),
                      subtitle: const Text(
                          "Sync vital records with Cloud Firestore",
                          style: TextStyle(fontSize: 11)),
                      value: settings.cloudSyncEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .toggleCloudSync(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // HARDWARE & SAFETY
              Text(
                "HARDWARE & SAFETY",
                style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              CustomCard(
                padding: EdgeInsets.zero,
                borderRadius: 18,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.tune_rounded,
                          color: AppColors.primary),
                      title: Text("Monitoring Thresholds",
                          style: AppTextStyles.titleSmall),
                      subtitle: const Text(
                          "Configure alert trigger limits for vitals",
                          style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ThresholdSettingsScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.bluetooth_rounded,
                          color: AppColors.secondary),
                      title: Text("Connected Wearable Device",
                          style: AppTextStyles.titleSmall),
                      subtitle: const Text("Scan, pair, and check BLE signal",
                          style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const DeviceConnectionScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined,
                          color: AppColors.success),
                      title: Text("Subsystem Diagnostics",
                          style: AppTextStyles.titleSmall),
                      subtitle: const Text(
                          "View sensor health and packet validation",
                          style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const DiagnosticsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ACCOUNT & SESSION
              Text(
                "ACCOUNT",
                style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              CustomCard(
                padding: EdgeInsets.zero,
                borderRadius: 18,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.baby_changing_station_rounded,
                          color: AppColors.primary),
                      title: Text("Edit Baby Profile",
                          style: AppTextStyles.titleSmall),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const BabyProfileScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded,
                          color: AppColors.danger),
                      title: Text("Log Out",
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.danger)),
                      onTap: () async {
                        await ref.read(authRepositoryProvider).logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Version Info
              Center(
                child: Column(
                  children: [
                    Text(
                      "DOODLEDRY v1.0.0 (Production Architecture)",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Smart Wearable Baby Monitoring Platform",
                      style: AppTextStyles.label.copyWith(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
