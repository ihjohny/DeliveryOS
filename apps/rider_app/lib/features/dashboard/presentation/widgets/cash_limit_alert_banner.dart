import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COD SAFETY LIMIT REACHED',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.error, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'Collected: ${formatCurrency(dutyState.codCashInHand)} / Limit: ${formatCurrency(dutyState.cashSafetyLimit)}. Deposit cash to unblock COD trips.',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onDeposit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('DEPOSIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
