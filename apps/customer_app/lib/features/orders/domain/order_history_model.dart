class OrderItemSummary {
  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? variantName;

  OrderItemSummary({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.variantName,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    return OrderItemSummary(
      productId: json['productId'] as String? ?? json['product_id'] as String? ?? '',
      name: json['productName'] as String? ?? json['name'] as String? ?? 'Menu Item',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      variantName: json['variantName'] as String? ?? json['variant_name'] as String?,
    );
  }
}

class PastOrder {
  final String id;
  final String orderNumber;
  final String vendorId;
  final String vendorName;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final List<OrderItemSummary> items;

  PastOrder({
    required this.id,
    required this.orderNumber,
    required this.vendorId,
    required this.vendorName,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  bool get isActive => ['PLACED', 'RIDER_ASSIGNED', 'ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'DISPATCHED'].contains(status.toUpperCase());

  factory PastOrder.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['orderItems'] as List<dynamic>? ?? json['items'] as List<dynamic>? ?? [];
    final vendor = json['vendor'] as Map<String, dynamic>? ?? {};

    return PastOrder(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? json['order_number'] as String? ?? '#ORD-2026',
      vendorId: json['vendorId'] as String? ?? json['vendor_id'] as String? ?? vendor['id'] as String? ?? '',
      vendorName: vendor['name'] as String? ?? json['vendorName'] as String? ?? "Sultan's Dine",
      status: json['status'] as String? ?? 'DELIVERED',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: itemsRaw.map((i) => OrderItemSummary.fromJson(i as Map<String, dynamic>)).toList(),
    );
  }

  static List<PastOrder> get pilotOrders => [
    PastOrder(
      id: 'ord-pilot-01',
      orderNumber: '#ORD-20260917-001',
      vendorId: 'b8b33bf6-6b22-4bb3-9d41-e9fb94c25601',
      vendorName: "Sultan's Dine - Banani",
      status: 'DISPATCHED',
      totalAmount: 480.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      items: [
        OrderItemSummary(
          productId: 'prod-kacchi-half',
          name: 'Kacchi Biryani (Basmati)',
          quantity: 1,
          unitPrice: 420.0,
          variantName: 'Full (2 Mutton pieces)',
        ),
        OrderItemSummary(
          productId: 'add-borhani',
          name: 'Chilled Spiced Borhani',
          quantity: 1,
          unitPrice: 60.0,
        ),
      ],
    ),
    PastOrder(
      id: 'ord-pilot-02',
      orderNumber: '#ORD-20260915-084',
      vendorId: 'b8b33bf6-6b22-4bb3-9d41-e9fb94c25601',
      vendorName: "Sultan's Dine - Banani",
      status: 'DELIVERED',
      totalAmount: 900.0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      items: [
        OrderItemSummary(
          productId: 'prod-kacchi-half',
          name: 'Kacchi Biryani (Basmati)',
          quantity: 2,
          unitPrice: 420.0,
        ),
      ],
    ),
    PastOrder(
      id: 'ord-pilot-03',
      orderNumber: '#ORD-20260912-142',
      vendorId: 'd6d55df8-8d44-5dd5-9f63-01fd16e47823',
      vendorName: 'Shwapno Superstore Express',
      status: 'DELIVERED',
      totalAmount: 640.0,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      items: [
        OrderItemSummary(
          productId: 'prod-milk-1',
          name: 'Pasteurized Milk (1L)',
          quantity: 2,
          unitPrice: 95.0,
        ),
        OrderItemSummary(
          productId: 'prod-eggs-1',
          name: 'Farm Fresh Brown Eggs (12 pcs)',
          quantity: 1,
          unitPrice: 155.0,
        ),
      ],
    ),
  ];
}

class ReorderValidationResult {
  final bool isStoreOperational;
  final bool hasStockChanges;
  final List<dynamic> validItems;
  final List<String> unavailableItems;

  ReorderValidationResult({
    required this.isStoreOperational,
    required this.hasStockChanges,
    this.validItems = const [],
    this.unavailableItems = const [],
  });

  factory ReorderValidationResult.fromJson(Map<String, dynamic> json) {
    return ReorderValidationResult(
      isStoreOperational: json['isStoreOperational'] as bool? ?? true,
      hasStockChanges: json['hasStockChanges'] as bool? ?? false,
      validItems: json['validItems'] as List<dynamic>? ?? [],
      unavailableItems: (json['unavailableItems'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
