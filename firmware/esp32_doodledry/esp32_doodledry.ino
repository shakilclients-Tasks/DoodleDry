/*
 * =========================================================================================
 *                         DOODLEDRY - SMART INFANT MONITORING FIRMWARE
 *                              Target Microcontroller: ESP32
 * =========================================================================================
 *
 * Description:
 *   Production-grade ESP32 firmware for the DOODLEDRY Smart Baby Monitoring Wearable.
 *   This code samples vital sensors (MAX30102 for Heart Rate & SpO2, MPU6050 for 6-Axis
 *   Motion & Fall Detection), processes biological bounds, detects sudden infant falls,
 *   classifies dynamic activity (sleeping, awake, active, restless), and streams
 *   real-time telemetry over Bluetooth Low Energy (BLE) to the DOODLEDRY Flutter App.
 *
 * Compatible Sensors:
 *   - MAX30102 / MAX30100 Pulse Oximeter & Optical Heart Rate Sensor (I2C: 0x57)
 *   - MPU6050 6-Axis Motion Tracking Accelerometer & Gyroscope (I2C: 0x68 / 0x69)
 *   - MLX90614 Non-Contact Infrared Body & Ambient Temperature Sensor (I2C: 0x5A)
 *   - On-board LiPo Battery Voltage Sensing (Analog ADC pin GPIO 34)
 *   - Onboard Status LED (GPIO 2)
 *
 * Pin Connections (ESP32 DevKit):
 *   ---------------------------------------------------------------------------------------
 *   ESP32 Pin       Sensor Pin       Function / Description
 *   ---------------------------------------------------------------------------------------
 *   GPIO 21 (SDA)   MAX30102 SDA     I2C Data Bus (Shared by MAX30102, MPU6050 & MLX90614)
 *   GPIO 21 (SDA)   MPU6050  SDA     I2C Data Bus (Shared)
 *   GPIO 21 (SDA)   MLX90614 SDA     I2C Data Bus (Shared)
 *   GPIO 22 (SCL)   MAX30102 SCL     I2C Clock Bus (Shared by MAX30102, MPU6050 & MLX90614)
 *   GPIO 22 (SCL)   MPU6050  SCL     I2C Clock Bus (Shared)
 *   GPIO 22 (SCL)   MLX90614 SCL     I2C Clock Bus (Shared)
 *   3.3V            VCC / VIN        Power Supply for 3.3V sensors
 *   GND             GND              Common Ground
 *   GPIO 34 (ADC1)  BAT_DIV          LiPo Battery Voltage Divider (100k / 100k resistors)
 *   GPIO 2          LED_BUILTIN      Connection & Alert Status Indicator
 *   ---------------------------------------------------------------------------------------
 *
 * BLE GATT Architecture (Matches lib/core/ble/ble_config.dart):
 *   - Device Advertised Name:  "DOODLEDRY-001"
 *   - Service UUID:             0000fff0-0000-1000-8000-00805f9b34fb
 *   - Telemetry Characteristic: 0000fff1-0000-1000-8000-00805f9b34fb (Notify, Read)
 *   - Command Characteristic:   0000fff2-0000-1000-8000-00805f9b34fb (Write)
 *
 * Author: DOODLEDRY Systems Engineering Team
 * License: MIT
 * =========================================================================================
 */

#include <Arduino.h>
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "MAX30105.h"
#include "heartRate.h"

// =========================================================================================
//                             CONFIGURATION & TOGGLES
// =========================================================================================

#define DEVICE_NAME             "DOODLEDRY-001"
#define BABY_ID                 "baby_default"
#define TELEMETRY_USE_JSON      1
#ifndef ENABLE_CALIBRATION_DEBUG
#define ENABLE_CALIBRATION_DEBUG 0 // Development only: exposes raw data in Diagnostics
#endif

// Hardware Pins
#define I2C_SDA_PIN             21
#define I2C_SCL_PIN             22
#define BATTERY_ADC_PIN         34
#define STATUS_LED_PIN          2

// -----------------------------------------------------------------------------------------
// SENSOR I2C ADDRESSES:
// All 3 sensors connect to the SAME I2C pins (SDA=GPIO 21, SCL=GPIO 22) with ZERO conflict:
// - MAX30102: Fixed address 0x57 (Heart Rate & SpO2)
// - MPU6050:  Default address 0x68 (Motion & Falls), Alternate 0x69
// - MLX90614: Fixed address 0x5A (Non-Contact Infrared Body & Room Temp)
// -----------------------------------------------------------------------------------------
#define MAX30102_I2C_ADDR       0x57
#define MPU6050_I2C_ADDR        0x68
#define MPU6050_ALT_I2C_ADDR    0x69
#define MLX90614_I2C_ADDR       0x5A

// MLX90614 Internal RAM Registers
#define MLX90614_TAMB           0x06      // Ambient / Nursery Room Temp register
#define MLX90614_TOBJ1          0x07      // Object / Infant Body Temp register

// MPU6050 Internal Registers
#define MPU6050_CONFIG          0x1A
#define MPU6050_GYRO_CONFIG     0x1B
#define MPU6050_ACCEL_CONFIG    0x1C
#define MPU6050_ACCEL_XOUT_H    0x3B
#define MPU6050_PWR_MGMT_1      0x6B

