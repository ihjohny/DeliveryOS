class AddonModel {
  final String id;
  final String name;
  final double price;
  final bool isInStock;

  AddonModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isInStock,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    return AddonModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isInStock: json['isInStock'] as bool? ?? json['is_in_stock'] as bool? ?? true,
    );
  }
}

class AddonGroupModel {
  final String id;
  final String name;
  final int minSelections;
  final int maxSelections;
  final List<AddonModel> addons;

  AddonGroupModel({
    required this.id,
    required this.name,
    this.minSelections = 0,
    this.maxSelections = 5,
    this.addons = const [],
  });

  factory AddonGroupModel.fromJson(Map<String, dynamic> json) {
    final addonsRaw = json['addons'] as List<dynamic>? ?? [];
    return AddonGroupModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      minSelections: (json['minSelections'] as num?)?.toInt() ?? 0,
      maxSelections: (json['maxSelections'] as num?)?.toInt() ?? 5,
      addons: addonsRaw.map((e) => AddonModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class VariantModel {
  final String id;
  final String name;
  final double price;
  final bool isInStock;

  VariantModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isInStock,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isInStock: json['isInStock'] as bool? ?? json['is_in_stock'] as bool? ?? true,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double basePrice;
  final String unitType;
  final String? imageUrl;
  final bool isInStock;
  final List<VariantModel> variants;
  final List<AddonGroupModel> addonGroups;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.basePrice,
    required this.unitType,
    this.imageUrl,
    required this.isInStock,
    this.variants = const [],
    this.addonGroups = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final variantsRaw = json['variants'] as List<dynamic>? ?? [];
    final addonsRaw = json['addonGroups'] as List<dynamic>? ?? json['addon_groups'] as List<dynamic>? ?? [];

    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? (json['base_price'] as num?)?.toDouble() ?? 0.0,
      unitType: json['unitType'] as String? ?? json['unit_type'] as String? ?? 'piece',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      isInStock: json['isInStock'] as bool? ?? json['is_in_stock'] as bool? ?? true,
      variants: variantsRaw.map((e) => VariantModel.fromJson(e as Map<String, dynamic>)).toList(),
      addonGroups: addonsRaw.map((e) => AddonGroupModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final int sortOrder;
  final List<ProductModel> products;

  CategoryModel({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.products = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final productsRaw = json['products'] as List<dynamic>? ?? json['items'] as List<dynamic>? ?? [];
    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      products: productsRaw.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class VendorCatalog {
  final String id;
  final String name;
  final String? logoUrl;
  final String? bannerUrl;
  final String addressText;
  final String? contactPhone;
  final double deliveryRadiusKm;
  final int estimatedPrepTimeMinutes;
  final bool isActive;
  final List<CategoryModel> categories;

  VendorCatalog({
    required this.id,
    required this.name,
    this.logoUrl,
    this.bannerUrl,
    required this.addressText,
    this.contactPhone,
    this.deliveryRadiusKm = 5.0,
    this.estimatedPrepTimeMinutes = 25,
    this.isActive = true,
    this.categories = const [],
  });

  factory VendorCatalog.fromJson(Map<String, dynamic> json) {
    final categoriesRaw = json['categories'] as List<dynamic>? ?? [];
    return VendorCatalog(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? json['logo_url'] as String?,
      bannerUrl: json['bannerUrl'] as String? ?? json['banner_url'] as String?,
      addressText: json['addressText'] as String? ?? json['address_text'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? json['contact_phone'] as String?,
      deliveryRadiusKm: (json['deliveryRadiusKm'] as num?)?.toDouble() ?? (json['delivery_radius_km'] as num?)?.toDouble() ?? 5.0,
      estimatedPrepTimeMinutes: (json['estimatedPrepTimeMinutes'] as num?)?.toInt() ?? (json['estimated_prep_time_minutes'] as num?)?.toInt() ?? 25,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      categories: categoriesRaw.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
