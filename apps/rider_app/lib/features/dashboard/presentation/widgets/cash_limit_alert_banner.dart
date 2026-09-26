import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/duty_models.dart';

class CashLimitAlertBanner extends StatelessWidget {
  final RiderDutyState dutyState;
  final VoidCallback onDeposit;

  const CashLimitAlertBanner({
    super.key,
    required this.dutyState,
    required this.onDeposit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COD SAFETY LIMIT REACHED',
                  style: AppTypography.badgeText.copyWith(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Collected: ${formatCurrency(dutyState.codCashInHand)} / Limit: ${formatCurrency(dutyState.cashSafetyLimit)}. Deposit cash to unblock COD trips.',
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onDeposit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'DEPOSIT',
              style: AppTypography.buttonText.copyWith(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
