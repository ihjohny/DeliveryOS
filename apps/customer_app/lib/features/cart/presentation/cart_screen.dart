import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../addresses/domain/address_model.dart';
import '../../addresses/presentation/address_book_screen.dart';
import '../../addresses/providers/address_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/presentation/phone_input_screen.dart';
import '../../location/providers/location_provider.dart';
import '../../tracking/presentation/order_tracking_screen.dart';
import '../domain/cart_item_model.dart';
import '../providers/cart_provider.dart';
import 'widgets/address_geofence_banner.dart';
import 'widgets/coupon_input_section.dart';
import 'widgets/delivery_mode_selector.dart';
import 'widgets/payment_method_selector.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    final auth = ref.read(authProvider);

    // If guest, prompt to login before submitting order
    if (auth.isGuest) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Login Required to Order', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
            'Please login with your phone number so we can track and deliver your order.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Login Now'),
            ),
          ],
        ),
      );

      if (shouldLogin == true && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
        );
      }
      return;
    }

    // Home Delivery requires saved address
    String? deliveryAddressId;
    final cart = ref.read(cartProvider);
    if (cart.deliveryMethod == DeliveryMethod.homeDelivery) {
      final addrState = ref.read(addressProvider);
      if (addrState.selectedAddress == null) {
        final picked = await Navigator.of(context).push<CustomerAddressModel>(
          MaterialPageRoute(builder: (_) => const AddressBookScreen(isSelectionMode: true)),
        );
        if (picked == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select or add a delivery address to proceed.')),
            );
          }
          return;
        }
        ref.read(addressProvider.notifier).selectAddress(picked);
        ref.read(cartProvider.notifier).validateCoverage(customLat: picked.latitude, customLng: picked.longitude);
        deliveryAddressId = picked.id;
      } else {
        deliveryAddressId = addrState.selectedAddress!.id;
      }
    }

    setState(() => _isSubmitting = true);
    final result = await ref.read(cartProvider.notifier).checkout(
          customerNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          deliveryAddressId: deliveryAddressId,
        );
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['success'] == true) {
      final orderId = result['orderId'] as String? ?? '';
      final orderNumber = result['orderNumber'] as String? ?? '#ORD-001';
      final isOnline = result['paymentMethod'] == 'ONLINE_GATEWAY';
      final paymentSession = result['paymentSession'] as Map<String, dynamic>?;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isOnline ? Icons.payment_rounded : Icons.check_circle_rounded,
                color: isOnline ? AppColors.primary : AppColors.secondary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'Online Payment Session' : 'Order Confirmed!',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order $orderNumber has been placed successfully!',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (isOnline) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Gateway:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(paymentSession?['gateway']?.toString() ?? 'SANDBOX', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Txn ID:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(paymentSession?['transactionId']?.toString() ?? 'PENDING', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text('৳${paymentSession?['amount']?.toString() ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '⚡ Business Rule: Courier & Kitchen dispatch will activate immediately upon online payment verification webhook confirmation.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ] else ...[
                const Text(
                  'We have dispatched the order to the kitchen and courier fleet.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Back to discovery home
              },
              child: const Text('Return to Home', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(
                      orderId: orderId,
                      orderNumber: orderNumber,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: Text(isOnline ? 'Go to Tracking' : 'Track Order', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Order placement failed.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final userLocation = ref.watch(locationProvider).location;
    final addressState = ref.watch(addressProvider);

    if (cartState.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'My Cart',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.remove_shopping_cart_rounded, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Browse restaurants and stores to add your favorite items',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Start Exploring', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Cart',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            if (cartState.vendorName != null)
              Text(
                cartState.vendorName!,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            tooltip: 'Clear Cart',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Cart?'),
                  content: const Text('Are you sure you want to remove all items from your cart?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearCart();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Delivery Method Selector
          DeliveryModeSelector(
            selectedMethod: cartState.deliveryMethod,
            onMethodChanged: (method) {
              ref.read(cartProvider.notifier).setDeliveryMethod(method);
            },
          ),
          const SizedBox(height: 12),

          // 2. Delivery Address Card & Geofence Banner
          if (cartState.deliveryMethod == DeliveryMethod.homeDelivery) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            addressState.selectedAddress != null
                                ? (addressState.selectedAddress!.label.toLowerCase() == 'home'
                                    ? Icons.home_rounded
                                    : (addressState.selectedAddress!.label.toLowerCase() == 'work'
                                        ? Icons.work_rounded
                                        : Icons.location_on_rounded))
                                : Icons.my_location_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            addressState.selectedAddress != null
                                ? 'Deliver to: ${addressState.selectedAddress!.label}'
                                : 'Deliver to Current Location',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await Navigator.of(context).push<CustomerAddressModel>(
                            MaterialPageRoute(
                              builder: (_) => const AddressBookScreen(isSelectionMode: true),
                            ),
                          );
                          if (picked != null) {
                            ref.read(addressProvider.notifier).selectAddress(picked);
                            ref.read(cartProvider.notifier).validateCoverage(
                                  customLat: picked.latitude,
                                  customLng: picked.longitude,
                                );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    addressState.selectedAddress?.addressLine ?? userLocation.addressLine,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            AddressGeofenceBanner(
              isWithinCoverage: cartState.isWithinCoverage,
              currentAddress: addressState.selectedAddress?.addressLine ?? userLocation.addressLine,
              coverageError: cartState.coverageError,
              onAddressChanged: () {
                final lat = addressState.selectedAddress?.latitude;
                final lng = addressState.selectedAddress?.longitude;
                ref.read(cartProvider.notifier).validateCoverage(customLat: lat, customLng: lng);
              },
            ),
            const SizedBox(height: 14),
          ],

          // Store Closed / Busy Warning Banner
          if (!cartState.isVendorActive || cartState.isVendorBusy) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: !cartState.isVendorActive ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !cartState.isVendorActive ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    !cartState.isVendorActive ? Icons.store_mall_directory_outlined : Icons.timer_outlined,
                    color: !cartState.isVendorActive ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      !cartState.isVendorActive
                          ? '${cartState.vendorName ?? "Store"} is currently closed and not accepting orders.'
                          : '${cartState.vendorName ?? "Store"} has temporarily paused orders due to rush hour.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: !cartState.isVendorActive ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 3. Cart Items Section
          const Text(
            'Order Items',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ...List.generate(cartState.items.length, (index) {
            final item = cartState.items[index];
            return _buildCartItemCard(item, index);
          }),
          const SizedBox(height: 16),

          // 4. Coupon Code Input Section
          const Text(
            'Promotions & Vouchers',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          CouponInputSection(
            appliedCoupon: cartState.couponCode,
            couponDiscount: cartState.couponDiscount,
            isLoading: cartState.isApplyingCoupon,
            message: cartState.couponMessage,
            onApplyCoupon: (code) {
              ref.read(cartProvider.notifier).applyCoupon(code);
            },
            onRemoveCoupon: () {
              ref.read(cartProvider.notifier).removeCoupon();
            },
          ),
          const SizedBox(height: 16),

          // 5. Cooking & Delivery Instructions
          const Text(
            'Cooking & Delivery Notes',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'e.g. Ring doorbell, leave at door, extra napkins...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),

          // 6. Payment Method Choice
          const Text(
            'Payment Method',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          PaymentMethodSelector(
            selectedMethod: cartState.paymentMethod,
            onMethodChanged: (method) {
              ref.read(cartProvider.notifier).setPaymentMethod(method);
            },
          ),
          const SizedBox(height: 16),

          // 7. Order Summary Card
          _buildSummaryCard(cartState),
          const SizedBox(height: 24),
        ],
      ),

      // Bottom Bar with "Place Order" CTA
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (cartState.canCheckout && !_isSubmitting) ? _handlePlaceOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          !cartState.isVendorActive
                              ? 'Store Currently Closed'
                              : cartState.isVendorBusy
                                  ? 'Store Paused (Rush Hour)'
                                  : (!cartState.isWithinCoverage && cartState.deliveryMethod == DeliveryMethod.homeDelivery)
                                      ? 'Address Out of Coverage'
                                      : 'Place Order (${cartState.totalItemCount} items)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '৳${cartState.totalPayable.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                if (item.selectedVariant != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Portion: ${item.selectedVariant!.name}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
                if (item.selectedAddons.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Extras: ${item.selectedAddons.map((a) => a.name).join(", ")}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
                if (item.specialInstructions != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Note: "${item.specialInstructions}"',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '৳${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),

          // Stepper Controls
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    ref.read(cartProvider.notifier).updateQuantity(index, item.quantity - 1);
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    ref.read(cartProvider.notifier).updateQuantity(index, item.quantity + 1);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow('Item Subtotal', '৳${cart.grossSubtotal.toStringAsFixed(0)}'),
          if (cart.couponDiscount > 0)
            _buildSummaryRow(
              'Coupon Discount (${cart.couponCode})',
              '-৳${cart.couponDiscount.toStringAsFixed(0)}',
              color: AppColors.secondary,
            ),
          _buildSummaryRow(
            'Delivery Fee',
            cart.deliveryMethod == DeliveryMethod.takeaway ? 'FREE' : '৳${cart.deliveryFee.toStringAsFixed(0)}',
          ),
          const Divider(height: 20, color: AppColors.border),
          _buildSummaryRow(
            'Total Payable',
            '৳${cart.totalPayable.toStringAsFixed(0)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: color ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
