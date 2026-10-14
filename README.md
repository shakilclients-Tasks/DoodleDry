# DOODLEDRY – Smart Baby Monitoring System

<p align="center">
  <strong>Flutter application and ESP32 sensor prototype</strong><br>
  Live BLE telemetry from MAX30102 and MLX90614 hardware.
</p>

---

## 🌟 Project Overview

**DOODLEDRY** is a modern, cross-platform mobile application built using **Flutter, Dart, Material 3, and Riverpod**. It connects directly to an infant wearable/removable smart monitoring hardware module integrated into baby clothing. 

The application provides caregivers with immediate, real-time insight into:
* **Heart Rate (BPM)** with live pulse visualization and dynamic sparkline charts
* **MAX30102 heart rate and SpO₂ estimates** with explicit validity flags
* **MLX90614 IR object/surface temperature** with Celsius (°C) and Fahrenheit (°F) conversion
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

### 2. Multi-Layer Hardware Communication Architecture
* **Real BLE Hardware Layer**: Automated BLE scanning for nearby `DOODLEDRY` peripherals, signal strength (RSSI) rating, GATT service discovery, and characteristic notifications via `FlutterBluePlus`.
* **Versioned JSON telemetry**: The app accepts only packets with measured values and matching sensor validity flags. Missing readings appear as `--`.
* **Cloud Sync Layer**: Firestore & local queue syncing architecture.

### 3. Safety Alert Engine & Configurable Thresholds
* Evaluates incoming sensor packets against caregiver-customizable bounds:
  * Minimum / Maximum Heart Rate
  * Minimum SpO₂ Oxygen level
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
│   │   └── ble_packet_parser.dart          # Versioned JSON BLE frame parser
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

### JSON Telemetry Packet Specification
The wearable firmware streams UTF-8 JSON packets over characteristic `0000fff1-0000-1000-8000-00805f9b34fb`. A reading is `null` unless the sensor reports it valid:

```json
{
  "protocol": 2,
  "deviceId": "DOODLEDRY-001",
  "sensorModel": "MLX90614_IR_OBJECT",
  "heartRate": null,
  "spo2": null,
  "temperature": null,
  "ambientTemp": null,
  "fingerDetected": false,
  "heartRateValid": false,
  "spo2Valid": false,
  "temperatureValid": false,
  "temperatureMeasuring": false,
  "motionValid": false,
  "poorSignal": false,
  "fallDetected": false,
  "activity": "unknown",
  "battery": null
}
```

The previous 12-byte binary fallback and built-in vital simulator were removed. A disconnected, invalid, or stale measurement is never replaced with a plausible number.

---

## 🧪 Hardware verification

Flash the sketch in `firmware/esp32_doodledry`, open Serial Monitor at 115200 baud, and confirm both I²C addresses (MAX30102 `0x57`, MLX90614 `0x5A`). Watch `[SENSORS]` while making and removing optical contact. The app should show `--` until the MAX30102 has collected a valid 100-sample window and MLX90614 has returned three valid object readings. Check the Diagnostics page for sensor status.

The optical SpO₂ calculation and skin placement require validation against a suitable reference device before clinical use. MLX90614 reads IR object/surface temperature, not core body temperature; the app does not raise fever alerts from it.

---

## 🚀 Setup & Execution

### Prerequisites
* Flutter SDK (3.5+ or latest stable)
* Dart SDK (3.5+)
* Android Studio / Xcode (for mobile deployments)

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/shakilclients-Tasks/DoodleDry.git
cd DoodleDry
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