// Physical Scales & Constants
#define ACCEL_SCALE_FACTOR      16384.0f  // for +/- 2g range (LSB / g)
#define GRAVITY_MSS             9.80665f  // standard 1g in m/s^2
#define GYRO_SCALE_FACTOR       131.0f    // for +/- 250 deg/s range (LSB / (deg/s))

// Motion & Fall Detection Thresholds
#define FREE_FALL_THRESHOLD     4.5f      // m/s^2 (Near zero-g drop)
#define IMPACT_THRESHOLD        17.0f     // m/s^2 (Sudden crash / impact landing)
#define DIRECT_SHOCK_THRESHOLD  24.0f     // m/s^2 (Bench-test drop / sudden shock)
#define FALL_ALERT_HOLD_MS      10000     // Hold fall alarm for 10 seconds

// Bluetooth base UUIDs are equivalent to the 128-bit values in Flutter BleConfig.
// Use their 16-bit form so the service and device name both fit in advertising.
#define SERVICE_UUID            "FFF0"
#define SENSOR_CHAR_UUID        "FFF1"
#define COMMAND_CHAR_UUID       "FFF2"

// Intervals
#define TELEMETRY_INTERVAL_MS   1000      // Stream BLE telemetry every 1 second
#define MOTION_SAMPLE_INTERVAL  20        // Sample MPU6050 at 50 Hz (every 20 ms)

// Bench-calibration settings. The zero offset must only change after comparison
// with a reference thermometer at the intended sensor distance and placement.
const float TEMP_CALIBRATION_OFFSET = 0.0f;
const float FINGER_IR_THRESHOLD = 25000.0f;
const float MIN_PPG_AC = 80.0f;
const float MAX_MOTION_FOR_PPG = 2.8f;
const float MOTION_STILL_THRESHOLD = 0.25f;
const float MOTION_ACTIVE_THRESHOLD = 1.20f;
const unsigned long MOTION_DWELL_MS = 600;
const unsigned long PPG_TIMEOUT_MS = 2500;
const unsigned long MOTION_TIMEOUT_MS = 1500;
const unsigned long TEMP_TIMEOUT_MS = 7000;
// Enable only after checking that the GPIO34 voltage divider is fitted.
const bool BATTERY_DIVIDER_FITTED = false;

// -----------------------------------------------------------------------------------------
// TEMPERATURE SENSOR HARDWARE CONFIGURATION:
//   TEMP_SENSOR_NONE              (0) : No sensor (sends "null")
//   TEMP_SENSOR_MLX90614          (1) : MLX90614 Contactless Infrared Sensor (I2C: 0x5A)
//   TEMP_SENSOR_MAX30102_INTERNAL (2) : MAX30102 on-chip sensor (maxSensor.readTemperature())
//   TEMP_SENSOR_ANALOG_NTC        (3) : Analog thermistor / LM35 on GPIO 35
// -----------------------------------------------------------------------------------------
#define TEMP_SENSOR_NONE               0
#define TEMP_SENSOR_MLX90614           1
#define TEMP_SENSOR_MAX30102_INTERNAL  2
#define TEMP_SENSOR_ANALOG_NTC         3

#ifndef TEMP_SENSOR_TYPE
#define TEMP_SENSOR_TYPE               TEMP_SENSOR_MLX90614   // Default to MLX90614 Non-Contact Sensor!
#endif

#define TEMP_ADC_PIN                   35                     // Analog ADC pin (GPIO 35) if using thermistor

// Backward-compatible toggle:
#define HAS_TEMPERATURE_SENSOR         (TEMP_SENSOR_TYPE != TEMP_SENSOR_NONE)

// =========================================================================================
//                                   GLOBAL OBJECTS & STATE
// =========================================================================================

MAX30105 maxSensor;
BLEServer* pServer = nullptr;
BLECharacteristic* pSensorCharacteristic = nullptr;
BLECharacteristic* pCommandCharacteristic = nullptr;

volatile bool deviceConnected = false;
bool oldDeviceConnected = false;
bool max30102Present = false;
bool mpu6050Present = false;
bool mlx90614Present = false;
uint8_t activeMpuAddr = MPU6050_I2C_ADDR;

// Vital Sensor State
float liveHeartRate = 0.0f;
float liveSpo2 = 0.0f;
bool fingerDetected = false;
bool heartRateValid = false;
bool spo2Valid = false;
bool poorSignal = false;
uint32_t rawIR = 0, rawRed = 0;
float ppgQuality = 0.0f;
unsigned long lastPpgSampleTime = 0;
unsigned long fingerSince = 0;
unsigned long lastValidBeatTime = 0;
uint32_t irMin = UINT32_MAX, irMax = 0, redMin = UINT32_MAX, redMax = 0;
uint16_t ppgWindowCount = 0;
float spo2Window[3] = {0};
byte spo2WindowCount = 0, spo2WindowSpot = 0;

// Temperature Sensor State (MLX90614 Non-Contact IR + MAX30102 Fallback)
float liveTemperature = 0.0f;
float liveAmbientTemperature = 0.0f;
float rawObjectTemperature = 0.0f;
bool temperatureValid = false;
byte temperatureSampleCount = 0;
unsigned long lastValidTemperatureTime = 0;

