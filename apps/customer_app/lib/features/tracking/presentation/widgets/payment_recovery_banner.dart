import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class PaymentRecoveryBanner extends StatelessWidget {
  final VoidCallback onSwitchToCOD;
  final VoidCallback onRefresh;

  const PaymentRecoveryBanner({
    super.key,
    required this.onSwitchToCOD,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.warningBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded, color: AppColors.warningDark, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Online Payment Pending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.warningText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Kitchen preparation and courier dispatch will begin immediately once payment is confirmed.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.warningTextDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: onSwitchToCOD,
                icon: const Icon(Icons.money_rounded, size: 16),
                label: Text(
                  'Switch to Cash (COD)',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningDark,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: Text(
                  'Refresh',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.warningText),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warningText,
                  side: const BorderSide(color: AppColors.warning),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
