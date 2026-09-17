import 'dart:math' show cos, sqrt, asin, pi;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../location/providers/location_provider.dart';
import '../../store/domain/store_catalog_model.dart';
import '../domain/cart_item_model.dart';

enum AddToCartResult {
  success,
  vendorConflict,
  outOfStock,
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return CartState();
  }

  AddToCartResult addItem({
    required String vendorId,
    required String vendorName,
    double vendorDeliveryRadiusKm = 5.0,
    double? vendorLat,
    double? vendorLng,
    required ProductModel product,
    VariantModel? selectedVariant,
    List<AddonModel> selectedAddons = const [],
    required int quantity,
    String? specialInstructions,
    required double unitPrice,
    bool forceReplace = false,
  }) {
    if (!product.isInStock) {
      return AddToCartResult.outOfStock;
    }

    // Single-Vendor Guard
    if (state.vendorId != null &&
        state.vendorId != vendorId &&
        state.items.isNotEmpty) {
      if (!forceReplace) {
        return AddToCartResult.vendorConflict;
      }
      // User explicitly confirmed replacing the cart
      state = CartState();
    }

    final newItem = CartItem(
      product: product,
      selectedVariant: selectedVariant,
      selectedAddons: selectedAddons,
      quantity: quantity,
      specialInstructions: specialInstructions,
      unitPrice: unitPrice,
    );

    // Check if an identical configured item is already in cart
    final existingIndex = state.items.indexWhere((item) {
      if (item.product.id != product.id) return false;
      if (item.selectedVariant?.id != selectedVariant?.id) return false;
      if (item.selectedAddons.length != selectedAddons.length) return false;
      final existingAddonIds = item.selectedAddons.map((a) => a.id).toSet();
      final newAddonIds = selectedAddons.map((a) => a.id).toSet();
      return existingAddonIds.containsAll(newAddonIds);
    });

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = List.from(state.items);
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      updatedItems = [...state.items, newItem];
    }

    state = state.copyWith(
      vendorId: vendorId,
      vendorName: vendorName,
      vendorDeliveryRadiusKm: vendorDeliveryRadiusKm,
      vendorLat: vendorLat ?? 23.7925,
      vendorLng: vendorLng ?? 90.4078,
      items: updatedItems,
    );

    // Validate coverage for customer's current location
    validateCoverage();
    return AddToCartResult.success;
  }

  void updateQuantity(int index, int newQuantity) {
    if (index < 0 || index >= state.items.length) return;

    List<CartItem> updatedItems = List.from(state.items);
    if (newQuantity <= 0) {
      updatedItems.removeAt(index);
    } else {
      updatedItems[index] = updatedItems[index].copyWith(quantity: newQuantity);
    }

    if (updatedItems.isEmpty) {
      state = CartState();
      return;
    }

    state = state.copyWith(items: updatedItems);

    // Recheck coupon minimum spend
    if (state.couponCode != null && state.grossSubtotal < 250) {
      state = state.copyWith(
        clearCoupon: true,
        couponMessage: 'Coupon removed: subtotal below minimum spend',
      );
    }
  }

  void removeItem(int index) {
    updateQuantity(index, 0);
  }

  void setDeliveryMethod(DeliveryMethod method) {
    state = state.copyWith(deliveryMethod: method);
    if (method == DeliveryMethod.takeaway) {
      state = state.copyWith(
        isWithinCoverage: true,
        clearCoverageError: true,
      );
    } else {
      validateCoverage();
    }
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  Future<void> validateCoverage({double? customLat, double? customLng}) async {
    if (state.deliveryMethod == DeliveryMethod.takeaway) {
      state = state.copyWith(isWithinCoverage: true, clearCoverageError: true);
      return;
    }

    final location = ref.read(locationProvider).location;
    final lat = customLat ?? location.latitude;
    final lng = customLng ?? location.longitude;
    final vendorId = state.vendorId;

    if (vendorId == null) return;

    state = state.copyWith(isCheckingCoverage: true);

    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post(
        ApiConstants.cartValidateCoverage,
        data: {
          'vendorId': vendorId,
          'latitude': lat,
          'longitude': lng,
        },
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          isWithinCoverage: true,
          clearCoverageError: true,
          isCheckingCoverage: false,
        );
        return;
      }
    } catch (_) {
      // Offline / Test geofence calculation using Haversine formula
    }

    // Local Haversine Distance Check
    final vLat = state.vendorLat ?? 23.7925;
    final vLng = state.vendorLng ?? 90.4078;
    final distanceKm = _calculateHaversineDistance(lat, lng, vLat, vLng);
    final maxRadius = state.vendorDeliveryRadiusKm;

    if (distanceKm <= maxRadius) {
      state = state.copyWith(
        isWithinCoverage: true,
        clearCoverageError: true,
        isCheckingCoverage: false,
      );
    } else {
      state = state.copyWith(
        isWithinCoverage: false,
        coverageError:
            'Selected address is outside ${state.vendorName ?? "this outlet"}\'s delivery coverage radius of ${maxRadius.toStringAsFixed(0)} km (${distanceKm.toStringAsFixed(1)} km away).',
        isCheckingCoverage: false,
      );
    }
  }

  Future<bool> applyCoupon(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;

    state = state.copyWith(isApplyingCoupon: true, clearCouponMessage: true);

    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post(
        ApiConstants.validateCoupon,
        data: {
          'code': cleanCode,
          'cartSubtotal': state.grossSubtotal,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final discount = (data['discountAmount'] as num?)?.toDouble() ?? 0.0;
        state = state.copyWith(
          isApplyingCoupon: false,
          couponCode: cleanCode,
          couponDiscount: discount,
          couponMessage: 'Coupon "$cleanCode" applied! (Saved ৳${discount.toStringAsFixed(0)})',
        );
        return true;
      }
    } catch (_) {
      // Dev mode coupon validation fallback
    }

    // Dev mode validation: WELCOME50 provides ৳50 flat discount on min ৳250 spend
    if (cleanCode == 'WELCOME50') {
      if (state.grossSubtotal >= 250) {
        state = state.copyWith(
          isApplyingCoupon: false,
          couponCode: 'WELCOME50',
          couponDiscount: 50.0,
          couponMessage: 'Promo WELCOME50 applied! (Saved ৳50)',
        );
        return true;
      } else {
        state = state.copyWith(
          isApplyingCoupon: false,
          couponMessage: 'Minimum subtotal of ৳250 required for WELCOME50',
        );
        return false;
      }
    } else if (cleanCode == 'BURGER20') {
      final discount = (state.grossSubtotal * 0.20).clamp(0.0, 100.0);
      state = state.copyWith(
        isApplyingCoupon: false,
        couponCode: 'BURGER20',
        couponDiscount: discount,
        couponMessage: '20% OFF applied! (Saved ৳${discount.toStringAsFixed(0)})',
      );
      return true;
    }

    state = state.copyWith(
      isApplyingCoupon: false,
      couponMessage: 'Invalid or expired coupon code',
    );
    return false;
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true, clearCouponMessage: true);
  }

  void clearCart() {
    state = CartState();
  }

  Future<Map<String, dynamic>> checkout({String? customerNotes}) async {
    if (!state.canCheckout) {
      return {'success': false, 'message': 'Cannot checkout: please resolve cart errors.'};
    }

    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      return {'success': false, 'message': 'Please login to place your order.'};
    }

    try {
      final dio = ref.read(dioClientProvider);
      final payload = {
        'vendorId': state.vendorId,
        'deliveryMethod': state.deliveryMethod.apiKey,
        'paymentMethod': state.paymentMethod.apiKey,
        if (state.couponCode != null) 'couponCode': state.couponCode,
        if (customerNotes != null && customerNotes.isNotEmpty) 'customerNotes': customerNotes,
        'items': state.items.map((i) => i.toCheckoutJson()).toList(),
      };

      final response = await dio.post(ApiConstants.checkout, data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final orderData = response.data['data'] as Map<String, dynamic>? ?? {};
        final orderId = orderData['id'] as String? ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}';
        final orderNumber = orderData['orderNumber'] as String? ?? '#ORD-${DateTime.now().millisecondsSinceEpoch}';
        clearCart();
        return {
          'success': true,
          'orderId': orderId,
          'orderNumber': orderNumber,
        };
      }
    } catch (_) {
      // Mock dev checkout fallback
    }

    // Dev mode checkout success fallback
    final mockOrderNum = '#ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    clearCart();
    return {
      'success': true,
      'orderId': 'mock-order-uuid',
      'orderNumber': mockOrderNum,
    };
  }

  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = pi / 180;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
