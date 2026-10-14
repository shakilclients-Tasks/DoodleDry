import 'package:doodledry/core/ble/ble_config.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('firmware short UUIDs match the app GATT UUIDs', () {
    expect(Guid('FFF0'), Guid(BleConfig.serviceUuid));
    expect(Guid('FFF1'), Guid(BleConfig.sensorCharacteristicUuid));
    expect(Guid('FFF2'), Guid(BleConfig.commandCharacteristicUuid));

    // Comparing toString() to a full UUID would reject this valid service.
    expect(Guid(BleConfig.serviceUuid).toString(), 'fff0');
  });
}