// 3-Axis Accelerometer (in m/s^2) & Gyroscope (in deg/s)
float accelX = 0.0f;
float accelY = 0.0f;
float accelZ = 0.0f;
float accelMagnitude = 0.0f;
float gyroX = 0.0f;
float gyroY = 0.0f;
float gyroZ = 0.0f;

// Dynamic Motion Tracking
float motionEnergy = 0.0f;
float prevAx = 0.0f, prevAy = 0.0f, prevAz = 9.81f;

// Fall Detection & Activity State
bool fallDetected = false;
unsigned long fallTriggerTime = 0;
bool potentialFreeFall = false;
unsigned long freeFallStartTime = 0;
String activityStatus = "unknown";
bool motionValid = false;
unsigned long lastValidMotionTime = 0;
String pendingActivity = "still";
unsigned long pendingActivitySince = 0;

// Battery & Timing
int batteryPercentage = -1;
unsigned long lastTelemetryTime = 0;
unsigned long lastMotionSampleTime = 0;
unsigned long lastMpuInitAttempt = 0;
unsigned long lastMaxInitAttempt = 0;

// Heart Beat Detection Buffers
const byte RATE_SIZE = 4;
byte rates[RATE_SIZE];
byte rateSpot = 0;
long lastBeat = 0;
byte validRateCount = 0;

// 12-Byte Binary Packet Fallback Layout (as per BlePacketParser.dart)
#pragma pack(push, 1)
struct DoodleDryBinaryPacket {
  uint8_t heartRate;      // [0]: Heart rate BPM (0..255)
  uint8_t spo2;           // [1]: SpO2 % (0..100)
  uint16_t temperature;   // [2..3]: Temp in C * 100 (Big-Endian)
  int16_t accelX;         // [4..5]: Ax in m/s^2 * 100 (Int16 Big-Endian)
  int16_t accelY;         // [6..7]: Ay in m/s^2 * 100 (Int16 Big-Endian)
  int16_t accelZ;         // [8..9]: Az in m/s^2 * 100 (Int16 Big-Endian)
  uint8_t flags;          // [10]: bit 0: fallDetected, bits 1..3: activity (0: sleep, 1: awake, 2: active, 3: restless)
  uint8_t battery;        // [11]: Battery % (0..100)
};
#pragma pack(pop)

// =========================================================================================
//                             BLE CALLBACK HANDLERS
// =========================================================================================

class ServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("[BLE] >>> Caregiver Mobile Application Connected!");
    digitalWrite(STATUS_LED_PIN, HIGH);
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("[BLE] <<< Device Disconnected. Resuming BLE Advertising...");
    digitalWrite(STATUS_LED_PIN, LOW);
  }
};

class CommandCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    // Compatible with both ESP32 Core 2.x and Core 3.x
    String rxValue = pCharacteristic->getValue().c_str();
    if (rxValue.length() > 0) {
      Serial.print("[BLE COMMAND RECEIVED]: ");
      Serial.println(rxValue);

      if (rxValue.indexOf("RESET") >= 0) {
        Serial.println("[COMMAND] Resetting fall detection & vital buffers...");
        fallDetected = false;
      } else if (rxValue.indexOf("PING") >= 0) {
        Serial.println("[COMMAND] Ping acknowledged.");
      }
    }
  }
};

// =========================================================================================
//                             HARDWARE INITIALIZATION
// =========================================================================================

void scanI2CDevices() {
  Serial.println("[I2C SCAN] Checking connected sensors on SDA=21, SCL=22...");
  byte count = 0;
  for (byte address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    byte error = Wire.endTransmission(true);
    if (error == 0) {
      Serial.print("  [+] I2C device detected at address 0x");
      if (address < 16) Serial.print("0");
      Serial.print(address, HEX);
      if (address == MAX30102_I2C_ADDR) {
        Serial.println(" -> MAX30102 Optical Heart Rate & SpO2 Sensor");
        max30102Present = true;
      } else if (address == MPU6050_I2C_ADDR) {
        Serial.println(" -> MPU6050 Motion Sensor (Default address, AD0=GND)");
        activeMpuAddr = MPU6050_I2C_ADDR;
        mpu6050Present = true;
      } else if (address == MPU6050_ALT_I2C_ADDR) {
        Serial.println(" -> MPU6050 Motion Sensor (Alternate address, AD0=3.3V)");
        activeMpuAddr = MPU6050_ALT_I2C_ADDR;
        mpu6050Present = true;
      } else if (address == MLX90614_I2C_ADDR) {
        Serial.println(" -> MLX90614 Non-Contact Infrared Body & Ambient Temperature Sensor");
        mlx90614Present = true;
      } else {
        Serial.println();
      }
      count++;
    }
  }
  if (count == 0) {
    Serial.println("  [!] No physical I2C devices detected. Check SDA (21) / SCL (22) wiring!");
  } else {
    Serial.printf("  [✓] Total %d I2C sensor(s) detected.\n", count);
  }
}

