import 'dart:async';
import '../../../../shared/models/baby_sensor_data.dart';
import '../models/vital_history_entry.dart';

enum HistoryTimeframe {
  day,
  week,
  month;

  String get displayName {
    switch (this) {
      case HistoryTimeframe.day:
        return 'Today';
      case HistoryTimeframe.week:
        return '7 Days';
      case HistoryTimeframe.month:
        return '30 Days';
    }
  }
}

/// Repository managing rolling live buffers and historical analytics
class HistoryRepository {
  final List<VitalHistoryEntry> _liveBuffer = [];
  final List<VitalHistoryEntry> _historicalRecords = [];
  DateTime _lastSampleTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _throttleInterval = Duration(seconds: 4);

  final StreamController<List<VitalHistoryEntry>> _liveBufferStreamController =
      StreamController<List<VitalHistoryEntry>>.broadcast();

  HistoryRepository();

  Stream<List<VitalHistoryEntry>> get liveBufferStream => _liveBufferStreamController.stream;
  List<VitalHistoryEntry> get liveBuffer => List.unmodifiable(_liveBuffer);

  /// Ingest real-time data point with throttling
  void recordDataPoint(BabySensorData data) {
    if (!data.isDeviceConnected) return;
    if (data.heartRate == null && data.spo2 == null && data.temperature == null && data.motionValid != true) return;

    final now = DateTime.now();
    if (now.difference(_lastSampleTime) < _throttleInterval) {
      return;
    }
    _lastSampleTime = now;

    final entry = VitalHistoryEntry(
      timestamp: now,
      heartRate: data.heartRate,
      spo2: data.spo2,
      temperature: data.temperature,
      activityStatus: data.motionValid == true ? data.activityStatus ?? 'unknown' : 'unknown',
      isSimulation: data.isSimulation,
    );

    _liveBuffer.add(entry);
    _historicalRecords.add(entry);
    if (_liveBuffer.length > 40) {
      _liveBuffer.removeAt(0);
    }
    _liveBufferStreamController.add(List.from(_liveBuffer));
  }

  /// Get historical records filtered by timeframe
  List<VitalHistoryEntry> getHistory(HistoryTimeframe timeframe) {
    final now = DateTime.now();
    Duration cutoff;
    switch (timeframe) {
      case HistoryTimeframe.day:
        cutoff = const Duration(hours: 24);
        break;
      case HistoryTimeframe.week:
        cutoff = const Duration(days: 7);
        break;
      case HistoryTimeframe.month:
        cutoff = const Duration(days: 30);
        break;
    }

    final start = now.subtract(cutoff);
    return _historicalRecords.where((e) => e.timestamp.isAfter(start)).toList();
  }

  /// Summary statistics for a timeframe
  Map<String, double> getAverages(HistoryTimeframe timeframe) {
    final entries = getHistory(timeframe);
    final hrs = entries.map((e) => e.heartRate).whereType<double>().toList();
    final oxygen = entries.map((e) => e.spo2).whereType<double>().toList();
    final temps = entries.map((e) => e.temperature).whereType<double>().toList();
    return {
      if (hrs.isNotEmpty) 'avgHr': hrs.reduce((a, b) => a + b) / hrs.length,
      if (oxygen.isNotEmpty) 'avgSpo2': oxygen.reduce((a, b) => a + b) / oxygen.length,
      if (temps.isNotEmpty) 'avgTemp': temps.reduce((a, b) => a + b) / temps.length,
    };
  }

  /// Activity distribution breakdown (% sleeping, awake, active, restless)
  Map<String, double> getActivityDistribution(HistoryTimeframe timeframe) {
    final entries = getHistory(timeframe);
    int still = 0, moving = 0, active = 0;
    for (final e in entries) {
      switch (e.activityStatus.toLowerCase()) {
        case 'sleeping':
        case 'still':
          still++;
          break;
        case 'awake':
        case 'moving':
          moving++;
          break;
        case 'active':
        case 'restless':
          active++;
          break;
        default:
          break;
      }
    }
    final total = still + moving + active;
    if (total == 0) return {};
    return {
      'still': (still / total) * 100,
      'moving': (moving / total) * 100,
      'active': (active / total) * 100,
    };
  }

  void dispose() {
    _liveBufferStreamController.close();
  }
}
