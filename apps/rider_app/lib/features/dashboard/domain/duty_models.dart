class RiderDutyState {
  final bool isOnline;
  final bool isBeaconing;
  final double latitude;
  final double longitude;
  final double speed;
  final double bearing;
  final int todayTrips;
  final double todayEarnings;
  final double codCashInHand;
  final double cashSafetyLimit;
  final String? activeOrderId;
  final DateTime? lastBeaconTimestamp;
  final String statusMessage;
  final bool isToggling;
  final String? error;

  RiderDutyState({
    this.isOnline = false,
    this.isBeaconing = false,
    this.latitude = 23.7925,
    this.longitude = 90.4078,
    this.speed = 0.0,
    this.bearing = 0.0,
    this.todayTrips = 0,
    this.todayEarnings = 0.0,
    this.codCashInHand = 0.0,
    this.cashSafetyLimit = 5000.0,
    this.activeOrderId,
    this.lastBeaconTimestamp,
    this.statusMessage = 'Offline • Tap switch to go Online',
    this.isToggling = false,
    this.error,
  });

  bool get canAcceptCodTrips => codCashInHand < cashSafetyLimit;
  bool get isCashLimitReached => codCashInHand >= cashSafetyLimit;

  RiderDutyState copyWith({
    bool? isOnline,
    bool? isBeaconing,
    double? latitude,
    double? longitude,
    double? speed,
    double? bearing,
    int? todayTrips,
    double? todayEarnings,
    double? codCashInHand,
    double? cashSafetyLimit,
    String? activeOrderId,
    DateTime? lastBeaconTimestamp,
    String? statusMessage,
    bool? isToggling,
    String? error,
    bool clearError = false,
  }) {
    return RiderDutyState(
      isOnline: isOnline ?? this.isOnline,
      isBeaconing: isBeaconing ?? this.isBeaconing,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      todayTrips: todayTrips ?? this.todayTrips,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      codCashInHand: codCashInHand ?? this.codCashInHand,
      cashSafetyLimit: cashSafetyLimit ?? this.cashSafetyLimit,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      lastBeaconTimestamp: lastBeaconTimestamp ?? this.lastBeaconTimestamp,
      statusMessage: statusMessage ?? this.statusMessage,
      isToggling: isToggling ?? this.isToggling,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
