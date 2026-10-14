import 'package:doodledry/features/history/data/repositories/history_repository.dart';
import 'package:doodledry/shared/models/baby_sensor_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history starts empty and never fills missing vitals', () {
    final repository = HistoryRepository();
    expect(repository.getHistory(HistoryTimeframe.month), isEmpty);
    expect(repository.getAverages(HistoryTimeframe.month), isEmpty);

    repository.recordDataPoint(BabySensorData(
      deviceId: 'DOODLEDRY-001', babyId: 'baby',
      temperature: 36.4, temperatureValid: true,
      timestamp: DateTime.now(), isDeviceConnected: true,
    ));

    final records = repository.getHistory(HistoryTimeframe.day);
    expect(records, hasLength(1));
    expect(records.single.heartRate, isNull);
    expect(records.single.spo2, isNull);
    expect(records.single.temperature, 36.4);
    expect(repository.getAverages(HistoryTimeframe.day).keys, {'avgTemp'});
    repository.dispose();
  });
}
