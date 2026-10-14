import 'package:doodledry/core/services/local_storage_service.dart';
import 'package:doodledry/features/settings/presentation/providers/settings_provider.dart';
import 'package:doodledry/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SettingsScreen displays preference switches and hardware links',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(localStorage),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    expect(find.text('Profile & Settings'), findsOneWidget);
    expect(find.text('PREFERENCES & UNITS'), findsOneWidget);
    expect(find.text('Temperature Unit'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Notifications & Alerts'), findsOneWidget);
    expect(find.text('Cloud Database Sync'), findsOneWidget);
    expect(find.text('Monitoring Thresholds'), findsOneWidget);
    expect(find.text('Hardware Simulation Mode'), findsNothing);
    expect(find.text('Connected Wearable Device'), findsOneWidget);
  });
}
