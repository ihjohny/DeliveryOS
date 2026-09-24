import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/core/localization/app_localizations.dart';
import 'package:customer_app/core/localization/language_provider.dart';
import 'package:customer_app/core/storage/local_storage.dart';
import 'package:customer_app/core/utils/phone_call_launcher.dart';
import 'package:customer_app/features/auth/providers/auth_provider.dart';
import 'package:customer_app/features/cart/providers/cart_provider.dart';
import 'package:customer_app/features/orders/domain/order_history_model.dart';
import 'mock_dio_client.dart';
import 'package:customer_app/features/orders/presentation/order_history_screen.dart';
import 'package:customer_app/features/orders/providers/order_history_provider.dart';
import 'package:customer_app/features/tracking/domain/tracking_models.dart';
import 'package:customer_app/features/tracking/presentation/order_tracking_screen.dart';
import 'package:customer_app/features/tracking/presentation/widgets/order_stepper_widget.dart';
import 'package:customer_app/features/tracking/presentation/widgets/tracking_map_view.dart';
import 'package:customer_app/features/tracking/providers/tracking_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = LocalStorage(prefs);
  });

  Widget createTestWidget({required Widget child, ProviderContainer? container}) {
    return UncontrolledProviderScope(
      container: container ??
          ProviderContainer(
            overrides: [
              localStorageProvider.overrideWithValue(storage),
            ],
          ),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: child,
      ),
    );
  }

  group('Task 5.4 - Domain & Unit Logic Tests', () {
    test('OrderStage contains sequential stages with proper metadata', () {
      expect(OrderStage.placed.title, 'Order Placed');
      expect(OrderStage.dispatched.title, 'Courier on the Way');
      expect(OrderStage.delivered.title, 'Order Delivered');

      expect(OrderStageExtension.fromString('PREPARING'), OrderStage.preparing);
      expect(OrderStageExtension.fromString('READY_FOR_PICKUP'), OrderStage.readyForPickup);
      expect(OrderStageExtension.fromString('DISPATCHED'), OrderStage.dispatched);
      expect(OrderStageExtension.fromString('UNKNOWN_STATUS'), OrderStage.placed);
    });

    test('OrderTrackingState calculates progression and delivery status accurately', () {
      final state = OrderTrackingState(
        orderId: 'test-order-1',
        orderNumber: '#ORD-1234',
        stage: OrderStage.dispatched,
        store: StoreMeta(
          id: 's-1',
          name: "Sultan's Dine",
          phone: '+8801711223344',
          latitude: 23.7925,
          longitude: 90.4078,
          address: 'Gulshan 2, Dhaka',
        ),
        rider: RiderMeta(
          id: 'r-1',
          name: 'Rakib Hasan',
          phone: '+8801811223344',
          vehicleType: 'Motorbike',
          rating: 4.85,
          latitude: 23.795,
          longitude: 90.410,
          speed: 28.5,
        ),
        customer: CustomerMeta(
          address: 'Gulshan 1, Dhaka',
          phone: '+8801711000000',
          latitude: 23.798,
          longitude: 90.415,
        ),
        estimatedMinutesRemaining: 12,
      );

      expect(state.isCompleted, isFalse);
      expect(state.isStageCompleted(OrderStage.placed), isTrue);
      expect(state.isStageCompleted(OrderStage.preparing), isTrue);
      expect(state.isStageActive(OrderStage.dispatched), isTrue);
      expect(state.isStageActive(OrderStage.delivered), isFalse);

      final completedState = state.copyWith(stage: OrderStage.delivered, estimatedMinutesRemaining: 0);
      expect(completedState.isCompleted, isTrue);
      expect(completedState.isStageCompleted(OrderStage.dispatched), isTrue);
      expect(completedState.isStageActive(OrderStage.delivered), isTrue);
    });

    test('Direct phone dialer cleanPhone extracts digits and handles international format', () {
      final clean = cleanPhoneNumber('+880 1711-223344');
      expect(clean, '+8801711223344');

      final cleanLocal = cleanPhoneNumber('01711 223 344');
      expect(cleanLocal, '01711223344');
    });

    test('ReorderValidationResult parses operational and stock availability correctly', () {
      final json = {
        'isStoreOperational': true,
        'hasStockChanges': false,
        'validItems': [
          {
            'productId': 'prod-1',
            'productName': 'Kacchi Biryani',
            'unitPrice': 420.0,
            'quantity': 2,
            'totalPrice': 840.0,
          }
        ],
        'unavailableItems': <Map<String, dynamic>>[],
      };

      final result = ReorderValidationResult.fromJson(json);
      expect(result.isStoreOperational, isTrue);
      expect(result.hasStockChanges, isFalse);
      expect(result.validItems.length, 1);
      expect(result.unavailableItems, isEmpty);
    });

    test('TrackingNotifier initializes with active telemetry state', () {
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      final notifier = container.read(trackingProvider('test-ord-123').notifier);
      final state = container.read(trackingProvider('test-ord-123'));
      expect(state.orderId, 'test-ord-123');
      expect(state.stage, OrderStage.dispatched);
      expect(state.store.name, contains("Sultan's Dine"));
      expect(state.rider, isNotNull);
      expect(state.rider!.name, 'Tanvir Hossain');
      expect(state.estimatedMinutesRemaining, 15);
      notifier.stopSimulation();
    });

    test('Re-order validation repopulates cart provider successfully', () async {
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          dioClientProvider.overrideWithValue(createTestMockDioClient()),
        ],
      );

      final orderNotifier = container.read(orderHistoryProvider.notifier);
      final sampleOrder = PastOrder(
        id: 'ord-hist-1',
        orderNumber: '#ORD-9988',
        vendorId: 'b8b33bf6-6b22-4bb3-9d41-e9fb94c25601',
        vendorName: "Sultan's Dine - Banani",
        status: 'DELIVERED',
        totalAmount: 420.0,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        items: [
          OrderItemSummary(
            productId: 'prod-kacchi',
            name: 'Kacchi Biryani',
            unitPrice: 420.0,
            quantity: 1,
          ),
        ],
      );

      // Execute re-order workflow
      final result = await orderNotifier.validateAndReorder(sampleOrder);
      expect(result.isStoreOperational, isTrue);

      final cart = container.read(cartProvider);
      expect(cart.vendorId, 'b8b33bf6-6b22-4bb3-9d41-e9fb94c25601');
      expect(cart.vendorName, "Sultan's Dine - Banani");
      expect(cart.items.length, 1);
      expect(cart.items.first.product.id, 'prod-kacchi');
      expect(cart.items.first.quantity, 1);
      expect(cart.grossSubtotal, 420.0);
    });
  });

  group('Task 5.4 - UI & Widget Tests', () {
    testWidgets('OrderStepperWidget renders active stage title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(
            body: OrderStepperWidget(currentStage: OrderStage.readyForPickup),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ready for Pickup'), findsWidgets);
      expect(find.text('Order packed and waiting for courier pickup'), findsOneWidget);
    });

    testWidgets('TrackingMapView renders canvas and elements', (tester) async {
      final state = OrderTrackingState(
        orderId: 'ord-123',
        orderNumber: '#ORD-123',
        stage: OrderStage.dispatched,
        store: StoreMeta.defaultSultansDine(),
        rider: RiderMeta.pilotRider(),
        customer: CustomerMeta.defaultCustomer(),
      );

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: SizedBox(
              height: 300,
              width: 400,
              child: TrackingMapView(state: state),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text("Sultan's Dine"), findsOneWidget);
    });

    testWidgets('OrderTrackingScreen displays ETA, Call Rider and Call Store buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createTestWidget(
          container: container,
          child: const OrderTrackingScreen(
            orderId: 'mock-order-uuid',
            orderNumber: '#ORD-7744',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Order Tracking'), findsOneWidget);
      expect(find.text('#ORD-7744'), findsOneWidget);
      expect(find.text('Call Rider'), findsOneWidget);
      expect(find.text('Call Store'), findsOneWidget);
      expect(find.textContaining('mins'), findsWidgets);

      container.read(trackingProvider('mock-order-uuid').notifier).stopSimulation();
    });

    testWidgets('OrderHistoryScreen renders past orders and reorder button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const OrderHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Orders'), findsOneWidget);
      expect(find.textContaining("Sultan's Dine"), findsWidgets);
      expect(find.text('Re-order'), findsWidgets);
      expect(find.text('Track Order'), findsWidgets);
    });
  });
}
