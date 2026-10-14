import 'package:doodledry/core/services/local_storage_service.dart';
import 'package:doodledry/features/diagnostics/presentation/screens/diagnostics_screen.dart';
import 'package:doodledry/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('DiagnosticsScreen displays all subsystem health statuses', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(localStorage),
        ],
        child: const MaterialApp(
          home: DiagnosticsScreen(),
        ),
      ),
    );

    expect(find.text('System Diagnostics'), findsOneWidget);
    expect(find.text('HARDWARE & SUBSYSTEM HEALTH'), findsOneWidget);
    expect(find.text('Bluetooth Adapter'), findsOneWidget);
    expect(find.text('Heart Rate Optical Sensor'), findsOneWidget);
    expect(find.text('SpO₂ Pulse Oximeter Sensor'), findsOneWidget);
    expect(find.text('MLX90614 Object Temperature'), findsOneWidget);
    expect(find.text('3-Axis Motion / IMU Sensor'), findsOneWidget);
    expect(find.text('Cloud Database Sync'), findsOneWidget);
    expect(find.text('LAST DATA PACKET RECEIVED'), findsOneWidget);
  });
}
