# DOODLEDRY – Smart Baby Monitoring System

<p align="center">
  <strong>Production-Grade Cross-Platform Mobile Application (Android & iOS)</strong><br>
  Real-Time Infant Health & Safety Telemetry, BLE Hardware Ingestion, Advanced Alert Engine, and Interactive Simulation.
</p>

---

## 🌟 Project Overview

**DOODLEDRY** is a modern, cross-platform mobile application built using **Flutter, Dart, Material 3, and Riverpod**. It connects directly to an infant wearable/removable smart monitoring hardware module integrated into baby clothing. 

The application provides caregivers with immediate, real-time insight into:
* **Heart Rate (BPM)** with live pulse visualization and dynamic sparkline charts
* **Blood Oxygen Saturation (SpO₂ %)** with hypoxemia alert thresholds
* **Body / Skin Temperature** with instant Celsius (°C) and Fahrenheit (°F) conversion
* **Motion & Fall Detection** with 3-axis accelerometer telemetry and emergency alert banners
* **Infant Activity Classification** (Sleeping, Awake, Active, Restless)
* **Hardware & BLE Diagnostics** for individual sensor health monitoring
* **Historical Trend Analytics** (Daily, Weekly, Monthly views using FL Chart)

---

## 📱 Key Features

### 1. Real-Time Health & Safety Dashboard
* **Dynamic Caregiver Greeting** (`Good Morning, Sarah`) and baby monitoring status.
* **Large Device Status Card** showing wearable connection state, signal status, battery percentage, and relative update timestamp.
* **Quick Vital Cards** for Heart Rate, SpO₂, Temperature, and Activity state.
* **High-Priority Fall Detection Banner** with immediate audio/visual alert presentation.
* **Persistent Simulation Mode Indicator** with 1-tap access to virtual test injection controls.

### 2. Multi-Layer Hardware Communication Architecture
* **Real BLE Hardware Layer**: Automated BLE scanning for nearby `DOODLEDRY` peripherals, signal strength (RSSI) rating, GATT service discovery, and characteristic notifications via `FlutterBluePlus`.
* **Hardware Simulation Engine**: Full-featured built-in telemetry generator simulating realistic physiological rhythms (sinusoidal vitals with noise), gradual battery drain, and edge case triggers (fever, tachycardia, bradycardia, hypoxia, fall impact, disconnection drops).
* **Cloud Sync Layer**: Firestore & local queue syncing architecture.

### 3. Safety Alert Engine & Configurable Thresholds
* Evaluates incoming sensor packets against caregiver-customizable bounds:
  * Minimum / Maximum Heart Rate
  * Minimum SpO₂ Oxygen level
  * Minimum / Maximum Body Temperature
  * Low Battery warning levels
  * Fall & Impact detection triggers
* Multi-level severity tagging: `Information`, `Warning`, and `Critical`.
* Cooldown deduplication to prevent repetitive alert spamming.
* Complete Alert History log with filtering by severity, timestamp, and read status.

### 4. System Diagnostics Screen
* Real-time subsystem status indicator for:
  * Bluetooth Adapter (ON / OFF / Permission)
  * Wearable Peripheral connection
  * Optical Heart Rate sensor (Receiving Data / Error / No Data)
  * Pulse Oximeter SpO₂ sensor
  * Skin Temperature sensor
  * 3-Axis IMU motion sensor
  * Cloud Database synchronization

### 5. Onboarding, Auth & Baby Profile
* **3-Slide Interactive Onboarding** explaining Smart Monitoring, Connected Wearable, and Smart Alerts.
* **Caregiver Authentication**: Email & Password registration, login, password recovery, and session persistence.
* **Baby Profile Manager**: Name, age calculation in months/days, gender, caregiver relationship, emergency contact phone, and medical disclaimer notice.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x / Dart 3.x (Material Design 3) |
| **State Management** | Flutter Riverpod (`flutter_riverpod: ^2.5.1`) |
| **Bluetooth Low Energy** | `flutter_blue_plus: ^1.36.x` |
| **Data Visualizations** | `fl_chart: ^0.68.0` |
| **Local Persistence** | `shared_preferences: ^2.5.x` |
| **Typography & UI** | Google Fonts (`Outfit`, `Inter`), `flutter_animate` |
| **Date & Utilities** | `intl: ^0.19.0`, `uuid: ^4.6.0` |

---

## 📂 Clean Architecture Folder Structure

