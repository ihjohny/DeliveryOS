enum AddressType { home, work, other }

class UserLocation {
  final double latitude;
  final double longitude;
  final String addressLine;
  final String? buildingFloor;
  final String? deliveryNote;
  final AddressType addressType;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.addressLine,
    this.buildingFloor,
    this.deliveryNote,
    this.addressType = AddressType.home,
  });

  factory UserLocation.defaultBanani() {
    return UserLocation(
      latitude: 23.7925,
      longitude: 90.4078,
      addressLine: 'House 42, Road 11, Banani, Dhaka',
      addressType: AddressType.home,
    );
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? addressLine,
    String? buildingFloor,
    String? deliveryNote,
    AddressType? addressType,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressLine: addressLine ?? this.addressLine,
      buildingFloor: buildingFloor ?? this.buildingFloor,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      addressType: addressType ?? this.addressType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'addressLine': addressLine,
      'buildingFloor': buildingFloor,
      'deliveryNote': deliveryNote,
      'addressType': addressType.name,
    };
  }

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 23.7925,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 90.4078,
      addressLine: json['addressLine'] as String? ?? 'Banani, Dhaka',
      buildingFloor: json['buildingFloor'] as String?,
      deliveryNote: json['deliveryNote'] as String?,
      addressType: AddressType.values.firstWhere(
        (e) => e.name == json['addressType'],
        orElse: () => AddressType.home,
      ),
    );
  }
}
