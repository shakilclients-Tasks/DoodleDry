# 🔌 DOODLEDRY – ESP32 Firmware Guide & Hardware Setup

This directory contains the Arduino/C++ firmware for the **DOODLEDRY Smart Baby Monitoring Wearable** running on an **ESP32 microcontroller**. Sensor thresholds and optical SpO₂ estimation still require physical calibration before medical interpretation.

## Current telemetry contract

The active firmware streams JSON through BLE service `FFF0`, notify characteristic `FFF1`, and command characteristic `FFF2`. These are the 16-bit Bluetooth base UUID equivalents of the 128-bit values in the app. Using the short service UUID lets the service and `DOODLEDRY-001` name fit in the advertisement. Notifications are split into 20-byte chunks; the app reassembles each JSON object. One packet is sent per second.

Fields: `deviceId`, nullable `heartRate`, `spo2`, `temperature`, `activity`, `fingerDetected`, `heartRateValid`, `spo2Valid`, `temperatureValid`, `temperatureMeasuring`, `motionValid`, `poorSignal`, `fallDetected`, and nullable `battery`. A missing or invalid measurement is `null`; it is never replaced with a normal-looking value. Setting `ENABLE_CALIBRATION_DEBUG` to `1` adds raw PPG, temperature, and IMU fields in `debug`, visible only on the app's Diagnostics page in debug builds.

`TEMP_CALIBRATION_OFFSET` is `0.0 °C` until comparison with a reference thermometer at the final sensor distance. The MLX90614 reads object/surface temperature, not core body temperature. `BATTERY_DIVIDER_FITTED` defaults to `false`; set it to `true` only after verifying GPIO34 wiring and voltage scaling. Finger and motion thresholds near the top of the sketch are starting points for bench testing. The existing RED/IR ratio SpO₂ estimate is not clinically calibrated.

---

