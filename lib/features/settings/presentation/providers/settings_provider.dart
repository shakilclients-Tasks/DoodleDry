import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../data/models/monitoring_thresholds.dart';
import '../../data/models/settings_model.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError(
      "LocalStorageService must be overridden in ProviderScope");
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final LocalStorageService _storageService;

  SettingsNotifier(this._storageService) : super(_storageService.getSettings());

  Future<void> toggleTemperatureUnit() async {
    final updated = state.copyWith(isFahrenheit: !state.isFahrenheit);
    state = updated;
    await _storageService.saveSettings(updated);
  }

  Future<void> toggleTheme([bool? isDark]) async {
    final updated = state.copyWith(isDarkMode: isDark ?? !state.isDarkMode);
    state = updated;
    await _storageService.saveSettings(updated);
  }

  Future<void> updateThresholds(MonitoringThresholds thresholds) async {
    final updated = state.copyWith(thresholds: thresholds);
    state = updated;
    await _storageService.saveSettings(updated);
  }

  Future<void> toggleNotifications([bool? enabled]) async {
    final updated = state.copyWith(
        notificationsEnabled: enabled ?? !state.notificationsEnabled);
    state = updated;
    await _storageService.saveSettings(updated);
  }

  Future<void> toggleSoundAlerts([bool? enabled]) async {
    final updated = state.copyWith(
        soundAlertsEnabled: enabled ?? !state.soundAlertsEnabled);
    state = updated;
    await _storageService.saveSettings(updated);
  }

  Future<void> toggleCloudSync([bool? enabled]) async {
    final updated =
        state.copyWith(cloudSyncEnabled: enabled ?? !state.cloudSyncEnabled);
    state = updated;
    await _storageService.saveSettings(updated);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return SettingsNotifier(storage);
});
