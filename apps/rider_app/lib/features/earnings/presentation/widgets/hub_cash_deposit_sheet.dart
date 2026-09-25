import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/domain/duty_models.dart';

class HubCashDepositSheet extends StatelessWidget {
  final RiderDutyState dutyState;
  final Future<void> Function() onConfirmDeposit;

  const HubCashDepositSheet({
    super.key,
    required this.dutyState,
    required this.onConfirmDeposit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Text(
                'Hub Cash Settlement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Submit your collected physical cash to the station cashier at your local hub counter to reset your COD safety limit.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Outstanding Cash to Submit:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  formatCurrency(dutyState.codCashInHand),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await onConfirmDeposit();
              },
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                'CONFIRM FULL DEPOSIT (${formatCurrency(dutyState.codCashInHand)})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dutyOnline,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

void showHubCashDepositSheet({
  required BuildContext context,
  required RiderDutyState dutyState,
  required Future<void> Function() onConfirmDeposit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => HubCashDepositSheet(
      dutyState: dutyState,
      onConfirmDeposit: onConfirmDeposit,
    ),
  );
}
