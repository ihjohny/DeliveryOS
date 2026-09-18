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

    final initialState = RiderDutyState(
      isOnline: isOnlineStored && (profile?.isApproved ?? false),
      isBeaconing: isOnlineStored && (profile?.isApproved ?? false),
      todayTrips: profile?.completedTripsCount ?? 0,
      todayEarnings: profile?.earningsBalance ?? 0.0,
      codCashInHand: profile?.cashInHand ?? 0.0,
      cashSafetyLimit: profile?.maxCashLimit ?? 5000.0,
      statusMessage: (isOnlineStored && (profile?.isApproved ?? false))
          ? 'Online • GPS Radar Active'
          : 'Offline • Tap switch to go Online',
    );

    if (initialState.isOnline) {
      _startGpsBeaconing();
    }

    return initialState;
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

  void simulateTripCompleted({required double payout, double? codCollected}) {
    state = state.copyWith(
      todayTrips: state.todayTrips + 1,
      todayEarnings: state.todayEarnings + payout,
      codCashInHand: state.codCashInHand + (codCollected ?? 0.0),
    );
  }
}

final riderDutyProvider = NotifierProvider<RiderDutyNotifier, RiderDutyState>(
  RiderDutyNotifier.new,
);
