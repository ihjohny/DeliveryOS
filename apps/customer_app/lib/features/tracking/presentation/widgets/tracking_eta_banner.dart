import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/tracking_models.dart';

/// Modular ETA, Delivery status, and Cancellation banner widget.
class TrackingEtaBanner extends StatelessWidget {
  final OrderTrackingState state;

  const TrackingEtaBanner({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
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
}
