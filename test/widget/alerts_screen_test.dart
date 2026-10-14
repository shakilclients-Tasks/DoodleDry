import 'package:doodledry/core/services/local_storage_service.dart';
import 'package:doodledry/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:doodledry/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('AlertsScreen renders filter chips and alert list items', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(localStorage),
        ],
        child: const MaterialApp(
          home: AlertsScreen(),
        ),
      ),
    );

    expect(find.text('Safety Alerts'), findsOneWidget);
    expect(find.textContaining('All ('), findsOneWidget);
    expect(find.textContaining('Critical ('), findsOneWidget);
    expect(find.textContaining('Warnings ('), findsOneWidget);
    expect(find.textContaining('Info ('), findsOneWidget);
  });
}
