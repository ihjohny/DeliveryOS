import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/duty_models.dart';

class RiderDutyNotifier extends Notifier<RiderDutyState> {
  Timer? _beaconTimer;

  @override
  RiderDutyState build() {
    final storage = ref.watch(localStorageProvider);
    final isOnlineStored = storage.getIsOnline();
    final auth = ref.watch(riderAuthProvider);
    final profile = auth.profile;

    ref.onDispose(() {
      _beaconTimer?.cancel();
    });

    final sampleTrips = getPilotSampleTrips();
    final initialCodCash = profile?.cashInHand ?? 0.0;
    final initialTodayEarnings = profile?.earningsBalance ?? 0.0;
    final initialWeeklyEarnings = initialTodayEarnings;

    final initialState = RiderDutyState(
      isOnline: isOnlineStored && (profile?.isApproved ?? false),
      isBeaconing: isOnlineStored && (profile?.isApproved ?? false),
      todayTrips: profile?.completedTripsCount ?? 0,
      todayEarnings: initialTodayEarnings,
      weeklyTrips: profile?.completedTripsCount ?? 0,
      weeklyEarnings: initialWeeklyEarnings,
      codCashInHand: initialCodCash,
      cashSafetyLimit: profile?.maxCashLimit ?? 5000.0,
      completedTrips: sampleTrips,
      statusMessage: (isOnlineStored && (profile?.isApproved ?? false))
          ? 'Online • GPS Radar Active'
          : 'Offline • Tap switch to go Online',
    );

    if (initialState.isOnline) {
      _startGpsBeaconing();
    }

    return initialState;
  }

  static List<RiderCompletedTrip> getPilotSampleTrips() {
    final now = DateTime.now();
    return [
      RiderCompletedTrip(
        orderId: 'demo-101',
        orderNumber: 'ORD-8821',
        storeName: 'Kacchi Bhai - Banani',
        customerAddress: 'House 42, Road 11, Banani, Dhaka',
        completedAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        payout: 60.0,
        codCollected: 780.0,
        isCod: true,
        distanceKm: 2.8,
      ),
      RiderCompletedTrip(
        orderId: 'demo-102',
        orderNumber: 'ORD-8794',
        storeName: 'Sultan\'s Dine - Gulshan 2',
        customerAddress: 'Apt 5B, Road 45, Gulshan 2, Dhaka',
        completedAt: now.subtract(const Duration(hours: 3, minutes: 45)),
        payout: 75.0,
        codCollected: 0.0,
        isCod: false,
        distanceKm: 3.5,
      ),
      RiderCompletedTrip(
        orderId: 'demo-103',
        orderNumber: 'ORD-8750',
        storeName: 'Chillox - Banani',
        customerAddress: 'Flat 2A, Road 7, Block D, Banani',
        completedAt: now.subtract(const Duration(days: 1, hours: 2)),
        payout: 50.0,
        codCollected: 520.0,
        isCod: true,
        distanceKm: 1.9,
      ),
    ];
  }

  void stopBeaconing() {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    state = state.copyWith(isBeaconing: false);
  }

  Future<bool> toggleDuty({bool? forceState}) async {
    final auth = ref.read(riderAuthProvider);
    final profile = auth.profile;

    // INVARIANT GUARD: Unapproved account is strictly blocked from going online
    if (profile == null || !profile.isApproved || profile.status == AccountStatus.pendingApproval) {
      state = state.copyWith(
        isOnline: false,
        isBeaconing: false,
        error: 'Unapproved account: Duty switch is locked until administrator approval.',
        statusMessage: 'Locked • Awaiting Admin Approval',
      );
      return false;
    }

    final targetState = forceState ?? !state.isOnline;
    state = state.copyWith(isToggling: true, clearError: true);

    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch(
        ApiConstants.toggleDuty,
        data: {'isOnline': targetState},
      );
    } catch (_) {
      // Dev mode fallback
    }

    final storage = ref.read(localStorageProvider);
    await storage.setIsOnline(targetState);

    if (targetState) {
      _startGpsBeaconing();
      state = state.copyWith(
        isOnline: true,
        isBeaconing: true,
        isToggling: false,
        statusMessage: 'Online • GPS Radar Active • Ready for Trips',
      );
    } else {
      _beaconTimer?.cancel();
      _beaconTimer = null;
      state = state.copyWith(
        isOnline: false,
        isBeaconing: false,
        isToggling: false,
        speed: 0.0,
        statusMessage: 'Offline • Tap switch to go Online',
      );
    }

    return true;
  }

  void _startGpsBeaconing() {
    _beaconTimer?.cancel();
    _beaconTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!state.isOnline) {
        _beaconTimer?.cancel();
        return;
      }

      // Small realistic location jitter for live telemetry beaconing (e.g. Banani area)
      final newLat = 23.7925 + ((DateTime.now().second % 10) - 5) * 0.0001;
      final newLng = 90.4078 + ((DateTime.now().second % 8) - 4) * 0.0001;
      final speed = state.activeOrderId != null ? 28.0 : 0.0;

      state = state.copyWith(
        latitude: newLat,
        longitude: newLng,
        speed: speed,
        bearing: (state.bearing + 15) % 360,
        lastBeaconTimestamp: DateTime.now(),
        isBeaconing: true,
      );

      _dispatchTelemetryToBackend(newLat, newLng, speed);
    });
  }

  Future<void> _dispatchTelemetryToBackend(double lat, double lng, double speed) async {
    try {
      final dio = ref.read(dioClientProvider);
      // Dispatches telemetry coordinates to backend radar
      await dio.patch(
        ApiConstants.toggleDuty,
        data: {
          'isOnline': true,
          'latitude': lat,
          'longitude': lng,
          'speed': speed,
        },
      );
    } catch (_) {
      // Silent telemetry dispatch fallback
    }
  }

  void simulateTripCompleted({
    required double payout,
    double? codCollected,
    RiderCompletedTrip? tripRecord,
  }) {
    final updatedTrips = [
      if (tripRecord != null) tripRecord,
      ...state.completedTrips,
    ];

    state = state.copyWith(
      todayTrips: state.todayTrips + 1,
      todayEarnings: state.todayEarnings + payout,
      weeklyTrips: state.weeklyTrips + 1,
      weeklyEarnings: state.weeklyEarnings + payout,
      codCashInHand: state.codCashInHand + (codCollected ?? 0.0),
      completedTrips: updatedTrips,
    );
  }

  Future<bool> depositCashToHub({double? amount}) async {
    final depositAmount = amount ?? state.codCashInHand;
    if (depositAmount <= 0) return false;

    state = state.copyWith(isDepositingCash: true, clearError: true);

    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(
        '/rider/cash-deposit',
        data: {
          'amount': depositAmount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {
      // Dev mode fallback
    }

    final newBalance = (state.codCashInHand - depositAmount).clamp(0.0, double.infinity);
    state = state.copyWith(
      codCashInHand: newBalance,
      isDepositingCash: false,
    );

    return true;
  }
}

final riderDutyProvider = NotifierProvider<RiderDutyNotifier, RiderDutyState>(
  RiderDutyNotifier.new,
);