bool initMPU6050() {
  activeMpuAddr = MPU6050_I2C_ADDR;
  Wire.beginTransmission(activeMpuAddr);
  Wire.write(MPU6050_PWR_MGMT_1);
  Wire.write(0x00); // Wake up MPU-6050 (clear sleep bit)
  byte error = Wire.endTransmission(true);

  // If 0x68 does not respond, try alternate address 0x69 (AD0 pulled HIGH)
  if (error != 0) {
    activeMpuAddr = MPU6050_ALT_I2C_ADDR;
    Wire.beginTransmission(activeMpuAddr);
    Wire.write(MPU6050_PWR_MGMT_1);
    Wire.write(0x00);
    error = Wire.endTransmission(true);
  }

  if (error == 0) {
    // Configure Digital Low Pass Filter (~42 Hz DLPF)
    Wire.beginTransmission(activeMpuAddr);
    Wire.write(MPU6050_CONFIG);
    Wire.write(0x03);
    Wire.endTransmission(true);

    // Configure Gyroscope (+/- 250 deg/s)
    Wire.beginTransmission(activeMpuAddr);
    Wire.write(MPU6050_GYRO_CONFIG);
    Wire.write(0x00);
    Wire.endTransmission(true);

    // Configure Accelerometer (+/- 2g)
    Wire.beginTransmission(activeMpuAddr);
    Wire.write(MPU6050_ACCEL_CONFIG);
    Wire.write(0x00);
    Wire.endTransmission(true);

    Serial.printf("[INIT] MPU6050 Motion Sensor active on address: 0x%02X\n", activeMpuAddr);
    return true;
  } else {
    Serial.println("[WARN] MPU6050 Motion Sensor not detected at 0x68 or 0x69!");
    return false;
  }
}

bool initMAX30102() {
  if (maxSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    Serial.println("[INIT] MAX30102 Pulse Oximeter initialized on 0x57.");
    byte ledBrightness = 60; // 0 to 255 (~12mA)
    byte sampleAverage = 4;
    byte ledMode = 2;        // Red + IR mode
    int sampleRate = 400;    // 400 Hz internal sampling
    int pulseWidth = 411;    // 411 us (18-bit ADC)
    int adcRange = 4096;
    maxSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
    maxSensor.setPulseAmplitudeRed(0x28); // Red LED optimal brightness
    maxSensor.setPulseAmplitudeIR(0x28);  // IR LED optimal brightness
    return true;
  } else {
    Serial.println("[WARN] MAX30102 not detected on I2C bus!");
    return false;
  }
}

