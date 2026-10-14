import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/data/models/settings_model.dart';
import '../../features/baby_profile/data/models/baby_profile_model.dart';
import '../../features/authentication/data/models/user_model.dart';

/// Local Storage Service utilizing SharedPreferences for offline persistence
class LocalStorageService {
  static const String _keyOnboardingDone = 'doodledry_onboarding_done';
  static const String _keySettings = 'doodledry_app_settings';
  static const String _keyBabyProfile = 'doodledry_baby_profile';
  static const String _keyUser = 'doodledry_user_session';
  static const String _keyOfflineSensorQueue = 'doodledry_offline_sensor_queue';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // Onboarding
  bool isOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_keyOnboardingDone, completed);
  }

  // App Settings
  AppSettings getSettings() {
    final jsonString = _prefs.getString(_keySettings);
    if (jsonString == null) return AppSettings.defaults();
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(map);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final jsonString = jsonEncode(settings.toJson());
    await _prefs.setString(_keySettings, jsonString);
  }

  // Baby Profile
  BabyProfileModel? getBabyProfile() {
    final jsonString = _prefs.getString(_keyBabyProfile);
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return BabyProfileModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBabyProfile(BabyProfileModel profile) async {
    final jsonString = jsonEncode(profile.toJson());
    await _prefs.setString(_keyBabyProfile, jsonString);
  }

  // User Session
  UserModel? getUser() {
    final jsonString = _prefs.getString(_keyUser);
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    final jsonString = jsonEncode(user.toJson());
    await _prefs.setString(_keyUser, jsonString);
  }

  Future<void> clearUser() async {
    await _prefs.remove(_keyUser);
  }

  // Offline Sensor Queue (for offline sync)
  List<Map<String, dynamic>> getOfflineSensorQueue() {
    final jsonListString = _prefs.getStringList(_keyOfflineSensorQueue) ?? [];
    return jsonListString.map((e) {
      try {
        return jsonDecode(e) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((element) => element.isNotEmpty).toList();
  }

  Future<void> appendToOfflineQueue(Map<String, dynamic> packet) async {
    final current = _prefs.getStringList(_keyOfflineSensorQueue) ?? [];
    // Keep max 200 packets to avoid unbound local storage
    if (current.length > 200) {
      current.removeAt(0);
    }
    current.add(jsonEncode(packet));
    await _prefs.setStringList(_keyOfflineSensorQueue, current);
  }

  Future<void> clearOfflineQueue() async {
    await _prefs.remove(_keyOfflineSensorQueue);
  }
}
