import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/metric_tile.dart';
import '../../domain/duty_models.dart';

class PerformanceMetricsCard extends StatelessWidget {
  final RiderDutyState dutyState;
  final VoidCallback onOpenEarnings;

  const PerformanceMetricsCard({
    super.key,
    required this.dutyState,
    required this.onOpenEarnings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TODAY\'S PERFORMANCE',
              style: AppTypography.badgeText.copyWith(color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: onOpenEarnings,
              child: Text(
                'View All ➔',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                title: 'Completed Trips',
                value: '${dutyState.todayTrips}',
                icon: Icons.task_alt_rounded,
                iconColor: AppColors.dutyOnline,
                onTap: onOpenEarnings,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: MetricTile(
                title: 'Earned Payout',
                value: formatCurrency(dutyState.todayEarnings),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.primary,
                onTap: onOpenEarnings,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: onOpenEarnings,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.roundedLg,
              border: Border.all(
                color: dutyState.isCashLimitReached ? AppColors.error : AppColors.border,
                width: dutyState.isCashLimitReached ? 1.5 : 1.0,
              ),
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
                          Icon(Icons.payments_rounded, color: AppColors.warning, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              'COD Cash in Hand',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${formatCurrency(dutyState.codCashInHand)} / ${formatCurrency(dutyState.cashSafetyLimit)}',
                      style: AppTypography.bodyBold.copyWith(
                        color: dutyState.isCashLimitReached ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (dutyState.codCashInHand / dutyState.cashSafetyLimit).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      dutyState.isCashLimitReached ? AppColors.error : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dutyState.isCashLimitReached
                            ? '⚠️ Cash safety limit reached! Deposit cash to accept more COD orders.'
                            : 'Safe limit remaining: ${formatCurrency(dutyState.remainingCashLimit)}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: dutyState.isCashLimitReached ? AppColors.error : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