void initBLE() {
  Serial.println("[BLE] Initializing ESP32 BLE GATT Server...");
  BLEDevice::init(DEVICE_NAME);
  BLEDevice::setMTU(512);

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Create Primary Wearable Service
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // Sensor Telemetry Characteristic (Notify & Read)
  pSensorCharacteristic = pService->createCharacteristic(
    SENSOR_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pSensorCharacteristic->addDescriptor(new BLE2902());

  // Command & Config Characteristic (Write)
  pCommandCharacteristic = pService->createCharacteristic(
    COMMAND_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_WRITE_NR
  );
  pCommandCharacteristic->setCallbacks(new CommandCallbacks());

  pService->start();

  // BLE Advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("[BLE] GATT Service & Advertising ready. Name: " DEVICE_NAME);
}

// =========================================================================================
//                             SENSOR READING ROUTINES
// =========================================================================================

void readMPU6050() {
  if (!mpu6050Present) {
    if (millis() - lastMpuInitAttempt < 5000) return;
    lastMpuInitAttempt = millis();
    mpu6050Present = initMPU6050();
    if (!mpu6050Present) {
      motionValid = false;
      activityStatus = "unknown";
      return;
    }
  }

  Wire.beginTransmission(activeMpuAddr);
  Wire.write(MPU6050_ACCEL_XOUT_H);
  byte error = Wire.endTransmission(true); // Send STOP bit to cleanly release bus
  if (error == 0 && Wire.requestFrom((uint8_t)activeMpuAddr, (size_t)14, (bool)true) == 14) {
    int16_t rawAx = (Wire.read() << 8) | Wire.read();
    int16_t rawAy = (Wire.read() << 8) | Wire.read();
    int16_t rawAz = (Wire.read() << 8) | Wire.read();
    int16_t rawTemp = (Wire.read() << 8) | Wire.read(); // Chip die temp (ignored)
    int16_t rawGx = (Wire.read() << 8) | Wire.read();
    int16_t rawGy = (Wire.read() << 8) | Wire.read();
    int16_t rawGz = (Wire.read() << 8) | Wire.read();

    accelX = (float)rawAx / ACCEL_SCALE_FACTOR * GRAVITY_MSS;
    accelY = (float)rawAy / ACCEL_SCALE_FACTOR * GRAVITY_MSS;
    accelZ = (float)rawAz / ACCEL_SCALE_FACTOR * GRAVITY_MSS;

    gyroX = (float)rawGx / GYRO_SCALE_FACTOR; // deg/s
    gyroY = (float)rawGy / GYRO_SCALE_FACTOR;
    gyroZ = (float)rawGz / GYRO_SCALE_FACTOR;
  } else {
    // I2C communication glitch or NACK
    if (millis() - lastValidMotionTime > MOTION_TIMEOUT_MS) {
      motionValid = false;
      activityStatus = "unknown";
      mpu6050Present = false;
    }
    return;
  }

  motionValid = true;
  lastValidMotionTime = millis();

  // 1. Total acceleration vector magnitude: |A| = sqrt(Ax^2 + Ay^2 + Az^2)
  accelMagnitude = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);

  // 2. High-sensitivity per-axis motion detection (Linear Jerk + Rotational Velocity)
  float diffAx = abs(accelX - prevAx);
  float diffAy = abs(accelY - prevAy);
  float diffAz = abs(accelZ - prevAz);
  float linearJerk = diffAx + diffAy + diffAz;

  float gyroRate = sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ); // deg/s

  // Combined instantaneous motion metric (sensitive to any hand move, tilt, or rotation)
  float instantMotion = linearJerk + (gyroRate * 0.05f);

  // Smooth motion energy with exponential moving average
  motionEnergy = (motionEnergy * 0.70f) + (instantMotion * 0.30f);

  prevAx = accelX;
  prevAy = accelY;
  prevAz = accelZ;

  // ---------------------------------------------------------------------------------------
  // MOTION & FALL DETECTION CONDITIONS
  // ---------------------------------------------------------------------------------------
  // Condition 1: Free Fall Detection (Weightlessness / drop: |A| < 4.5 m/s^2)
  if (accelMagnitude < FREE_FALL_THRESHOLD && !potentialFreeFall) {
    potentialFreeFall = true;
    freeFallStartTime = millis();
    Serial.println("[FALL-DETECTOR] Free-fall detected (low-G drop)...");
  }

  // Condition 2: High Impact Shock following free-fall within 1.2 seconds
  if (potentialFreeFall) {
    if (millis() - freeFallStartTime < 1200) {
      if (accelMagnitude > IMPACT_THRESHOLD || linearJerk > 14.0f) {
        fallDetected = true;
        fallTriggerTime = millis();
        potentialFreeFall = false;
        Serial.println("[ALERT] >>> INFANT FALL DETECTED! (Free-fall + Landing Impact) <<<");
      }
    } else {
      potentialFreeFall = false; // Free-fall window expired without impact
    }
  }

  // Condition 3: Direct Shock Impact (Sudden drop / bench-test crash: > 24.0 m/s^2)
  if (accelMagnitude > DIRECT_SHOCK_THRESHOLD || linearJerk > 20.0f) {
    fallDetected = true;
    fallTriggerTime = millis();
    Serial.println("[ALERT] >>> DIRECT HIGH-IMPACT CRASH DETECTED! <<<");
  }

  // Hold fall alert for 10 seconds so BLE and App display emergency notification
  if (fallDetected && (millis() - fallTriggerTime > FALL_ALERT_HOLD_MS)) {
    fallDetected = false;
    Serial.println("[INFO] Fall alert hold expired. Resuming normal monitoring.");
  }

  // ---------------------------------------------------------------------------------------
  // DYNAMIC ACTIVITY MODE CLASSIFICATION
  // Updates in real-time when the sensor is moved, picked up, rotated, or shaken:
  // ---------------------------------------------------------------------------------------
  String nextStatus;
  if (fallDetected) {
    nextStatus = "active";
  } else if (motionEnergy < MOTION_STILL_THRESHOLD) {
    nextStatus = "still";
  } else if (motionEnergy < MOTION_ACTIVE_THRESHOLD) {
    nextStatus = "moving";
  } else {
    nextStatus = "active";
  }
  if (nextStatus != pendingActivity) {
    pendingActivity = nextStatus;
    pendingActivitySince = millis();
  } else if (activityStatus != nextStatus && millis() - pendingActivitySince >= MOTION_DWELL_MS) {
    activityStatus = nextStatus;
    Serial.printf("[MOTION STATUS CHANGE] >>> New Mode: %s (Energy: %.2f | Jerk: %.2f | Gyro: %.1f deg/s)\n",
      activityStatus.c_str(), motionEnergy, linearJerk, gyroRate);
  }
}

