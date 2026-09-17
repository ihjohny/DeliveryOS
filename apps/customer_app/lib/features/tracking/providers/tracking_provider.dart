import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../location/providers/location_provider.dart';
import '../domain/tracking_models.dart';

class TrackingNotifier extends Notifier<OrderTrackingState> {
  final String orderId;
  TrackingNotifier(this.orderId);

  Timer? _telemetryTimer;
  double _routeProgress = 0.2;

  @override
  OrderTrackingState build() {
    final customerLocation = ref.read(locationProvider).location;
    final initialState = OrderTrackingState(
      orderId: orderId,
      orderNumber: '#ORD-${orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId}',
      stage: OrderStage.dispatched,
      store: StoreMeta.defaultSultansDine(),
      rider: RiderMeta.pilotRider(),
      customer: CustomerMeta(
        address: customerLocation.addressLine,
        phone: '+8801700000005',
        latitude: customerLocation.latitude,
        longitude: customerLocation.longitude,
      ),
      estimatedMinutesRemaining: 15,
      itemsCount: 2,
      totalAmount: 480.0,
    );

    ref.onDispose(() {
      _telemetryTimer?.cancel();
    });

    _startTelemetrySimulation();
    return initialState;
  }

  void stopSimulation() {
    _telemetryTimer?.cancel();
  }

  void _startTelemetrySimulation() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (state.stage != OrderStage.dispatched) return;

      _routeProgress += 0.08;
      if (_routeProgress > 1.0) {
        _routeProgress = 1.0;
        state = state.copyWith(
          stage: OrderStage.delivered,
          estimatedMinutesRemaining: 0,
        );
        _telemetryTimer?.cancel();
        return;
      }

      // Smooth interpolation from store coordinates to customer coordinates
      final store = state.store;
      final customer = state.customer;
      final newLat = store.latitude + (customer.latitude - store.latitude) * _routeProgress;
      final newLng = store.longitude + (customer.longitude - store.longitude) * _routeProgress;
      final minsRemaining = ((1.0 - _routeProgress) * 15).round().clamp(1, 15);

      final updatedRider = state.rider?.copyWith(
        latitude: newLat,
        longitude: newLng,
        speed: 26.0 + (_routeProgress * 5),
      );

      state = state.copyWith(
        rider: updatedRider,
        estimatedMinutesRemaining: minsRemaining,
      );
    });
  }

  void setStage(OrderStage newStage) {
    state = state.copyWith(stage: newStage);
  }

  Future<void> refreshDetails() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('${ApiConstants.orderDetails}/${state.orderId}');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final statusStr = data['status'] as String? ?? 'DISPATCHED';
        state = state.copyWith(stage: OrderStageExtension.fromString(statusStr));
      }
    } catch (_) {}
  }
}

final trackingProvider =
    NotifierProvider.family<TrackingNotifier, OrderTrackingState, String>(
  (orderId) => TrackingNotifier(orderId),
);