## 📋 Table of Contents
1. [System Overview](#-system-overview)
2. [Hardware Bill of Materials (BOM)](#-hardware-bill-of-materials-bom)
3. [Circuit Wiring & Pinout Diagram](#-circuit-wiring--pinout-diagram)
4. [Prerequisites & Library Installation](#-prerequisites--library-installation)
5. [Arduino IDE Configuration](#-arduino-ide-configuration)
6. [Flashing the Code to ESP32](#-flashing-the-code-to-esp32)
7. [Testing & Verification with DOODLEDRY App](#-testing--verification-with-doodledry-app)
8. [BLE Protocol & Packet Specifications](#-ble-protocol--packet-specifications)
9. [Troubleshooting & FAQs](#-troubleshooting--faqs)

---

## 🌟 System Overview

The ESP32 firmware is specifically designed to work seamlessly **even if you only have a Heart Rate sensor and a Motion sensor**:
- **MAX30102 Optical Pulse & SpO₂**: Reads real RED and IR signals. Pulse intervals produce BPM after three valid beats; three acceptable RED/IR windows are required for an SpO₂ estimate. Removing the finger transmits `null`.
- **MPU6050 6-Axis Motion & Activity Tracking**: Reads 3-axis accelerometer ($A_x, A_y, A_z$) and 3-axis gyroscope ($\omega_x, \omega_y, \omega_z$) at 50 Hz.
- **Dynamic Activity State Classification (Updates when moving sensor)**:
  - **Still**: motion energy below 0.25.
  - **Moving**: motion energy from 0.25 to 1.20.
  - **Active**: motion energy at or above 1.20.
- **Infant Fall & Impact Detection**:
  - **Free-Fall + Landing**: Drop weightlessness ($|A| < 4.5\text{ m/s}^2$) followed by landing shock ($|A| > 17.0\text{ m/s}^2$) within 1.2 seconds.
  - **Direct Shock Impact**: Sudden high-G drop or bench impact ($|A| > 24.0\text{ m/s}^2$).
  - Triggers 10-second hold alert and streams `fallDetected: true` with `restless` mode to the Flutter App!
- **MLX90614 object temperature**: Three valid samples are required before display. A failed or out-of-range measurement becomes unavailable; MAX30102 die temperature is not substituted.

---

## 🛠️ Hardware Bill of Materials (BOM)

| Item | Component | Description / Notes |
|:---|:---|:---|
| 1 | **ESP32 Dev Module** | ESP32-WROOM-32 / NodeMCU-32S (30-pin or 38-pin) |
| 2 | **MAX30102** or **MAX30100** | Pulse Oximeter & Heart-Rate Sensor Module (I2C) |
| 3 | **MPU6050** | 3-Axis Accelerometer & Gyroscope Sensor (I2C) |
| 4 | **MLX90614 (GY-906)** | Contactless Infrared Body & Ambient Temp Sensor (I2C: 0x5A) |
| 5 | **Voltage Divider** | Two 100kΩ resistors (for 3.7V LiPo battery ADC) |
| 6 | **Jumper Wires & Breadboard** | For prototyping connections |
| 7 | **Micro-USB Cable** | Data & power cable to connect ESP32 to PC |

---

## 📌 Circuit Wiring & Pinout Diagram

All three sensors (**MAX30102**, **MPU6050**, and **MLX90614**) communicate over the **same I2C Bus** and share the same `SDA` (GPIO 21) and `SCL` (GPIO 22) pins on the ESP32 with **ZERO address conflict**:

```
       +------------------------------------------------------+
       |                  ESP32 Dev Board                     |
       |                                                      |
       |  [3.3V] ------+-------------+---------------+        |
       |  [GND]  ---+--|----------+--|------------+--|-----+  |
       |            |  |          |  |            |  |     |  |
       |  [GPIO 21] |  | (SDA) ---+--|--------+   |  |     |  |
       |  [GPIO 22] |  | (SCL) ------+----+   |   |  |     |  |
       |  [GPIO 34] |  |                  |   |   |  |     |  |
       |  [GPIO 2]  |  | (Onboard LED)    |   |   |  |     |  |
       +------------|--|------------------|---|---|--|-----|--+
                    |  |                  |   |   |  |     |
                    |  +--- VCC           |   |   |  |     |
                    +------ GND           |   |   |  |     |
                            SDA ----------+---|---+--|-----+ (MAX30102 I2C: 0x57)
                            SCL --------------+      |       [Heart Rate & SpO2]
                    |  |                  |   |      |
                    |  +--- VCC           |   |      |
                    +------ GND           |   |      |
                            SDA --------------+      |       (MPU6050 I2C: 0x68)
                            SCL ---------------------+       [6-Axis Accelerometer]
                    |  |                  |   |      |
                    |  +--- VCC           |   |      |
                    +------ GND           |   |      |
                            SDA --------------+------+       (MLX90614 I2C: 0x5A)
                            SCL ---------------------+       [Infant IR Body Temp]
```

### Detailed Pin Connections:

| ESP32 Pin | Sensor / Component | Pin Name | Description |
|:---|:---|:---|:---|
| **3.3V** | MAX30102, MPU6050 & MLX90614 | **VIN / VCC** | 3.3V Power rail |
| **GND** | MAX30102, MPU6050 & MLX90614 | **GND** | Common Ground |
| **GPIO 21** | MAX30102, MPU6050 & MLX90614 | **SDA** | I2C Data bus (shared) |
| **GPIO 22** | MAX30102, MPU6050 & MLX90614 | **SCL** | I2C Clock bus (shared) |
| **GPIO 34** | Battery Voltage Divider | **BAT_DIV** | Analog ADC input (0 - 3.3V) |
| **GPIO 2** | Built-in LED | **LED** | Fast blink = Advertising; Solid = Connected |

---

## 💻 Prerequisites & Library Installation

### 1. Install Arduino IDE
Download and install **Arduino IDE 2.x** from [arduino.cc](https://www.arduino.cc/en/software).

### 2. Add ESP32 Board Support
1. Open Arduino IDE and navigate to **File > Preferences**.
2. In the **Additional Boards Manager URLs** field, add:
   ```text
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. Go to **Tools > Board > Boards Manager...**, search for `esp32` by **Espressif Systems**, and click **Install**.

### 3. Install Required Sensor Libraries
Open **Tools > Manage Libraries...** (or `Ctrl + Shift + I`) and install:
1. **SparkFun MAX3010x Pulse and Proximity Sensor Library** (by SparkFun Electronics)
   - Search: `SparkFun MAX3010x` -> Click **Install**.
2. **Wire** and **BLEDevice** (pre-installed with ESP32 core).

---

## ⚙️ Arduino IDE Configuration

1. Connect your ESP32 board to your computer using a micro-USB cable.
2. Under **Tools**, select the following settings:
   - **Board**: `ESP32 Dev Module` (or `NodeMCU-32S`)
   - **Upload Speed**: `921600` (or `115200` if upload fails)
   - **CPU Frequency**: `240MHz (WiFi/BT)`
   - **Flash Frequency**: `80MHz`
   - **Partition Scheme**: `Huge APP (3MB No OTA/1MB SPIFFS)` or `Default 4MB with spiffs`
   - **Port**: Select the COM port corresponding to your ESP32 (e.g. `COM3` on Windows).

---

## 🚀 Flashing the Code to ESP32

1. Open `firmware/esp32_doodledry/esp32_doodledry.ino` in Arduino IDE.
2. Click the **Verify** button (check mark icon) to ensure compilation succeeds.
3. Click the **Upload** button (right arrow icon).
   > *Tip*: If the Arduino IDE displays `Connecting........_____.....`, press and hold the **BOOT** button on your ESP32 board until the flashing progress bar begins.
4. Once flashed, open the **Serial Monitor** (`Tools > Serial Monitor` or `Ctrl + Shift + M`).
5. Set baud rate to **115200 baud**.
6. Press the **EN / RESET** button on the ESP32. You will see:
   ```text
   =================================================
      DOODLEDRY - SMART INFANT MONITORING SYSTEM    
      Target: ESP32 Wearable BLE Telemetry Unit     
   =================================================
   [INIT] MPU6050 IMU motion sensor detected on 0x68.
   [INIT] MAX30102 Pulse Oximeter initialized on 0x57.
   [BLE] Initializing ESP32 BLE GATT Server...
   [BLE] GATT Service & Advertising ready. Name: DOODLEDRY-001
   [READY] DOODLEDRY Hardware Module Ready!
   Open the DOODLEDRY Mobile App to scan and connect.
   ```

---

## 📱 Testing & Verification with DOODLEDRY App

1. **Launch the DOODLEDRY Flutter App** on your Android/iOS smartphone or run `flutter run`.
2. Ensure Bluetooth and Location permissions are enabled on your phone.
3. In the App, navigate to the **Device Connection** tab (or tap the wearable card on the Dashboard).
4. Tap **Scan for Wearable Devices**.
5. You will see **`DOODLEDRY-001`** appear in the list with active RSSI signal strength.
6. Tap **Connect**.
7. Observe:
   - **ESP32 Serial Monitor**: Outputs `[BLE] >>> Caregiver Mobile Application Connected!`.
   - **ESP32 Onboard LED**: Turns solid ON.
   - **App Dashboard**: Shows `--` while each sensor collects enough valid samples, then displays live readings.
   - **Diagnostics Screen**: Shows each sensor's measured validity and connection details.

---

## 📡 BLE Protocol & Packet Specifications

The firmware implements the GATT specifications defined in `lib/core/ble/ble_config.dart`:

- **GATT Service UUID**: `0000fff0-0000-1000-8000-00805f9b34fb`
- **Telemetry Characteristic UUID (Notify/Read)**: `0000fff1-0000-1000-8000-00805f9b34fb`
- **Command Characteristic UUID (Write)**: `0000fff2-0000-1000-8000-00805f9b34fb`

### Transmitted JSON Payload (Default Mode):
```json
{
  "deviceId": "DOODLEDRY-001",
  "heartRate": null,
  "spo2": null,
  "temperature": null,
  "activity": "still",
  "fingerDetected": false,
  "heartRateValid": false,
  "spo2Valid": false,
  "temperatureValid": false,
  "temperatureMeasuring": true,
  "motionValid": true,
  "poorSignal": false,
  "fallDetected": false,
  "battery": null
}
```

### Legacy 12-Byte Binary Mode
The sketch retains this older mode for compatibility, but it does not carry the new per-sensor validity flags and is not suitable for production use. Keep `TELEMETRY_USE_JSON` set to `1`.
- `[0]`: Heart Rate (0-255 BPM)
- `[1]`: SpO₂ (0-100%)
- `[2..3]`: Temperature in °C × 100 (Uint16 Big-Endian)
- `[4..5]`: Accel X in m/s² × 100 (Int16 Big-Endian)
- `[6..7]`: Accel Y in m/s² × 100 (Int16 Big-Endian)
- `[8..9]`: Accel Z in m/s² × 100 (Int16 Big-Endian)
- `[10]`: Flags (`bit 0`: Fall detected; `bits 1..3`: Activity code)
- `[11]`: Battery percentage (0-100%)

---

## ❓ Troubleshooting & FAQs

### 1. I2C Sensors Not Detected (`[WARN] MAX30102 not detected` or `MPU6050 not detected`)
- Check your wiring: ensure SDA is connected to **GPIO 21** and SCL to **GPIO 22**.
- Some MAX30102 clone breakout boards require 5V on VIN rather than 3.3V because they have an onboard 3.3V LDO regulator.
- Ensure the sensors are receiving sufficient current.

### 2. Upload fails with `A fatal error occurred: Failed to connect to ESP32: No serial data received`
- Hold down the **BOOT** button on the ESP32 while Arduino IDE displays `Connecting........_____`. Release it once writing starts.
- Install the **CP2102** or **CH340** USB-to-UART bridge driver for your computer.

### 3. Mobile App does not discover `DOODLEDRY-001`
- On Android, ensure **Bluetooth** and **Location Services** (GPS) are toggled ON in the device status bar (required by Android OS for BLE scanning).
- Check the ESP32 Serial Monitor to ensure the firmware printed `[BLE] GATT Service & Advertising ready`.
