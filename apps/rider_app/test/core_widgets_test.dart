import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/utils/currency_formatter.dart';
import 'package:rider_app/core/widgets/empty_state_view.dart';
import 'package:rider_app/core/widgets/metric_tile.dart';
import 'package:rider_app/features/auth/domain/auth_models.dart';
import 'package:rider_app/features/auth/presentation/widgets/vehicle_type_selector.dart';
import 'package:rider_app/features/earnings/presentation/widgets/earnings_timeframe_selector.dart';
import 'package:rider_app/features/trips/domain/trip_models.dart';
import 'package:rider_app/features/trips/presentation/widgets/trip_timeline_header.dart';

void main() {
  group('Core Utilities & Widgets Tests', () {
    test('formatCurrency formats BDT currency correctly', () {
      expect(formatCurrency(0), '৳0');
      expect(formatCurrency(500), '৳500');
      expect(formatCurrency(1250.75, decimalDigits: 2), '৳1250.75');
    });

    testWidgets('EmptyStateView renders title, message, and optional action', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.inbox,
              title: 'Empty Inbox',
              message: 'No messages found',
              action: ElevatedButton(
                onPressed: () => actionTriggered = true,
                child: const Text('Refresh'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Empty Inbox'), findsOneWidget);
      expect(find.text('No messages found'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('MetricTile displays title, value, icon, and triggers onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricTile(
              title: 'Today Earnings',
              value: '৳1500',
              icon: Icons.payments,
              iconColor: Colors.green,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Today Earnings'), findsOneWidget);
      expect(find.text('৳1500'), findsOneWidget);
      expect(find.byIcon(Icons.payments), findsOneWidget);

      await tester.tap(find.text('Today Earnings'));
      expect(tapped, isTrue);
    });

    testWidgets('VehicleTypeSelector switches vehicle types correctly', (tester) async {
      VehicleType selected = VehicleType.motorcycle;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: VehicleTypeSelector(
                  selectedVehicle: selected,
                  onVehicleSelected: (v) => setState(() => selected = v),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Motorcycle'), findsOneWidget);
      expect(find.text('Bicycle'), findsOneWidget);
      expect(find.text('Car'), findsOneWidget);

      await tester.tap(find.text('Bicycle'));
      await tester.pump();
      expect(selected, VehicleType.bicycle);

      await tester.tap(find.text('Car'));
      await tester.pump();
      expect(selected, VehicleType.car);
    });

    testWidgets('EarningsTimeframeSelector toggles timeframe', (tester) async {
      EarningsTimeframe timeframe = EarningsTimeframe.today;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: EarningsTimeframeSelector(
                  selectedTimeframe: timeframe,
                  onTimeframeChanged: (tf) => setState(() => timeframe = tf),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);

      await tester.tap(find.text('This Week'));
      await tester.pump();
      expect(timeframe, EarningsTimeframe.week);
    });

    testWidgets('TripTimelineHeader shows active and completed pills for current step', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TripTimelineHeader(currentStep: TripStep.delivering),
          ),
        ),
      );

      expect(find.text('Pick Up'), findsOneWidget);
      expect(find.text('Deliver'), findsOneWidget);
      expect(find.text('Handover'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget); // Step 1 is completed
    });
  });
}
