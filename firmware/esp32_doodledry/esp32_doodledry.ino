/*
 * =========================================================================================
 *                         DOODLEDRY - SMART INFANT MONITORING FIRMWARE
 *                              Target Microcontroller: ESP32
 * =========================================================================================
 *
 * Description:
 *   ESP32 prototype firmware for the DOODLEDRY wearable.
 *   This code samples vital sensors (MAX30102 for Heart Rate & SpO2, MPU6050 for 6-Axis
 *   Motion & Fall Detection), processes biological bounds, detects sudden infant falls,
 *   classifies activity, and streams
 *   real-time telemetry over Bluetooth Low Energy (BLE) to the DOODLEDRY Flutter App.
 *
 * Compatible Sensors:
 *   - MAX30102 Pulse Oximeter & Optical Heart Rate Sensor (I2C: 0x57)
 *   - MPU6050 6-Axis Motion Tracking Accelerometer & Gyroscope (I2C: 0x68 / 0x69)
 *   - MLX90614 Non-Contact Infrared Object & Ambient Temperature Sensor (I2C: 0x5A)
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
#include "spo2_algorithm.h"

// =========================================================================================
//                             CONFIGURATION & TOGGLES
// =========================================================================================

#define DEVICE_NAME             "DOODLEDRY-001"
#define BABY_ID                 "baby_default"
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
// - MLX90614: Fixed address 0x5A (Non-Contact Infrared Object & Ambient Temp)
// -----------------------------------------------------------------------------------------
#define MAX30102_I2C_ADDR       0x57
#define MPU6050_I2C_ADDR        0x68
#define MPU6050_ALT_I2C_ADDR    0x69
#define MLX90614_I2C_ADDR       0x5A

// MLX90614 Internal RAM Registers
#define MLX90614_TAMB           0x06      // Local sensor ambient temperature register
#define MLX90614_TOBJ1          0x07      // IR object temperature register

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

// Contact and signal thresholds must be verified with the final optical placement.
const float FINGER_IR_THRESHOLD = 25000.0f;
const float MIN_PPG_AC = 80.0f;
const float MAX_MOTION_FOR_PPG = 2.8f;
const float MOTION_STILL_THRESHOLD = 0.25f;
const float MOTION_ACTIVE_THRESHOLD = 1.20f;
const unsigned long MOTION_DWELL_MS = 600;
const unsigned long PPG_TIMEOUT_MS = 2500;
const unsigned long MOTION_TIMEOUT_MS = 1500;
// Enable only after checking that the GPIO34 voltage divider is fitted.
const bool BATTERY_DIVIDER_FITTED = false;

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
// MAXREFDES117 reference algorithm expects 100 samples at 25 samples/second.
static const uint16_t PPG_BUFFER_SIZE = 100;
static const uint16_t PPG_STEP_SIZE = 25;
uint32_t irBuffer[PPG_BUFFER_SIZE] = {0};
uint32_t redBuffer[PPG_BUFFER_SIZE] = {0};
uint16_t ppgSampleCount = 0;
unsigned long lastPpgCalculationTime = 0;

// Temperature is the MLX90614 IR object's surface temperature, not core body temperature.
float liveTemperature = 0.0f;
float liveAmbientTemperature = 0.0f;
float rawObjectTemperature = 0.0f;
bool temperatureValid = false;
byte temperatureSampleCount = 0;

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
    int sampleRate = 100;    // 100 Hz / 4-sample average = 25 FIFO samples/s
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

void clearPpgReadings() {
  heartRateValid = false;
  spo2Valid = false;
  liveHeartRate = 0.0f;
  liveSpo2 = 0.0f;
  ppgSampleCount = 0;
  lastPpgCalculationTime = 0;
}

void readMAX30102() {
  if (!max30102Present) {
    if (millis() - lastMaxInitAttempt >= 5000) {
      lastMaxInitAttempt = millis();
      max30102Present = initMAX30102();
    }
    fingerDetected = false;
    poorSignal = false;
    clearPpgReadings();
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
    if (irValue < FINGER_IR_THRESHOLD || redValue < 1000 ||
        irValue >= 260000 || redValue >= 260000) {
      fingerDetected = false;
      poorSignal = false;
      clearPpgReadings();
      continue;
    }
    if (!fingerDetected) {
      fingerDetected = true;
      poorSignal = false;
      clearPpgReadings();
    }
    if (motionValid && motionEnergy > MAX_MOTION_FOR_PPG) {
      poorSignal = true;
      clearPpgReadings();
      continue;
    }
    irBuffer[ppgSampleCount] = irValue;
    redBuffer[ppgSampleCount] = redValue;
    ppgSampleCount++;
    if (ppgSampleCount == PPG_BUFFER_SIZE) {
      uint32_t irMin = UINT32_MAX, irMax = 0, redMin = UINT32_MAX, redMax = 0;
      for (uint16_t i = 0; i < PPG_BUFFER_SIZE; i++) {
        irMin = min(irMin, irBuffer[i]);
        irMax = max(irMax, irBuffer[i]);
        redMin = min(redMin, redBuffer[i]);
        redMax = max(redMax, redBuffer[i]);
      }
      const float irDcFloor = 10000.0f;
      ppgQuality = ((float)irMax - irMin) / max((float)irMax, irDcFloor);
      poorSignal = irMin < FINGER_IR_THRESHOLD || redMin < 1000 ||
          irMax >= 260000 || redMax >= 260000 ||
          irMax - irMin < MIN_PPG_AC || redMax - redMin < MIN_PPG_AC ||
          ppgQuality < 0.001f || ppgQuality > 0.25f;

      int32_t calculatedSpo2 = -999, calculatedHr = -999;
      int8_t validSpo2 = 0, validHr = 0;
      if (!poorSignal) {
        maxim_heart_rate_and_oxygen_saturation(irBuffer, PPG_BUFFER_SIZE,
            redBuffer, &calculatedSpo2, &validSpo2, &calculatedHr, &validHr);
      }
      heartRateValid = !poorSignal && validHr == 1 &&
          calculatedHr >= 40 && calculatedHr <= 240;
      spo2Valid = !poorSignal && validSpo2 == 1 &&
          calculatedSpo2 >= 50 && calculatedSpo2 <= 100;
      liveHeartRate = heartRateValid ? (float)calculatedHr : 0.0f;
      liveSpo2 = spo2Valid ? (float)calculatedSpo2 : 0.0f;
      lastPpgCalculationTime = millis();
      if (!heartRateValid && !spo2Valid) poorSignal = true;

      // Keep 75 measured samples and recalculate after 25 new ones (1 second).
      for (uint16_t i = PPG_STEP_SIZE; i < PPG_BUFFER_SIZE; i++) {
        irBuffer[i - PPG_STEP_SIZE] = irBuffer[i];
        redBuffer[i - PPG_STEP_SIZE] = redBuffer[i];
      }
      ppgSampleCount = PPG_BUFFER_SIZE - PPG_STEP_SIZE;
    }
  }
  if (millis() - lastPpgSampleTime > PPG_TIMEOUT_MS) {
    fingerDetected = false;
    poorSignal = false;
    clearPpgReadings();
    if (millis() - lastPpgSampleTime > 5000) max30102Present = false;
  }
  if (lastPpgCalculationTime != 0 &&
      millis() - lastPpgCalculationTime > PPG_TIMEOUT_MS) {
    heartRateValid = spo2Valid = false;
    liveHeartRate = liveSpo2 = 0.0f;
  }
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
  rawObjectTemperature = objTemp;
  liveAmbientTemperature = (isfinite(ambTemp) && ambTemp >= -20.0f && ambTemp <= 85.0f)
      ? ambTemp : -999.0f;
  if (isfinite(objTemp) && objTemp >= -20.0f && objTemp <= 100.0f) {
    mlx90614Present = true;
    liveTemperature = objTemp; // The current, PEC-checked IR object measurement.
    if (temperatureSampleCount < 3) temperatureSampleCount++;
    temperatureValid = temperatureSampleCount >= 3;
  } else {
    // Never keep reporting an older temperature after a failed I2C/PEC read.
    temperatureValid = false;
    temperatureSampleCount = 0;
    liveTemperature = 0.0f;
    mlx90614Present = false;
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

  char jsonBuffer[640];
  char hr[16], o2[16], temp[16], ambient[16], battery[8];
  if (heartRateValid && fingerDetected) snprintf(hr, sizeof(hr), "%.0f", liveHeartRate); else strcpy(hr, "null");
  if (spo2Valid && fingerDetected) snprintf(o2, sizeof(o2), "%.1f", liveSpo2); else strcpy(o2, "null");
  if (temperatureValid) snprintf(temp, sizeof(temp), "%.2f", liveTemperature); else strcpy(temp, "null");
  if (liveAmbientTemperature > -100.0f) snprintf(ambient, sizeof(ambient), "%.2f", liveAmbientTemperature); else strcpy(ambient, "null");
  if (batteryPercentage >= 0) snprintf(battery, sizeof(battery), "%d", batteryPercentage); else strcpy(battery, "null");

#if ENABLE_CALIBRATION_DEBUG
  int length = snprintf(jsonBuffer, sizeof(jsonBuffer),
    "{\"protocol\":2,\"deviceId\":\"%s\",\"sensorModel\":\"MLX90614_IR_OBJECT\",\"heartRate\":%s,\"spo2\":%s,\"temperature\":%s,\"ambientTemp\":%s,\"activity\":\"%s\","
    "\"fingerDetected\":%s,\"heartRateValid\":%s,\"spo2Valid\":%s,\"temperatureValid\":%s,"
    "\"temperatureMeasuring\":%s,\"motionValid\":%s,\"poorSignal\":%s,\"fallDetected\":%s,\"battery\":%s,"
    "\"debug\":{\"red\":%lu,\"ir\":%lu,\"q\":%.3f,\"ambient\":%.2f,\"object\":%.2f,"
    "\"ax\":%.2f,\"ay\":%.2f,\"az\":%.2f,\"gx\":%.1f,\"gy\":%.1f,\"gz\":%.1f,\"am\":%.2f}}",
    DEVICE_NAME, hr, o2, temp, ambient, activityStatus.c_str(),
    fingerDetected ? "true" : "false", heartRateValid ? "true" : "false",
    spo2Valid ? "true" : "false", temperatureValid ? "true" : "false",
    temperatureSampleCount > 0 && !temperatureValid ? "true" : "false",
    motionValid ? "true" : "false", poorSignal ? "true" : "false",
    fallDetected ? "true" : "false", battery,
    (unsigned long)rawRed, (unsigned long)rawIR, ppgQuality,
    liveAmbientTemperature, rawObjectTemperature,
    accelX, accelY, accelZ, gyroX, gyroY, gyroZ, accelMagnitude);
#else
  int length = snprintf(jsonBuffer, sizeof(jsonBuffer),
    "{\"protocol\":2,\"deviceId\":\"%s\",\"sensorModel\":\"MLX90614_IR_OBJECT\",\"heartRate\":%s,\"spo2\":%s,\"temperature\":%s,\"ambientTemp\":%s,\"activity\":\"%s\","
    "\"fingerDetected\":%s,\"heartRateValid\":%s,\"spo2Valid\":%s,\"temperatureValid\":%s,"
    "\"temperatureMeasuring\":%s,\"motionValid\":%s,\"poorSignal\":%s,\"fallDetected\":%s,\"battery\":%s}"
    , DEVICE_NAME, hr, o2, temp, ambient, activityStatus.c_str(),
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
    delay(20); // Space notifications so a small phone BLE receive queue can keep up.
  }

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
    Serial.printf("[SENSORS] MAX30102=%s IR=%lu RED=%lu contact=%d signal=%d HR=%s SpO2=%s | MLX90614=%s object=%.2fC valid=%d\n",
      max30102Present ? "present" : "missing", (unsigned long)rawIR,
      (unsigned long)rawRed, fingerDetected, !poorSignal,
      heartRateValid ? "valid" : "--", spo2Valid ? "valid" : "--",
      mlx90614Present ? "present" : "missing", rawObjectTemperature,
      temperatureValid);
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
