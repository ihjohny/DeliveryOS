import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/tracking_models.dart';

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
      bgColor = AppColors.errorContainer;
      borderColor = AppColors.errorBorder;
      iconBgColor = AppColors.errorDark;
      icon = Icons.cancel_rounded;
      title = 'Order Cancelled';
      subtitle = state.cancellationReason != null && state.cancellationReason!.isNotEmpty
          ? 'Reason: ${state.cancellationReason}'
          : 'This order has been cancelled.';
      titleColor = AppColors.errorText;
      subtitleColor = AppColors.errorTextMedium;
    } else if (isDelivered) {
      bgColor = AppColors.successContainer;
      borderColor = AppColors.successBorder;
      iconBgColor = AppColors.successDark;
      icon = Icons.task_alt_rounded;
      title = 'Delivered Successfully!';
      subtitle = 'Order completed at ${state.customer.address.split(',').first}';
      titleColor = AppColors.successText;
      subtitleColor = AppColors.successMedium;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderLg,
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
              color: AppColors.white,
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
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
