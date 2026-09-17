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

                  // 6-Stage Stepper
                  OrderStepperWidget(currentStage: trackingState.stage),
                  const SizedBox(height: 12),

                  // Courier Card with Native Dialer Call Button
                  if (trackingState.rider != null) ...[
                    _buildRiderCard(context, trackingState.rider!),
                    const SizedBox(height: 10),
                  ],

                  // Store Card with Native Dialer Call Button
                  _buildStoreCard(context, trackingState.store),
                  const SizedBox(height: 16),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDelivered ? const Color(0xFFECFDF5) : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDelivered ? const Color(0xFFA7F3D0) : AppColors.primaryLight.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDelivered ? const Color(0xFF059669) : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivered ? Icons.task_alt_rounded : Icons.timer_outlined,
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
                  isDelivered
                      ? 'Delivered Successfully!'
                      : 'Estimated Arrival in ~${state.estimatedMinutesRemaining} mins',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDelivered ? const Color(0xFF065F46) : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDelivered
                      ? 'Order completed at ${state.customer.address.split(',').first}'
                      : 'Rider is on the move with your fresh order',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDelivered ? const Color(0xFF047857) : AppColors.textSecondary,
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
}
