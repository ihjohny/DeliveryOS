class CustomerAddressModel {
  final String id;
  final String label;
  final String addressLine;
  final String? buildingFloor;
  final String? deliveryNote;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime? createdAt;

  const CustomerAddressModel({
    required this.id,
    required this.label,
    required this.addressLine,
    this.buildingFloor,
    this.deliveryNote,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    this.createdAt,
  });

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) {
    return CustomerAddressModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      addressLine: json['addressLine'] as String? ?? '',
      buildingFloor: json['buildingFloor'] as String?,
      deliveryNote: json['deliveryNote'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 23.7925,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 90.4078,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'addressLine': addressLine,
      'buildingFloor': buildingFloor,
      'deliveryNote': deliveryNote,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    };
  }

  CustomerAddressModel copyWith({
    String? id,
    String? label,
    String? addressLine,
    String? buildingFloor,
    String? deliveryNote,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CustomerAddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      addressLine: addressLine ?? this.addressLine,
      buildingFloor: buildingFloor ?? this.buildingFloor,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
