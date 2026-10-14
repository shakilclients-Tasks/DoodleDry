import 'package:doodledry/app.dart';
import 'package:doodledry/core/services/local_storage_service.dart';
import 'package:doodledry/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('DoodledryApp loads SplashScreen and transitions to Dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'doodledry_onboarding_done': true});
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(localStorage),
        ],
        child: const DoodledryApp(),
      ),
    );

    // Initial frame verification on splash
    expect(find.text('DOODLEDRY'), findsOneWidget);
    expect(find.text('Smart Baby Monitoring System'), findsOneWidget);

    // Pump past splash timer duration
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 200));

    // Verifies navigation to Main Dashboard
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('REAL-TIME VITALS'), findsOneWidget);
  });
}
