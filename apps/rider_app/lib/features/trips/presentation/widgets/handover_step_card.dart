import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
            padding: const EdgeInsets.all(20),
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
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.payments_rounded, color: AppColors.warning, size: 26),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'CASH ON DELIVERY',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatCurrency(trip.totalAmount),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please collect the exact cash amount shown above from the customer before releasing the food package.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => onCashVerifiedChanged(!cashCollectedVerified),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dutyOnlineBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.dutyOnline, width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.dutyOnline, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREPAID ONLINE ORDER',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.dutyOnline),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No cash to collect. Hand over food package to customer.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isUpdating || (trip.isCod && !cashCollectedVerified)
                ? null
                : onCompleteDelivery,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dutyOnline,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: isUpdating
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt_rounded, size: 22),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'COMPLETE DELIVERY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