void readMAX30102() {
  if (!max30102Present) {
    if (millis() - lastMaxInitAttempt >= 5000) {
      lastMaxInitAttempt = millis();
      max30102Present = initMAX30102();
    }
    fingerDetected = false;
    heartRateValid = false;
    spo2Valid = false;
    return;
  }
  maxSensor.check();
  while (maxSensor.available()) {
    uint32_t irValue = maxSensor.getFIFOIR();
    uint32_t redValue = maxSensor.getFIFORed();
    maxSensor.nextSample();
    rawIR = irValue;
    rawRed = redValue;
    lastPpgSampleTime = millis();
    if (irValue < FINGER_IR_THRESHOLD || redValue < 1000) {
      fingerDetected = false;
      heartRateValid = false;
      spo2Valid = false;
      poorSignal = false;
      liveHeartRate = liveSpo2 = 0.0f;
      validRateCount = rateSpot = spo2WindowCount = spo2WindowSpot = 0;
      ppgWindowCount = 0;
      irMin = redMin = UINT32_MAX;
      irMax = redMax = 0;
      lastBeat = 0;
      continue;
    }
    if (!fingerDetected) {
      fingerDetected = true;
      fingerSince = millis();
      validRateCount = spo2WindowCount = 0;
      lastBeat = 0;
    }
    if (motionValid && motionEnergy > MAX_MOTION_FOR_PPG) {
      poorSignal = true;
      heartRateValid = spo2Valid = false;
      validRateCount = spo2WindowCount = ppgWindowCount = 0;
      lastBeat = 0;
      continue;
    }
    if (checkForBeat(irValue)) {
      unsigned long now = millis();
      unsigned long interval = now - lastBeat;
      lastBeat = now;
      if (interval >= 333 && interval <= 1500 && now - fingerSince > 2000) {
        rates[rateSpot] = (byte)(60000.0f / interval);
        rateSpot = (rateSpot + 1) % RATE_SIZE;
        if (validRateCount < RATE_SIZE) validRateCount++;
        if (validRateCount >= 3) {
          byte ordered[RATE_SIZE];
          for (byte i = 0; i < validRateCount; i++) ordered[i] = rates[i];
          for (byte i = 0; i < validRateCount; i++)
            for (byte j = i + 1; j < validRateCount; j++)
              if (ordered[j] < ordered[i]) { byte t = ordered[i]; ordered[i] = ordered[j]; ordered[j] = t; }
          liveHeartRate = ordered[validRateCount / 2];
          heartRateValid = !poorSignal;
          lastValidBeatTime = now;
        }
      } else if (interval > 1500) {
        validRateCount = 0;
        heartRateValid = false;
      }
    }
    if (irValue < irMin) irMin = irValue;
    if (irValue > irMax) irMax = irValue;
    if (redValue < redMin) redMin = redValue;
    if (redValue > redMax) redMax = redValue;
    if (++ppgWindowCount >= 300) {
      float acIR = (float)(irMax - irMin), acRed = (float)(redMax - redMin);
      float dcIR = ((float)irMax + irMin) / 2.0f;
      float dcRed = ((float)redMax + redMin) / 2.0f;
      ppgQuality = dcIR > 0 ? acIR / dcIR : 0;
      poorSignal = acIR < MIN_PPG_AC || acRed < MIN_PPG_AC ||
          ppgQuality < 0.002f || ppgQuality > 0.20f;
      if (!poorSignal && dcRed > 10000 && dcIR > 10000) {
        float ratio = (acRed / dcRed) / (acIR / dcIR);
        // Existing ratio estimate. Must be calibrated against a reference oximeter;
        // no value is clamped into a healthy band.
        float estimate = 104.0f - 17.0f * ratio;
        if (ratio > 0.2f && ratio < 1.8f && estimate >= 50.0f && estimate <= 100.0f) {
          spo2Window[spo2WindowSpot] = estimate;
          spo2WindowSpot = (spo2WindowSpot + 1) % 3;
          if (spo2WindowCount < 3) spo2WindowCount++;
          if (spo2WindowCount == 3 && millis() - fingerSince > 5000) {
            float a = spo2Window[0], b = spo2Window[1], c = spo2Window[2];
            liveSpo2 = max(min(a, b), min(max(a, b), c));
            spo2Valid = true;
          }
        } else {
          poorSignal = true;
        }
      }
      if (poorSignal) {
        heartRateValid = spo2Valid = false;
        spo2WindowCount = 0;
      }
      ppgWindowCount = 0;
      irMin = redMin = UINT32_MAX;
      irMax = redMax = 0;
    }
  }
  if (millis() - lastPpgSampleTime > PPG_TIMEOUT_MS) {
    fingerDetected = heartRateValid = spo2Valid = false;
    liveHeartRate = liveSpo2 = 0.0f;
  }
  if (millis() - lastValidBeatTime > PPG_TIMEOUT_MS) heartRateValid = false;
}

// =========================================================================================
//                             MLX90614 NATIVE I2C DRIVER
// =========================================================================================

uint8_t mlxPecUpdate(uint8_t crc, uint8_t value) {
  crc ^= value;
  for (byte bit = 0; bit < 8; bit++)
    crc = (crc & 0x80) ? (uint8_t)((crc << 1) ^ 0x07) : (uint8_t)(crc << 1);
  return crc;
}

float readMLX90614Temp(uint8_t reg) {
  Wire.beginTransmission(MLX90614_I2C_ADDR);
  Wire.write(reg);
  byte error = Wire.endTransmission(false); // Repeated start (crucial for SMBus)
  if (error != 0) {
    Wire.beginTransmission(MLX90614_I2C_ADDR);
    Wire.write(reg);
    error = Wire.endTransmission(true);
    if (error != 0) return -999.0f;
  }

  uint8_t bytesReceived = Wire.requestFrom((uint8_t)MLX90614_I2C_ADDR, (size_t)3, (bool)true);
  if (bytesReceived == 3) {
    uint8_t dataLow = Wire.read();
    uint8_t dataHigh = Wire.read();
    uint8_t receivedPec = Wire.read();
    uint8_t calculatedPec = 0;
    calculatedPec = mlxPecUpdate(calculatedPec, MLX90614_I2C_ADDR << 1);
    calculatedPec = mlxPecUpdate(calculatedPec, reg);
    calculatedPec = mlxPecUpdate(calculatedPec, (MLX90614_I2C_ADDR << 1) | 1);
    calculatedPec = mlxPecUpdate(calculatedPec, dataLow);
    calculatedPec = mlxPecUpdate(calculatedPec, dataHigh);
    if (calculatedPec != receivedPec) return -999.0f;

    // Check error bit (bit 7 of Data High indicates sensor error)
    if (dataHigh & 0x80) {
      return -999.0f;
    }

    uint16_t raw = ((uint16_t)dataHigh << 8) | dataLow;
    float tempCelsius = (raw * 0.02f) - 273.15f;
    return tempCelsius;
  }
  return -999.0f;
}

