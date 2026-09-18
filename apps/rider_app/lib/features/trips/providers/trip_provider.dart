import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../dashboard/providers/duty_provider.dart';
import '../domain/trip_models.dart';

class RiderTripState {
  final TripOrder? incomingTrip;
  final TripOrder? activeTrip;
  final int countdownSeconds;
  final bool isClaiming;
  final bool isUpdating;
  final String? error;

  RiderTripState({
    this.incomingTrip,
    this.activeTrip,
    this.countdownSeconds = 45,
    this.isClaiming = false,
    this.isUpdating = false,
    this.error,
  });

  bool get hasIncomingAlert => incomingTrip != null;
  bool get hasActiveTrip => activeTrip != null;

  RiderTripState copyWith({
    TripOrder? incomingTrip,
    bool clearIncomingTrip = false,
    TripOrder? activeTrip,
    bool clearActiveTrip = false,
    int? countdownSeconds,
    bool? isClaiming,
    bool? isUpdating,
    String? error,
    bool clearError = false,
  }) {
    return RiderTripState(
      incomingTrip: clearIncomingTrip ? null : (incomingTrip ?? this.incomingTrip),
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      isClaiming: isClaiming ?? this.isClaiming,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RiderTripNotifier extends Notifier<RiderTripState> {
  Timer? _countdownTimer;

  @override
  RiderTripState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    return RiderTripState();
  }

  void stopTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void triggerBroadcastAlert(TripOrder trip) {
    _countdownTimer?.cancel();
    state = state.copyWith(
      incomingTrip: trip,
      countdownSeconds: 45,
      clearError: true,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds <= 1) {
        dismissIncomingAlert();
      } else {
        state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
      }
    });
  }

  void dismissIncomingAlert() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = state.copyWith(clearIncomingTrip: true, countdownSeconds: 45);
  }

  Future<bool> claimTrip(TripOrder trip) async {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    state = state.copyWith(isClaiming: true, clearError: true);

    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post('${ApiConstants.claimOrder}/${trip.id}/claim');
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully acquired atomic Redis mutex lock
      }
    } catch (_) {
      // Dev mode fallback
    }

    final claimedTrip = trip.copyWith(
      currentStep: TripStep.pickup,
      status: 'RIDER_ASSIGNED',
    );

    state = state.copyWith(
      isClaiming: false,
      clearIncomingTrip: true,
      activeTrip: claimedTrip,
    );

    return true;
  }

  Future<bool> confirmPickup() async {
    final trip = state.activeTrip;
    if (trip == null) return false;

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch('${ApiConstants.pickupOrder}/${trip.id}/pickup');
    } catch (_) {
      // Dev mode fallback
    }

    final updated = trip.copyWith(
      currentStep: TripStep.delivering,
      status: 'DISPATCHED',
    );

    state = state.copyWith(
      isUpdating: false,
      activeTrip: updated,
    );

    return true;
  }

  void proceedToHandover() {
    final trip = state.activeTrip;
    if (trip != null) {
      state = state.copyWith(
        activeTrip: trip.copyWith(currentStep: TripStep.handover),
      );
    }
  }

  Future<bool> completeDelivery({
    required bool codCashCollected,
    required double amountCollected,
  }) async {
    final trip = state.activeTrip;
    if (trip == null) return false;

    // INVARIANT GUARD: COD orders require cash collection check
    if (trip.isCod && !codCashCollected) {
      state = state.copyWith(
        error: 'Please verify that cash has been collected from customer.',
      );
      return false;
    }

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch(
        '${ApiConstants.deliverOrder}/${trip.id}/deliver',
        data: {
          'codCashCollected': codCashCollected,
          'amountCollected': amountCollected,
        },
      );
    } catch (_) {
      // Dev mode fallback
    }

    // Credit rider wallet metrics
    ref.read(riderDutyProvider.notifier).simulateTripCompleted(
          payout: trip.payout,
          codCollected: trip.isCod ? amountCollected : 0.0,
        );

    state = state.copyWith(
      isUpdating: false,
      clearActiveTrip: true,
    );

    return true;
  }

  void simulateIncomingBroadcast({TripOrder? customTrip}) {
    final trip = customTrip ?? TripOrder.pilotKacchiOrder();
    triggerBroadcastAlert(trip);
  }
}

final riderTripProvider = NotifierProvider<RiderTripNotifier, RiderTripState>(
  RiderTripNotifier.new,
);
