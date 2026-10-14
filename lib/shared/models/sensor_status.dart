/// Status state for an individual hardware sensor
enum SensorState {
  active,
  measuring,
  poorSignal,
  noData,
  error;

  String get displayName {
    switch (this) {
      case SensorState.active:
        return 'Active';
      case SensorState.measuring:
        return 'Measuring...';
      case SensorState.poorSignal:
        return 'Adjust Finger';
      case SensorState.noData:
        return 'No Data';
      case SensorState.error:
        return 'Sensor Error';
    }
  }
}

/// Quality status classification for incoming sensor data
enum SensorDataQuality {
  valid,
  invalid,
  missing,
  stale,
  sensorError;

  String get displayName {
    switch (this) {
      case SensorDataQuality.valid:
        return 'Valid Data';
      case SensorDataQuality.invalid:
        return 'Questionable / Invalid';
      case SensorDataQuality.missing:
        return 'No Reading';
      case SensorDataQuality.stale:
        return 'Stale Data';
      case SensorDataQuality.sensorError:
        return 'Hardware Fault';
    }
  }
}
