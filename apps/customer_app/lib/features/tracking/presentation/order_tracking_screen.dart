import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/phone_call_launcher.dart';
import '../domain/tracking_models.dart';
import '../providers/tracking_provider.dart';
import 'widgets/order_stepper_widget.dart';
import 'widgets/tracking_map_view.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  final String? orderNumber;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.orderNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(trackingProvider(orderId));

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
              'Live Order Tracking',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            Text(
              orderNumber ?? trackingState.orderNumber,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textPrimary),
            tooltip: 'Refresh Status',
            onPressed: () {
              ref.read(trackingProvider(orderId).notifier).refreshDetails();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Map with Store, Rider, and Delivery Pins
          Expanded(
            flex: 4,
            child: TrackingMapView(state: trackingState),
          ),

          // Lower Panel with ETA, Stepper, and Direct Call Actions
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ETA Card
                  _buildEtaBanner(trackingState),
                  const SizedBox(height: 12),

                  // Refund Banner (if cancelled and refund processed/applicable)
                  if (trackingState.isCancelled &&
                      (trackingState.paymentStatus == 'REFUNDED' ||
                          trackingState.paymentMethod == 'ONLINE')) ...[
                    _buildRefundBanner(trackingState),
                    const SizedBox(height: 12),
                  ],

                  // 6-Stage Stepper
                  OrderStepperWidget(currentStage: trackingState.stage),
                  const SizedBox(height: 12),

                  // Courier Card with Native Dialer Call Button
                  if (trackingState.rider != null && !trackingState.isCancelled) ...[
                    _buildRiderCard(context, trackingState.rider!),
                    const SizedBox(height: 10),
                  ],

                  // Store Card with Native Dialer Call Button
                  _buildStoreCard(context, trackingState.store),
                  const SizedBox(height: 16),

                  // Customer Cancel CTA (allowed in PLACED and RIDER_ASSIGNED)
                  if (trackingState.canCancel) ...[
                    _buildCancelOrderButton(context, ref, trackingState),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaBanner(OrderTrackingState state) {
    final isDelivered = state.stage == OrderStage.delivered;
    final isCancelled = state.stage == OrderStage.cancelled;

    Color bgColor = AppColors.primaryContainer;
    Color borderColor = AppColors.primaryLight.withValues(alpha: 0.5);
    Color iconBgColor = AppColors.primary;
    IconData icon = Icons.timer_outlined;
    String title = 'Estimated Arrival in ~${state.estimatedMinutesRemaining} mins';
    String subtitle = 'Rider is on the move with your fresh order';
    Color titleColor = AppColors.primaryDark;
    Color subtitleColor = AppColors.textSecondary;

    if (isCancelled) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      iconBgColor = const Color(0xFFDC2626);
      icon = Icons.cancel_rounded;
      title = 'Order Cancelled';
      subtitle = state.cancellationReason != null && state.cancellationReason!.isNotEmpty
          ? 'Reason: ${state.cancellationReason}'
          : 'This order has been cancelled.';
      titleColor = const Color(0xFF991B1B);
      subtitleColor = const Color(0xFFB91C1C);
    } else if (isDelivered) {
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      iconBgColor = const Color(0xFF059669);
      icon = Icons.task_alt_rounded;
      title = 'Delivered Successfully!';
      subtitle = 'Order completed at ${state.customer.address.split(',').first}';
      titleColor = const Color(0xFF065F46);
      subtitleColor = const Color(0xFF047857);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(BuildContext context, RiderMeta rider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rider.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                    Text(
                      rider.rating.toString(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${rider.vehicleType} • ${rider.phone}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Direct Native Dialer Call Button
          ElevatedButton.icon(
            onPressed: () async {
              final launched = await makeDirectPhoneCall(rider.phone);
              if (!launched && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling ${rider.phone}...')),
                );
              }
            },
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Call Rider', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context, StoreMeta store) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  store.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Direct Native Dialer Call Store Button
          OutlinedButton.icon(
            onPressed: () async {
              final launched = await makeDirectPhoneCall(store.phone);
              if (!launched && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling store at ${store.phone}...')),
                );
              }
            },
            icon: const Icon(Icons.phone_rounded, size: 14),
            label: const Text('Call Store', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundBanner(OrderTrackingState state) {
    final isRefunded = state.paymentStatus == 'REFUNDED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRefunded ? 'Refund Processed' : 'Refund Pending',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isRefunded
                      ? '৳${state.totalAmount.toStringAsFixed(0)} has been refunded to your original payment method.'
                      : 'Your refund will be returned to your original payment method shortly.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelOrderButton(
    BuildContext context,
    WidgetRef ref,
    OrderTrackingState state,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCancelDialog(context, ref, state),
        icon: const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFDC2626)),
        label: const Text(
          'Cancel Order',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFDC2626),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCA5A5)),
          backgroundColor: const Color(0xFFFEF2F2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    OrderTrackingState state,
  ) {
    final reasonController = TextEditingController();
    String selectedPreset = 'Changed my mind';
    final presets = [
      'Changed my mind',
      'Ordered by mistake',
      'Delivery takes too long',
      'Wrong delivery address',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text(
                'Cancel Order?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to cancel this order? You can cancel for free before the kitchen starts preparing your meal.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                if (state.paymentStatus == 'PAID' || state.paymentMethod == 'ONLINE') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Your payment of ৳${state.totalAmount.toStringAsFixed(0)} will be automatically refunded.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Reason for cancellation',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presets.map((preset) {
                    final isSelected = selectedPreset == preset;
                    return ChoiceChip(
                      label: Text(preset),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() {
                            selectedPreset = preset;
                            if (preset != 'Other') {
                              reasonController.text = preset;
                            } else {
                              reasonController.clear();
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                if (selectedPreset == 'Other') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Please specify reason...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Keep Order', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = selectedPreset == 'Other'
                    ? (reasonController.text.trim().isEmpty ? 'Customer requested cancellation' : reasonController.text.trim())
                    : selectedPreset;
                Navigator.of(dialogCtx).pop();

                final success = await ref
                    .read(trackingProvider(orderId).notifier)
                    .cancelOrder(reason);

                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order cancelled successfully.'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  } else {
                    final err = ref.read(trackingProvider(orderId)).error ?? 'Could not cancel order.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
