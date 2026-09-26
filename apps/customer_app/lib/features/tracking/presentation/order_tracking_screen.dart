import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_call_launcher.dart';
import '../domain/tracking_models.dart';
import '../providers/tracking_provider.dart';
import 'widgets/order_stepper_widget.dart';
import 'widgets/payment_recovery_banner.dart';
import 'widgets/tracking_contact_card.dart';
import 'widgets/tracking_eta_banner.dart';
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
            icon: const Icon(Icons.support_agent_rounded, size: 22, color: AppColors.primary),
            tooltip: '24/7 Support Hotline',
            onPressed: () => makeDirectPhoneCall('+8801700000000'),
          ),
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
          Expanded(
            flex: 4,
            child: TrackingMapView(state: trackingState),
          ),
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
                  if (trackingState.paymentMethod == 'ONLINE_GATEWAY' &&
                      trackingState.paymentStatus != 'PAID' &&
                      !trackingState.isCancelled) ...[
                    PaymentRecoveryBanner(
                      onSwitchToCOD: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await ref.read(trackingProvider(orderId).notifier).switchToCOD();
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Switched to Cash on Delivery! Order is now being dispatched.'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      },
                      onRefresh: () {
                        ref.read(trackingProvider(orderId).notifier).refreshDetails();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Checking gateway payment status...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],

                  TrackingEtaBanner(state: trackingState),
                  const SizedBox(height: 12),

                  if (trackingState.isCancelled &&
                      (trackingState.paymentStatus == 'REFUNDED' ||
                          trackingState.paymentMethod == 'ONLINE')) ...[
                    _buildRefundBanner(trackingState),
                    const SizedBox(height: 12),
                  ],

                  OrderStepperWidget(currentStage: trackingState.stage),
                  const SizedBox(height: 12),

                  if (trackingState.rider != null && !trackingState.isCancelled) ...[
                    TrackingContactCard(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
                      ),
                      title: trackingState.rider!.name,
                      titleTrailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                          Text(
                            trackingState.rider!.rating.toString(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      subtitle: '${trackingState.rider!.vehicleType} • ${trackingState.rider!.phone}',
                      actionLabel: 'Call Rider',
                      isPrimaryAction: true,
                      onAction: () async {
                        final launched = await makeDirectPhoneCall(trackingState.rider!.phone);
                        if (!launched && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${trackingState.rider!.phone}...')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  TrackingContactCard(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                    ),
                    title: trackingState.store.name,
                    subtitle: trackingState.store.address,
                    actionLabel: 'Call Store',
                    isPrimaryAction: false,
                    onAction: () async {
                      final launched = await makeDirectPhoneCall(trackingState.store.phone);
                      if (!launched && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling store at ${trackingState.store.phone}...')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

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
                      ? '${CurrencyFormatter.format(state.totalAmount)} has been refunded to your original payment method.'
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
                      'Your payment of ${CurrencyFormatter.format(state.totalAmount)} will be automatically refunded.',
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