```
lib/
├── app.dart                                # MaterialApp, Theme routing, and 5-Tab Navigation
├── main.dart                               # Entry point, orientation locking, and ProviderScope
│
├── core/
│   ├── ble/
│   │   ├── ble_config.dart                 # Centralized GATT Service & Characteristic UUIDs
│   │   └── ble_packet_parser.dart          # Resilient JSON & Binary BLE byte stream parser
│   ├── constants/
│   │   ├── app_colors.dart                 # Calibrated health-tech color palette
│   │   ├── app_text_styles.dart            # Typography tokens (Outfit & Inter)
│   │   └── app_theme.dart                  # Material 3 Light & Dark mode configurations
│   ├── errors/
│   │   └── failures.dart                   # Typed Failure abstractions
│   ├── services/
│   │   └── local_storage_service.dart      # SharedPreferences persistence wrapper
│   └── utils/
│       ├── date_formatter.dart             # Timestamps and relative time formatting
│       ├── sensor_data_validator.dart      # Staleness and biological bounds checking
│       └── vitals_evaluator.dart           # Unit conversion and threshold color classification
│
├── features/
│   ├── alerts/
│   │   ├── data/models/alert_model.dart
│   │   ├── data/repositories/alert_repository.dart
│   │   ├── presentation/providers/alert_provider.dart
│   │   └── presentation/screens/alerts_screen.dart
│   │
│   ├── authentication/
│   │   ├── data/models/user_model.dart
│   │   ├── data/repositories/auth_repository.dart
│   │   ├── presentation/providers/auth_provider.dart
│   │   └── presentation/screens/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── forgot_password_screen.dart
│   │
│   ├── baby_profile/
│   │   ├── data/models/baby_profile_model.dart
│   │   ├── data/repositories/baby_profile_repository.dart
│   │   ├── presentation/providers/baby_profile_provider.dart
│   │   └── presentation/screens/baby_profile_screen.dart
│   │
│   ├── dashboard/
│   │   ├── presentation/screens/dashboard_screen.dart
│   │   └── presentation/widgets/
│   │       ├── device_status_card.dart
│   │       ├── fall_alert_banner.dart
│   │       ├── quick_vital_card.dart
│   │       └── simulation_banner.dart
│   │
│   ├── device_connection/
│   │   ├── data/models/device_connection_state.dart
│   │   ├── data/models/discovered_device.dart
│   │   ├── data/repositories/ble_device_repository.dart
│   │   ├── presentation/providers/device_connection_provider.dart
│   │   └── presentation/screens/device_connection_screen.dart
│   │
│   ├── diagnostics/
│   │   └── presentation/screens/diagnostics_screen.dart
│   │
│   ├── history/
│   │   ├── data/models/vital_history_entry.dart
│   │   ├── data/repositories/history_repository.dart
│   │   ├── presentation/providers/history_provider.dart
│   │   ├── presentation/screens/history_screen.dart
│   │   └── presentation/widgets/
│   │       ├── activity_distribution_chart.dart
│   │       └── vitals_trend_chart.dart
│   │
│   ├── monitoring/
│   │   ├── presentation/screens/monitoring_screen.dart
│   │   └── presentation/widgets/
│   │       ├── heart_rate_monitor_card.dart
│   │       ├── live_vital_sparkline.dart
│   │       ├── motion_monitor_card.dart
│   │       ├── spo2_monitor_card.dart
│   │       └── temperature_monitor_card.dart
│   │
│   ├── onboarding/
│   │   └── presentation/screens/onboarding_screen.dart
│   │
│   ├── settings/
│   │   ├── data/models/monitoring_thresholds.dart
│   │   ├── data/models/settings_model.dart
│   │   ├── presentation/providers/settings_provider.dart
│   │   └── presentation/screens/
│   │       ├── settings_screen.dart
│   │       └── threshold_settings_screen.dart
│   │
│   ├── simulation/
│   │   ├── data/simulation_engine.dart
│   │   └── presentation/widgets/simulation_control_sheet.dart
│   │
│   └── splash/
│       └── presentation/screens/splash_screen.dart
│
└── shared/
    ├── models/
    │   ├── baby_sensor_data.dart           # Core unified sensor model
    │   ├── sensor_status.dart              # SensorState & SensorDataQuality enums
    │   └── sync_status.dart                # SyncStatus enum
    └── widgets/
        ├── custom_button.dart
        ├── custom_card.dart
        ├── custom_text_field.dart
        ├── loading_indicator.dart
        └── navigation_bar.dart
```

---

## 📡 Hardware BLE Configuration & Packet Formats

All BLE GATT configuration is centralized in `lib/core/ble/ble_config.dart`.