bool initMLX90614() {
  Wire.beginTransmission(MLX90614_I2C_ADDR);
  byte error = Wire.endTransmission(true);
  if (error == 0) {
    mlx90614Present = true;
    Serial.println("[INIT] MLX90614 Infrared Non-Contact Temperature Sensor verified on 0x5A.");
    return true;
  } else {
    mlx90614Present = false;
    Serial.println("[WARN] MLX90614 sensor not responding on I2C address 0x5A!");
    return false;
  }
}

void readTemperature() {
  float objTemp = readMLX90614Temp(MLX90614_TOBJ1);
  float ambTemp = readMLX90614Temp(MLX90614_TAMB);
  if (isfinite(objTemp) && objTemp >= 30.0f && objTemp <= 44.0f) {
    mlx90614Present = true;
    rawObjectTemperature = objTemp;
    float calibrated = objTemp + TEMP_CALIBRATION_OFFSET;
    if (temperatureSampleCount == 0) liveTemperature = calibrated;
    else liveTemperature = 0.65f * liveTemperature + 0.35f * calibrated;
    if (temperatureSampleCount < 3) temperatureSampleCount++;
    temperatureValid = temperatureSampleCount >= 3;
    lastValidTemperatureTime = millis();
    if (isfinite(ambTemp) && ambTemp >= -20.0f && ambTemp <= 85.0f)
      liveAmbientTemperature = ambTemp;
  } else {
    if (millis() - lastValidTemperatureTime > TEMP_TIMEOUT_MS) {
      temperatureValid = false;
      temperatureSampleCount = 0;
      mlx90614Present = false;
    }
  }
}

void readBattery() {
  if (!BATTERY_DIVIDER_FITTED) { batteryPercentage = -1; return; }
  float voltage = (analogReadMilliVolts(BATTERY_ADC_PIN) / 1000.0f) * 2.0f;
  if (!isfinite(voltage) || voltage < 3.0f || voltage > 4.3f) {
    batteryPercentage = -1;
    return;
  }
  batteryPercentage = constrain((int)roundf((voltage - 3.3f) * 100.0f / 0.9f), 0, 100);
}

// =========================================================================================
//                             TELEMETRY TRANSMISSION
// =========================================================================================

void sendTelemetry() {
  if (!deviceConnected) return;

#if TELEMETRY_USE_JSON
  char jsonBuffer[512];
  char hr[16], o2[16], temp[16], battery[8];
  if (heartRateValid && fingerDetected) snprintf(hr, sizeof(hr), "%.0f", liveHeartRate); else strcpy(hr, "null");
  if (spo2Valid && fingerDetected) snprintf(o2, sizeof(o2), "%.1f", liveSpo2); else strcpy(o2, "null");
  if (temperatureValid) snprintf(temp, sizeof(temp), "%.2f", liveTemperature); else strcpy(temp, "null");
  if (batteryPercentage >= 0) snprintf(battery, sizeof(battery), "%d", batteryPercentage); else strcpy(battery, "null");

#if ENABLE_CALIBRATION_DEBUG
  int length = snprintf(jsonBuffer, sizeof(jsonBuffer),
    "{\"deviceId\":\"%s\",\"heartRate\":%s,\"spo2\":%s,\"temperature\":%s,\"activity\":\"%s\","
    "\"fingerDetected\":%s,\"heartRateValid\":%s,\"spo2Valid\":%s,\"temperatureValid\":%s,"
    "\"temperatureMeasuring\":%s,\"motionValid\":%s,\"poorSignal\":%s,\"fallDetected\":%s,\"battery\":%s,"
    "\"debug\":{\"red\":%lu,\"ir\":%lu,\"q\":%.3f,\"ambient\":%.2f,\"object\":%.2f,\"offset\":%.2f,"
    "\"ax\":%.2f,\"ay\":%.2f,\"az\":%.2f,\"gx\":%.1f,\"gy\":%.1f,\"gz\":%.1f,\"am\":%.2f}}",
    DEVICE_NAME, hr, o2, temp, activityStatus.c_str(),
    fingerDetected ? "true" : "false", heartRateValid ? "true" : "false",
    spo2Valid ? "true" : "false", temperatureValid ? "true" : "false",
    temperatureSampleCount > 0 && !temperatureValid ? "true" : "false",
    motionValid ? "true" : "false", poorSignal ? "true" : "false",
    fallDetected ? "true" : "false", battery,
    (unsigned long)rawRed, (unsigned long)rawIR, ppgQuality,
    liveAmbientTemperature, rawObjectTemperature, TEMP_CALIBRATION_OFFSET,
    accelX, accelY, accelZ, gyroX, gyroY, gyroZ, accelMagnitude);
#else
  int length = snprintf(jsonBuffer, sizeof(jsonBuffer),
    "{\"deviceId\":\"%s\",\"heartRate\":%s,\"spo2\":%s,\"temperature\":%s,\"activity\":\"%s\","
    "\"fingerDetected\":%s,\"heartRateValid\":%s,\"spo2Valid\":%s,\"temperatureValid\":%s,"
    "\"temperatureMeasuring\":%s,\"motionValid\":%s,\"poorSignal\":%s,\"fallDetected\":%s,\"battery\":%s}"
    , DEVICE_NAME, hr, o2, temp, activityStatus.c_str(),
    fingerDetected ? "true" : "false", heartRateValid ? "true" : "false",
    spo2Valid ? "true" : "false", temperatureValid ? "true" : "false",
    temperatureSampleCount > 0 && !temperatureValid ? "true" : "false",
    motionValid ? "true" : "false", poorSignal ? "true" : "false",
    fallDetected ? "true" : "false", battery);
#endif
  if (length <= 0 || length >= (int)sizeof(jsonBuffer)) {
    Serial.println("[BLE] Telemetry overflow; packet dropped");
    return;
  }
  // Framed by JSON braces, sent in MTU-23-safe chunks. Flutter reassembles it.
  for (int offset = 0; offset < length && deviceConnected; offset += 20) {
    int chunk = min(20, length - offset);
    pSensorCharacteristic->setValue((uint8_t*)jsonBuffer + offset, chunk);
    pSensorCharacteristic->notify();
    delay(5);
  }

#else
  DoodleDryBinaryPacket packet;
  packet.heartRate = (uint8_t)constrain((int)liveHeartRate, 0, 255);
  packet.spo2 = (uint8_t)constrain((int)liveSpo2, 0, 100);

#if HAS_TEMPERATURE_SENSOR
  if (temperatureValid && liveTemperature > 0.0f) {
    uint16_t rawTemp = (uint16_t)(liveTemperature * 100.0f);
    packet.temperature = (uint16_t)(((rawTemp >> 8) & 0x00FF) | ((rawTemp << 8) & 0xFF00));
  } else {
    packet.temperature = 0;
  }
#else
  packet.temperature = 0; // null temperature scaled
#endif

  int16_t axScaled = (int16_t)(accelX * 100.0f);
  packet.accelX = (int16_t)(((axScaled >> 8) & 0x00FF) | ((axScaled << 8) & 0xFF00));
  int16_t ayScaled = (int16_t)(accelY * 100.0f);
  packet.accelY = (int16_t)(((ayScaled >> 8) & 0x00FF) | ((ayScaled << 8) & 0xFF00));
  int16_t azScaled = (int16_t)(accelZ * 100.0f);
  packet.accelZ = (int16_t)(((azScaled >> 8) & 0x00FF) | ((azScaled << 8) & 0xFF00));

  uint8_t activityCode = 0; // 0: sleeping, 1: awake, 2: active, 3: restless
  if (activityStatus == "awake") activityCode = 1;
  else if (activityStatus == "active") activityCode = 2;
  else if (activityStatus == "restless") activityCode = 3;

  packet.flags = (fallDetected ? 0x01 : 0x00) | ((activityCode & 0x07) << 1);
  packet.battery = (uint8_t)constrain(batteryPercentage, 0, 100);

  pSensorCharacteristic->setValue((uint8_t*)&packet, sizeof(packet));
  pSensorCharacteristic->notify();

  Serial.println("[BLE TX BINARY] >> 12 bytes notified.");
#endif
}

