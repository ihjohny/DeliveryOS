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
    final productsRaw = json['products'] as List<dynamic>? ?? [];
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

  static VendorCatalog pilotSultansDine() {
    return VendorCatalog(
      id: 'b8b33bf6-6b22-4bb3-9d41-e9fb94c25601',
      name: "Sultan's Dine - Banani",
      addressText: 'House 42, Road 11, Block D, Banani, Dhaka',
      contactPhone: '+8801711223344',
      deliveryRadiusKm: 6.0,
      estimatedPrepTimeMinutes: 20,
      isActive: true,
      categories: [
        CategoryModel(
          id: 'cat-kacchi',
          name: 'Shahi Kacchi',
          sortOrder: 1,
          products: [
            ProductModel(
              id: 'prod-kacchi-half',
              name: 'Kacchi Biryani (Basmati)',
              description: 'Authentic Dhaka-style tender mutton biryani cooked with fragrant basmati, aloo bukhara, and golden potatoes.',
              basePrice: 420.0,
              unitType: 'portion',
              isInStock: true,
              variants: [
                VariantModel(id: 'v-half', name: 'Half (1 Mutton piece)', price: 340.0, isInStock: true),
                VariantModel(id: 'v-full', name: 'Full (2 Mutton pieces)', price: 460.0, isInStock: true),
                VariantModel(id: 'v-special', name: 'Special Platter (3 pieces + egg)', price: 620.0, isInStock: true),
              ],
              addonGroups: [
                AddonGroupModel(
                  id: 'addon-grp-side',
                  name: 'Add-ons & Extras',
                  minSelections: 0,
                  maxSelections: 4,
                  addons: [
                    AddonModel(id: 'add-borhani', name: 'Chilled Spiced Borhani (250ml)', price: 60.0, isInStock: true),
                    AddonModel(id: 'add-jali', name: 'Beef Jali Kebab (1 pc)', price: 70.0, isInStock: true),
                    AddonModel(id: 'add-firni', name: 'Zafrani Shahi Firni', price: 80.0, isInStock: true),
                    AddonModel(id: 'add-salad', name: 'Cucumber Mint Raita', price: 40.0, isInStock: true),
                  ],
                ),
              ],
            ),
            ProductModel(
              id: 'prod-soldout-roast',
              name: 'Shahi Chicken Roast with Polao',
              description: 'Rich ghee-roasted quarter chicken served with fragrant chinigura polao.',
              basePrice: 320.0,
              unitType: 'portion',
              isInStock: false, // SOLD OUT
              variants: [],
              addonGroups: [],
            ),
          ],
        ),
        CategoryModel(
          id: 'cat-sides',
          name: 'Kebabs & Sides',
          sortOrder: 2,
          products: [
            ProductModel(
              id: 'prod-mutton-rezala',
              name: 'Mutton Shahi Rezala',
              description: 'Tender mutton simmered in yogurt gravy with dry fruits and cashews.',
              basePrice: 380.0,
              unitType: 'bowl',
              isInStock: true,
              variants: [],
              addonGroups: [],
            ),
            ProductModel(
              id: 'prod-borhani-large',
              name: 'Traditional Borhani (1 Liter Bottle)',
              description: 'Digestive probiotic yogurt drink with roasted cumin, mint, and black salt.',
              basePrice: 220.0,
              unitType: 'bottle',
              isInStock: true,
              variants: [],
              addonGroups: [],
            ),
          ],
        ),
      ],
    );
  }
}