### GATT UUIDs
```dart
class BleConfig {
  // Primary Wearable GATT Service UUID
  static const String serviceUuid = "0000fff0-0000-1000-8000-00805f9b34fb";

  // Telemetry Characteristic UUID (Notify / Read)
  static const String sensorCharacteristicUuid = "0000fff1-0000-1000-8000-00805f9b34fb";

  // Command & Config Characteristic UUID (Write)
  static const String commandCharacteristicUuid = "0000fff2-0000-1000-8000-00805f9b34fb";

  // Advertised Device Name Prefix Filter
  static const String deviceNamePrefix = "DOODLEDRY";
}
```

### JSON Telemetry Packet Specification (Primary)
The wearable firmware streams UTF-8 JSON packets over characteristic `0000fff1-0000-1000-8000-00805f9b34fb`:

```json
{
  "deviceId": "DOODLEDRY-001",
  "babyId": "baby_leo_001",
  "heartRate": 128.5,
  "spo2": 98.2,
  "temperature": 36.8,
  "accelerationX": 0.12,
  "accelerationY": -0.03,
  "accelerationZ": 9.81,
  "fallDetected": false,
  "activityStatus": "sleeping",
  "batteryPercentage": 85,
  "timestamp": "2026-08-27T12:30:00.000Z"
}
```

### Binary Microcontroller Packet Fallback
For low-bandwidth hardware protocols, `BlePacketParser` also parses a 12-byte packed struct:
```
[0]:   Heart rate BPM (0..255)
[1]:   SpO₂ % (0..100)
[2..3]: Temperature in °C * 100 (Uint16 Big-Endian)
[4..5]: Accel X in m/s² * 100 (Int16 Big-Endian)
[6..7]: Accel Y in m/s² * 100 (Int16 Big-Endian)
[8..9]: Accel Z in m/s² * 100 (Int16 Big-Endian)
[10]:  Flags (bit 0: Fall detected, bits 1..3: Activity code)
[11]:  Battery % (0..100)
```

---

## 🧪 Simulation Mode & Testing Guide

The application includes an integrated **Hardware Simulator** that runs out of the box without requiring physical hardware:

1. **Activate Simulator**: Open the app or navigate to **Settings** > **Hardware Simulation Mode** (ON).
2. **Access Control Panel**: Tap the **Test Panel** button on the top banner or the tune icon in the app bar.
3. **Simulate Scenarios**:
   * **Trigger Fall Event**: Simulates sudden impact acceleration, triggers an immediate alert and dashboard emergency banner.
   * **Simulate Drop / Disconnect**: Simulates Bluetooth packet loss and reconnection recovery.
   * **Inject High HR (185 BPM) / Low HR (72 BPM)**: Verifies threshold warning and critical alert generation.
   * **Inject Hypoxia (88% SpO₂)**: Verifies oxygen saturation alert triggers.
   * **Inject High Fever (39.2°C)**: Verifies temperature warning triggers.
   * **Battery Degradation (18% / 7%)**: Tests low battery warning badges.
   * **Reset All**: Instantly restores healthy baseline values.

---

## 🚀 Setup & Execution

### Prerequisites
* Flutter SDK (3.5+ or latest stable)
* Dart SDK (3.5+)
* Android Studio / Xcode (for mobile deployments)

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/doodledry/doodledry.git
cd doodledry
flutter pub get
```

### 2. Run Test Suite
```bash
flutter test
```
All unit tests (`BlePacketParser`, `SensorDataValidator`, `AlertRepository`) and widget tests (`DashboardScreen`, `DiagnosticsScreen`, `AlertsScreen`, `SettingsScreen`) will execute.

### 3. Launch App
```bash
# Launch on connected phone or emulator
flutter run

# Or launch on Web / Windows desktop for quick UI inspection
flutter run -d chrome
flutter run -d windows
```

---

## 🔒 Platform Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
* `BLUETOOTH_SCAN` (`neverForLocation`)
* `BLUETOOTH_CONNECT`
* `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` (for legacy Android 11 and below)
* `POST_NOTIFICATIONS`

### iOS (`ios/Runner/Info.plist`)
* `NSBluetoothAlwaysUsageDescription`
* `NSBluetoothPeripheralUsageDescription`

---

## 🛡️ Medical Disclaimer
> **IMPORTANT**: DOODLEDRY is a caregiver monitoring assistance platform. It is not an automated medical diagnostic instrument. Caregivers should always verify infant health directly and seek qualified professional medical attention when necessary.