// =========================================================================================
//                             ARDUINO SETUP & LOOP
// =========================================================================================

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("=================================================");
  Serial.println("   DOODLEDRY - SMART INFANT MONITORING SYSTEM    ");
  Serial.println("   Target: ESP32 Wearable BLE Telemetry Unit     ");
  Serial.println("=================================================");

  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);
  pinMode(BATTERY_ADC_PIN, INPUT);

  // Initialize I2C Communication
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  Wire.setClock(100000); // 100kHz standard mode REQUIRED for MLX90614 SMBus!

  // Auto-scan I2C bus to detect both sensor addresses
  scanI2CDevices();

  // Initialize Sensors
  mpu6050Present = initMPU6050();
  max30102Present = initMAX30102();
  initMLX90614(); // Verify MLX90614 Contactless Infrared Sensor on 0x5A

  // Initialize BLE Stack
  initBLE();

  Serial.println("[READY] DOODLEDRY Hardware Module Ready!");
  Serial.println("Open the DOODLEDRY Mobile App to scan and connect.");
}

void loop() {
  unsigned long now = millis();

  // 1. MAX30102 check - sampled every 25ms to prevent shared I2C bus starvation
  static unsigned long lastHeartSampleTime = 0;
  if (now - lastHeartSampleTime >= 25) {
    lastHeartSampleTime = now;
    readMAX30102();
  }

  // 2. Motion sampling (MPU6050 sampled at 50 Hz = 20ms for fast fall & activity detection)
  if (now - lastMotionSampleTime >= MOTION_SAMPLE_INTERVAL) {
    lastMotionSampleTime = now;
    readMPU6050();
    readBattery();
  }

  // 3. Periodic Temperature Sampling (every 2.5 seconds to preserve I2C bus bandwidth)
  static unsigned long lastTempSampleTime = 0;
  if (now - lastTempSampleTime >= 2500) {
    lastTempSampleTime = now;
    readTemperature();
  }

  // 4. Periodic Telemetry Streaming (1 Hz)
  if (now - lastTelemetryTime >= TELEMETRY_INTERVAL_MS) {
    lastTelemetryTime = now;
    sendTelemetry();
  }

  // Handle BLE Disconnection Re-advertising
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] Restarted BLE advertising...");
    oldDeviceConnected = deviceConnected;
  }

  // Handle BLE Connection Transition
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Status LED Blinking when advertising / waiting for connection
  if (!deviceConnected) {
    digitalWrite(STATUS_LED_PIN, (now / 500) % 2 == 0 ? HIGH : LOW);
  }
}
