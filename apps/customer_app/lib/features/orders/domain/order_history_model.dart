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
      vendorName: vendor['name'] as String? ?? json['vendorName'] as String? ?? 'Outlet',
      status: json['status'] as String? ?? 'DELIVERED',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: itemsRaw.map((i) => OrderItemSummary.fromJson(i as Map<String, dynamic>)).toList(),
    );
  }
}

class ReorderValidationResult {
  final bool isStoreOperational;
  final bool hasStockChanges;
  final List<dynamic> validItems;
  final List<String> unavailableItems;

  const ReorderValidationResult({
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
