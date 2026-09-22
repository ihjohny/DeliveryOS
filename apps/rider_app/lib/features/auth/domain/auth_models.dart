enum VehicleType {
  motorcycle,
  bicycle,
  car,
}

extension VehicleTypeExtension on VehicleType {
  String get apiKey {
    switch (this) {
      case VehicleType.motorcycle:
        return 'motorcycle';
      case VehicleType.bicycle:
        return 'bicycle';
      case VehicleType.car:
        return 'car';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleType.motorcycle:
        return 'Motorcycle / Scooter';
      case VehicleType.bicycle:
        return 'Bicycle';
      case VehicleType.car:
        return 'Car / Van';
    }
  }

  static VehicleType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'bicycle':
        return VehicleType.bicycle;
      case 'car':
        return VehicleType.car;
      case 'motorcycle':
      default:
        return VehicleType.motorcycle;
    }
  }
}

enum AccountStatus {
  active,
  pendingApproval,
  suspended,
}

extension AccountStatusExtension on AccountStatus {
  String get apiKey {
    switch (this) {
      case AccountStatus.active:
        return 'ACTIVE';
      case AccountStatus.pendingApproval:
        return 'PENDING_APPROVAL';
      case AccountStatus.suspended:
        return 'SUSPENDED';
    }
  }

  String get displayName {
    switch (this) {
      case AccountStatus.active:
        return 'Approved & Active';
      case AccountStatus.pendingApproval:
        return 'Pending Admin Approval';
      case AccountStatus.suspended:
        return 'Suspended';
    }
  }

  static AccountStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return AccountStatus.active;
      case 'SUSPENDED':
        return AccountStatus.suspended;
      case 'PENDING_APPROVAL':
      default:
        return AccountStatus.pendingApproval;
    }
  }
}

class RiderProfileData {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final VehicleType vehicleType;
  final AccountStatus status;
  final bool isOnline;
  final double earningsBalance;
  final double cashInHand;
  final double maxCashLimit;
  final int completedTripsCount;
  final double rating;

  RiderProfileData({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.vehicleType,
    required this.status,
    this.isOnline = false,
    this.earningsBalance = 0.0,
    this.cashInHand = 0.0,
    this.maxCashLimit = 5000.0,
    this.completedTripsCount = 0,
    this.rating = 5.0,
  });

  bool get isApproved => status == AccountStatus.active;
  bool get canGoOnline => isApproved && status != AccountStatus.suspended;
  bool get isCashLimitExceeded => cashInHand >= maxCashLimit;

  RiderProfileData copyWith({
    String? fullName,
    VehicleType? vehicleType,
    AccountStatus? status,
    bool? isOnline,
    double? earningsBalance,
    double? cashInHand,
    double? maxCashLimit,
    int? completedTripsCount,
    double? rating,
  }) {
    return RiderProfileData(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      phone: phone,
      vehicleType: vehicleType ?? this.vehicleType,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      earningsBalance: earningsBalance ?? this.earningsBalance,
      cashInHand: cashInHand ?? this.cashInHand,
      maxCashLimit: maxCashLimit ?? this.maxCashLimit,
      completedTripsCount: completedTripsCount ?? this.completedTripsCount,
      rating: rating ?? this.rating,
    );
  }

  factory RiderProfileData.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    final statusStr = json['status'] as String? ?? user['status'] as String? ?? 'PENDING_APPROVAL';
    final vehicleStr = json['vehicleType'] as String? ?? 'motorcycle';

    return RiderProfileData(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? user['id'] as String? ?? '',
      fullName: user['fullName'] as String? ?? json['fullName'] as String? ?? 'Rider Partner',
      phone: user['phone'] as String? ?? json['phone'] as String? ?? '',
      vehicleType: VehicleTypeExtension.fromString(vehicleStr),
      status: AccountStatusExtension.fromString(statusStr),
      isOnline: json['isOnline'] as bool? ?? false,
      earningsBalance: double.tryParse(json['earningsBalance']?.toString() ?? '') ?? 0.0,
      cashInHand: double.tryParse(json['cashInHand']?.toString() ?? '') ?? 0.0,
      maxCashLimit: double.tryParse(json['maxCashLimit']?.toString() ?? '') ?? 5000.0,
      completedTripsCount: int.tryParse(json['completedTripsCount']?.toString() ?? '') ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'vehicleType': vehicleType.apiKey,
      'status': status.apiKey,
      'isOnline': isOnline,
      'earningsBalance': earningsBalance,
      'cashInHand': cashInHand,
      'maxCashLimit': maxCashLimit,
      'completedTripsCount': completedTripsCount,
      'rating': rating,
    };
  }

  // Mock / Dev Pilot Profile
  factory RiderProfileData.pilotApproved({
    String? phone,
    String? fullName,
    bool isOnline = false,
  }) {
    return RiderProfileData(
      id: 'rider-pilot-01',
      userId: 'user-rider-pilot-01',
      fullName: fullName ?? 'Tanvir Hossain',
      phone: phone ?? '+8801700112233',
      vehicleType: VehicleType.motorcycle,
      status: AccountStatus.active,
      isOnline: isOnline,
      earningsBalance: 1250.0,
      cashInHand: 840.0,
      maxCashLimit: 5000.0,
      completedTripsCount: 14,
      rating: 4.92,
    );
  }

  factory RiderProfileData.pilotPending({
    String? phone,
    String? fullName,
    VehicleType? vehicleType,
  }) {
    return RiderProfileData(
      id: 'rider-pending-01',
      userId: 'user-pending-01',
      fullName: fullName ?? 'Shafiqul Islam',
      phone: phone ?? '+8801700998877',
      vehicleType: vehicleType ?? VehicleType.motorcycle,
      status: AccountStatus.pendingApproval,
      isOnline: false,
      earningsBalance: 0.0,
      cashInHand: 0.0,
      maxCashLimit: 5000.0,
      completedTripsCount: 0,
      rating: 5.0,
    );
  }
}
