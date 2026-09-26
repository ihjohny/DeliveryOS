import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/trip_models.dart';

class HandoverStepCard extends StatelessWidget {
  final TripOrder trip;
  final bool isUpdating;
  final bool cashCollectedVerified;
  final ValueChanged<bool> onCashVerifiedChanged;
  final Future<void> Function() onCompleteDelivery;
  final VoidCallback onReportIssue;

  const HandoverStepCard({
    super.key,
    required this.trip,
    required this.isUpdating,
    required this.cashCollectedVerified,
    required this.onCashVerifiedChanged,
    required this.onCompleteDelivery,
    required this.onReportIssue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trip.isCod) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.warningBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.warning, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.payments_rounded, color: AppColors.warning, size: 26),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              'CASH ON DELIVERY',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.badgeText.copyWith(fontSize: 13, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      formatCurrency(trip.totalAmount),
                      style: AppTypography.statNumber.copyWith(fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Please collect the exact cash amount shown above from the customer before releasing the food package.',
                  style: AppTypography.caption.copyWith(height: 1.3),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => onCashVerifiedChanged(!cashCollectedVerified),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cashCollectedVerified ? AppColors.dutyOnline : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: cashCollectedVerified,
                          activeColor: AppColors.dutyOnline,
                          onChanged: (val) => onCashVerifiedChanged(val ?? false),
                        ),
                        Expanded(
                          child: Text(
                            'I have collected ${formatCurrency(trip.totalAmount)} in cash from customer',
                            style: AppTypography.bodyBold.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.dutyOnlineBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.dutyOnline, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.dutyOnline, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREPAID ONLINE ORDER',
                        style: AppTypography.badgeText.copyWith(fontSize: 13, color: AppColors.dutyOnline),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'No cash to collect. Hand over food package to customer.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isUpdating || (trip.isCod && !cashCollectedVerified)
                ? null
                : onCompleteDelivery,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dutyOnline,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: isUpdating
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_alt_rounded, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'COMPLETE DELIVERY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.buttonText.copyWith(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onReportIssue,
          icon: const Icon(Icons.person_off_rounded, size: 18, color: AppColors.error),
          label: const Text(
            'Customer Unreachable / Payment Refused?',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
          ),
        ),
      ],
    );
  }
}
