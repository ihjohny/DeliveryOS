import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/socket_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../location/providers/location_provider.dart';
import '../domain/tracking_models.dart';

class TrackingNotifier extends Notifier<OrderTrackingState> {
  final String orderId;
  TrackingNotifier(this.orderId);

  Timer? _telemetryTimer;

  @override
  OrderTrackingState build() {
    final customerLocation = ref.read(locationProvider).location;
    final socket = ref.watch(socketServiceProvider);

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
      itemsCount: 1,
      totalAmount: 350.0,
    );

    // 1. Join real-time WebSocket dynamic order room
    socket.joinOrder(orderId);

    // 2. Listen to order:status:changed from backend
    void handleStatusChanged(dynamic payload) {
      if (payload is Map<String, dynamic>) {
        final data = payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : payload;
        final newStatusStr = data['newStatus'] as String? ?? '';
        final newStage = OrderStageExtension.fromString(newStatusStr);

        RiderMeta? updatedRider = state.rider;
        if (data['riderName'] != null) {
          updatedRider = RiderMeta(
            id: data['riderId'] as String? ?? 'rider-01',
            name: data['riderName'] as String,
            phone: data['riderPhone'] as String? ?? '+8801700000002',
            vehicleType: 'Dhaka Metro HA-11-2233',
            rating: 4.9,
            latitude: state.store.latitude,
            longitude: state.store.longitude,
            speed: 0.0,
          );
        }

        state = state.copyWith(
          stage: newStage,
          rider: updatedRider,
        );
      }
    }

    // 3. Listen to order:rider:moved from backend telemetry stream
    void handleRiderMoved(dynamic payload) {
      if (payload is Map<String, dynamic>) {
        final data = payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : payload;
        final loc = data['riderLocation'] as Map<String, dynamic>? ?? {};
        final lat = (loc['latitude'] as num?)?.toDouble();
        final lng = (loc['longitude'] as num?)?.toDouble();
        final bearing = (loc['bearing'] as num?)?.toDouble() ?? 0.0;
        final eta = (data['estimatedMinutesRemaining'] as num?)?.toInt();

        if (lat != null && lng != null) {
          final currentRider = state.rider ?? RiderMeta.pilotRider();
          state = state.copyWith(
            rider: currentRider.copyWith(
              latitude: lat,
              longitude: lng,
              bearing: bearing,
            ),
            estimatedMinutesRemaining: eta ?? state.estimatedMinutesRemaining,
          );
        }
      }
    }

    socket.on('order:status:changed', handleStatusChanged);
    socket.on('order:status_changed', handleStatusChanged);
    socket.on('order:rider:moved', handleRiderMoved);

    ref.onDispose(() {
      socket.leaveOrder(orderId);
      socket.off('order:status:changed');
      socket.off('order:status_changed');
      socket.off('order:rider:moved');
      _telemetryTimer?.cancel();
    });

    // Initial background fetch to populate authoritative store and items
    Future.microtask(() => refreshDetails());

    return initialState;
  }

  void stopSimulation() {
    _telemetryTimer?.cancel();
  }

  void setStage(OrderStage newStage) {
    state = state.copyWith(stage: newStage);
  }

  Future<void> refreshDetails() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('${ApiConstants.orderDetails}/$orderId');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final statusStr = data['status'] as String? ?? 'PLACED';
        final vendor = data['vendor'] as Map<String, dynamic>? ?? {};
        final items = (data['orderItems'] as List<dynamic>?) ?? [];

        final storeMeta = StoreMeta(
          id: vendor['id'] as String? ?? state.store.id,
          name: vendor['name'] as String? ?? state.store.name,
          address: vendor['addressText'] as String? ?? state.store.address,
          phone: vendor['phone'] as String? ?? state.store.phone,
          latitude: (vendor['latitude'] as num?)?.toDouble() ?? state.store.latitude,
          longitude: (vendor['longitude'] as num?)?.toDouble() ?? state.store.longitude,
        );

        final riderData = data['rider'] as Map<String, dynamic>?;
        RiderMeta? riderMeta;
        if (riderData != null) {
          final user = riderData['user'] as Map<String, dynamic>? ?? {};
          riderMeta = RiderMeta(
            id: riderData['id'] as String? ?? 'rider-01',
            name: user['fullName'] as String? ?? 'Delivery Courier',
            phone: user['phone'] as String? ?? '+8801700000002',
            vehicleType: 'Dhaka Metro HA-11-2233',
            rating: 4.9,
            latitude: storeMeta.latitude,
            longitude: storeMeta.longitude,
            speed: 0.0,
          );
        }

        state = state.copyWith(
          orderNumber: data['orderNumber'] as String? ?? state.orderNumber,
          stage: OrderStageExtension.fromString(statusStr),
          store: storeMeta,
          rider: riderMeta ?? state.rider,
          itemsCount: items.isNotEmpty ? items.length : state.itemsCount,
          totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? state.totalAmount,
        );
      }
    } catch (e) {
      debugPrint('Error refreshing order tracking details: $e');
    }
  }
}

final trackingProvider =
    NotifierProvider.family<TrackingNotifier, OrderTrackingState, String>(
  (orderId) => TrackingNotifier(orderId),
);
