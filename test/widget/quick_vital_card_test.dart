import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/features/dashboard/presentation/widgets/quick_vital_card.dart';
import 'package:doodledry/shared/models/sensor_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('QuickVitalCard renders label, value, unit, and status correctly', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickVitalCard(
            label: 'Heart Rate',
            value: '128',
            unit: 'BPM',
            statusText: 'Status: Active',
            icon: Icons.favorite,
            accentColor: AppColors.heartRate,
            bgColor: AppColors.heartRateBg,
            sensorState: SensorState.active,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('HEART RATE'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('BPM'), findsOneWidget);
    expect(find.text('Status: Active'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tap(find.byType(QuickVitalCard));
    expect(tapped, isTrue);
  });
}
