import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
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
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hub Cash Settlement',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h2.copyWith(fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Submit your collected physical cash to the station cashier at your local hub counter to reset your COD safety limit.',
              style: AppTypography.caption.copyWith(fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Outstanding Cash to Submit:',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyBold.copyWith(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    formatCurrency(dutyState.codCashInHand),
                    style: AppTypography.h2.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.buttonText.copyWith(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dutyOnline,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.xxl)),
    ),
    builder: (_) => HubCashDepositSheet(
      dutyState: dutyState,
      onConfirmDeposit: onConfirmDeposit,
    ),
  );
}
